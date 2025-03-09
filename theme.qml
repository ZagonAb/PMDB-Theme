// theme.qml
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

    // Imagen de fondo principal
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: currentMovie ? (currentMovie.assets.screenshot || currentMovie.assets.background) : ""
        fillMode: Image.PreserveAspectCrop
        mipmap: true
        cache: true
    }

    // Imagen superpuesta semi-transparente
    Image {
        id: overlayImage
        anchors.fill: parent
        source: "assets/icons/background.png" // Imagen superpuesta
        fillMode: Image.PreserveAspectCrop
        opacity: 0.7 // 30% de opacidad
        mipmap: true
        cache: true
    }

    property string currentFocus: "menu"
    property bool isPlayerActive: false
    property bool isLoading: false
    property var gameDataCache: ({})
    property var game: null
    property var currentMovie: null

    LeftMenu { id: leftMenu }

    FilterListview { id: collectionsItem }
    ListviewHome {
        id: listviewContainer
        randomMoviesModel: collectionsItem.randomMoviesModel
        unplayedMoviesModel: collectionsItem.unplayedMoviesModel
        continuePlayingMovies: collectionsItem.continuePlayingMovies
        favoriteMovies: collectionsItem.favoriteMovies
    }

    // Nuevo GridViewMovies
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

    Delegate { id: movieDelegate }

    Keys.onPressed: {
        switch (event.key) {
            case Qt.Key_Left:
                event.accepted = true
                if (currentFocus === "gridViewTitles") {
                    gridViewTitles.hideGrid();
                } else if (currentFocus !== "menu") {
                    currentFocus = "menu"
                    leftMenu.menuList.focus = true
                    backgroundImage.source = "" // Limpiar la imagen de fondo
                }
                break
            case Qt.Key_Up:
                event.accepted = true
                if (currentFocus === "continue") {
                    if (listviewContainer.unplayedMoviesModel.count > 0) {
                        currentFocus = "unplayed"
                        listviewContainer.contentFlickable.contentY = listviewContainer.unplayedMoviesSection.y
                    } else {
                        currentFocus = "random"
                        listviewContainer.contentFlickable.contentY = listviewContainer.randomMoviesSection.y
                    }
                } else if (currentFocus === "favorites") {
                    if (listviewContainer.continuePlayingMovies.count > 0) {
                        currentFocus = "continue"
                        listviewContainer.contentFlickable.contentY = listviewContainer.continuePlayingSection.y
                    } else if (listviewContainer.unplayedMoviesModel.count > 0) {
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
                if (currentFocus === "random") {
                    if (listviewContainer.unplayedMoviesModel.count > 0) {
                        currentFocus = "unplayed"
                        listviewContainer.contentFlickable.contentY = listviewContainer.unplayedMoviesSection.y
                    } else if (listviewContainer.continuePlayingMovies.count > 0) {
                        currentFocus = "continue"
                        listviewContainer.contentFlickable.contentY = listviewContainer.continuePlayingSection.y
                    } else if (listviewContainer.favoriteMovies.count > 0) {
                        currentFocus = "favorites"
                        listviewContainer.contentFlickable.contentY = listviewContainer.favoriteSection.y
                    }
                } else if (currentFocus === "unplayed") {
                    if (listviewContainer.continuePlayingMovies.count > 0) {
                        currentFocus = "continue"
                        listviewContainer.contentFlickable.contentY = listviewContainer.continuePlayingSection.y
                    } else if (listviewContainer.favoriteMovies.count > 0) {
                        currentFocus = "favorites"
                        listviewContainer.contentFlickable.contentY = listviewContainer.favoriteSection.y
                    }
                } else if (currentFocus === "continue") {
                    if (listviewContainer.favoriteMovies.count > 0) {
                        currentFocus = "favorites"
                        listviewContainer.contentFlickable.contentY = listviewContainer.favoriteSection.y
                    } else if (listviewContainer.unplayedMoviesModel.count > 0) {
                        currentFocus = "unplayed"
                        listviewContainer.contentFlickable.contentY = listviewContainer.unplayedMoviesSection.y
                    }
                } else if (currentFocus === "favorites") {
                    if (listviewContainer.unplayedMoviesModel.count > 0) {
                        currentFocus = "random"
                        listviewContainer.contentFlickable.contentY = listviewContainer.randomMoviesSection.y
                    }
                }
                break
        }
    }

    onCurrentFocusChanged: {
        if (currentFocus === "menu") {
            leftMenu.menuList.focus = true;
            backgroundImage.source = ""; // Limpiar la imagen de fondo
        } else if (currentFocus === "random") {
            listviewContainer.randomMoviesList.focus = true;
            listviewContainer.contentFlickable.contentY = listviewContainer.randomMoviesSection.y;
            if (listviewContainer.randomMoviesList.currentIndex >= 0) {
                currentMovie = listviewContainer.randomMoviesModel.get(listviewContainer.randomMoviesList.currentIndex);
                backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : ""; // Actualizar la imagen de fondo
            } else {
                backgroundImage.source = ""; // Limpiar la imagen de fondo
            }
        } else if (currentFocus === "continue") {
            if (listviewContainer.continuePlayingMovies.count > 0) {
                listviewContainer.continuePlayingList.focus = true;
                listviewContainer.contentFlickable.contentY = listviewContainer.continuePlayingSection.y;
                if (listviewContainer.continuePlayingList.currentIndex >= 0) {
                    currentMovie = listviewContainer.continuePlayingMovies.get(listviewContainer.continuePlayingList.currentIndex);
                    backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : ""; // Actualizar la imagen de fondo
                } else {
                    backgroundImage.source = ""; // Limpiar la imagen de fondo
                }
            } else {
                currentFocus = "random";
            }
        } else if (currentFocus === "favorites") {
            if (listviewContainer.favoriteMovies.count > 0) {
                listviewContainer.favoriteList.focus = true;
                listviewContainer.contentFlickable.contentY = listviewContainer.favoriteSection.y;
                if (listviewContainer.favoriteList.currentIndex >= 0) {
                    currentMovie = listviewContainer.favoriteMovies.get(listviewContainer.favoriteList.currentIndex);
                    backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : ""; // Actualizar la imagen de fondo
                } else {
                    backgroundImage.source = ""; // Limpiar la imagen de fondo
                }
            } else {
                currentFocus = listviewContainer.continuePlayingMovies.count > 0 ? "continue" : "random";
            }
        } else if (currentFocus === "unplayed") {
            if (listviewContainer.unplayedMoviesModel.count > 0) {
                listviewContainer.unplayedMoviesList.focus = true;
                listviewContainer.contentFlickable.contentY = listviewContainer.unplayedMoviesSection.y;
                if (listviewContainer.unplayedMoviesList.currentIndex >= 0) {
                    currentMovie = listviewContainer.unplayedMoviesModel.get(listviewContainer.unplayedMoviesList.currentIndex);
                    backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : ""; // Actualizar la imagen de fondo
                } else {
                    backgroundImage.source = ""; // Limpiar la imagen de fondo
                }
            } else {
                currentFocus = listviewContainer.favoriteMovies.count > 0 ? "favorites" :
                (listviewContainer.continuePlayingMovies.count > 0 ? "continue" : "random");
            }
        }
    }
}
