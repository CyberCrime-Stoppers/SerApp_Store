import QtQuick
import QtQuick.Controls.Basic

Rectangle {
    id: card
    width: 240
    height: 300
    radius: 12
    color: "#1c1e28"
    border.color: mouse.containsMouse ? "#8b6cff" : "#262939"
    border.width: mouse.containsMouse ? 2 : 1

    signal clicked()
    property string name: ""
    property string developer: ""
    property string summary: ""
    property string category: ""
    property bool installed: false

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
    }

    Column {
        anchors { fill: parent; margins: 14; topMargin: 18 }
        spacing: 8

        Rectangle {   // icon placeholder until icon downloads are wired
            width: 96; height: 96; radius: 14
            color: "#2c2f40"
            anchors.horizontalCenter: parent.horizontalCenter
            Label {
                anchors.centerIn: parent
                text: card.category === "media" ? "♪"
                    : card.category === "system" ? "⚙"
                    : card.category === "games" ? "◆" : "✦"
                color: "#8b6cff"
                font.pixelSize: 40
            }
        }

        Label {
            text: card.name
            color: "#eae8ff"
            font.pixelSize: 16
            font.bold: true
            elide: Text.ElideRight
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }
        Label {
            text: card.developer
            color: "#8d93a8"
            font.pixelSize: 11
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Label {
            text: card.summary
            color: "#aab0c6"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            width: parent.width
            maximumLineCount: 3
            elide: Text.ElideRight
            height: 3 * (font.pixelSize + 6)
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: card.installed ? qsTr("✓ Installed") : qsTr("Free · Get")
            color: card.installed ? "#43d17c" : "#8b6cff"
            font.pixelSize: 12
            font.bold: true
        }
    }
}
