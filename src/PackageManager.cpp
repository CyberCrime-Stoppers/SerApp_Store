#include "PackageManager.hpp"
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QSaveFile>
#include <QProcess>
#include <QSettings>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QTemporaryDir>
#include <QCryptographicHash>
#include <QEventLoop>
#include <QSet>
#include <QFileInfo>

static const char *INDEX_URL = "https://store.sereneforge.org/index.json";

PackageManager::PackageManager(QObject *parent)
    : QAbstractListModel(parent)
{
    m_installRoot = qEnvironmentVariable("SERENE_STORE_ROOT",
                                         QStringLiteral("/opt/sereneos/store-apps"));
    loadInstalled();
}

int PackageManager::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_apps.size();
}

QVariant PackageManager::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_apps.size())
        return {};
    AppPackage *a = m_apps.at(index.row());
    switch (role) {
        case AppIdRole:           return a->appId();
        case NameRole:            return a->name();
        case DeveloperRole:       return a->developer();
        case VersionRole:         return a->version();
        case CategoryRole:        return a->category();
        case SummaryRole:         return a->summary();
        case IconUrlRole:         return a->iconUrl();
        case SizeBytesRole:       return a->sizeBytes();
        case InstalledRole:       return a->installed();
        case UpdateAvailableRole: return a->updateAvailable();
        case PackageObjectRole:   return QVariant::fromValue(a);
    }
    return {};
}

QHash<int, QByteArray> PackageManager::roleNames() const
{
    return {
        {AppIdRole,           "appId"},
        {NameRole,            "name"},
        {DeveloperRole,       "developer"},
        {VersionRole,         "version"},
        {CategoryRole,        "category"},
        {SummaryRole,         "summary"},
        {IconUrlRole,         "iconUrl"},
        {SizeBytesRole,       "sizeBytes"},
        {InstalledRole,       "installed"},
        {UpdateAvailableRole, "updateAvailable"},
        {PackageObjectRole,   "packageObject"}
    };
}

int PackageManager::updateCount() const
{
    int n = 0;
    for (const auto *a : std::as_const(m_apps))
        if (a->updateAvailable()) ++n;
    return n;
}

bool PackageManager::loading() const { return m_loading; }
QString PackageManager::lastError() const { return m_lastError; }

void PackageManager::refresh()
{
    if (m_loading) return;
    m_loading = true;
    emit loadingChanged();

    QNetworkRequest req{QUrl(QString::fromLatin1(INDEX_URL))};
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                     QNetworkRequest::NoLessSafeRedirectPolicy);
    QNetworkReply *reply = m_nam.get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply] {
        reply->deleteLater();
        m_loading = false;
        emit loadingChanged();

        if (reply->error() != QNetworkReply::NoError) {
            m_lastError = reply->errorString();
            emit lastErrorChanged();
            return;
        }
        parseIndex(reply->readAll());
    });
}

// FAIL-CLOSED: EVERY manifest entry must pass signature verification against
// the pinned key. One bad signature rejects the whole index load — a tampered
// app should never silently appear in the store list.
void PackageManager::parseIndex(const QByteArray &payload)
{
    QJsonParseError err;
    const QJsonDocument doc = QJsonDocument::fromJson(payload, &err);
    if (err.error != QJsonParseError::NoError || !doc.isArray()) {
        m_lastError = QStringLiteral("Malformed store index");
        emit lastErrorChanged();
        return;
    }

    QList<AppPackage *> parsed;
    bool anyBad = false;
    QString badReason;

    for (const QJsonValue &v : doc.array()) {
        const QJsonObject obj = v.toObject();
        const QString appId = obj.value("appId").toString();
        const QString sig = obj.value("signature").toString();

        // Verify BEFORE trusting any field from the manifest.
        // The signature covers the canonical manifest — the index serves
        // each manifest's canonical bytes alongside the entry; here we
        // re-canonicalize the entry object (sorted keys, no whitespace)
        // and verify those bytes. A mismatch in ANY field breaks the sig.
        const QJsonDocument canonicalDoc(obj);
        const QByteArray canonical = canonicalDoc.toJson(QJsonDocument::Compact);

        AppPackage *pkg = new AppPackage(this);
        pkg->setData(appId,
                     obj.value("name").toString(),
                     obj.value("developer").toString(),
                     obj.value("version").toString(),
                     obj.value("category").toString(),
                     obj.value("summary").toString(),
                     obj.value("description").toString(),
                     QUrl(obj.value("iconUrl").toString()),
                     QUrl(obj.value("packageUrl").toString()),
                     obj.value("packageSha256").toString(),
                     static_cast<qint64>(obj.value("sizeBytes").toDouble(0)),
                     obj.value("permissions").toVariant().toStringList());

        if (!m_verifier.verifyManifest(canonical, sig)) {
            anyBad = true;
            badReason = appId.isEmpty() ? QStringLiteral("(unknown app)") : appId;
            delete pkg;
            break;
        }
        parsed.append(pkg);
    }

    if (anyBad) {
        qDeleteAll(parsed);
        parsed.clear();
        m_lastError = QStringLiteral("Signature verification FAILED for %1 — index rejected")
                          .arg(badReason);
        emit lastErrorChanged();
        return;
    }

    beginResetModel();
    qDeleteAll(m_apps);
    m_apps = parsed;
    endResetModel();

    scanInstalledDir();
    emit updateCountChanged();
}

AppPackage *PackageManager::app(int row) const
{
    return (row >= 0 && row < m_apps.size()) ? m_apps.at(row) : nullptr;
}

void PackageManager::scanInstalledDir()
{
    QDir root(m_installRoot);
    const QFileInfoList dirs =
        root.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
    QSet<QString> installedIds;
    for (const QFileInfo &fi : dirs)
        installedIds.insert(fi.fileName());

    for (AppPackage *a : std::as_const(m_apps)) {
        const bool isInstalled = installedIds.contains(a->appId());
        a->setInstalled(isInstalled);

        if (isInstalled) {
            QSettings s(QStringLiteral("%1/%2/state.ini")
                            .arg(m_installRoot, a->appId()),
                        QSettings::IniFormat);
            const QString installedVer = s.value("version").toString();
            a->setUpdateAvailable(!installedVer.isEmpty()
                                  && installedVer != a->version());
        } else {
            a->setUpdateAvailable(false);
        }
    }
    emit updateCountChanged();
}

void PackageManager::loadInstalled() { scanInstalledDir(); }

// ---------------------------------------------------------------------------
// Install pipeline
//   stage 1: download packageUrl to a staging temp file
//   stage 2: verify sha256 matches manifest's packageSha256 (integrity)
//   stage 3: extract into <root>/<appId>.tmp
//   stage 4: atomic rename to <root>/<appId>; write state.ini
// ---------------------------------------------------------------------------
void PackageManager::install(int row)
{
    AppPackage *pkg = app(row);
    if (!pkg || pkg->appId().isEmpty() || pkg->packageUrl().isEmpty())
        return;

    const QString appId = pkg->appId();
    const QString archivePath = downloadAndStage(pkg);
    if (archivePath.isEmpty()) {
        emit installFinished(appId, false);
        return;
    }
    const bool ok = extractStaged(pkg, archivePath);
    QFile::remove(archivePath);
    emit installFinished(appId, ok);
    scanInstalledDir();
}

QString PackageManager::downloadAndStage(AppPackage *pkg)
{
    QNetworkRequest req{pkg->packageUrl()};
    req.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                     QNetworkRequest::NoLessSafeRedirectPolicy);

    QNetworkReply *reply = m_nam.get(req);
    QCryptographicHash hasher(QCryptographicHash::Sha256);
    QTemporaryDir staging;
    if (!staging.isValid()) {
        m_lastError = QStringLiteral("Could not create staging directory");
        emit lastErrorChanged();
        return {};
    }
    const QString path = staging.filePath(QStringLiteral("pkg.bin"));
    QFile out(path);
    if (!out.open(QIODevice::WriteOnly)) {
        m_lastError = QStringLiteral("Could not write staging file");
        emit lastErrorChanged();
        return {};
    }

    // Synchronous within the caller for simplicity — fine for modest app
    // payloads; swap to a worker thread + QEventLoop-free streaming later.
    QEventLoop loop;
    connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
    connect(reply, &QNetworkReply::readyRead, this, [&] {
        const QByteArray chunk = reply->readAll();
        hasher.addData(chunk);
        out.write(chunk);
        emit progressChanged(pkg->appId(), out.pos(), reply->header(
            QNetworkRequest::ContentLengthHeader).toLongLong());
    });
    loop.exec();
    out.close();
    reply->deleteLater();

    if (reply->error() != QNetworkReply::NoError) {
        m_lastError = reply->errorString();
        emit lastErrorChanged();
        return {};
    }

    // Integrity gate — hash mismatch = corrupted OR tampered tarball.
    const QByteArray digest = hasher.result().toHex();
    if (!QString::fromLatin1(digest)
             .compare(pkg->packageSha256(), Qt::CaseInsensitive) == 0) {
        m_lastError = QStringLiteral("SHA-256 mismatch for %1 — download rejected")
                          .arg(pkg->appId());
        emit lastErrorChanged();
        return {};
    }

    // Move out of the (auto-deleted) TemporaryDir into a durable temp spot.
    const QString durable =
        QDir::temp().filePath(QStringLiteral("serapp_%1.bin").arg(pkg->appId()));
    QFile::remove(durable);
    if (!QFile::rename(path, durable)) {
        m_lastError = QStringLiteral("Could not stage download");
        emit lastErrorChanged();
        return {};
    }
    return durable;
}

bool PackageManager::extractStaged(AppPackage *pkg, const QString &archivePath)
{
    const QString finalDir = QStringLiteral("%1/%2").arg(m_installRoot, pkg->appId());
    const QString tmpDir = finalDir + QStringLiteral(".tmp");

    QDir rootDir(m_installRoot);
    if (!rootDir.mkpath(QStringLiteral("."))) {
        m_lastError = QStringLiteral("Cannot create install root");
        emit lastErrorChanged();
        return false;
    }
    QDir(tmpDir).removeRecursively();
    if (!rootDir.mkpath(pkg->appId() + QStringLiteral(".tmp"))) {
        m_lastError = QStringLiteral("Cannot create staging dir");
        emit lastErrorChanged();
        return false;
    }

    // Extraction via system tar (zstd-compressed tarballs per manifest spec).
    QProcess proc;
    proc.setProgram(QStringLiteral("/usr/bin/tar"));
    proc.setArguments({QStringLiteral("-I"), QStringLiteral("zstd"),
                       QStringLiteral("-xf"), archivePath,
                       QStringLiteral("-C"), tmpDir});
    proc.start();
    if (!proc.waitForStarted(5000) || !proc.waitForFinished(-1) ||
        proc.exitCode() != 0) {
        m_lastError = QStringLiteral("Extraction failed: %1")
                          .arg(QString::fromLocal8Bit(proc.readAllStandardError()));
        emit lastErrorChanged();
        QDir(tmpDir).removeRecursively();
        return false;
    }

    // Atomic swap: old install (if any) moved aside, new dir renamed in.
    if (QDir(finalDir).exists()) {
        const QString backup = finalDir + QStringLiteral(".old");
        QDir(backup).removeRecursively();
        QDir().rename(finalDir, backup);
        QDir().rename(tmpDir, finalDir);
        QDir(backup).removeRecursively();
    } else {
        QDir().rename(tmpDir, finalDir);
    }

    // Persist installed version so update detection works across launches.
    QSettings s(QStringLiteral("%1/state.ini").arg(finalDir), QSettings::IniFormat);
    s.setValue("version", pkg->version());
    s.sync();
    return true;
}

void PackageManager::uninstall(int row)
{
    AppPackage *pkg = app(row);
    if (!pkg || pkg->appId().isEmpty()) return;
    QDir(QStringLiteral("%1/%2").arg(m_installRoot, pkg->appId())).removeRecursively();
    pkg->setInstalled(false);
    pkg->setUpdateAvailable(false);
    emit updateCountChanged();
}
