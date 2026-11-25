import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

Page {
    id: library
    background: Rectangle { color: "#12131a" }
    property string pageName: "library"

    Component.onCompleted: PackageManager.loadInstalled()

    Label {
        anchors.centerIn: parent
        visible: !PackageManager.loading &&
                 PackageManager.rowCount > 0 &&
                 !library.anyInstalled
        text: qsTr("Nothing installed yet — grab something from Browse!")
        color: "#6d7388"
        font.pixelSize: 15
    }

    readonly property bool anyInstalled: {
        for (let i = 0; i < PackageManager.rowCount; ++i)
            if (PackageManager.app(i).installed) return true
        return false
    }

    ColumnLayout {
        anchors { fill: parent; margins: 24 }
        spacing: 16

        Label {
            text: qsTr("My apps")
            color: "#eae8ff"
            font.pixelSize: 20
            font.bold: true
            Layout.topMargin: 12
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
                        id: libCard
                        required property int index

                        readonly property bool showMe: model.installed
                        visible: showMe
                        Layout.preferredWidth: 240

                        name: model.name
                        developer: model.developer
                        summary: model.summary
                        category: model.category
                        installed: true
                        onClicked: library.StackView.view.push(libDetail, { rowIndex: index })
                    }
                }
            }
        }
    }

    Component { id: libDetail; AppDetailPage {} }
}
