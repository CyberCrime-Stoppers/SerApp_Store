import QtQuick
import QtQuick.Controls.Basic

Rectangle {
    id: card
    width: 240
    height: 300
    radius: 12
    color: "#203026"
    border.color: mouse.containsMouse ? "#7fa37a" : "#2f4035"
    border.width: mouse.containsMouse ? 2 : 1

    signal clicked()
    property string name: ""
    property string developer: ""
    property string summary: ""
    property string category: ""
    property string iconUrl: ""
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

        Rectangle {   // app icon: real icon from iconUrl, sparkle fallback
            width: 96; height: 96; radius: 14
            color: "#2f4035"
            anchors.horizontalCenter: parent.horizontalCenter

            Image {
                id: iconImage
                anchors.fill: parent
                anchors.margins: 8
                fillMode: Image.PreserveAspectFit
                source: card.iconUrl
                asynchronous: true
                visible: status === Image.Ready
            }

            Label {
                anchors.centerIn: parent
                visible: iconImage.status !== Image.Ready
                text: card.category === "media" ? "♪"
                    : card.category === "system" ? "⚙"
                    : card.category === "utilities" && card.summary.toLowerCase().includes("disk") ? "▤"
                    : card.category === "games" ? "◆" : "✦"
                color: "#a9c5a4"
                font.pixelSize: 40
            }
        }

        Label {
            text: card.name
            color: "#dde6da"
            font.pixelSize: 16
            font.bold: true
            elide: Text.ElideRight
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
        }
        Label {
            text: card.developer
            color: "#9db29a"
            font.pixelSize: 11
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Label {
            text: card.summary
            color: "#b7c6b4"
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
            color: card.installed ? "#7fa37a" : "#d4b76a"
            font.pixelSize: 12
            font.bold: true
        }
    }
}
