import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Rectangle {
    id: rail
    width: 220
    color: "#131b15"

    property int updateCount: 0
    signal pageSelected(string page)   // "home" | "browse" | "library" | "updates"

    QtObject {
        id: defs
        property var entries: [
            { key: "home",     text: qsTr("Home"),    icon: "✦" },
            { key: "browse",   text: qsTr("Browse"),  icon: "⌕" },
            { key: "library",  text: qsTr("Library"), icon: "▤" },
            { key: "updates",  text: qsTr("Updates"), icon: "↓" }
        ]
    }

    property string currentPage: "home"

    ColumnLayout {
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left; right: parent.right }
        anchors.margins: 14
        spacing: 4

        // Brand header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 56
            radius: 10
            color: "#1d2a21"
            Label {
                anchors.centerIn: parent
                text: "✦ SerApp Store"
                color: "#a9c5a4"
                font.pixelSize: 18
                font.bold: true
            }
        }

        Repeater {
            model: defs.entries.length
            delegate: Button {
                id: navBtn
                required property int index
                readonly property var entry: defs.entries[index]

                Layout.fillWidth: true
                flat: true

                checked: rail.currentPage === navBtn.entry.key
                onClicked: {
                    rail.currentPage = navBtn.entry.key
                    rail.pageSelected(navBtn.entry.key)
                }

                contentItem: RowLayout {
                    spacing: 10
                    Label { text: navBtn.entry.icon; color: "#a9c5a4"; font.pixelSize: 16 }
                    Label {
                        text: navBtn.entry.text
                        color: navBtn.checked ? "#dde6da" : "#9db29a"
                        font.bold: navBtn.checked
                        Layout.fillWidth: true
                    }
                    Rectangle {
                        visible: navBtn.entry.key === "updates" && rail.updateCount > 0
                        width: 26; height: 20; radius: 10
                        color: "#c98372"
                        Label {
                            anchors.centerIn: parent
                            text: rail.updateCount
                            color: "white"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }
                background: Rectangle {
                    radius: 8
                    color: navBtn.checked ? "#2f4035"
                         : (navBtn.hovered ? "#1d2a21" : "transparent")
                }
            }
        }

        Item { Layout.fillHeight: true } // spacer

        Label {
            Layout.fillWidth: true
            text: qsTr("Signed & verified by\nCCS / SereneForge")
            color: "#5a6b58"
            font.pixelSize: 10
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
