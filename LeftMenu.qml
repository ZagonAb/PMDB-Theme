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

FocusScope {
    id: leftMenu
    width: parent.width * 0.2
    height: parent.height
    focus: currentFocus === "menu"
    property real scaleFactor: Math.min(width / 200, height / 800)
    property real titleIconSize: 40 * scaleFactor
    property real titleFontSize: 18 * scaleFactor
    property real menuIconSize: 40 * scaleFactor
    property real menuFontSize: 28 * scaleFactor
    property real menuItemHeight: 80 * scaleFactor
    property real menuItemSpacing: 40 * scaleFactor
    property real menuMargin: 20 * scaleFactor

    Rectangle {
        id: leftRectangle
        anchors.fill: parent
        color: "#aa000000"

        Row {
            id: titleRow
            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 20 * leftMenu.scaleFactor
            }
            spacing: 10 * leftMenu.scaleFactor

            Image {
                id: titleIcon
                source: "assets/icons/logo2.svg"
                width: leftMenu.titleIconSize
                height: leftMenu.titleIconSize
                anchors.verticalCenter: parent.verticalCenter
                asynchronous: true
                mipmap: true
            }

            Text {
                text: "PMDB-THEME"
                color: "white"
                font {
                    family: global.fonts.sans
                    pixelSize: leftMenu.titleFontSize
                    bold: true
                }
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        ListView {
            id: menuList
            width: parent.width
            height: contentHeight
            anchors {
                top: titleRow.bottom
                topMargin: 20 * leftMenu.scaleFactor
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                bottomMargin: 20 * leftMenu.scaleFactor
            }
            focus: leftMenu.focus
            model: ListModel {
                ListElement { name: "Movies"; icon: "assets/icons/movies.svg" }
                ListElement { name: "Genres"; icon: "assets/icons/genre.svg" }
                ListElement { name: "Titles"; icon: "assets/icons/title.svg" }
                ListElement { name: "Years"; icon: "assets/icons/year.svg" }
                ListElement { name: "Rating"; icon: "assets/icons/rating.svg" }
                ListElement { name: "Resume"; icon: "assets/icons/continueplaying.svg" }
                ListElement { name: "Favorites"; icon: "assets/icons/favorite.svg" }
                ListElement { name: "Search"; icon: "assets/icons/search.svg" }
            }

            delegate: Rectangle {
                id: menuItem
                width: parent.width
                height: leftMenu.menuItemHeight
                color: ListView.isCurrentItem && menuList.focus ? "#022441" : "transparent"

                Row {
                    anchors {
                        verticalCenter: parent.verticalCenter
                        left: parent.left
                        leftMargin: leftMenu.menuMargin
                    }
                    spacing: leftMenu.menuItemSpacing

                    Image {
                        id: icon
                        source: model.icon
                        width: leftMenu.menuIconSize
                        height: leftMenu.menuIconSize
                        anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true
                        mipmap: true
                    }

                    Text {
                        text: model.name
                        color: "white"
                        font {
                            family: global.fonts.sans
                            pixelSize: leftMenu.menuFontSize
                        }
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Rectangle {
                    visible: model.name === "Movies"
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 5 * leftMenu.scaleFactor
                    }
                    height: 2
                    color: "#022441"
                }
            }

            Keys.onPressed: {
                if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                    event.accepted = true;
                    if (currentIndex >= 0 && currentIndex < model.count) {
                        var selectedOption = model.get(currentIndex).name;
                        handleMenuSelection(selectedOption);
                    }
                }
            }

            Keys.onRightPressed: {
                currentFocus = "recently";
                event.accepted = true;
            }

            Keys.onUpPressed: {
                decrementCurrentIndex();
                event.accepted = true;
            }

            Keys.onDownPressed: {
                incrementCurrentIndex();
                event.accepted = true;
            }
        }
    }

    function updateSizes() {
        scaleFactor = Math.min(width / 200, height / 800)
    }

    onWidthChanged: updateSizes()
    onHeightChanged: updateSizes()

    function handleMenuSelection(option) {
        try {
            switch (option) {
                case "Movies":
                    if (collectionsItem && collectionsItem.recentlyAddedMoviesModel) {
                        gridViewMovies.currentModel = collectionsItem.recentlyAddedMoviesModel;
                        gridViewMovies.resetGridView();
                        gridViewMovies.isVisible = true;
                        currentFocus = "gridView";
                    }
                    break;
                case "Years":
                    listviewContainer.visible = false;
                    yearList.isVisible = true;
                    yearList.selectedYear = -1;
                    yearList.isExpanded = false;
                    yearList.updateYearsList();
                    currentFocus = "yearList";
                    yearList.focus = true;
                    break;
                case "Rating":
                    listviewContainer.visible = false;
                    ratingList.isVisible = true;
                    ratingList.selectedRatingRange = "";
                    ratingList.isExpanded = false;
                    ratingList.updateRatingsList();
                    currentFocus = "ratingList";
                    ratingList.focus = true;
                    break;
                case "Genres":
                    listviewContainer.visible = false;
                    genreList.isVisible = true;
                    genreList.visible = true;
                    genreList.genereVisible = true;
                    genreList.isExpanded = true;
                    currentFocus = "genreList";
                    genreList.focus = true;
                    break;
                case "Resume":
                    if (collectionsItem && collectionsItem.recentlyPlayedSignificantMovies) {
                        gridViewMovies.currentModel = collectionsItem.recentlyPlayedSignificantMovies;
                        gridViewMovies.resetGridView();
                        gridViewMovies.isVisible = true;
                        currentFocus = "gridView";
                    }
                    break;
                case "Favorites":
                    if (collectionsItem && collectionsItem.favoriteMovies) {
                        gridViewMovies.currentModel = collectionsItem.favoriteMovies;
                        gridViewMovies.resetGridView();
                        gridViewMovies.isVisible = true;
                        currentFocus = "gridView";
                    }
                    break;
                case "Titles":
                    if (collectionsItem && collectionsItem.baseMoviesFilter) {
                        gridViewTitles.currentModel = collectionsItem.baseMoviesFilter;
                        gridViewTitles.resetGridView();
                        gridViewTitles.isVisible = true;
                        currentFocus = "gridViewTitles";
                    }
                    break;
                case "Search":
                    listviewContainer.visible = false
                    searchMovie.showSearch()
                    currentFocus = "search"
                    break
                default:
                    gridViewMovies.isVisible = false;
                    gridViewTitles.isVisible = false;
                    searchMovie.hideSearch();
                    currentFocus = "menu";
                    currentMovie = Utils.resetBackground(backgroundImage, overlayImage);
                    break;
            }
        } catch (e) {
            console.log("Error al manejar la selección del menú: " + e);
            gridViewMovies.isVisible = false;
            gridViewTitles.isVisible = false;
            searchMovie.hideSearch();
            currentFocus = "menu";
            backgroundImage.source = "";
            overlayImage.opacity = 0.7;
            currentMovie = null;
        }
    }

    function setFocus() {
        focus = true;
        menuList.focus = true;
        menuList.currentIndex = 0;
    }
}
