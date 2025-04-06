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
    id: yearList

    property var currentModel: null
    property bool isVisible: false
    property bool isExpanded: false
    property int selectedYear: -1
    property real scaleFactor: Math.min(width / 200, height / 800)
    property real menuFontSize: 28 * scaleFactor

    visible: isVisible
    focus: isVisible

    function filterMoviesByCollection(collectionName) {
        var filteredMovies = [];
        var allGamesCount = api.allGames.count;

        for (var i = 0; i < allGamesCount; i++) {
            var movie = api.allGames.get(i);
            var collectionsCount = movie.collections.count;

            for (var j = 0; j < collectionsCount; j++) {
                if (movie.collections.get(j).shortName === collectionName) {
                    filteredMovies.push(movie);
                    break;
                }
            }
        }
        return filteredMovies;
    }

    function createCategoriesFromYears() {
        var moviesByYear = new Map();
        var count = baseMoviesFilter.count;

        for (var i = 0; i < count; i++) {
            var movie = baseMoviesFilter.get(i);
            var year = movie.releaseYear;

            if (!moviesByYear.has(year)) {
                moviesByYear.set(year, []);
            }
            moviesByYear.get(year).push(movie);
        }

        return Array.from(moviesByYear.entries())
        .map(([year, movies]) => ({
            year: parseInt(year),
                                  count: movies.length,
                                  movies: movies
        }))
        .sort((a, b) => b.year - a.year);
    }

    function updateYearsList() {
        yearsListModel.clear();
        var yearsData = createCategoriesFromYears();
        var dataLength = yearsData.length;

        for (var i = 0; i < dataLength; i++) {
            yearsListModel.append({
                year: yearsData[i].year,
                count: yearsData[i].count,
                movies: yearsData[i].movies
            });
        }
    }

    Text {
        id: heading
        text: "Movies / Years"
        color: "white"
        font {
            family: global.fonts.sans
            pixelSize: Math.max(12, yearList.width * 0.03)
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
            id: yearsListModel
        }

        ListModel {
            id: baseMoviesFilter
        }

        SortFilterProxyModel {
            id: moviesByYearFilter
            sourceModel: baseMoviesFilter
            sorters: RoleSorter {
                roleName: "releaseYear"
                sortOrder: Qt.DescendingOrder
            }
        }

        SortFilterProxyModel {
            id: filteredMoviesByYear
            sourceModel: baseMoviesFilter
            filters: ValueFilter {
                id: yearFilter
                roleName: "releaseYear"
                value: -1
            }
        }

        Row {
            anchors.fill: parent
            spacing: 10

            ListView {
                id: yearsListView
                width: parent.width * 0.10
                height: parent.height * 0.90
                model: yearsListModel
                currentIndex: 0
                anchors.verticalCenter: parent.verticalCenter
                clip: true
                cacheBuffer: Math.max(0, height)

                delegate: Rectangle {
                    id: yearDelegate
                    width: yearsListView.width - 20
                    height: 60
                    color: ListView.isCurrentItem && yearsListView.focus ? "#006dc7" : "transparent"
                    radius: 5

                    Text {
                        anchors.centerIn: parent
                        text: model.year
                        color: "white"
                        font {
                            family: global.fonts.sans
                            pixelSize: yearList.menuFontSize
                            bold: true
                        }
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            yearsListView.currentIndex = index;
                            yearFilter.value = model.year;
                        }
                    }
                }

                Keys.onUpPressed: {
                    if (currentIndex > 0) {
                        currentIndex--;
                        yearFilter.value = yearsListModel.get(currentIndex).year;
                    }
                }

                Keys.onDownPressed: {
                    if (currentIndex < yearsListModel.count - 1) {
                        currentIndex++;
                        yearFilter.value = yearsListModel.get(currentIndex).year;
                    }
                }

                Keys.onRightPressed: {
                    moviesGridView.focus = true;
                }

                Keys.onPressed: {
                    if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        if (yearsListModel.count > 0) {
                            yearFilter.value = yearsListModel.get(0).year;
                        }
                        Utils.hideYearList();
                    }
                }

                focus: true
            }

            GridView {
                id: moviesGridView
                width: parent.width - yearsListView.width - 20
                height: parent.height
                cellWidth: width / 4
                cellHeight: height / 2
                clip: true
                model: filteredMoviesByYear
                cacheBuffer: cellHeight * 4
                boundsBehavior: Flickable.StopAtBounds
                displayMarginBeginning: cellHeight
                displayMarginEnd: cellHeight
                snapMode: GridView.SnapToRow

                delegate: Item {
                    id: delegateMovies
                    width: moviesGridView.cellWidth
                    height: moviesGridView.cellHeight

                    Rectangle {
                        width: parent.width * 0.8
                        height: parent.height * 0.8
                        color: "transparent"
                        border.color: "#006dc7"
                        border.width: moviesGridView.currentIndex === index && moviesGridView.focus ?
                        Math.max(2, parent.width * 0.015) : 0
                        visible: moviesGridView.currentIndex === index && moviesGridView.focus
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 0
                        z: 100
                    }

                    Rectangle {
                        id: posterContainer
                        width: parent.width * 0.8
                        height: parent.height * 0.8
                        color: "#022441"
                        radius: 4
                        clip: true
                        anchors {
                            horizontalCenter: parent.horizontalCenter
                            top: parent.top
                        }

                        Image {
                            id: posterImage
                            source: model.assets.boxFront
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            mipmap: true
                            sourceSize {
                                width: posterContainer.width > 300 ? 300 : posterContainer.width
                                height: posterContainer.height > 400 ? 400 : posterContainer.height
                            }
                            cache: true

                            Text {
                                visible: parent.status !== Image.Ready
                                anchors.centerIn: parent
                                text: "......"
                                color: "white"
                            }
                        }
                    }

                    Text {
                        text: model.title
                        font {
                            family: global.fonts.sans
                            pixelSize: Math.max(12, delegateMovies.width * 0.03)
                            bold: true
                        }
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        maximumLineCount: 2
                        width: parent.width * 0.8
                        anchors {
                            top: posterContainer.bottom
                            topMargin: 6
                            horizontalCenter: parent.horizontalCenter
                        }
                        color: "white"
                    }
                }

                onFocusChanged: {
                    if (focus && currentIndex >= 0 && count > 0) {
                        updateBackground();
                    } else if (!focus) {
                        backgroundImage.source = "";
                    }
                }

                onCurrentIndexChanged: {
                    if (focus && currentIndex >= 0 && count > 0) {
                        updateBackground();
                    }
                }

                function updateBackground() {
                    var selectedMovie = filteredMoviesByYear.get(currentIndex);
                    if (selectedMovie) {
                        root.currentMovie = selectedMovie;
                        backgroundImage.source = Utils.getBackgroundImage(selectedMovie);
                    }
                }

                Keys.onLeftPressed: {
                    if (currentIndex % 4 === 0) {
                        yearsListView.focus = true;
                        backgroundImage.source = "";
                    } else {
                        moveCurrentIndexLeft();
                    }
                }

                Keys.onRightPressed: moveCurrentIndexRight()
                Keys.onUpPressed: moveCurrentIndexUp()
                Keys.onDownPressed: moveCurrentIndexDown()

                Keys.onPressed: {
                    if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        yearsListView.focus = true;
                        backgroundImage.source = "";
                    } else if (api.keys.isAccept(event)) {
                        event.accepted = true;
                        if (currentIndex >= 0) {
                            Utils.showDetails(movieDetails, filteredMoviesByYear.get(currentIndex), "YearList");
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

            updateYearsList();

            if (yearsListModel.count > 0) {
                yearsListView.currentIndex = 0;
                yearFilter.value = yearsListModel.get(0).year;
            }
        }
    }
}
