import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Page {
    id: updates
    background: Rectangle { color: "#12131a" }
    property string pageName: "updates"

    ColumnLayout {
        anchors { fill: parent; margins: 24 }
        spacing: 16

        Label {
            text: qsTr("Updates") + (PackageManager.updateCount > 0
                  ? "  (" + PackageManager.updateCount + ")" : "")
            color: "#eae8ff"
            font.pixelSize: 20
            font.bold: true
            Layout.topMargin: 12
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: updateCol.height
            clip: true

            ColumnLayout {
                id: updateCol
                width: parent.width
                spacing: 12

                Repeater {
                    model: PackageManager
                    delegate: Rectangle {
                        id: updRow
                        required property int index
                        readonly property bool showMe: model.updateAvailable

                        Layout.fillWidth: true
                        height: showMe ? 72 : 0
                        radius: 10
                        color: "#1c1e28"
                        visible: showMe

                        RowLayout {
                            anchors { fill: parent; margins: 14 }
                            spacing: 14

                            Rectangle {
                                width: 40; height: 40; radius: 8
                                color: "#2c2f40"
                                Label {
                                    anchors.centerIn: parent
                                    text: "⟳"
                                    color: "#8b6cff"
                                    font.pixelSize: 20
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Label {
                                    text: model.name
                                    color: "#eae8ff"
                                    font.bold: true
                                    font.pixelSize: 15
                                }
                                Label {
                                    text: qsTr("New version %1 available")
                                          .arg(model.version)
                                    color: "#8d93a8"
                                    font.pixelSize: 12
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Button {
                                text: qsTr("Update")
                                onClicked: PackageManager.install(updRow.index)
                                background: Rectangle {
                                    radius: 6
                                    color: parent.hovered ? "#9d80ff" : "#8b6cff"
                                }
                                contentItem: Label {
                                    anchors.centerIn: parent
                                    text: parent.text
                                    color: "white"
                                    font.bold: true
                                }
                            }
                        }
                    }
                }
            }
        }

        Label {
            visible: PackageManager.updateCount === 0
            text: qsTr("Everything is up to date ✦")
            color: "#43d17c"
            font.pixelSize: 15
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 40
        }
    }
}
