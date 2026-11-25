#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include "PackageManager.hpp"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("CCS"));
    app.setApplicationName(QStringLiteral("SereneAppStore"));

    QQuickStyle::setStyle(QStringLiteral("Basic"));

    PackageManager packageManager;
    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("PackageManager"), &packageManager);
    engine.loadFromModule("SereneAppStore", "Main");
    if (engine.rootObjects().isEmpty())
        return -1;
    return app.exec();
}
