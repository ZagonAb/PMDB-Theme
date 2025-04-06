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
    id: genreList

    property var currentModel: null
    property bool isVisible: false
    property bool isExpanded: false
    property string selectedGenre: ""
    property bool genereVisible: isVisible

    property real scaleFactor: Math.min(width / 200, height / 800)
    property real menuFontSize: 28 * scaleFactor

    visible: isVisible
    focus: isVisible

    function isMovie(item) {
        if (!item.collections) return false;
        for (var j = 0; j < item.collections.count; j++) {
            if (item.collections.get(j).shortName === "movies") {
                return true;
            }
        }
        return false;
    }

    function normalizeGenre(genre) {
        var normalizedGenre = genre.trim()
        .split(' ')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
        .join(' ');

        return normalizedGenre.split(' ')[0];
    }

    function createCategoriesFromGenres() {
        var allGenres = {};
        for (var i = 0; i < api.allGames.count; i++) {
            var movie = api.allGames.get(i);
            if (!isMovie(movie) || !movie.genre) continue;
            var genreList = movie.genre.split(',');
            genreList.forEach(function(genre) {
                var baseCategory = genre.trim().split(/[\s\/-]/)[0].toLowerCase();
                if (!allGenres[baseCategory]) {
                    allGenres[baseCategory] = [];
                }
                allGenres[baseCategory].push(movie.title);
            });
        }
        var categoriesArray = [];
        Object.keys(allGenres).forEach(function(category) {
            categoriesArray.push({
                name: category,
                count: allGenres[category].length,
                games: allGenres[category]
            });
        });
        categoriesArray.sort((a, b) => b.count - a.count);
        return categoriesArray;
    }

    function formatGenreText(genreText, selectedGenre) {
        if (!genreText || !selectedGenre) return genreText;

        var genres = genreText.split(',');
        var result = [];
        var selectedBase = selectedGenre.split(/[\s\/-]/)[0].toLowerCase();

        for (var i = 0; i < genres.length; i++) {
            var genre = genres[i].trim();
            var baseGenre = genre.split(/[\s\/-]/)[0].toLowerCase();

            if (baseGenre === selectedBase) {
                result.push('<font color="#ff6600">' + genre + '</font>');
            } else {
                result.push('<font color="#a0a0a0">' + genre + '</font>');
            }
        }

        return result.join(', ');
    }

    ListModel {
        id: genreFilteredModel

        function filterCategory(category) {
            clear();
            var tempMovies = [];
            var categoryLower = category.toLowerCase();
            for (var i = 0; i < api.allGames.count; i++) {
                var movie = api.allGames.get(i);
                if (!isMovie(movie)) continue;

                var movieCategories = movie.genre ?
                movie.genre.split(',').map(function(genre) {
                    return genre.trim().split(/[\s\/-]/)[0].toLowerCase();
                }) : [];

                if (movieCategories.includes(categoryLower)) {
                    tempMovies.push(movie);
                }
            }
            for (var j = tempMovies.length - 1; j > 0; j--) {
                var randomIndex = Math.floor(Math.random() * (j + 1));
                [tempMovies[j], tempMovies[randomIndex]] = [tempMovies[randomIndex], tempMovies[j]];
            }
            tempMovies.forEach(function(movie) {
                append(movie);
            });
            if (tempMovies.length > 0 && moviesGridView.count > 0) {
                moviesGridView.currentIndex = 0;
            }
        }
    }

    Text {
        id: heading
        text: "Movies / Genres"
        color: "white"
        font {
            family: global.fonts.sans
            pixelSize: Math.max(12, genreList.width * 0.03)
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

        Component.onCompleted: {
            if (genresListView.model.length > 0) {
                genresListView.currentIndex = 0;
            }
        }

        Row {
            anchors.fill: parent
            spacing: 10

            ListView {
                id: genresListView
                width: parent.width * 0.15
                height: parent.height * 0.90
                focus: true
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                property int indexToPosition: -1
                property var categoriesModel: []
                property string selectedCategory: ""
                model: categoriesModel

                delegate: Rectangle {
                    width: genresListView.width - 20
                    height: 60
                    color: ListView.isCurrentItem && genresListView.focus ? "#006dc7" : "transparent"
                    radius: 5

                    Row {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            text: modelData ? (modelData.name.charAt(0).toUpperCase() + modelData.name.slice(1)) : ""
                            color: "white"
                            font {
                                family: global.fonts.sans
                                pixelSize: Math.max(10, genresListView.width * 0.14)
                                bold: true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            genresListView.currentIndex = index;
                        }
                    }
                }

                onCurrentIndexChanged: {
                    indexToPosition = currentIndex;
                    if (currentIndex >= 0 && currentIndex < model.length) {
                        selectedCategory = model[currentIndex].name;
                        genreFilteredModel.filterCategory(selectedCategory);
                        //console.log("Género seleccionado: " + selectedCategory + ", películas: " + genreFilteredModel.count);
                    }
                }

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Up) {
                        event.accepted = true;
                        if (genresListView.currentIndex > 0) {
                            genresListView.currentIndex--;
                            selectedGenre = genresListView.categoriesModel[genresListView.currentIndex].name;
                        }
                    } else if (event.key === Qt.Key_Down) {
                        event.accepted = true;
                        if (genresListView.currentIndex < genresListView.categoriesModel.length - 1) {
                            genresListView.currentIndex++;
                            selectedGenre = genresListView.categoriesModel[genresListView.currentIndex].name;
                        }
                    } else if (event.key === Qt.Key_Right) {
                        event.accepted = true;
                        if (moviesGridView.count > 0) {
                            moviesGridView.focus = true;
                        }
                    } else if (event.key === Qt.Key_Left) {
                        event.accepted = true;
                    } else if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        isExpanded = false;
                        genreList.isVisible = false;
                        genreList.visible = false;
                        listviewContainer.visible = true;
                        currentFocus = "menu";
                        Utils.setMenuFocus();
                        if (genresListView.categoriesModel.length > 0) {
                            selectedGenre = genresListView.categoriesModel[0].name;
                        }
                    }
                }

                onFocusChanged: {
                    if (focus && genresListView) {
                        if (genresListView.categoriesModel.length > 0) {
                            genresListView.currentIndex = 0;
                        }
                    }
                }
            }

            GridView {
                id: moviesGridView
                width: parent.width - genresListView.width - 20
                height: parent.height
                cellWidth: width / 4
                cellHeight: height / 2
                clip: true
                visible: true

                cacheBuffer: cellHeight * 4
                boundsBehavior: Flickable.StopAtBounds

                model: genreFilteredModel

                delegate: Item {
                    id: delegateMovies
                    width: moviesGridView.cellWidth
                    height: moviesGridView.cellHeight
                    visible: true

                    property real menuFontSize: 20

                    Binding {
                        target: delegateMovies
                        property: "menuFontSize"
                        value: genreList.menuFontSize
                        when: genreList.menuFontSize > 0
                    }

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

                    Column {
                        anchors.fill: parent
                        spacing: 10

                        Item {
                            id: contentContainer
                            width: parent.width
                            height: parent.height

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
                                    cache: true

                                    sourceSize {
                                        width: parent.width > 300 ? 300 : parent.width
                                        height: parent.height > 400 ? 400 : parent.height
                                    }

                                    Text {
                                        visible: parent.status !== Image.Ready
                                        anchors.centerIn: parent
                                        text: "......"
                                        color: "white"
                                    }
                                }
                            }

                            Text {
                                id: movieTitle
                                text: model.title
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, delegateMovies.width * 0.050)
                                    bold: true
                                }
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.WordWrap
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width * 0.8
                                color: "white"
                                anchors.top: posterContainer.bottom
                                anchors.topMargin: 10
                            }

                            Text {
                                text: formatGenreText(model.genre, genresListView.selectedCategory)
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, delegateMovies.width * 0.045)
                                }
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                wrapMode: Text.WordWrap
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width * 0.8
                                color: "#a0a0a0"
                                anchors.top: movieTitle.bottom
                                anchors.topMargin: 5
                                textFormat: Text.RichText
                            }
                        }
                    }
                }

                onFocusChanged: {
                    if (!focus) {
                        backgroundImage.source = "";
                    } else if (currentIndex >= 0 && genreFilteredModel.count > 0) {
                        var selectedMovie = genreFilteredModel.get(currentIndex);
                        if (selectedMovie) {
                            root.currentMovie = selectedMovie;
                            backgroundImage.source = Utils.getBackgroundImage(selectedMovie);
                        }
                    }
                }

                onCurrentIndexChanged: {
                    if (focus && currentIndex >= 0 && genreFilteredModel.count > 0) {
                        var selectedMovie = genreFilteredModel.get(currentIndex);
                        if (selectedMovie) {
                            root.currentMovie = selectedMovie;
                            backgroundImage.source = Utils.getBackgroundImage(selectedMovie);
                        }
                    }
                }

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Left) {
                        event.accepted = true;
                        if (currentIndex === 0) {
                            genresListView.focus = true;
                            backgroundImage.source = "";
                        } else if (currentIndex > 0) {
                            moveCurrentIndexLeft();
                        }
                    } else if (event.key === Qt.Key_Right) {
                        event.accepted = true;
                        if (currentIndex < count - 1) {
                            moveCurrentIndexRight();
                        }
                    } else if (event.key === Qt.Key_Up) {
                        event.accepted = true;
                        if (currentIndex >= 0) {
                            moveCurrentIndexUp();
                        }
                    } else if (event.key === Qt.Key_Down) {
                        event.accepted = true;
                        if (currentIndex >= 0) {
                            moveCurrentIndexDown();
                        }
                    } else if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        genresListView.focus = true;
                        backgroundImage.source = "";
                    } else if (!event.isAutoRepeat && api.keys.isAccept(event) && currentIndex >= 0 && currentIndex < count) {
                        event.accepted = true;
                        Utils.showDetails(movieDetails, genreFilteredModel.get(currentIndex), "GenreList");
                    }
                }
            }
        }
    }

    onIsVisibleChanged: {
        if (isVisible) {
            //console.log("GenreList se hizo visible");
            genresListView.categoriesModel = createCategoriesFromGenres();

            if (genresListView.categoriesModel.length > 0) {
                genresListView.currentIndex = 0;
                genresListView.selectedCategory = genresListView.categoriesModel[0].name;
                genreFilteredModel.filterCategory(genresListView.selectedCategory);
                genresListView.focus = true;
                if (genreFilteredModel.count > 0) {
                    moviesGridView.currentIndex = 0;
                }
                /*console.log("Inicializado con género: " + genresListView.selectedCategory +
                ", películas encontradas: " + genreFilteredModel.count);*/
            }
        }
    }
}
