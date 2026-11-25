import QtQuick
import QtQuick.Controls.Basic

// Featured app banner — store-style hero, SereneOS palette
Rectangle {
    id: hero
    radius: 16
    height: 260
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "#2a2350" }
        GradientStop { position: 1.0; color: "#171923" }
    }

    property string appName: ""
    property string tagline: ""
    signal openClicked()

    Column {
        anchors { left: parent.left; leftMargin: 36; verticalCenter: parent.verticalCenter }
        spacing: 12
        width: Math.min(520, parent.width - 72)

        Label { text: qsTr("FEATURED"); color: "#b7a7ff"; font.pixelSize: 12; font.bold: true }
        Label {
            text: hero.appName
            color: "#ffffff"
            font.pixelSize: 34
            font.bold: true
            elide: Text.ElideRight
            width: parent.width
        }
        Label {
            text: hero.tagline
            color: "#c3c8dd"
            font.pixelSize: 15
            wrapMode: Text.WordWrap
            width: parent.width
            elide: Text.ElideRight
            maximumLineCount: 2
        }
        Button {
            text: qsTr("View")
            onClicked: hero.openClicked()
            background: Rectangle {
                radius: 6
                color: parent.hovered ? "#9d80ff" : "#8b6cff"
            }
            contentItem: Label {
                text: parent.text
                color: "white"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    Rectangle {   // decorative glow circle
        width: 320; height: 320; radius: 160
        color: "#3a2f7a"
        opacity: 0.55
        anchors { right: parent.right; rightMargin: -90; verticalCenter: parent.verticalCenter }
    }
}
