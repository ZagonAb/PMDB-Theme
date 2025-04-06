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
import QtQuick.Window 2.15
import QtGraphicalEffects 1.15
import QtMultimedia 5.15
import QtQml.Models 2.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils

FocusScope {
    id: root
    focus: true

    onFocusChanged: {
        if (focus) {
            console.log("Interfaz enfocada, actualizando progreso...");
            Utils.forceModelUpdate(collectionsItem.continuePlayingMovies);
            listviewContainer.continuePlayingList.model = collectionsItem.continuePlayingMovies;
        }
    }

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: ""
        fillMode: Image.PreserveAspectCrop
        mipmap: true
        cache: true
    }

    Image {
        id: overlayImage
        anchors.fill: parent
        source: "assets/icons/background.png"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.7
        mipmap: true
        cache: true

        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }
    }

    property string currentFocus: "menu"
    property bool isPlayerActive: false
    property bool isLoading: false
    property var gameDataCache: ({})
    property var game: null
    property var currentMovie: null

    LeftMenu {
        id: leftMenu
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
         width: parent.width * 0.2
    }

    FilterListview { id: collectionsItem }

    ListviewHome {
        id: listviewContainer
        recentlyAddedMoviesModelLimited: collectionsItem.recentlyAddedMoviesModelLimited
        randomMoviesModel: collectionsItem.randomMoviesModel
        unplayedMoviesModel: collectionsItem.unplayedMoviesModel
        continuePlayingMovies: collectionsItem.continuePlayingMovies
        favoriteMovies: collectionsItem.favoriteMovies
    }

    GridViewMovies {
        id: gridViewMovies
        anchors {
            left: leftMenu.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        isVisible: false
    }

    GridViewTitles {
        id: gridViewTitles
        anchors {
            left: leftMenu.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        isVisible: false
    }

    MovieDetails {
        id: movieDetails
        anchors.fill: parent
        externalMediaPlayer: globalMediaPlayer
    }

    YearList {
        id: yearList
        anchors {
            left: leftMenu.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        isVisible: false
    }

    RatingList {
        id: ratingList
        anchors {
            left: leftMenu.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        isVisible: false
    }

    GenreList {
        id: genreList
        anchors {
            left: leftMenu.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        isVisible: false
    }

    MediaPlayerComponent {
        id: globalMediaPlayer
        width: parent.width
        height: parent.height

        anchors.centerIn: parent
        z: 2000
        visible: false
        movieDetailsRoot: movieDetails
    }

    SearchMovie {
        id: searchMovie
        anchors {
            left: leftMenu.right
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        isVisible: false
    }

    Delegate { id: movieDelegate }

    Keys.onPressed: {
        switch (event.key) {
            case Qt.Key_Left:
                event.accepted = true
                if (currentFocus === "search") {
                    searchMovie.clearAndHide()
                } else if  (currentFocus === "gridViewTitles") {
                    gridViewMovies.resetGridView();
                    gridViewTitles.hideGrid();
                } else if (currentFocus === "yearList") {
                    Utils.hideYearList();
                    listviewContainer.visible = true;
                     Utils.setMenuFocus();
                } else if (currentFocus === "ratingList") {
                    ratingList.hideRatingList();
                    listviewContainer.visible = true;
                    Utils.setMenuFocus();
                } else if (currentFocus !== "menu") {
                    backgroundImage.source = "";
                    currentMovie = null;
                    overlayImage.opacity = 0.7;
                    currentFocus = "menu";
                    Utils.setMenuFocus();
                }
                break
            case Qt.Key_Up:
                event.accepted = true
                if (currentFocus === "random") {
                    currentFocus = "recently"
                    listviewContainer.contentFlickable.contentY = listviewContainer.recentlyAddedSection.y
                } else if (currentFocus === "continue") {
                    if (listviewContainer.unplayedMoviesModel && listviewContainer.unplayedMoviesModel.count > 0) {
                        currentFocus = "unplayed"
                        listviewContainer.contentFlickable.contentY = listviewContainer.unplayedMoviesSection.y
                    } else {
                        currentFocus = "random"
                        listviewContainer.contentFlickable.contentY = listviewContainer.randomMoviesSection.y
                    }
                } else if (currentFocus === "favorites") {
                    if (listviewContainer.continuePlayingMovies && listviewContainer.continuePlayingMovies.count > 0) {
                        currentFocus = "continue"
                        listviewContainer.contentFlickable.contentY = listviewContainer.continuePlayingSection.y
                    } else if (listviewContainer.unplayedMoviesModel && listviewContainer.unplayedMoviesModel.count > 0) {
                        currentFocus = "unplayed"
                        listviewContainer.contentFlickable.contentY = listviewContainer.unplayedMoviesSection.y
                    } else {
                        currentFocus = "random"
                        listviewContainer.contentFlickable.contentY = listviewContainer.randomMoviesSection.y
                    }
                } else if (currentFocus === "unplayed") {
                    currentFocus = "random"
                    listviewContainer.contentFlickable.contentY = listviewContainer.randomMoviesSection.y
                }
                break
            case Qt.Key_Down:
                event.accepted = true
                if (currentFocus === "recently") {
                    currentFocus = "random"
                    listviewContainer.contentFlickable.contentY = listviewContainer.randomMoviesSection.y
                } else if (currentFocus === "random") {
                    if (listviewContainer.unplayedMoviesModel && listviewContainer.unplayedMoviesModel.count > 0) {
                        currentFocus = "unplayed"
                        listviewContainer.contentFlickable.contentY = listviewContainer.unplayedMoviesSection.y
                    } else if (listviewContainer.continuePlayingMovies && listviewContainer.continuePlayingMovies.count > 0) {
                        currentFocus = "continue"
                        listviewContainer.contentFlickable.contentY = listviewContainer.continuePlayingSection.y
                    } else if (listviewContainer.favoriteMovies && listviewContainer.favoriteMovies.count > 0) {
                        currentFocus = "favorites"
                        listviewContainer.contentFlickable.contentY = listviewContainer.favoriteSection.y
                    }
                } else if (currentFocus === "unplayed") {
                    if (listviewContainer.continuePlayingMovies && listviewContainer.continuePlayingMovies.count > 0) {
                        currentFocus = "continue"
                        listviewContainer.contentFlickable.contentY = listviewContainer.continuePlayingSection.y
                    } else if (listviewContainer.favoriteMovies && listviewContainer.favoriteMovies.count > 0) {
                        currentFocus = "favorites"
                        listviewContainer.contentFlickable.contentY = listviewContainer.favoriteSection.y
                    }
                } else if (currentFocus === "continue") {
                    if (listviewContainer.favoriteMovies && listviewContainer.favoriteMovies.count > 0) {
                        currentFocus = "favorites"
                        listviewContainer.contentFlickable.contentY = listviewContainer.favoriteSection.y
                    }
                } else if (currentFocus === "favorites") {
                    currentFocus = "recently"
                    listviewContainer.contentFlickable.contentY = listviewContainer.recentlyAddedSection.y
                }
                break
        }
    }

    onCurrentFocusChanged: {
        if (currentFocus === "menu") {
            if (leftMenu && leftMenu.menuList) {
                Utils.setMenuFocus();
            } else {
                //console.log("Advertencia: No se pudo establecer foco en menuList");
            }
            backgroundImage.source = "";
            overlayImage.opacity = 0.7;
            currentMovie = null;
        } else if (currentFocus === "search") {
            searchMovie.visible = true
            searchMovie.focus = true
            searchMovie.showSearch()
        } else if (currentFocus === "recently") {
            listviewContainer.recentlyMoviesList.focus = true;
            listviewContainer.contentFlickable.contentY = listviewContainer.recentlyAddedSection.y;
            if (listviewContainer.recentlyMoviesList &&
                listviewContainer.recentlyMoviesList.currentIndex >= 0 &&
                listviewContainer.recentlyAddedMoviesModelLimited &&
                listviewContainer.recentlyAddedMoviesModelLimited.count > 0) {
                try {
                    currentMovie = listviewContainer.recentlyAddedMoviesModelLimited.get(listviewContainer.recentlyMoviesList.currentIndex);
                    backgroundImage.source = Utils.getBackgroundImage(currentMovie);
                } catch(e) {
                    console.log("Error accessing recently movies: " + e);
                    backgroundImage.source = "";
                }
                } else {
                    backgroundImage.source = "";
                }
        } else if (currentFocus === "yearList") {
            yearList.visible = true;
            yearList.focus = true;
        } else if (currentFocus === "ratingList") {
            ratingList.visible = true;
            ratingList.focus = true;
        } else if (currentFocus === "random") {
            listviewContainer.randomMoviesList.focus = true;
            listviewContainer.contentFlickable.contentY = listviewContainer.randomMoviesSection.y;
            if (listviewContainer.randomMoviesList &&
                listviewContainer.randomMoviesList.currentIndex >= 0 &&
                listviewContainer.randomMoviesModel &&
                listviewContainer.randomMoviesModel.count > 0) {
                try {
                    currentMovie = listviewContainer.randomMoviesModel.get(listviewContainer.randomMoviesList.currentIndex);
                    backgroundImage.source = Utils.getBackgroundImage(currentMovie);
                } catch(e) {
                    console.log("Error accessing random movies: " + e);
                    backgroundImage.source = "";
                }
                } else {
                    backgroundImage.source = "";
                }
        } else if (currentFocus === "continue") {
            if (listviewContainer.continuePlayingMovies && listviewContainer.continuePlayingMovies.count > 0) {
                listviewContainer.continuePlayingList.focus = true;
                listviewContainer.contentFlickable.contentY = listviewContainer.continuePlayingSection.y;
                if (listviewContainer.continuePlayingList &&
                    listviewContainer.continuePlayingList.currentIndex >= 0) {
                    try {
                        currentMovie = listviewContainer.continuePlayingMovies.get(listviewContainer.continuePlayingList.currentIndex);
                        backgroundImage.source = Utils.getBackgroundImage(currentMovie);
                    } catch(e) {
                        console.log("Error accessing continue playing movies: " + e);
                        backgroundImage.source = "";
                    }
                    } else {
                        backgroundImage.source = "";
                    }
            } else {
                currentFocus = "random";
            }
        } else if (currentFocus === "favorites") {
            if (listviewContainer.favoriteMovies && listviewContainer.favoriteMovies.count > 0) {
                listviewContainer.favoriteList.focus = true;
                listviewContainer.contentFlickable.contentY = listviewContainer.favoriteSection.y;
                if (listviewContainer.favoriteList &&
                    listviewContainer.favoriteList.currentIndex >= 0) {
                    try {
                        currentMovie = listviewContainer.favoriteMovies.get(listviewContainer.favoriteList.currentIndex);
                        backgroundImage.source = Utils.getBackgroundImage(currentMovie);
                    } catch(e) {
                        console.log("Error accessing favorite movies: " + e);
                        backgroundImage.source = "";
                    }
                    } else {
                        backgroundImage.source = "";
                    }
            } else {
                currentFocus = listviewContainer.continuePlayingMovies && listviewContainer.continuePlayingMovies.count > 0 ? "continue" : "random";
            }
        } else if (currentFocus === "unplayed") {
            if (listviewContainer.unplayedMoviesModel && listviewContainer.unplayedMoviesModel.count > 0) {
                listviewContainer.unplayedMoviesList.focus = true;
                listviewContainer.contentFlickable.contentY = listviewContainer.unplayedMoviesSection.y;
                if (listviewContainer.unplayedMoviesList &&
                    listviewContainer.unplayedMoviesList.currentIndex >= 0) {
                    try {
                        currentMovie = listviewContainer.unplayedMoviesModel.get(listviewContainer.unplayedMoviesList.currentIndex);
                        backgroundImage.source = Utils.getBackgroundImage(currentMovie);
                    } catch(e) {
                        console.log("Error accessing unplayed movies: " + e);
                        backgroundImage.source = "";
                    }
                    } else {
                        backgroundImage.source = "";
                    }
            } else {
                currentFocus = (listviewContainer.favoriteMovies && listviewContainer.favoriteMovies.count > 0) ? "favorites" :
                ((listviewContainer.continuePlayingMovies && listviewContainer.continuePlayingMovies.count > 0) ? "continue" : "random");
            }
        } else if (currentFocus === "gridView") {
            gridViewMovies.visible = true;
            gridViewMovies.focus = true;
        } else if (currentFocus === "gridViewTitles") {
            gridViewTitles.visible = true;
            gridViewTitles.focus = true;
        }
    }
}
