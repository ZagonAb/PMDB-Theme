// MovieDetails.qml
import QtQuick 2.15
import QtGraphicalEffects 1.15
import "utils.js" as Utils

FocusScope {
    id: movieDetailsRoot
    visible: false
    z: 1000

    property var currentMovie: null
    property string previousFocus: "" // Almacenar el foco anterior
    property var externalMediaPlayer: null // Nueva propiedad para el reproductor externo

    property var mediaPlayer: MediaPlayerComponent {
        id: internalMediaPlayer
        anchors.fill: parent
        z: 1001
        movieDetailsRoot: movieDetailsRoot
    }

    // Cuando se asigna un reproductor externo, reemplazamos el interno
    onExternalMediaPlayerChanged: {
        if (externalMediaPlayer) {
            mediaPlayer = externalMediaPlayer;
        }
    }

    // Fondo con screenshot de la película
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : ""
        fillMode: Image.PreserveAspectCrop
        mipmap: true
        cache: true
    }

    // Overlay semi-transparente
    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "#022441"
        opacity: 0.5
    }

    Rectangle {
        id: videoOverlay
        anchors.fill: parent

        color: "#000a12"
        opacity: mediaPlayer.visible ? 0.9 : 0.0
        z: 1001
        Behavior on opacity { NumberAnimation { duration: 200 } }
        visible: opacity > 0

        // Contenedor principal para todos los elementos durante la reproducción
        Item {
            id: videoOverlayContent
            anchors.fill: parent

            // Contenedor superior (20%) para el logo
            Item {
                id: logoContainer
                width: parent.width
                height: parent.height * 0.2  // 20% del alto del padre
                anchors.top: parent.top

                // Imagen del logo centrada
                Image {
                    id: movieLogo
                    source: currentMovie ? currentMovie.assets.logo || "" : ""
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    cache: true
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.8, implicitWidth)
                    height: Math.min(parent.height * 0.8, implicitHeight)
                    opacity: mediaPlayer.visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // Efecto de sombra para el logo
                DropShadow {
                    anchors.fill: movieLogo
                    source: movieLogo
                    radius: 10
                    samples: 16
                    color: "#80000000"
                    visible: movieLogo.visible && movieLogo.source !== ""
                    transparentBorder: true
                    verticalOffset: 2
                }
            }

            Item {
                id: bottomContainer
                width: parent.width
                height: parent.height * 0.25
                anchors.bottom: parent.bottom

                Column {
                    width: parent.width //* 0.95  // Usar 95% del ancho para mejor margen
                    anchors.centerIn: parent
                    spacing:  parent.height * 0.1

                    // Fila superior - Ruta del archivo (ahora correctamente centrada)
                    Item {
                        width: parent.width
                        height: bottomContainer.height * 0.1  // Altura fija para mejor alineación

                        Row {
                            id: filePathRow
                            anchors.centerIn: parent
                            spacing: 10

                            // Icono de película
                            Image {
                                source: "assets/icons/movie-file.svg"
                                width: 24
                                height: 24
                                mipmap: true
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            // Texto con la ubicación del archivo
                            Text {
                                id: videoPathText
                                text: currentMovie ? Utils.getMovieFilePath(currentMovie) : "N/A"
                                color: "#AAAAAA"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: 14
                                }
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                                anchors.verticalCenter: parent.verticalCenter

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        videoPathText.text = (videoPathText.elide === Text.ElideRight)
                                        ? Utils.getMovieFilePath(currentMovie, true)
                                        : Utils.getMovieFilePath(currentMovie);
                                        videoPathText.elide = (videoPathText.elide === Text.ElideRight)
                                        ? Text.ElideNone
                                        : Text.ElideRight;
                                        videoPathText.wrapMode = (videoPathText.wrapMode === Text.NoWrap)
                                        ? Text.Wrap
                                        : Text.NoWrap;
                                    }
                                }
                            }
                        }
                    }

                    // Fila inferior - InfoRow con detalles técnicos
                    Item {
                        width: parent.width
                        height: bottomContainer.height * 0.1  // Altura fija para mejor alineación

                        Row {
                            id: infoRow
                            anchors.centerIn: parent
                            spacing: 15

                            // Componente reutilizable para los rectángulos de texto
                            component InfoRectangle: Rectangle {
                                property alias text: label.text
                                width: label.implicitWidth + 20
                                height: 30
                                color: "transparent"
                                border.color: "#4D4D4D"
                                border.width: 1
                                radius: 4

                                Text {
                                    id: label
                                    anchors.centerIn: parent
                                    color: "white"
                                    font {
                                        family: global.fonts.sans
                                        pixelSize: 14
                                        bold: true
                                    }
                                }
                            }

                            // Icono de calendario
                            Image {
                                source: "assets/icons/calen.svg"
                                width: 24
                                height: 24
                                anchors.verticalCenter: parent.verticalCenter
                                mipmap: true
                            }

                            // Fecha
                            InfoRectangle {
                                text: {
                                    if (!currentMovie || !currentMovie.release) return "N/A";
                                    var dateObj = new Date(currentMovie.release);
                                    if (isNaN(dateObj.getTime())) return "N/A";
                                    var day = dateObj.getDate();
                                    var month = dateObj.getMonth() + 1;
                                    return (day < 10 ? '0' : '') + day + '/' +
                                    (month < 10 ? '0' : '') + month + '/' +
                                    dateObj.getFullYear();
                                }
                            }

                            // Duración
                            InfoRectangle {
                                text: currentMovie && currentMovie.extra && currentMovie.extra["duration"] ?
                                currentMovie.extra["duration"] + " min" : "N/A"
                            }

                            // Formato video
                            InfoRectangle {
                                text: currentMovie && currentMovie.extra && currentMovie.extra["codec"] ?
                                currentMovie.extra["codec"] : "N/A"
                            }

                            // Resolución
                            InfoRectangle {
                                text: currentMovie && currentMovie.extra && currentMovie.extra["resolution"] ?
                                currentMovie.extra["resolution"] : "N/A"
                            }

                            // Relación de aspecto
                            InfoRectangle {
                                text: currentMovie && currentMovie.extra && currentMovie.extra["aspect"] ?
                                currentMovie.extra["aspect"] : "N/A"
                            }

                            // Audio
                            InfoRectangle {
                                text: currentMovie && currentMovie.extra && currentMovie.extra["audio"] ?
                                currentMovie.extra["audio"] : "N/A"
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: rectangleitem
        width: parent.width
        height: parent.height
        color: "transparent"
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter

        // Propiedad para establecer una escala base basada en la resolución de referencia
        property real scaleRatio: Math.min(width / 1920, height / 1080) // Asumiendo 1920x1080 como resolución de referencia

        // Contenedor principal para los detalles
        Item {
            id: itemContainer
            width: parent.width * 0.8
            height: parent.height * 0.7
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            // Contenedor para centrar el Row
            Item {
                id: rowWrapper
                width: parent.width
                height: parent.height
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: parent.width * 0.1
                }

                Row {
                    id: rowconteiner
                    width: parent.width * 0.9
                    height: parent.height * 0.9
                    anchors.centerIn: parent
                    spacing: 30 * rectangleitem.scaleRatio // Escalar el espaciado

                    // Columna izquierda con boxFront
                    Item {
                        id: leftColumn
                        width: parent.width * 0.25
                        height: parent.height

                        Image {
                            id: boxFrontImage
                            width: parent.width
                            height: width * 1.5 // Proporción 2:3 estándar para pósters
                            source: currentMovie ? currentMovie.assets.boxFront || "" : ""
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            cache: true
                            anchors.top: parent.top
                        }

                        // Botones debajo del póster
                        FocusScope {
                            id: buttonsColumn
                            anchors {
                                top: boxFrontImage.bottom
                                left: parent.left
                                right: parent.right
                                topMargin: 20 * rectangleitem.scaleRatio // Escalar margen
                            }
                            height: children[0].height // La altura se ajustará automáticamente
                            focus: movieDetailsRoot.focus

                            property int currentIndex: 0

                            Column {
                                id: buttonsLayout
                                width: parent.width
                                spacing: 12 * rectangleitem.scaleRatio // Escalar espaciado

                                // Botón Launch
                                Rectangle {
                                    id: btnLaunch
                                    width: parent.width
                                    height: 46 * rectangleitem.scaleRatio // Escalar altura
                                    color: btnLaunch.activeFocus ? "#006dc7" : "#022441"
                                    radius: 6 * rectangleitem.scaleRatio // Escalar radio
                                    border.width: btnLaunch.activeFocus ? 2 : 0
                                    border.color: "white"
                                    focus: true

                                    Text {
                                        text: "Launch"
                                        color: "white"
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: Math.max(12, 18 * rectangleitem.scaleRatio) // Escalar tamaño de fuente con un mínimo
                                            bold: true
                                        }
                                        anchors.centerIn: parent
                                    }

                                    Keys.onPressed: function(event) {
                                        if (api.keys.isAccept(event)) {
                                            event.accepted = true;

                                            // Opción 1: Si currentMovie es un juego Pegasus válido
                                            if (typeof currentMovie.launch === "function") {
                                                currentMovie.launch();
                                            }
                                            // Opción 2: Buscar por título en las colecciones
                                            else if (currentMovie && currentMovie.title) {
                                                Utils.launchGameFromMoviesCollection(currentMovie.title);
                                            } else {
                                                console.error("No hay título válido para lanzar.");
                                            }
                                        } else if (api.keys.isDown(event)) {
                                            event.accepted = true;
                                            btnFavorite.focus = true;
                                        } else if (api.keys.isCancel(event)) {
                                            event.accepted = true;
                                            Utils.hideDetails(movieDetailsRoot);
                                            if (previousFocus === "gridView") {
                                                gridViewMovies.visible = true;
                                                gridViewMovies.focus = true;
                                            } else if (previousFocus === "gridViewTitles") {
                                                gridViewTitles.visible = true;
                                                gridViewTitles.focus = true;
                                            } else if (previousFocus === "GenreList") {
                                                genreList.visible = true;
                                                genreList.focus = true;
                                            } else if (previousFocus === "YearList") {
                                                yearList.visible = true;
                                                yearList.focus = true;
                                            } else if (previousFocus === "RatingList") {
                                                ratingList.visible = true;
                                                ratingList.focus = true;
                                            }
                                        }
                                    }


                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            btnLaunch.focus = true;
                                            if (currentMovie) {
                                                currentMovie.launch();
                                            }
                                        }
                                    }
                                }

                                // Botón Favorite
                                Rectangle {
                                    id: btnFavorite
                                    width: parent.width
                                    height: 46 * rectangleitem.scaleRatio // Escalar altura
                                    color: btnFavorite.activeFocus ? "#006dc7" : "#022441"
                                    radius: 6 * rectangleitem.scaleRatio // Escalar radio
                                    border.width: btnFavorite.activeFocus ? 2 : 0
                                    border.color: "white"

                                    Text {
                                        id: favoriteText
                                        text: currentMovie ? Utils.getFavoriteButtonText(currentMovie.title) : "Favorite +"
                                        color: "white"
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: Math.max(12, 18 * rectangleitem.scaleRatio) // Escalar tamaño de fuente con un mínimo
                                            bold: true
                                        }
                                        anchors.centerIn: parent
                                    }

                                    // Actualizar el texto cuando cambia currentMovie
                                    Connections {
                                        target: movieDetailsRoot
                                        function onCurrentMovieChanged() {
                                            if (currentMovie) {
                                                favoriteText.text = Utils.getFavoriteButtonText(currentMovie.title);
                                            }
                                        }
                                    }

                                    Keys.onPressed: function(event) {
                                        if (api.keys.isAccept(event)) {
                                            event.accepted = true;
                                            if (currentMovie) {
                                                // Alterna el estado y actualiza el texto
                                                var isNowFavorite = Utils.toggleGameFavorite(currentMovie.title);
                                                favoriteText.text = isNowFavorite ? "Favorite -" : "Favorite +";
                                            }
                                        } else if (api.keys.isUp(event)) {
                                            event.accepted = true;
                                            btnLaunch.focus = true;
                                        } else if (api.keys.isDown(event)) {
                                            event.accepted = true;
                                            btnPlayTrailer.focus = true;
                                        } else if (api.keys.isCancel(event)) {
                                            event.accepted = true;
                                            Utils.hideDetails(movieDetailsRoot);
                                            if (previousFocus === "gridView") {
                                                gridViewMovies.visible = true;
                                                gridViewMovies.focus = true;
                                            } else if (previousFocus === "gridViewTitles") {
                                                gridViewTitles.visible = true;
                                                gridViewTitles.focus = true;
                                            } else if (previousFocus === "GenreList") {
                                                genreList.visible = true;
                                                genreList.focus = true;
                                            } else if (previousFocus === "YearList") {
                                                yearList.visible = true;
                                                yearList.focus = true;
                                            } else if (previousFocus === "RatingList") {
                                                ratingList.visible = true;
                                                ratingList.focus = true;
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            btnFavorite.focus = true;
                                            if (currentMovie) {
                                                var isNowFavorite = Utils.toggleGameFavorite(currentMovie.title);
                                                favoriteText.text = isNowFavorite ? "Favorite -" : "Favorite +";
                                            }
                                        }
                                    }
                                }

                                // Botón Play Trailer
                                Rectangle {
                                    id: btnPlayTrailer
                                    width: parent.width
                                    height: 46 * rectangleitem.scaleRatio // Escalar altura
                                    color: btnPlayTrailer.activeFocus ? "#006dc7" : "#022441"
                                    radius: 6 * rectangleitem.scaleRatio // Escalar radio
                                    border.width: btnPlayTrailer.activeFocus ? 2 : 0
                                    border.color: "white"

                                    Text {
                                        text: "Play Trailer"
                                        color: "white"
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: Math.max(12, 18 * rectangleitem.scaleRatio) // Escalar tamaño de fuente con un mínimo
                                            bold: true
                                        }
                                        anchors.centerIn: parent
                                    }

                                    Keys.onPressed: function(event) {
                                        if (api.keys.isAccept(event)) {
                                            event.accepted = true;
                                            if (currentMovie && currentMovie.assets && currentMovie.assets.video) {
                                                mediaPlayer.playVideo(currentMovie.assets.video);
                                            }
                                        } else if (api.keys.isUp(event)) {
                                            event.accepted = true;
                                            btnFavorite.focus = true;
                                        } else if (api.keys.isCancel(event)) {
                                            event.accepted = true;
                                            Utils.hideDetails(movieDetailsRoot);
                                            if (previousFocus === "gridView") {
                                                gridViewMovies.visible = true;
                                                gridViewMovies.focus = true;
                                            } else if (previousFocus === "gridViewTitles") {
                                                gridViewTitles.visible = true;
                                                gridViewTitles.focus = true;
                                            } else if (previousFocus === "GenreList") {
                                                genreList.visible = true;
                                                genreList.focus = true;
                                            } else if (previousFocus === "YearList") {
                                                yearList.visible = true;
                                                yearList.focus = true;
                                            } else if (previousFocus === "RatingList") {
                                                ratingList.visible = true;
                                                ratingList.focus = true;
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            btnPlayTrailer.focus = true;
                                            if (currentMovie && currentMovie.assets && currentMovie.assets.video) {
                                                mediaPlayer.playVideo(currentMovie.assets.video);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Columna derecha con información
                    Column {
                        id: columnConteiner
                        width: parent.width - leftColumn.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        property int extraSpacing: parent.height * 0.1
                        height: Math.min(implicitHeight, parent.height * 0.7)
                        spacing: parent.height * 0.02

                        // Título de la película
                        Text {
                            text: currentMovie ? currentMovie.title : ""
                            color: "white"
                            font {
                                family: global.fonts.sans
                                pixelSize: Math.max(16, 32 * rectangleitem.scaleRatio) // Escalar tamaño de fuente con un mínimo
                                bold: true
                            }
                            width: parent.width
                        }

                        // Información de clasificación y duración
                        Row {
                            spacing: parent.height * 0.05
                            //topPadding: -10

                            Item {
                                width: classificationText.width + 10 * rectangleitem.scaleRatio
                                height: classificationText.height + 8 * rectangleitem.scaleRatio

                                Rectangle {
                                    anchors.fill: parent
                                    color: "transparent"
                                    border.color: "white"
                                    border.width: 1 * Math.max(0.5, rectangleitem.scaleRatio) // Escalar grosor de borde con un mínimo
                                    radius: 4 * rectangleitem.scaleRatio
                                }

                                Text {
                                    id: classificationText
                                    anchors.centerIn: parent
                                    text: currentMovie && currentMovie.extra && currentMovie.extra["classification"] ?
                                    currentMovie.extra["classification"] : "PG"
                                    color: "white"
                                    font {
                                        family: global.fonts.sans
                                        pixelSize: Math.max(10, 16 * rectangleitem.scaleRatio) // Escalar tamaño de fuente con un mínimo
                                    }
                                }
                            }

                            // Fecha de estreno
                            Text {
                                text: currentMovie && currentMovie.releaseYear ? currentMovie.releaseYear : "N/A"
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(12, 18 * rectangleitem.scaleRatio) // Escalar tamaño de fuente
                                }
                            }

                            // Géneros
                            Text {
                                text: currentMovie && currentMovie.genre ? currentMovie.genre : "N/A"
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(12, 18 * rectangleitem.scaleRatio) // Escalar tamaño de fuente
                                }
                            }

                            // Duración
                            Text {
                                text: currentMovie && currentMovie.extra && currentMovie.extra["duration"] ?
                                currentMovie.extra["duration"] + " min" : "N/A"
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(12, 18 * rectangleitem.scaleRatio) // Escalar tamaño de fuente
                                }
                            }
                        }

                        // Rating visual con círculo
                        Item {
                            height: 80 * rectangleitem.scaleRatio
                            width: parent.width

                            Row {
                                spacing: parent.height * 0.1

                                Item {
                                    width: 70 * rectangleitem.scaleRatio
                                    height: 70 * rectangleitem.scaleRatio

                                    // Fondo circular oscuro
                                    Rectangle {
                                        id: backgroundCircle
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: "#1A1A2E"
                                    }

                                    Canvas {
                                        id: ratingCanvas
                                        anchors.fill: parent
                                        antialiasing: true

                                        property real rating: currentMovie ? currentMovie.rating || 0 : 0
                                        property color ratingColor: getColorForRating(rating)

                                        // Función sin cambios
                                        function getColorForRating(rating) {
                                            if (rating >= 0.75) return "#A3E635";
                                            if (rating >= 0.6) return "#A3E635";
                                            if (rating >= 0.4) return "#FCD34D";
                                            return "#F87171";
                                        }

                                        onPaint: {
                                            var ctx = getContext("2d");
                                            var centerX = width / 2;
                                            var centerY = height / 2;
                                            var radius = width / 2 - 4 * rectangleitem.scaleRatio; // Escalar el margen

                                            // Dibuja el círculo de fondo
                                            ctx.beginPath();
                                            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                                            ctx.lineWidth = 3 * rectangleitem.scaleRatio; // Escalar grosor de línea
                                            ctx.strokeStyle = "#333344";
                                            ctx.stroke();

                                            // Dibuja el arco de progreso
                                            if (rating > 0) {
                                                ctx.beginPath();
                                                ctx.arc(centerX, centerY, radius, -Math.PI/2, (2 * Math.PI * rating) - Math.PI/2);
                                                ctx.lineWidth = 3 * rectangleitem.scaleRatio; // Escalar grosor de línea
                                                ctx.strokeStyle = ratingColor;
                                                ctx.stroke();
                                            }
                                        }

                                        // Actualiza el canvas cuando cambia el rating
                                        onRatingChanged: requestPaint()
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: currentMovie ? Math.round(currentMovie.rating * 100) + "%" : "N/A"
                                        color: "white"
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: Math.max(10, 18 * rectangleitem.scaleRatio) // Escalar tamaño de fuente
                                            bold: true
                                        }
                                    }
                                }

                                // Texto User Score
                                Text {
                                    text: "Rating\nScore"
                                    color: "white"
                                    font {
                                        family: global.fonts.sans
                                        pixelSize: Math.max(10, 18 * rectangleitem.scaleRatio) // Escalar tamaño de fuente
                                        bold: true
                                    }
                                    lineHeight: 1.1
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                // Emojis de reacción
                                Row {
                                    spacing: 4 * rectangleitem.scaleRatio
                                    leftPadding: 20 * rectangleitem.scaleRatio
                                    anchors.verticalCenter: parent.verticalCenter

                                    // Lista de emojis sin cambios
                                    property var emojiList: ["🤩", "😍", "😃", "😊", "🙂", "😐", "😕", "😞", "😠", "😡"]

                                    // Función sin cambios
                                    function getEmojisForRating(rating) {
                                        var index = Math.min(Math.floor((1 - rating) * emojiList.length), emojiList.length - 3);
                                        if (rating < 0.1) {
                                            index = emojiList.length - 3;
                                        }
                                        return [
                                            emojiList[index],
                                            emojiList[Math.min(index + 1, emojiList.length - 1)],
                                            emojiList[Math.min(index + 2, emojiList.length - 1)]
                                        ];
                                    }

                                    property var currentEmojis: getEmojisForRating(currentMovie ? currentMovie.rating || 0 : 0)

                                    Repeater {
                                        model: 3

                                        Text {
                                            text: parent.currentEmojis[index]
                                            font.pixelSize: Math.max(14, 28 * rectangleitem.scaleRatio) // Escalar tamaño de emojis
                                            opacity: index === 0 ? 1.0 : (index === 1 ? 0.7 : 0.4)
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    // Actualizar emojis cuando cambia el rating
                                    Connections {
                                        target: currentMovie
                                        function onRatingChanged() {
                                            currentEmojis = getEmojisForRating(currentMovie ? currentMovie.rating || 0 : 0);
                                        }
                                    }
                                }
                            }
                        }

                        // Tagline o frase promocional
                        Text {
                            text: currentMovie && currentMovie.extra && currentMovie.extra["tagline"] ?
                            currentMovie.extra["tagline"] : "no tagline available..."
                            color: "#CCCCCC"
                            font {
                                family: global.fonts.sans
                                pixelSize: Math.max(14, 22 * rectangleitem.scaleRatio) // Escalar tamaño de fuente
                                italic: true
                            }
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }

                        // Título de Overview
                        Text {
                            text: "Overview"
                            color: "white"
                            font {
                                family: global.fonts.sans
                                pixelSize: Math.max(14, 24 * rectangleitem.scaleRatio) // Escalar tamaño de fuente
                                bold: true
                            }
                            topPadding: 10 * rectangleitem.scaleRatio
                        }

                        // Descripción de la película
                        Text {
                            text: currentMovie ? currentMovie.description || "No description available." : "No description available."
                            color: "white"
                            font {
                                family: global.fonts.sans
                                pixelSize: Math.max(12, 24 * rectangleitem.scaleRatio) // Escalar tamaño de fuente
                            }
                            wrapMode: Text.WordWrap
                            width: parent.width
                            lineHeight: 1.0
                        }

                        // Información del equipo de producción
                        Grid {
                            columns: 2
                            rowSpacing: 15 * rectangleitem.scaleRatio
                            columnSpacing: 30 * rectangleitem.scaleRatio
                            topPadding: parent.height * 0.01
                            width: parent.width

                            // Creadores
                            Repeater {
                                model: [
                                    { role: "Director", name: currentMovie ? currentMovie.developer || "N/A" : "N/A" },
                                    { role: "Publisher", name: currentMovie ? currentMovie.publisher || "N/A" : "N/A" },
                                ]

                                delegate: Column {
                                    width: parent.width / 2
                                    spacing: parent.height * 0.02

                                    Text {
                                        text: modelData.role
                                        color: "#BBBBBB"
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: Math.max(10, 16 * rectangleitem.scaleRatio) // Escalar tamaño de fuente
                                            bold: true
                                        }
                                    }

                                    Text {
                                        text: modelData.name
                                        color: "white"
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: Math.max(10, 16 * rectangleitem.scaleRatio) // Escalar tamaño de fuente
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Listener para actualizar scaleRatio cuando cambia el tamaño de la ventana
        onWidthChanged: {
            scaleRatio = Math.min(width / 1920, height / 1080)
        }

        onHeightChanged: {
            scaleRatio = Math.min(width / 1920, height / 1080)
        }

        // Establecer un valor inicial para scaleRatio
        Component.onCompleted: {
            scaleRatio = Math.min(width / 1920, height / 1080)
        }
    }

    // Cuando MovieDetails se vuelve visible, establecer el foco en el primer botón
    onVisibleChanged: {
        if (visible) {
            btnLaunch.focus = true;
        }
    }
}
