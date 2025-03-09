// Delegate.qml
import QtQuick 2.15

Component {
    id: movieDelegate

    Item {
        id: delegateRoot
        width: 200
        height: 300

        property bool isFocused: ListView.isCurrentItem && ListView.view.focus
        property var game: modelData
        property var cachedData: null

        Component.onCompleted: {
            if (game) {
                cachedData = {
                    title: game.title || "",
                    posterUrl: game.assets ? (game.assets.poster || game.assets.boxFront || "") : "",
                    hasPoster: game.assets && (game.assets.poster || game.assets.boxFront)
                };
            }
        }

        Rectangle {
            id: selectionRect
            anchors.fill: parent
            color: "transparent"
            border.color: "#006dc7"
            border.width: delegateRoot.isFocused ? 4 : 0
            visible: delegateRoot.isFocused
            z: 100
        }

        Image {
            id: poster
            anchors.fill: parent
            source: cachedData ? cachedData.posterUrl : ""
            fillMode: Image.PreserveAspectCrop
            mipmap: true
            asynchronous: true
            cache: true
            sourceSize { width: 200; height: 300 }
            visible: status === Image.Ready
            layer.enabled: delegateRoot.isFocused
            layer.effect: null
        }

        Rectangle {
            id: titlePanel
            anchors.bottom: parent.bottom
            width: parent.width
            height: 60
            color: "#aa000000"
            visible: cachedData && !cachedData.hasPoster

            Text {
                anchors.centerIn: parent
                text: cachedData ? cachedData.title : ""
                color: "white"
                font { family: global.fonts.sans; pixelSize: 14 }
                elide: Text.ElideRight
                width: parent.width - 20
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Rectangle {
            id: loadingIndicator
            anchors.fill: parent
            color: "transparent"
            visible: poster.status !== Image.Ready

            Image {
                id: loadingSpinner
                anchors.centerIn: parent
                width: 40
                height: 40
                source: "assets/icons/loading-spinner.svg"
                mipmap: true
                visible: poster.status === Image.Loading

                RotationAnimator on rotation {
                    running: loadingSpinner.visible && poster.status === Image.Loading
                    loops: Animator.Infinite
                    from: 0
                    to: 360
                    duration: 1000
                }
            }
        }

        Keys.onPressed: function(event) {
            if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                event.accepted = true;
                if (game) {
                    launchTimer.start();
                }
            }
        }

        Timer {
            id: launchTimer
            interval: 150
            repeat: false
            onTriggered: {
                if (game) {
                    game.launch();
                }
            }
        }

        transitions: Transition {
            from: ""
            to: "selected"
            reversible: true
            NumberAnimation { properties: "scale"; duration: 150; easing.type: Easing.OutQuad }
        }
    }
}
