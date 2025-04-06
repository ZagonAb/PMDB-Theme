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
    property real scaleFactor: Math.min(width / 200, height / 800)
    property real menuFontSize: 28 * scaleFactor
    visible: isVisible
    focus: isVisible

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
        var ratingRanges = [];
        for (var i = 9; i >= 0; i--) {
            ratingRanges.push({
                label: i + ".0",
                min: i/10,
                max: (i+1)/10 - 0.0001
            });
        }

        ratingRanges.forEach(range => {
            moviesByRating.set(range.label, []);
        });

        for (var k = 0; k < baseMoviesFilter.count; k++) {
            var movie = baseMoviesFilter.get(k);
            var rating = movie.rating;
            var rangeIndex = Math.floor(rating * 10);
            if (rangeIndex > 9) rangeIndex = 9;
            if (rangeIndex < 0) rangeIndex = 0;

            var rangeLabel = rangeIndex + ".0";
            moviesByRating.get(rangeLabel).push(movie);
        }

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

        ListModel {
            id: ratingListModel
        }

        ListModel {
            id: baseMoviesFilter
        }

        SortFilterProxyModel {
            id: moviesByRatingFilter
            sourceModel: baseMoviesFilter
            sorters: RoleSorter { roleName: "rating"; sortOrder: Qt.DescendingOrder }
        }

        SortFilterProxyModel {
            id: filteredMoviesByRating
            sourceModel: baseMoviesFilter
            filters: [
                RangeFilter {
                    id: ratingMinFilter
                    roleName: "rating"
                    minimumValue: -1
                    maximumValue: 2
                },
                ValueFilter {
                    id: ratingNoRatingFilter
                    roleName: "rating"
                    enabled: false
                    value: 0.0
                }
            ]

            sorters: RoleSorter {
                roleName: "rating"
                sortOrder: Qt.DescendingOrder
            }
        }

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
                        width: ratingsListView.width
                        height: 60
                        color: ListView.isCurrentItem && ratingsListView.focus ? "#006dc7" : "transparent"
                        radius: 5


                        Row {
                            anchors {
                                verticalCenter: parent.verticalCenter
                                left: parent.left
                                leftMargin: 10
                            }
                            spacing: 4

                            Text {
                                text: "★"
                                color: "#ffcc00"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: ratingList.menuFontSize
                                    bold: true
                                }

                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: model.label
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
                            moviesGridView.focus = true;
                        } else if (api.keys.isCancel(event)) {
                            event.accepted = true;
                            if (ratingListModel.count > 0) {
                                var firstItem = ratingListModel.get(0);
                                setFilterForRating(firstItem.min, firstItem.max, firstItem.label);
                            }

                            Utils.hideRatingList();
                        }
                    }

                    focus: true
                }
            }

            GridView {
                id: moviesGridView
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: width / 4
                cellHeight: height / 2
                clip: true

                cacheBuffer: cellHeight * 8
                boundsBehavior: Flickable.StopAtBounds

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
                                    color: "#FFD700"
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

                Keys.onPressed: {
                    if (event.key === Qt.Key_Left) {
                        event.accepted = true;
                        if (moviesGridView.currentIndex === 0) {
                            ratingsListView.focus = true;
                            backgroundImage.source = "";
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
                        backgroundImage.source = "";
                    } else if (api.keys.isAccept(event)) {
                        event.accepted = true;
                        if (currentIndex >= 0) {
                            Utils.showDetails(movieDetails, filteredMoviesByRating.get(currentIndex), "RatingList");
                        }
                    }
                }

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
            ratingMinFilter.enabled = true;
            ratingNoRatingFilter.enabled = false;
            ratingMinFilter.minimumValue = 0.0;
            ratingMinFilter.maximumValue = 0.099;
        } else {
            ratingMinFilter.enabled = true;
            ratingNoRatingFilter.enabled = false;
            ratingMinFilter.minimumValue = min - 0.0001;
            ratingMinFilter.maximumValue = max + 0.0001;
        }
        selectedRatingRange = label;
        moviesGridView.currentIndex = 0;
        moviesGridView.positionViewAtBeginning();
    }
}
