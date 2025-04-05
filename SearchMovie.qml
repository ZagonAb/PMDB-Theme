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
import SortFilterProxyModel 0.2
import QtGraphicalEffects 1.15
import "utils.js" as Utils

Item {
    id: searchMovie
    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        bottom: parent.bottom
    }
    visible: false
    focus: false

    property bool isVisible: false
    property var searchResults: []
    property string currentSearchTerm: ""
    property int lastFocusedIndex: 0

    // Modelo para los resultados de búsqueda
    ListModel {
        id: searchResultsModel
    }

    // Barra de búsqueda
    Rectangle {
        id: searchBar
        width: parent.width * 0.8
        height: 60
        anchors {
            top: parent.top
            topMargin: 20
            horizontalCenter: parent.horizontalCenter
        }
        color: "#022441"
        radius: 5
        border.color: searchBar.focus ? "#1E90FF" : "#1E90FF"
        border.width: 2
        opacity: 0.5

        TextInput {
            id: searchInput
            anchors {
                fill: parent
                margins: 15
            }
            color: "white"
            font {
                family: global.fonts.sans
                pixelSize: 24
            }
            focus: true
            clip: true
            verticalAlignment: TextInput.AlignVCenter
            onTextChanged: {
                currentSearchTerm = text.toLowerCase().trim()
                performSearch(currentSearchTerm)
            }

            Keys.onPressed: {
                if (api.keys.isAccept(event) && searchResultsModel.count > 0) {
                    resultsGrid.focus = true
                    resultsGrid.currentIndex = 0
                    event.accepted = true
                }
                else if (api.keys.isCancel(event)) {
                    if (text.length > 0) {
                        // Borra un carácter
                        text = text.substring(0, text.length - 1)
                    } else {
                        // Si no hay texto, retrocede y limpia el fondo
                        backgroundImage.source = ""
                        clearAndHide()
                    }
                    event.accepted = true
                }
                else if (event.key === Qt.Key_Down && searchResultsModel.count > 0) {
                    resultsGrid.focus = true
                    resultsGrid.currentIndex = 0
                    event.accepted = true
                }
            }

            // Placeholder text
            Text {
                text: "Search movies..."
                color: "#aaaaaa"
                font: searchInput.font
                visible: searchInput.text === ""
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                }
            }
        }
    }
    // GridView para resultados (una sola fila en la parte inferior)
    Rectangle {
        id: gridContainer
        width: parent.width * 0.95
        height: parent.height * 0.5 // 40% del alto
        anchors {
            bottom: parent.bottom
            bottomMargin: parent.height * 0.1 // 10% de margen inferior
            horizontalCenter: parent.horizontalCenter
        }
        color: "transparent"

        GridView {
            id: resultsGrid
            anchors.fill: parent
            cellWidth: width / 4 // Mostrar 5 elementos por fila
            cellHeight: height // Una sola fila, altura completa del contenedor
            clip: true
            model: searchResultsModel
            visible: searchResultsModel.count > 0
            focus: false
            interactive: false // Deshabilitar scroll ya que es una sola

            delegate: Item {
                width: resultsGrid.cellWidth
                height: resultsGrid.cellHeight

                Column {
                    width: parent.width - 20
                    height: parent.height - 20
                    anchors.centerIn: parent
                    spacing: 10

                    // Contenedor para la imagen con borde de selección
                    Item {
                        width: parent.width
                        height: parent.height - 40 // Altura para el título

                        Image {
                            id: posterImage
                            anchors.fill: parent
                            source: model.assets ? model.assets.boxFront : ""
                            fillMode: Image.Stretch //PreserveAspectCrop
                            mipmap: true
                            asynchronous: true
                            cache: true
                            sourceSize { width: 200; height: 300 }
                        }

                        Rectangle {
                            anchors.fill: parent
                            color: "transparent"
                            border.color: resultsGrid.focus && resultsGrid.currentIndex === index ? "#006dc7" : "transparent"
                            border.width: resultsGrid.focus && resultsGrid.currentIndex === index ? 3 : 0
                            radius: 0
                        }
                    }

                    Text {
                        id: movieTitle
                        text: model.title ? Utils.highlightSearchText(model.title, currentSearchTerm) : ""
                        width: parent.width
                        height: 30
                        horizontalAlignment: Text.AlignHCenter
                        color: "white"
                        font {
                            family: global.fonts.sans
                            pixelSize: 12
                        }
                        elide: Text.ElideRight
                        wrapMode: Text.WordWrap
                        textFormat: Text.RichText // Añadir esto para interpretar el HTML
                    }
                }
            }

            onCurrentIndexChanged: Utils.updateBackground()

            onFocusChanged: {
                if (focus) {
                    Utils.updateBackground()
                } else {
                    backgroundImage.source = ""
                }
            }

            Keys.onPressed: {
                if (api.keys.isAccept(event)) {
                    event.accepted = true
                    if (resultsGrid.currentIndex >= 0) {
                        // Guardar el índice actual antes de abrir detalles
                        lastFocusedIndex = currentIndex

                        // Mostrar detalles de la película seleccionada
                        var selectedMovie = searchResultsModel.get(currentIndex)
                        Utils.showDetails(movieDetails, selectedMovie, "search")
                    }
                }
                else if (api.keys.isCancel(event)) {
                    backgroundImage.source = ""
                    searchBar.focus = true
                    searchInput.forceActiveFocus()
                    event.accepted = true
                }
                else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right ||
                    event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
                    // Manejar navegación
                    if (event.key === Qt.Key_Left && resultsGrid.currentIndex > 0) {
                        resultsGrid.currentIndex--
                    }
                    else if (event.key === Qt.Key_Right && resultsGrid.currentIndex < resultsGrid.count - 1) {
                        resultsGrid.currentIndex++
                    }
                    else if (event.key === Qt.Key_Up && resultsGrid.currentIndex > 0) {
                        resultsGrid.currentIndex--
                    }
                    else if (event.key === Qt.Key_Down && resultsGrid.currentIndex < resultsGrid.count - 1) {
                        resultsGrid.currentIndex++
                    }
                    event.accepted = true

                    // Forzar actualización
                    updateBackground()
                    }
            }
        }
    }

    // Texto cuando no hay resultados
    Text {
        id: noResultsText
        text: "No results found"
        color: "white"
        font {
            family: global.fonts.sans
            pixelSize: 24
            bold: true
        }
        anchors.centerIn: parent
        visible: searchResultsModel.count === 0 && currentSearchTerm.length > 0
    }

    // Texto inicial
    Text {
        text: "Start typing to search movies"
        color: "#aaaaaa"
        font {
            family: global.fonts.sans
            pixelSize: 24
        }
        anchors.centerIn: parent
        visible: searchResultsModel.count === 0 && currentSearchTerm.length === 0
    }

    // Función para restaurar el foco después de volver de MovieDetails
    function restoreFocus() {
        if (isVisible) {
            resultsGrid.focus = true
            resultsGrid.currentIndex = lastFocusedIndex
            Utils.updateBackground()
        }
    }

    function performSearch(term) {
        searchResultsModel.clear()
        if (term.length === 0) {
            return
        }

        // Buscar en la colección de películas
        for (var i = 0; i < api.collections.count; ++i) {
            var collection = api.collections.get(i)
            if (collection.shortName.toLowerCase() === "movies") {
                for (var j = 0; j < collection.games.count; ++j) {
                    var game = collection.games.get(j)
                    if (game.title.toLowerCase().includes(term)) {
                        searchResultsModel.append(game)
                    }
                }
                break
            }
        }
    }

    function clearAndHide() {
        searchInput.text = ""
        searchResultsModel.clear()
        currentSearchTerm = ""
        backgroundImage.source = ""
        hideSearch()
    }

    function showSearch() {
        isVisible = true
        visible = true
        focus = true
        searchBar.focus = true
        searchInput.forceActiveFocus()
    }

    function hideSearch() {
        isVisible = false
        visible = false
        focus = false
        listviewContainer.visible = true
        currentFocus = "menu"
        leftMenu.menuList.focus = true
    }
}
