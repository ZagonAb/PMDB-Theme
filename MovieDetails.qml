// MovieDetails.qml
import QtQuick 2.15
import QtGraphicalEffects 1.15
import "utils.js" as Utils

FocusScope {
    id: movieDetailsRoot
    anchors.fill: parent
    visible: false

    property var currentMovie: null
    property string previousFocus: "" // Almacenar el foco anterior

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

    // Contenedor principal para los detalles
    Item {
        id: itemContainer
        width: parent.width * 0.8
        height: parent.height * 0.8
        anchors.centerIn: parent

        Row {
            id: rowconteiner
            width: parent.width * 0.9
            height: parent.height * 0.9
            anchors.centerIn: parent  // Esto lo centra dentro de itemContainer
            spacing: 30

            // Columna izquierda con boxFront
            Item {
                id: leftColumn
                width: parent.width * 0.25
                height: parent.height
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: parent.width * 0.02

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
                Column {
                    anchors {
                        top: boxFrontImage.bottom
                        left: parent.left
                        right: parent.right
                        topMargin: 20
                    }
                    spacing: 12

                    // Botón Launch
                    Rectangle {
                        width: parent.width
                        height: 46
                        color: "#022441"
                        radius: 6

                        Text {
                            text: "Launch"
                            color: "white"
                            font { family: global.fonts.sans; pixelSize: 18; bold: true }
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (currentMovie) {
                                    currentMovie.launch();
                                }
                            }
                        }
                    }

                    // Botón Favorite
                    Rectangle {
                        width: parent.width
                        height: 46
                        color: "#022441"
                        radius: 6

                        Text {
                            text: "Favorite"
                            color: "white"
                            font { family: global.fonts.sans; pixelSize: 18; bold: true }
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (currentMovie) {
                                    currentMovie.favorite = !currentMovie.favorite;
                                }
                            }
                        }
                    }

                    // Botón Play Trailer
                    Rectangle {
                        width: parent.width
                        height: 46
                        color: "#022441"
                        radius: 6

                        Text {
                            text: "Play Trailer"
                            color: "white"
                            font { family: global.fonts.sans; pixelSize: 18; bold: true }
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (currentMovie && currentMovie.assets && currentMovie.assets.trailer) {
                                    //console.log("Reproduciendo tráiler: " + currentMovie.assets.trailer);
                                }
                            }
                        }
                    }
                }
            }

            // Columna derecha con información
            Column {
                id: columnConteiner
                width: parent.width - leftColumn.width - parent.width * 0.1 - 30 - extraSpacing

                // Definimos un espacio extra para separar más de la columna izquierda
                property int extraSpacing: parent.height * 0.1  // Puedes ajustar este valor según necesites

                // Anclamos al centro vertical del padre
                anchors.verticalCenter: parent.verticalCenter

                // Limitamos la altura máxima para asegurar que todo el contenido es visible
                height: Math.min(implicitHeight, parent.height * 0.9)

                // Usamos left en lugar de right para poder controlar la separación desde leftColumn
                anchors.left: leftColumn.right
                anchors.leftMargin: extraSpacing  // Aquí aplicamos la separación adicional

                // Si el contenido es más alto que el espacio disponible, activamos el recorte
                //clip: implicitHeight > parent.height * 0.9

                spacing: parent.height * 0.02

                // Título de la película
                Text {
                    text: currentMovie.title
                    color: "white"
                    font { family: global.fonts.sans; pixelSize: 32; bold: true }
                    width: parent.width
                }

                // Información de clasificación y duración
                Row {
                    spacing: parent.height * 0.05
                    //topPadding: -10

                    Item {
                        width: classificationText.width + 10
                        height: classificationText.height + 8

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: "white"
                            border.width: 1
                            radius: 4
                        }

                        Text {
                            id: classificationText
                            anchors.centerIn: parent
                            text: currentMovie && currentMovie.extra && currentMovie.extra["classification"] ?
                            currentMovie.extra["classification"] : "PG" //proximamente
                            color: "white"
                            font { family: global.fonts.sans; pixelSize: 16 }
                        }
                    }

                    // Fecha de estreno
                    Text {
                        text: currentMovie && currentMovie.releaseYear ? currentMovie.releaseYear : "N/A"
                        color: "white"
                        font { family: global.fonts.sans; pixelSize: 16 }
                    }

                    // Géneros
                    Text {
                        text: currentMovie && currentMovie.extra && currentMovie.extra["genres"] ?
                        currentMovie.extra["genres"] : "Animation, Adventure, Family"
                        color: "white"
                        font { family: global.fonts.sans; pixelSize: 16 }
                    }

                    // Duración
                    Text {
                        text: currentMovie && currentMovie.extra && currentMovie.extra["duration"] ?
                        currentMovie.extra["duration"] + " min" : "N/A"
                        color: "white"
                        font { family: global.fonts.sans; pixelSize: 16 }
                    }
                }

                // Rating visual con círculo
                Item {
                    height: 80
                    width: parent.width

                    Row {
                        spacing: parent.height * 0.1

                        Item {
                            width: 70
                            height: 70

                            // Fondo circular oscuro
                            Rectangle {
                                id: backgroundCircle
                                anchors.fill: parent
                                radius: width / 2
                                color: "#1A1A2E" // Color de fondo oscuro, ajusta según tu diseño
                            }

                            Canvas {
                                id: ratingCanvas
                                anchors.fill: parent
                                antialiasing: true

                                property real rating: currentMovie ? currentMovie.rating || 0 : 0
                                property color ratingColor: getColorForRating(rating)

                                // Función para determinar el color según el rating
                                function getColorForRating(rating) {
                                    if (rating >= 0.75) return "#A3E635"; // Verde brillante para ratings altos
                                    if (rating >= 0.6) return "#A3E635";  // Verde-amarillo para ratings buenos
                                    if (rating >= 0.4) return "#FCD34D";  // Amarillo para ratings medios
                                    return "#F87171";                    // Rojo para ratings bajos
                                }

                                onPaint: {
                                    var ctx = getContext("2d");
                                    var centerX = width / 2;
                                    var centerY = height / 2;
                                    var radius = width / 2 - 4; // Un poco más pequeño para dejar margen

                                    // Dibuja el círculo de fondo (contorno gris oscuro)
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                                    ctx.lineWidth = 3;
                                    ctx.strokeStyle = "#333344"; // Gris oscuro para el contorno completo
                                    ctx.stroke();

                                    // Dibuja el arco de progreso según el rating
                                    if (rating > 0) {
                                        ctx.beginPath();
                                        // -Math.PI/2 comienza desde arriba (posición 12 en punto)
                                        ctx.arc(centerX, centerY, radius, -Math.PI/2, (2 * Math.PI * rating) - Math.PI/2);
                                        ctx.lineWidth = 3;
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
                                font { family: global.fonts.sans; pixelSize: 18; bold: true }
                            }
                        }

                        // Texto User Score
                        Text {
                            text: "Rating\nScore"
                            color: "white"
                            font { family: global.fonts.sans; pixelSize: 18; bold: true }
                            lineHeight: 1.1
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Emojis de reacción
                        Row {
                            spacing: 4
                            leftPadding: 20
                            anchors.verticalCenter: parent.verticalCenter

                            // Lista completa de emojis según rating (de mejor a peor)
                            property var emojiList: ["🤩", "😍", "😃", "😊", "🙂", "😐", "😕", "😞", "😠", "😡"]

                            // Función para obtener 3 emojis apropiados según el rating
                            function getEmojisForRating(rating) {
                                // Convertir rating (0-1) a índice en la lista de emojis
                                var index = Math.min(Math.floor((1 - rating) * emojiList.length), emojiList.length - 3);

                                // Si el rating es muy bajo, mostrar los últimos 3 emojis (los más negativos)
                                if (rating < 0.1) {
                                    index = emojiList.length - 3;
                                }

                                // Devolver 3 emojis consecutivos
                                return [
                                    emojiList[index],
                                    emojiList[Math.min(index + 1, emojiList.length - 1)],
                                    emojiList[Math.min(index + 2, emojiList.length - 1)]
                                ];
                            }

                            // Obtener los emojis apropiados para el rating actual
                            property var currentEmojis: getEmojisForRating(currentMovie ? currentMovie.rating || 0 : 0)

                            // Mostrar los 3 emojis seleccionados
                            Repeater {
                                model: 3

                                Text {
                                    text: parent.currentEmojis[index]
                                    font.pixelSize: 28
                                    opacity: index === 0 ? 1.0 : (index === 1 ? 0.7 : 0.4) // El primer emoji más destacado
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
                    font { family: global.fonts.sans; pixelSize: 20; italic: true }
                    width: parent.width
                }

                // Título de Overview
                Text {
                    text: "Overview"
                    color: "white"
                    font { family: global.fonts.sans; pixelSize: 24; bold: true }
                    topPadding: 10
                }

                // Descripción de la película
                Text {
                    text: currentMovie ? currentMovie.description || "No description available." : "No description available."
                    color: "white"
                    font { family: global.fonts.sans; pixelSize: 18 }
                    wrapMode: Text.WordWrap
                    width: parent.width
                    lineHeight: 1.0
                }

                // Información del equipo de producción
                Grid {
                    columns: 2
                    rowSpacing: 15
                    columnSpacing: 30
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
                                font { family: global.fonts.sans; pixelSize: 16; bold: true }
                            }

                            Text {
                                text: modelData.name
                                color: "white"
                                font { family: global.fonts.sans; pixelSize: 16 }
                            }
                        }
                    }
                }
            }
        }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event)) {
            event.accepted = true;
            Utils.hideDetails(movieDetailsRoot);
            if (previousFocus === "gridView") {
                gridViewMovies.visible = true;
                gridViewMovies.focus = true;
            } else if (previousFocus === "gridViewTitles") {
                gridViewTitles.visible = true;
                gridViewTitles.focus = true;
            }
        }
    }
}
