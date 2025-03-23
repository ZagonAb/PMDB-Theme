// Delegate.qml
import QtQuick 2.15

Component {
    id: movieDelegate

    Item {
        id: delegateRoot
        width: listviewContainer.delegateWidth
        height: listviewContainer.delegateHeight

        property bool isFocused: ListView.isCurrentItem && ListView.view.focus
        property var game: modelData
        property var cachedData: null

        // Propiedades responsivas para elementos internos
        property real borderWidth: Math.max(2, 4 * listviewContainer.scaleFactor)
        property real titlePanelHeight: Math.min(60, 50 * listviewContainer.scaleFactor)
        property real titleFontSize: Math.min(16, 14 * listviewContainer.scaleFactor)
        property real loadingSpinnerSize: Math.min(50, 40 * listviewContainer.scaleFactor)

        // Escala cuando está enfocado
        scale: isFocused ? 1.01 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        Component.onCompleted: {
            if (game) {
                cachedData = {
                    title: game.title || "",
                    posterUrl: game.assets ? (game.assets.poster || game.assets.boxFront || "") : "",
                    hasPoster: game.assets && (game.assets.poster || game.assets.boxFront)
                };
            }
        }

        // Sombra cuando está enfocado
        Rectangle {
            id: shadow
            anchors.fill: parent
            anchors.margins: -borderWidth
            color: "transparent"
            border.color: "#006dc7"
            border.width: delegateRoot.isFocused ? borderWidth : 0
            visible: delegateRoot.isFocused
            z: 100
        }

        // Contenedor del poster con bordes redondeados
        Rectangle {
            id: posterContainer
            anchors.fill: parent
            color: "#022441"
            radius: 4
            clip: true

            Image {
                id: poster
                anchors.fill: parent
                source: cachedData ? cachedData.posterUrl : ""
                fillMode: Image.PreserveAspectCrop
                mipmap: true
                asynchronous: true
                cache: true
                sourceSize {
                    width: delegateRoot.width * 1.5
                    height: delegateRoot.height * 1.5
                }
                visible: status === Image.Ready
            }
        }

        Rectangle {
            id: titlePanel
            anchors.bottom: parent.bottom
            width: parent.width
            height: titlePanelHeight
            color: "#aa000000"
            radius: 0
            visible: cachedData && (!cachedData.hasPoster || !poster.visible)

            Text {
                anchors.centerIn: parent
                text: cachedData ? cachedData.title : ""
                color: "white"
                font {
                    family: global.fonts.sans
                    pixelSize: titleFontSize
                    bold: delegateRoot.isFocused
                }
                elide: Text.ElideRight
                width: parent.width - (listviewContainer.listMargin * 2)
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Rectangle {
            id: loadingIndicator
            anchors.fill: parent
            color: "#022441"
            radius: 4
            visible: poster.status !== Image.Ready

            Image {
                id: loadingSpinner
                anchors.centerIn: parent
                width: loadingSpinnerSize
                height: loadingSpinnerSize
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

            // Mostrar título mientras carga
            Text {
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    margins: listviewContainer.listMargin
                }
                text: cachedData ? cachedData.title : ""
                color: "white"
                font {
                    family: global.fonts.sans
                    pixelSize: titleFontSize
                }
                elide: Text.ElideRight
                width: parent.width - (listviewContainer.listMargin * 2)
                horizontalAlignment: Text.AlignHCenter
                visible: cachedData && cachedData.title
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
    }
}
