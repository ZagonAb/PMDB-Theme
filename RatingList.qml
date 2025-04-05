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
import QtQuick.Layouts 1.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils

FocusScope {
    id: ratingList

    property var currentModel: null
    property bool isVisible: false
    property bool isExpanded: false
    property string selectedRatingRange: ""
    property real scaleFactor: Math.min(width / 200, height / 800) // Factor de escala base
    property real menuFontSize: 28 * scaleFactor



    visible: isVisible
    focus: isVisible

    // Función para filtrar películas por colección
    function filterMoviesByCollection(collectionName) {
        var filteredMovies = [];
        for (var i = 0; i < api.allGames.count; i++) {
            var movie = api.allGames.get(i);
            for (var j = 0; j < movie.collections.count; j++) {
                if (movie.collections.get(j).shortName === collectionName) {
                    filteredMovies.push(movie);
                    break;
                }
            }
        }
        return filteredMovies;
    }

    function createCategoriesFromRatings() {
        var moviesByRating = new Map();

        // Crear rangos simplificados de 0.0 a 9.0
        var ratingRanges = [];
        for (var i = 9; i >= 0; i--) {
            ratingRanges.push({
                label: i + ".0",
                min: i/10,
                max: (i+1)/10 - 0.0001 // Pequeña tolerancia para evitar solapamientos
            });
        }

        // Inicializar los mapas para cada rango
        ratingRanges.forEach(range => {
            moviesByRating.set(range.label, []);
        });

        // Agrupar películas por rangos de calificación
        for (var k = 0; k < baseMoviesFilter.count; k++) {
            var movie = baseMoviesFilter.get(k);
            var rating = movie.rating; // Ya está en escala 0-1

            // Encontrar el rango correspondiente
            var rangeIndex = Math.floor(rating * 10);
            if (rangeIndex > 9) rangeIndex = 9; // Por si acaso hay valores > 0.999
            if (rangeIndex < 0) rangeIndex = 0; // Por si acaso hay valores < 0

            var rangeLabel = rangeIndex + ".0";
            moviesByRating.get(rangeLabel).push(movie);
        }

        // Convertir el mapa a un array con solo rangos que tengan películas
        var ratingsArray = [];
        ratingRanges.forEach(range => {
            var movies = moviesByRating.get(range.label);
            if (movies.length > 0) {
                ratingsArray.push({
                    label: range.label,
                    count: movies.length,
                    movies: movies,
                    min: range.min,
                    max: range.max
                });
            }
        });

        return ratingsArray;
    }

    // Función para cargar la lista de rangos de calificación en ratingListModel
    function updateRatingsList() {
        ratingListModel.clear();
        var ratingsData = createCategoriesFromRatings();

        for (var i = 0; i < ratingsData.length; i++) {
            ratingListModel.append({
                label: ratingsData[i].label,
                count: ratingsData[i].count,
                movies: ratingsData[i].movies,
                min: ratingsData[i].min,
                max: ratingsData[i].max
            });
        }
    }

    Text {
        id: heading
        text: "Movies / Ratings"
        color: "white"
        font {
            family: global.fonts.sans
            pixelSize: Math.max(12, ratingList.width * 0.03)
            bold: true
        }
        anchors {
            top: parent.top
            left: parent.left
            margins: 30
        }
    }

    Rectangle {
        id: container
        anchors {
            top: heading.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 10
        }
        color: "transparent"

        // Modelo para almacenar la lista de rangos de calificación disponibles
        ListModel {
            id: ratingListModel
        }

        // Filtra solo las películas en la colección "movies"
        ListModel {
            id: baseMoviesFilter
        }

        // Ordena películas por calificación
        SortFilterProxyModel {
            id: moviesByRatingFilter
            sourceModel: baseMoviesFilter
            sorters: RoleSorter { roleName: "rating"; sortOrder: Qt.DescendingOrder }
        }

        // Filtra películas por rango de calificación seleccionado
        SortFilterProxyModel {
            id: filteredMoviesByRating
            sourceModel: baseMoviesFilter
            filters: [
                RangeFilter {
                    id: ratingMinFilter
                    roleName: "rating"
                    minimumValue: -1  // Se establecerá cuando se seleccione un rango
                    maximumValue: 2   // Valor predeterminado, cambiará cuando se seleccione un rango
                },
                ValueFilter {
                    id: ratingNoRatingFilter
                    roleName: "rating"
                    enabled: false    // Activado solo para "No Rating"
                    value: 0.0
                }
            ]
            // Ordenar las películas por calificación (de mayor a menor)
            sorters: RoleSorter {
                roleName: "rating"
                sortOrder: Qt.DescendingOrder
            }
        }

        // Diseño de la UI
        RowLayout {
            anchors.fill: parent
            spacing: 10

            Item {
                Layout.preferredWidth: parent.width * 0.10
                Layout.fillHeight: true

                ListView {
                    id: ratingsListView
                    width: parent.width
                    height: contentHeight
                    anchors.centerIn: parent

                    model: ratingListModel
                    currentIndex: 0
                    spacing: 15

                    delegate: Rectangle {
                        id: ratingDelegate
                        width: ratingsListView.width //- 20
                        height: 60 // Altura más compacta como en la imagen
                        color: ListView.isCurrentItem && ratingsListView.focus ? "#006dc7" : "transparent"
                        radius: 5 // Sin bordes redondeados


                        Row {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                leftMargin: 10
                            }
                            spacing: 4

                            Text {
                                text: "★" // Estrella
                                color: "#ffcc00" // Color amarillo/dorado para la estrella
                                font {
                                    family: global.fonts.sans
                                    pixelSize: ratingList.menuFontSize
                                    bold: true
                                }

                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: model.label // Muestra el label
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: ratingList.menuFontSize
                                    bold: true
                                }
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                ratingsListView.currentIndex = index;
                                setFilterForRating(model.min, model.max, model.label);
                            }
                        }
                    }

                    // Manejar la navegación con las teclas de dirección y la tecla "Cancel"
                    Keys.onPressed: {
                        if (event.key === Qt.Key_Up) {
                            event.accepted = true;
                            if (ratingsListView.currentIndex > 0) {
                                ratingsListView.currentIndex--;
                                var item = ratingListModel.get(ratingsListView.currentIndex);
                                setFilterForRating(item.min, item.max, item.label);
                            }
                        } else if (event.key === Qt.Key_Down) {
                            event.accepted = true;
                            if (ratingsListView.currentIndex < ratingListModel.count - 1) {
                                ratingsListView.currentIndex++;
                                var item = ratingListModel.get(ratingsListView.currentIndex);
                                setFilterForRating(item.min, item.max, item.label);
                            }
                        } else if (event.key === Qt.Key_Right) {
                            event.accepted = true;
                            // Mover el foco al GridView
                            moviesGridView.focus = true;
                        } else if (api.keys.isCancel(event)) {
                            event.accepted = true;
                            // Reiniciar los filtros al salir
                            if (ratingListModel.count > 0) {
                                var firstItem = ratingListModel.get(0);
                                setFilterForRating(firstItem.min, firstItem.max, firstItem.label);
                            }

                            // Llamar a la función para salir de RatingList
                            Utils.hideRatingList();
                        }
                    }

                    // Asegurarse de que el ListView tenga el foco al entrar
                    focus: true
                }
            }

            /*GridView {
                id: moviesGridView
                width: parent.width - ratingsListView.width - 20
                height: parent.height*/
            GridView {
                id: moviesGridView
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: width / 4  // 4 columnas
                cellHeight: height / 2 // 2 filas
                clip: true // Para evitar que los elementos se salgan del área visible

                cacheBuffer: cellHeight * 8
                boundsBehavior: Flickable.StopAtBounds // Comportamiento más predecible

                model: filteredMoviesByRating

                delegate: Item {
                    id: delegateMovies
                    width: moviesGridView.cellWidth
                    height: moviesGridView.cellHeight

                    property real menuFontSize: ratingList.menuFontSize

                    Rectangle {
                        width: parent.width * 0.8
                        height: parent.height * 0.8
                        color: "transparent"
                        border.color: "#006dc7"
                        border.width: moviesGridView.currentIndex === index ? Math.max(2, parent.width * 0.015) : 0
                        visible: moviesGridView.currentIndex === index && moviesGridView.focus
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 0
                        z: 100
                    }

                    Component.onCompleted: console.log("scaleFactor:", scaleFactor, "menuFontSize:", menuFontSize)

                    Column {
                        anchors.fill: parent
                        spacing: 10

                        Item {
                            id: contentContainer
                            width: parent.width
                            height: parent.height
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                id: posterContainer
                                width: parent.width * 0.8
                                height: parent.height * 0.8
                                color: "#022441"
                                radius: 4
                                clip: true
                                anchors.horizontalCenter: parent.horizontalCenter

                                Image {
                                    source: model.assets.boxFront
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    mipmap: true

                                    Text {
                                        visible: parent.status !== Image.Ready
                                        anchors.centerIn: parent
                                        text: "......"
                                        color: "white"
                                    }
                                }
                            }

                            Column {
                                anchors {
                                    top: posterContainer.bottom
                                    topMargin: 5
                                    horizontalCenter: parent.horizontalCenter
                                }
                                width: parent.width * 0.8
                                spacing: 5

                                Text {
                                    text: model.title

                                    font {
                                        family: global.fonts.sans
                                        pixelSize: Math.max(8, delegateMovies.width * 0.050)
                                        bold: true
                                    }

                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                    color: "white"
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                }

                                Text {
                                    text: "Rating: " + Math.round(model.rating * 100) + "%"

                                    font {
                                        family: global.fonts.sans
                                        pixelSize: Math.max(8, delegateMovies.width * 0.045)
                                        bold: true
                                    }
                                    horizontalAlignment: Text.AlignHCenter
                                    width: parent.width
                                    color: "#FFD700" // Color dorado para las calificaciones
                                    visible: model.rating > 0
                                }
                            }
                        }
                    }
                }

                onFocusChanged: {
                    if (!focus) {
                        backgroundImage.source = "";
                    } else if (currentIndex >= 0 && filteredMoviesByRating.count > 0) {
                        var selectedMovie = filteredMoviesByRating.get(currentIndex);
                        if (selectedMovie) {
                            root.currentMovie = selectedMovie;
                            backgroundImage.source = Utils.getBackgroundImage(selectedMovie);
                        }
                    }
                }

                onCurrentIndexChanged: {
                    if (focus && currentIndex >= 0 && filteredMoviesByRating.count > 0) {
                        var selectedMovie = filteredMoviesByRating.get(currentIndex);
                        if (selectedMovie) {
                            root.currentMovie = selectedMovie;
                            backgroundImage.source = Utils.getBackgroundImage(selectedMovie);
                        }
                    }
                }

                // Manejar la navegación con las teclas de dirección en el GridView
                Keys.onPressed: {
                    if (event.key === Qt.Key_Left) {
                        event.accepted = true;
                        if (moviesGridView.currentIndex === 0) {
                            ratingsListView.focus = true;
                            backgroundImage.source = ""; // Limpiar background al volver
                        } else {
                            moviesGridView.moveCurrentIndexLeft();
                        }
                    } else if (event.key === Qt.Key_Right) {
                        event.accepted = true;
                        moviesGridView.moveCurrentIndexRight();
                    } else if (event.key === Qt.Key_Up) {
                        event.accepted = true;
                        moviesGridView.moveCurrentIndexUp();
                    } else if (event.key === Qt.Key_Down) {
                        event.accepted = true;
                        moviesGridView.moveCurrentIndexDown();
                    } else if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        ratingsListView.focus = true;
                        backgroundImage.source = ""; // Limpiar background al retroceder
                    } else if (api.keys.isAccept(event)) {
                        event.accepted = true;
                        if (currentIndex >= 0) {
                            Utils.showDetails(movieDetails, filteredMoviesByRating.get(currentIndex), "RatingList"); // Pasar "gridViewTitles" como previousFocus
                            //genreList.visible = false; // Ocultar el grid al mostrar los detalles
                        }
                    }
                }

                // Asegurarse de que el GridView tenga el foco al entrar desde el ListView
                focus: false
            }

        }

        Component.onCompleted: {
            var movies = filterMoviesByCollection("movies");
            baseMoviesFilter.clear();
            for (var i = 0; i < movies.length; i++) {
                baseMoviesFilter.append(movies[i]);
            }
            updateRatingsList();

            // Seleccionar el primer rango de calificación al cargar
            if (ratingListModel.count > 0) {
                ratingsListView.currentIndex = 0;
                var firstItem = ratingListModel.get(0);
                setFilterForRating(firstItem.min, firstItem.max, firstItem.label);
            }
        }
    }

    function setFilterForRating(min, max, label) {
        //console.log("Filtrando por: " + label + " (min: " + min + ", max: " + max + ")");

        if (label === "0.0") {
            // Modificar para mostrar todas las películas sin calificación
            ratingMinFilter.enabled = true;
            ratingNoRatingFilter.enabled = false;
            ratingMinFilter.minimumValue = 0.0;
            ratingMinFilter.maximumValue = 0.099; // Incluir películas con ratings muy bajos
        } else {
            // Configurar filtro de rango para películas con calificación
            ratingMinFilter.enabled = true;
            ratingNoRatingFilter.enabled = false;
            ratingMinFilter.minimumValue = min - 0.0001; // Pequeña tolerancia
            ratingMinFilter.maximumValue = max + 0.0001; // Pequeña tolerancia
        }
        selectedRatingRange = label;

        // Asegurarnos de que el GridView se actualice correctamente
        moviesGridView.currentIndex = 0;
        moviesGridView.positionViewAtBeginning();
    }
}
