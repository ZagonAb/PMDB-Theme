// PMDB-Theme
// Copyright (C) 2025  Gonzalo Abbate
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

import QtQuick 2.15
import "utils.js" as Utils
import QtGraphicalEffects 1.15
import "qrc:/qmlutils" as PegasusUtils

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
    property var currentMovie: null

    // Función para ocultar el gridview
    function hideGrid() {
        isVisible = false;
        hasFocus = false;

        // Limpia la imagen de fondo explícitamente
        backgroundImage.source = "";
        currentMovie = null;

        // Asegúrate de que el overlay tenga la opacidad correcta
        overlayImage.opacity = 0.7;

        currentFocus = "menu";
        leftMenu.menuList.focus = true;
        listviewContainer.visible = true;
        gridViewTitlesRoot.visible = false;
    }

    function resetGridView() {
        Utils.resetGridView(gridView);
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

    // GridView con exactamente 2 columnas
    GridView {
        id: gridView
        anchors.fill: parent

        // Exactamente 2 columnas siempre
        cellWidth: width / 2  // Siempre divide el ancho en 2
        cellHeight: cellWidth * 0.43  // Mantiene proporción 2:1

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
            } else if (api.keys.isAccept(event)) {
                event.accepted = true;
                if (currentIndex >= 0) {
                    Utils.showDetails(movieDetails, currentModel.get(currentIndex), "gridViewTitles"); // Pasar "gridViewTitles" como previousFocus
                    gridViewTitlesRoot.visible = false; // Ocultar el grid al mostrar los detalles
                }
            }
        }
    }

    // Delegate para cada tarjeta de juego
    Component {
        id: gridDelegate

        Item {
            width: gridView.cellWidth
            height: gridView.cellHeight

            // Contenedor principal - Responsive
            Rectangle {
                id: cardContainer
                anchors.fill: parent
                anchors.margins: parent.width * 0.02  // Margen proporcional
                color: "#232323"  // Color de fondo de la tarjeta
                radius: 5  // Bordes redondeados

                // Fila para la portada y los detalles - Responsive
                Row {
                    anchors.fill: parent
                    anchors.margins: parent.width * 0.02
                    spacing: parent.width * 0.02

                    // Portada del juego (BOXFRONT) - Responsive
                    Rectangle {
                        width: parent.width * 0.3  // 30% del ancho
                        height: parent.height
                        color: "transparent"

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

                    // Columna para los detalles del juego - Responsive
                    Column {
                        width: parent.width * 0.68  // 68% del ancho restante
                        height: parent.height
                        spacing: parent.height * 0.05

                        // Título del juego - Responsive
                        Text {
                            text: modelData.title
                            color: "white"
                            font {
                                family: global.fonts.sans
                                pixelSize: Math.max(12, cardContainer.width * 0.03)  // Tamaño responsivo
                                bold: true
                            }
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        // Detalles (año de lanzamiento, rating, género) - Responsive
                        Row {
                            spacing: 5
                            width: parent.width

                            Text {
                                text: modelData.releaseYear || "N/A"
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, cardContainer.width * 0.025)  // Tamaño responsivo
                                }
                            }
                            Text {
                                text: "|"
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, cardContainer.width * 0.025)
                                }
                            }
                            Text {
                                text: (modelData.rating * 100).toFixed(0) + "%" || "N/A"
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, cardContainer.width * 0.025)
                                }
                            }
                            Text {
                                text: "|"
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, cardContainer.width * 0.025)
                                }
                            }
                            Text {
                                text: modelData.genre || "N/A"
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, cardContainer.width * 0.025)
                                }
                                elide: Text.ElideRight
                                width: parent.width * 0.4
                            }
                        }

                        // Solución para AutoScroll condicionado
                        Item {
                            width: parent.width
                            height: parent.height * 0.5

                            // Texto estático (cuando no está seleccionado)
                            Text {
                                id: staticDescription
                                anchors.fill: parent
                                text: modelData.description || "No description available."
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, cardContainer.width * 0.025)
                                }
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                                visible: gridView.currentIndex !== index
                            }

                            // AutoScroll (solo visible cuando está seleccionado)
                            PegasusUtils.AutoScroll {
                                anchors.fill: parent
                                visible: gridView.currentIndex === index

                                Text {
                                    text: modelData.description || "No description available."
                                    color: "white"
                                    font {
                                        family: global.fonts.sans
                                        pixelSize: Math.max(10, cardContainer.width * 0.025)
                                    }
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                    horizontalAlignment: Text.AlignJustify
                                }
                            }
                        }
                        // Versión simplificada pero funcional
                        Text {
                            width: parent.width
                            height: Math.max(20, cardContainer.width * 0.04)
                            text: Utils.formatVideoPath(modelData)
                            color: "#AAAAAA"
                            font {
                                family: global.fonts.sans
                                pixelSize: Math.max(12, cardContainer.width * 0.022)
                            }
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap

                            MouseArea {
                                id: pathMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    // Alternar entre vista completa y abreviada al hacer clic
                                    parent.text = (parent.elide === Text.ElideRight)
                                    ? Utils.formatVideoPath(modelData, true)
                                    : Utils.formatVideoPath(modelData);
                                    parent.elide = (parent.elide === Text.ElideRight)
                                    ? Text.ElideNone
                                    : Text.ElideRight;
                                    parent.wrapMode = (parent.wrapMode === Text.NoWrap)
                                    ? Text.Wrap
                                    : Text.NoWrap;
                                }
                            }
                        }
                    }
                }

                // Rectángulo de selección - Responsivo
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "#006dc7"
                    border.width: gridView.currentIndex === index ? Math.max(2, parent.width * 0.007) : 0  // Ancho proporcional
                    visible: gridView.currentIndex === index
                    radius: 0
                    z: 100
                }
            }
        }
    }
}
