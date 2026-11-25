import QtQuick

Row {
    id: stars
    property real rating: 0      // 0.0 – 5.0
    property int starSize: 14
    spacing: 2

    Repeater {
        model: 5
        delegate: Label {
            required property int index
            width: stars.starSize
            height: stars.starSize
            text: index < Math.round(stars.rating) ? "★" : "☆"
            color: index < Math.round(stars.rating) ? "#ffc94d" : "#4a4f63"
            font.pixelSize: stars.starSize
        }
    }
}
