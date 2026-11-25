import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Page {
    id: browse
    background: Rectangle { color: "#12131a" }
    property string pageName: "browse"

    ColumnLayout {
        anchors { fill: parent; margins: 24 }
        spacing: 16

        TextField {
            id: search
            Layout.fillWidth: true
            Layout.topMargin: 12
            placeholderText: qsTr("Search apps, categories, developers…")
            color: "#eae8ff"
            font.pixelSize: 14

            background: Rectangle {
                radius: 8
                color: "#1c1e28"
                border.color: search.activeFocus ? "#8b6cff" : "#262939"
                border.width: search.activeFocus ? 2 : 1
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true

            GridLayout {
                columns: Math.max(1, Math.floor(width / 256))
                columnSpacing: 16
                rowSpacing: 16

                Repeater {
                    model: PackageManager
                    delegate: AppCard {
                        id: card
                        required property int index

                        readonly property string hay:
                            (model.name + " " + model.summary + " " +
                             model.developer + " " + model.category).toLowerCase()
                        readonly property string needle: search.text.toLowerCase()

                        visible: hay.includes(needle)
                        Layout.preferredWidth: 240
                        name: model.name
                        developer: model.developer
                        summary: model.summary
                        category: model.category
                        installed: model.installed
                        onClicked: detailPush.open(index)
                    }
                }
            }
        }
    }

    QtObject {
        id: detailPush
        function open(rowIndex) {
            browse.StackView.view.push(detailComp, { rowIndex: rowIndex })
        }
    }
    Component { id: detailComp; AppDetailPage {} }
}
