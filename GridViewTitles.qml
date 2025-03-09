// GridViewTitles.qml
import QtQuick 2.15

FocusScope {
    id: gridViewTitlesRoot

    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        bottom: parent.bottom
    }

    property var currentModel: null
    property bool isVisible: false
    property bool hasFocus: false

    // Función para ocultar el gridview
    function hideGrid() {
        isVisible = false;
        hasFocus = false;
        currentFocus = "menu";
        leftMenu.menuList.focus = true;
        listviewContainer.visible = true;
        gridViewTitlesRoot.visible = false;
    }

    // Manejar cambios de visibilidad
    onIsVisibleChanged: {
        if (isVisible) {
            listviewContainer.visible = false;
            gridViewTitlesRoot.visible = true;
            gridViewTitlesRoot.focus = true;
            gridView.focus = true;
            hasFocus = true;
        } else {
            listviewContainer.visible = true;
            gridViewTitlesRoot.visible = false;
            gridViewTitlesRoot.focus = false;
            hasFocus = false;
        }
    }

    // GridView
    GridView {
        id: gridView
        anchors.fill: parent
        cellWidth: parent.width / 2  // Ajusta el ancho de las celdas según sea necesario
        cellHeight: 200  // Ajusta la altura de las celdas según sea necesario
        model: currentModel
        delegate: gridDelegate
        focus: hasFocus

        // Cambiar el foco cuando se selecciona un elemento
        onCurrentIndexChanged: {
            if (currentIndex >= 0) {
                currentMovie = currentModel.get(currentIndex);
                backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : "";
            }
        }

        // Manejo de teclas
        Keys.onLeftPressed: moveCurrentIndexLeft()
        Keys.onRightPressed: moveCurrentIndexRight()
        Keys.onUpPressed: moveCurrentIndexUp()
        Keys.onDownPressed: moveCurrentIndexDown()

        Keys.onPressed: {
            if (api.keys.isCancel(event)) {
                event.accepted = true;
                hideGrid();  // Ocultar el gridview al presionar "Cancelar"
            }
        }
    }

    // Delegate para cada tarjeta de juego
    Component {
        id: gridDelegate

        Item {
            width: gridView.cellWidth
            height: gridView.cellHeight

            // Contenedor principal
            Rectangle {
                anchors.fill: parent
                anchors.margins: 10  // Espaciado entre celdas
                color: "#191919"  // Color de fondo de la tarjeta
                radius: 5  // Bordes redondeados

                // Fila para la portada y los detalles
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.topMargin: 10  // Añade margen superior a toda la fila
                    spacing: 10

                    // Portada del juego (BOXFRONT)
                    Rectangle {
                        width: 100  // Ancho de la portada
                        height: parent.height
                        color: "transparent"  // Fondo negro para la portada

                        Image {
                            anchors.fill: parent
                            source: modelData.assets ? modelData.assets.boxFront : ""
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            asynchronous: true
                            cache: true
                            visible: status === Image.Ready
                        }
                    }

                    // Columna para los detalles del juego
                    Column {
                        width: parent.width - 110  // Ancho restante para los detalles
                        height: parent.height
                        spacing: 5

                        // Título del juego
                        Text {
                            text: modelData.title
                            color: "white"
                            font { family: global.fonts.sans; pixelSize: 18; bold: true }
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        // Detalles (año de lanzamiento, rating, género)
                        Row {
                            spacing: 5
                            Text {
                                text: modelData.releaseYear || "N/A"
                                color: "white"
                                font { family: global.fonts.sans; pixelSize: 14 }
                            }
                            Text {
                                text: "|"
                                color: "white"
                                font { family: global.fonts.sans; pixelSize: 14 }
                            }
                            Text {
                                text: (modelData.rating * 100).toFixed(0) + "%" || "N/A"
                                color: "white"
                                font { family: global.fonts.sans; pixelSize: 14 }
                            }
                            Text {
                                text: "|"
                                color: "white"
                                font { family: global.fonts.sans; pixelSize: 14 }
                            }
                            Text {
                                text: modelData.genre || "N/A"
                                color: "white"
                                font { family: global.fonts.sans; pixelSize: 14 }
                                elide: Text.ElideRight
                                width: parent.width * 0.5
                            }
                        }

                        // Descripción del juego
                        Text {
                            text: modelData.description || "No description available."
                            color: "white"
                            font { family: global.fonts.sans; pixelSize: 14 }
                            wrapMode: Text.WordWrap
                            width: parent.width
                            maximumLineCount: 3  // Limitar a 3 líneas
                            elide: Text.ElideRight
                        }
                    }
                }

                // Rectángulo de selección
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "#006dc7"
                    border.width: gridView.currentIndex === index ? 4 : 0
                    visible: gridView.currentIndex === index
                    radius: 5
                    z: 100
                }
            }
        }
    }
}
