// DelegateContinuePlaying.qml
import QtQuick 2.15
import "utils.js" as Utils

Component {
    id: movieDelegateContinuePlaying

    Item {
        id: delegateRoot
        width: listviewContainer.delegateWidth
        height: listviewContainer.delegateHeight

        property bool isFocused: ListView.isCurrentItem && ListView.view.focus
        property var game: modelData
        property var cachedData: null
        property real progressPercentage: 0

        property real borderWidth: Math.max(2, 4 * listviewContainer.scaleFactor)
        property real titlePanelHeight: Math.min(60, 50 * listviewContainer.scaleFactor)
        property real titleFontSize: Math.min(16, 14 * listviewContainer.scaleFactor)
        property real loadingSpinnerSize: Math.min(50, 40 * listviewContainer.scaleFactor)

        Component.onCompleted: {
            if (game) {
                // Depuración - mostrar todas las propiedades extra disponibles
                //console.log("Título película:", game.title);
                //console.log("Propiedades extra disponibles:", JSON.stringify(game.extra));

                // Verificar específicamente Duration y playTime
                var durationValue = game.extra ? game.extra["duration"] || game.extra["duration"] : null;
                //console.log("Duration value:", durationValue);

                // Obtener el tiempo de reproducción desde el archivo JSON
                var watchedTime = Utils.getLastPosition(game.title) / 1000; // Convertir a segundos
                //console.log("Tiempo reproducido en segundos:", watchedTime);

                // Calculate progress percentage based on watchedTime and Duration
                var totalDuration = 0;
                if (durationValue) {
                    totalDuration = parseInt(durationValue) * 60; // Convert minutes to seconds
                    //console.log("Total duration en segundos:", totalDuration);
                } else {
                    //console.log("¡ADVERTENCIA! No se encontró Duration en los datos extra");
                }

                // Ensure we don't exceed 100% progress
                progressPercentage = totalDuration > 0 ? Math.min(watchedTime / totalDuration, 1.0) : 0;
                //console.log("Porcentaje de progreso calculado:", progressPercentage);

                cachedData = {
                    title: game.title || "",
                    posterUrl: game.assets ? (game.assets.poster || game.assets.boxFront || "") : "",
                    hasPoster: game.assets && (game.assets.poster || game.assets.boxFront),
                    progress: progressPercentage,
                    watchedTime: watchedTime,
                    totalDuration: totalDuration
                };
            }
        }

        Rectangle {
            id: selectionRect
            anchors.fill: parent
            anchors.margins: -borderWidth
            color: "transparent"
            border.color: "#006dc7"
            border.width: delegateRoot.isFocused ? 4 : 0
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
                layer.enabled: delegateRoot.isFocused
                layer.effect: null
            }
        }

        // Efecto de oscurecimiento sobre la imagen de fondo
        Rectangle {
            id: darkenOverlay
            anchors.fill: parent
            color: "#80000000"  // Color negro con 50% de opacidad
            visible: poster.status === Image.Ready
        }

        // Imagen "continue.svg" centrada
        Image {
            id: continueIcon
            anchors.centerIn: parent
            width: parent.width * 0.75
            height: parent.height * 0.5
            source: "assets/icons/continue.png"
            visible: poster.status === Image.Ready
            mipmap: true
        }

        // Progress bar container - Fuera del recuadro de la imagen
        Rectangle {
            id: progressBarContainer
            anchors {
                left: parent.left
                right: parent.right
                top: parent.bottom
                topMargin: 10  // Ajusta este valor para la distancia deseada
            }
            height: 6  // Incrementado para mejor visibilidad
            color: "#33ffffff" // Semi-transparent white
            visible: true      // Siempre visible para depuración
            z: 200            // Asegurar que esté encima de otros elementos

            // Progress bar fill
            Rectangle {
                id: progressBarFill
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: parent.width * progressPercentage
                color: "#006dc7" // Green color
            }
        }

        Rectangle {
            id: titlePanel
            anchors.bottom: parent.bottom
            width: parent.width
            height: 40
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
