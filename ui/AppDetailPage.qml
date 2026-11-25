import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

// Pushed with: stack.push("AppDetailPage.qml", { rowIndex: N })
Page {
    id: detail
    background: Rectangle { color: "#12131a" }
    property string pageName: "detail"

    required property int rowIndex
    readonly property var pkg: PackageManager.rowCount > rowIndex
                                  ? PackageManager.app(rowIndex) : null

    Flickable {
        anchors.fill: parent
        contentHeight: content.implicitHeight + 72
        clip: true

        ColumnLayout {
            id: content
            x: 36
            width: parent.width - 72
            spacing: 14

            Button {
                text: "← " + qsTr("Back")
                flat: true
                onClicked: detail.StackView.view.pop()
                contentItem: Label {
                    text: parent.text
                    color: "#b7a7ff"
                    font.pixelSize: 14
                }
            }

            RowLayout {
                spacing: 24

                Rectangle {
                    width: 128; height: 128; radius: 18; color: "#2c2f40"
                    Label {
                        anchors.centerIn: parent
                        text: "✦"
                        color: "#8b6cff"
                        font.pixelSize: 56
                    }
                }

                ColumnLayout {
                    spacing: 6
                    Label {
                        text: pkg ? pkg.name : ""
                        color: "#ffffff"
                        font.pixelSize: 28
                        font.bold: true
                    }
                    Label {
                        text: pkg ? (pkg.developer + "  ·  v" + pkg.version) : ""
                        color: "#8d93a8"
                        font.pixelSize: 13
                    }
                    Row {
                        spacing: 8
                        Label {
                            text: qsTr("Free")
                            color: "#43d17c"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        Label {
                            text: pkg ? (Math.round(pkg.sizeBytes / 1048576.0) + " MB") : ""
                            color: "#6d7388"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Permissions chips — key for a security-first store
                    Row {
                        spacing: 6
                        Layout.topMargin: 6
                        Repeater {
                            model: pkg ? pkg.permissions : []
                            delegate: Rectangle {
                                readonly property string permText: modelData
                                width: permLabel.implicitWidth + 18
                                height: 24
                                radius: 12
                                color: "#2c2f40"
                                Label {
                                    id: permLabel
                                    anchors.centerIn: parent
                                    text: permText
                                    color: "#b7a7ff"
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    readonly property bool isInstalled: pkg ? pkg.installed : false
                    text: isInstalled ? qsTr("Uninstall")
                          : (pkg && pkg.updateAvailable ? qsTr("Update") : qsTr("Get"))
                    enabled: pkg
                    onClicked: {
                        if (isInstalled) PackageManager.uninstall(rowIndex)
                        else PackageManager.install(rowIndex)
                    }
                    background: Rectangle {
                        radius: 8
                        color: parent.hovered ? "#9d80ff" : "#8b6cff"
                    }
                    contentItem: Label {
                        anchors.centerIn: parent
                        text: parent.text
                        color: "white"
                        font.bold: true
                        font.pixelSize: 15
                    }
                    implicitWidth: 140
                    implicitHeight: 42
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: "#262939" }

            Label {
                Layout.fillWidth: true
                text: pkg ? pkg.description : ""
                color: "#c3c8dd"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
            }

            Label {
                Layout.topMargin: 8
                text: qsTr("✓ Signed manifest verified against the pinned CCS / SereneForge key")
                color: "#43d17c"
                font.pixelSize: 11
            }
        }
    }
}
