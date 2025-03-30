import QtQuick 2.15
import QtMultimedia 5.15
import QtGraphicalEffects 1.15


FocusScope {
    id: mediaPlayerComponent
    property real playerWidth:  parent.width * 0.6
    property real playerHeight: parent.height * 0.6
    anchors.centerIn: parent
    visible: false
    z: 2001 // Mayor que el overlay oscuro

    property string videoSource: ""
    property bool showControls: true
    property bool isMuted: false
    property var movieDetailsRoot: null

    function playVideo(source) {
        videoSource = source;
        mediaPlayer.source = videoSource;
        mediaPlayer.play();
        visible = true;
        focus = true;
    }


    function stopVideo() {
        mediaPlayer.stop();
        visible = false;
        // Notificar al padre que hemos terminado
        if (movieDetailsRoot) {
            movieDetailsRoot.focus = true;
            movieDetailsRoot.btnLaunch.focus = true;
        }
    }

    // Función para formatear el tiempo
    function formatTime(ms) {
        var hours = Math.floor(ms / 3600000)
        var minutes = Math.floor((ms % 3600000) / 60000)
        var seconds = Math.floor((ms % 60000) / 1000)
        return hours > 0
        ? `${hours}:${pad(minutes)}:${pad(seconds)}`
        : `${minutes}:${pad(seconds)}`
    }

    function pad(num) {
        return num < 10 ? "0" + num : num
    }

    // Contenedor principal que tendrá el foco
    Rectangle {
        id: playerContainer
        width: playerWidth
        height: playerHeight
        anchors.centerIn: parent
        color: "transparent"
        focus: true // Asegurar que este contenedor tenga el foco

        // Timer para ocultar los controles
        Timer {
            id: hideControlsTimer
            interval: 5000
            onTriggered: showControls = false
        }

        // MediaPlayer para reproducir el video
        MediaPlayer {
            id: mediaPlayer
            autoPlay: true
            volume: isMuted ? 0.0 : volumeSlider.value

            onStopped: {
                if (status === MediaPlayer.EndOfMedia) {
                    mediaPlayerComponent.stopVideo();
                }
            }
        }

        Item {
            id: videoContainer
            anchors.fill: parent

            clip: true

            Item {
                id: scaledVideoContainer
                anchors.fill: parent

                VideoOutput {
                    id: videoOutput
                    anchors.fill: parent
                    source: mediaPlayer
                    visible: false
                    fillMode: VideoOutput.PreserveAspectCrop
                }
            }

            OpacityMask {
                anchors.fill: parent
                source: videoOutput
                maskSource: Rectangle {
                    width: videoContainer.width
                    height: videoContainer.height
                    radius: 40
                    visible: false
                }
            }
        }

        // Área para mostrar controles al mover el mouse
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: {
                if (mouseY > parent.height - 100) {
                    showControls = true
                    hideControlsTimer.restart()
                }
            }
            onClicked: {
                showControls = true
                hideControlsTimer.restart()
            }
        }

        // Botón de cerrar en la esquina superior derecha
        /*Image {
            source: "assets/icons/close.svg"
            width: 32
            height: 32
            mipmap: true
            anchors {
                top: parent.top
                right: parent.right
                margins: 20
            }
            opacity: showControls ? 1 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: mediaPlayerComponent.stopVideo() // Solo cierra el reproductor
            }
        }*/

        // Contenedor de controles
        Rectangle {
            id: controlsContainer
            height: 100
            color: Qt.rgba(0, 0, 0, 0.7)
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            opacity: showControls ? 1 : 0
            visible: opacity > 0

            radius: 40

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            // Barra de progreso
            Rectangle {
                id: progressBar
                height: 8
                color: "#444444"
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: controlsRow.top
                    margins: 20
                }
                radius: 5

                Rectangle {
                    id: progressIndicator
                    width: mediaPlayer.duration > 0 ? (mediaPlayer.position / mediaPlayer.duration) * parent.width : 0
                    height: parent.height
                    color: "#022441"
                    radius: 3
                }

                Rectangle {
                    id: progressHandle
                    width: 15
                    height: 15
                    radius: 6
                    color: "#022441"
                    anchors.verticalCenter: parent.verticalCenter
                    x: mediaPlayer.duration > 0 ? (mediaPlayer.position / mediaPlayer.duration) * (parent.width - width) : 0
                    visible: true //progressBarArea.containsMouse || progressBarArea.pressed
                }

                MouseArea {
                    id: progressBarArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (mediaPlayer.duration > 0) {
                            var newPosition = (mouse.x / width) * mediaPlayer.duration
                            mediaPlayer.seek(newPosition)
                        }
                    }
                }
            }

            // Controles principales
            Row {
                id: controlsRow
                spacing: 20
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    margins: 20
                }

                // Botón retroceder 10s
                Image {
                    source: "assets/icons/replay.svg"
                    width: 32
                    height: 32
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mediaPlayer.seek(mediaPlayer.position - 10000)
                    }
                    mipmap: true
                }

                // Botón play/pause
                Image {
                    source: mediaPlayer.playbackState === MediaPlayer.PlayingState
                    ? "assets/icons/pause.svg"
                    : "assets/icons/play.svg"
                    width: 32
                    height: 32
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                                mediaPlayer.pause()
                            } else {
                                mediaPlayer.play()
                            }
                        }
                    }
                    mipmap: true
                }

                // Botón de stop
                Image {
                    source: "assets/icons/close.svg"
                    width: 32
                    height: 32
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mediaPlayerComponent.stopVideo() // Solo cierra el reproductor
                    }
                    mipmap: true
                }

                // Botón adelantar 10s
                Image {
                    source: "assets/icons/forward.svg"
                    width: 32
                    height: 32
                    MouseArea {
                        anchors.fill: parent
                        onClicked: mediaPlayer.seek(mediaPlayer.position + 10000)
                    }
                    mipmap: true
                }
            }

            // Control de volumen personalizado
            Item {
                id: volumeControl
                width: 120
                height: 24
                anchors {
                    right: timeText.left
                    bottom: parent.bottom
                    margins: 20
                }

                Image {
                    id: volumeIcon
                    source: isMuted ? "assets/icons/mute.svg" : "assets/icons/volume.svg"
                    width: 24
                    height: 24
                    mipmap: true
                    MouseArea {
                        anchors.fill: parent
                        onClicked: isMuted = !isMuted
                    }
                }

                Rectangle {
                    id: volumeSlider
                    property real value: 1.0
                    height: 6
                    width: 80
                    color: "#444444"
                    radius: 2
                    anchors {
                        left: volumeIcon.right
                        leftMargin: 10
                        verticalCenter: volumeIcon.verticalCenter
                    }

                    Rectangle {
                        width: parent.width * parent.value
                        height: parent.height
                        color: "#022441"
                        radius: 2
                    }

                    Rectangle {
                        id: volumeHandle
                        width: 12
                        height: 12
                        radius: 6
                        color: "#022441"
                        x: (parent.width - width) * parent.value
                        anchors.verticalCenter: parent.verticalCenter
                        visible: true //volumeArea.containsMouse || volumeArea.pressed
                    }

                    MouseArea {
                        id: volumeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onMouseXChanged: {
                            if (pressed) {
                                var newValue = Math.max(0, Math.min(1, mouseX / width))
                                parent.value = newValue
                            }
                        }
                        onClicked: {
                            var newValue = Math.max(0, Math.min(1, mouseX / width))
                            parent.value = newValue
                        }
                    }
                }
            }

            // Tiempo actual / duración
            Text {
                id: timeText
                anchors {
                    right: parent.right
                    bottom: parent.bottom
                    margins: 20
                }
                color: "white"
                text: formatTime(mediaPlayer.position) + " / " + formatTime(mediaPlayer.duration)
                font.pixelSize: 14
            }
        }

        Rectangle {
            id: videoBorder
            anchors.fill: parent
            color: "transparent"
            border.color: "#022441"
            border.width: 6
            radius: 40
            // No necesitaríamos un z muy alto aquí, ya que el orden de declaración
            // garantiza que se dibuje encima
        }


        // Cuando el componente pierde visibilidad, liberar recursos
        onVisibleChanged: {
            if (!visible) {
                mediaPlayer.stop();
            }
        }

        Keys.onPressed: function(event) {
            if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                event.accepted = true;
                stopVideo();
                return;
            }

            if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                event.accepted = true;
                if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                    mediaPlayer.pause();
                } else {
                    mediaPlayer.play();
                }
                return;
            }

            switch (event.key) {
                case Qt.Key_Space:
                    if (mediaPlayer.playbackState === MediaPlayer.PlayingState) {
                        mediaPlayer.pause();
                    } else {
                        mediaPlayer.play();
                    }
                    event.accepted = true;
                    break;
                case Qt.Key_Left:
                    mediaPlayer.seek(mediaPlayer.position - 10000);
                    event.accepted = true;
                    break;
                case Qt.Key_Right:
                    mediaPlayer.seek(mediaPlayer.position + 10000);
                    event.accepted = true;
                    break;
                case Qt.Key_Up:
                    volumeSlider.value = Math.min(1.0, volumeSlider.value + 0.1);
                    event.accepted = true;
                    break;
                case Qt.Key_Down:
                    volumeSlider.value = Math.max(0.0, volumeSlider.value - 0.1);
                    event.accepted = true;
                    break;
            }
        }
    }
}
