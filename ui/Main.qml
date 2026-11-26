import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts

// All page/component types come from this module itself (implicit self-import):
// HomePage, BrowsePage, AppDetailPage, LibraryPage, UpdatesPage,
// NavRail, AppCard, RatingStars, HeroBanner.
ApplicationWindow {
    id: root
    width: 1280
    height: 800
    minimumWidth: 960
    minimumHeight: 600
    visible: true
    title: qsTr("Serene App Store")

    color: "#16201a"                 // SereneForge dusk — deep forest (sereneforge.org)

    readonly property color accent: "#7fa37a"      // SereneForge sage
    readonly property color surface: "#203026"      // dusk panel
    readonly property color surfaceAlt: "#25332a"   // dusk panel alt

    Component.onCompleted: PackageManager.refresh()

    RowLayout {
        anchors.fill: parent
        spacing: 0

        NavRail {
            id: nav
            Layout.fillHeight: true
            updateCount: PackageManager.updateCount
            onPageSelected: function(page) {
                if (stack.currentItem && stack.currentItem.pageName === page)
                    return
                for (let i = 0; i < stack.depth; ++i)
                    stack.pop(stack.initialItem, StackView.Immediate)
                if (page === "updates")
                    stack.replace(stack.initialItem, updatesComp)
                else if (page === "browse")
                    stack.replace(stack.initialItem, browseComp)
                else if (page === "library")
                    stack.replace(stack.initialItem, libraryComp)
                else
                    stack.replace(stack.initialItem, homeComp)
            }
        }

        StackView {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            initialItem: homeComp
        }
    }

    Component { id: homeComp;    HomePage {} }
    Component { id: browseComp; BrowsePage {} }
    Component { id: libraryComp; LibraryPage {} }
    Component { id: updatesComp; UpdatesPage {} }

    // Simple transient toast for install feedback
    Rectangle {
        id: toast
        property string message: ""
        visible: message !== ""

        function show(msg) {
            toast.message = msg
            toastHide.restart()
        }

        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 32 }
        width: toastLabel.implicitWidth + 32
        height: 44
        radius: 10
        color: "#25332a"
        border.color: "#7fa37a"
        border.width: 1

        Label {
            id: toastLabel
            anchors.centerIn: parent
            text: toast.message
            color: "#dde6da"
            font.pixelSize: 13
        }

        Timer {
            id: toastHide
            interval: 3500
            onTriggered: toast.message = ""
        }
    }

    Connections {
        target: PackageManager
        function onInstallFinished(appId, success) {
            toast.show(success ? qsTr("%1 installed ✓").arg(appId)
                               : qsTr("Install failed: %1").arg(appId))
        }
        function onProgressChanged(appId, received, total) {
            if (total > 0)
                toast.show(qsTr("%1 — %2%")
                    .arg(appId).arg(Math.round(received * 100 / total)))
        }
    }
}
