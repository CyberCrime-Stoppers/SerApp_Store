import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Page {
    id: home
    background: Rectangle { color: "#12131a" }
    property string pageName: "home"

    property bool hasApps: PackageManager.rowCount > 0
    property var firstApp: hasApps ? PackageManager.app(0) : null

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight + 120
        clip: true

        ColumnLayout {
            id: col
            x: 36
            width: parent.width - 72
            spacing: 24

            HeroBanner {
                Layout.topMargin: 24
                Layout.fillWidth: true
                appName: firstApp ? firstApp.name : qsTr("Welcome to SerApp Store")
                tagline: firstApp ? firstApp.summary
                                  : qsTr("Apps by CCS / SereneForge, signed and verified.")
                onOpenClicked: {
                    if (hasApps)
                        stackRef.push(detailComp, { rowIndex: 0 })
                }
            }

            Label {
                text: qsTr("All apps")
                color: "#eae8ff"
                font.pixelSize: 20
                font.bold: true
            }

            GridLayout {
                columns: Math.max(1, Math.floor(width / 256))
                columnSpacing: 16
                rowSpacing: 16
                Layout.fillWidth: true

                Repeater {
                    model: PackageManager
                    delegate: AppCard {
                        id: delegateCard
                        required property int index

                        Layout.preferredWidth: 240
                        name: model.name
                        developer: model.developer
                        summary: model.summary
                        category: model.category
                        installed: model.installed
                        onClicked: stackRef.push(detailComp, { rowIndex: index })
                    }
                }
            }
        }
    }

    // Access to the enclosing StackView for pushing detail pages
    readonly property StackView stackRef: home.StackView.view
    Component { id: detailComp; AppDetailPage {} }

    BusyIndicator {
        anchors.centerIn: parent
        visible: PackageManager.loading
    }

    Label {
        anchors.centerIn: parent
        visible: !PackageManager.loading && PackageManager.rowCount === 0 && PackageManager.lastError === ""
        text: qsTr("Loading store index…")
        color: "#6d7388"
        font.pixelSize: 15
    }

    Label {
        anchors { left: parent.left; right: parent.right; margins: 36; bottom: parent.bottom; bottomMargin: 16 }
        visible: PackageManager.lastError !== ""
        text: PackageManager.lastError
        color: "#ff5470"
        font.pixelSize: 12
        wrapMode: Text.WordWrap
    }
}
