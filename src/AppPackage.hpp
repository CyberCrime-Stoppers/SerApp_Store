#pragma once
#include <QObject>
#include <QString>
#include <QUrl>
#include <QStringList>

class AppPackage : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString appId READ appId CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString developer READ developer CONSTANT)
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString category READ category CONSTANT)
    Q_PROPERTY(QString summary READ summary CONSTANT)
    Q_PROPERTY(QString description READ description CONSTANT)
    Q_PROPERTY(QUrl iconUrl READ iconUrl CONSTANT)
    Q_PROPERTY(QUrl packageUrl READ packageUrl CONSTANT)
    Q_PROPERTY(QString packageSha256 READ packageSha256 CONSTANT)
    Q_PROPERTY(qint64 sizeBytes READ sizeBytes CONSTANT)
    Q_PROPERTY(QStringList permissions READ permissions CONSTANT)
    Q_PROPERTY(bool installed READ installed NOTIFY installedChanged)
    Q_PROPERTY(bool updateAvailable READ updateAvailable NOTIFY updateAvailableChanged)

public:
    explicit AppPackage(QObject *parent = nullptr) : QObject(parent) {}

    QString appId() const { return m_appId; }
    QString name() const { return m_name; }
    QString developer() const { return m_developer; }
    QString version() const { return m_version; }
    QString category() const { return m_category; }
    QString summary() const { return m_summary; }
    QString description() const { return m_description; }
    QUrl iconUrl() const { return m_iconUrl; }
    QUrl packageUrl() const { return m_packageUrl; }
    QString packageSha256() const { return m_packageSha256; }
    qint64 sizeBytes() const { return m_sizeBytes; }
    QStringList permissions() const { return m_permissions; }
    bool installed() const { return m_installed; }
    bool updateAvailable() const { return m_updateAvailable; }

    // Populated by PackageManager when parsing a verified manifest
    void setData(const QString &appId, const QString &name, const QString &developer,
                 const QString &version, const QString &category, const QString &summary,
                 const QString &description, const QUrl &iconUrl, const QUrl &packageUrl,
                 const QString &packageSha256, qint64 sizeBytes, const QStringList &permissions)
    {
        m_appId = appId; m_name = name; m_developer = developer; m_version = version;
        m_category = category; m_summary = summary; m_description = description;
        m_iconUrl = iconUrl; m_packageUrl = packageUrl; m_packageSha256 = packageSha256;
        m_sizeBytes = sizeBytes; m_permissions = permissions;
    }

    void setInstalled(bool installed) {
        if (m_installed == installed) return;
        m_installed = installed;
        emit installedChanged();
    }
    void setUpdateAvailable(bool avail) {
        if (m_updateAvailable == avail) return;
        m_updateAvailable = avail;
        emit updateAvailableChanged();
    }

signals:
    void installedChanged();
    void updateAvailableChanged();

private:
    QString m_appId, m_name, m_developer, m_version, m_category,
            m_summary, m_description, m_packageSha256;
    QUrl m_iconUrl, m_packageUrl;
    qint64 m_sizeBytes = 0;
    QStringList m_permissions;
    bool m_installed = false;
    bool m_updateAvailable = false;
};
