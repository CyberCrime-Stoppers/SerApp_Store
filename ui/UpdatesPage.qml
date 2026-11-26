import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Page {
    id: updates
    background: Rectangle { color: "#16201a" }
    property string pageName: "updates"

    ColumnLayout {
        anchors { fill: parent; margins: 24 }
        spacing: 16

        Label {
            text: qsTr("Updates") + (PackageManager.updateCount > 0
                  ? "  (" + PackageManager.updateCount + ")" : "")
            color: "#dde6da"
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
                        color: "#203026"
                        visible: showMe

                        RowLayout {
                            anchors { fill: parent; margins: 14 }
                            spacing: 14

                            Rectangle {
                                width: 40; height: 40; radius: 8
                                color: "#2f4035"
                                Label {
                                    anchors.centerIn: parent
                                    text: "⟳"
                                    color: "#a9c5a4"
                                    font.pixelSize: 20
                                }
                            }

                            ColumnLayout {
                                spacing: 2
                                Label {
                                    text: model.name
                                    color: "#dde6da"
                                    font.bold: true
                                    font.pixelSize: 15
                                }
                                Label {
                                    text: qsTr("New version %1 available")
                                          .arg(model.version)
                                    color: "#9db29a"
                                    font.pixelSize: 12
                                }
                            }

                            Item { Layout.fillWidth: true }

                            Button {
                                text: qsTr("Update")
                                onClicked: PackageManager.install(updRow.index)
                                background: Rectangle {
                                    radius: 6
                                    color: parent.hovered ? "#8fb18a" : "#7fa37a"
                                }
                                contentItem: Label {
                                    anchors.centerIn: parent
                                    text: parent.text
                                    color: "#16201a"
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
            color: "#7fa37a"
            font.pixelSize: 15
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 40
        }
    }
}
