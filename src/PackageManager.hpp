#pragma once
#include <QObject>
#include <QAbstractListModel>
#include <QNetworkAccessManager>
#include "AppPackage.hpp"
#include "SignatureVerifier.hpp"

/*
 * PackageManager — the model + install engine behind the whole store.
 *
 * Exposes to QML:
 *   - a list model (apps) with roles: appId, name, developer, version,
 *     category, summary, iconUrl, sizeBytes, installed, updateAvailable,
 *     packageObject
 *   - properties: updateCount, loading, lastError
 *   - invokables: refresh(), app(row), install(row), uninstall(row),
 *     loadInstalled()
 *   - signals: installFinished(appId, success), progressChanged(appId,
 *     received, total)
 *
 * Security model:
 *   - Store index is a JSON array of signed canonical manifests.
 *   - FAIL-CLOSED: if ANY manifest fails Ed25519 verification against the
 *     pinned CCS/SereneForge key, the whole index fetch is rejected.
 *   - Downloaded tarballs must match the manifest's packageSha256 before
 *     extraction; install is staged then atomically renamed into place.
 */
class PackageManager : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int updateCount READ updateCount NOTIFY updateCountChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)

public:
    enum Roles {
        AppIdRole = Qt::UserRole + 1,
        NameRole, DeveloperRole, VersionRole, CategoryRole,
        SummaryRole, IconUrlRole, SizeBytesRole,
        InstalledRole, UpdateAvailableRole, PackageObjectRole
    };
    Q_ENUM(Roles)

    explicit PackageManager(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = {}) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int updateCount() const;
    bool loading() const;
    QString lastError() const;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE AppPackage *app(int row) const;
    Q_INVOKABLE void install(int row);
    Q_INVOKABLE void uninstall(int row);
    Q_INVOKABLE void loadInstalled();

signals:
    void updateCountChanged();
    void loadingChanged();
    void lastErrorChanged();
    void installFinished(const QString &appId, bool success);
    void progressChanged(const QString &appId, qint64 received, qint64 total);

private:
    void parseIndex(const QByteArray &payload);
    void scanInstalledDir();
    QString downloadAndStage(AppPackage *pkg);      // stage 1+2, returns staged archive path ("" on failure)
    bool extractStaged(AppPackage *pkg, const QString &archivePath); // stage 3+4

    QList<AppPackage *> m_apps;
    QNetworkAccessManager m_nam;
    SignatureVerifier m_verifier;
    bool m_loading = false;
    QString m_lastError;

    // Local install root; SERENE_STORE_ROOT env var overrides for dev/testing
    QString m_installRoot;
};
