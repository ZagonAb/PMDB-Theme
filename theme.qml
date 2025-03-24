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

    // Detectar cambios de foco
    onFocusChanged: {
        if (focus) {
            // El usuario ha vuelto a la interfaz
            console.log("Interfaz enfocada, actualizando progreso...");
            Utils.forceModelUpdate(collectionsItem.continuePlayingMovies);
            listviewContainer.continuePlayingList.model = collectionsItem.continuePlayingMovies;
        }
    }

    // Imagen de fondo principal
    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "" //currentMovie ? (currentMovie.assets.screenshot || currentMovie.assets.background) : ""
        fillMode: Image.PreserveAspectCrop
        mipmap: true
        cache: true
    }

    // Imagen superpuesta semi-transparente
    Image {
        id: overlayImage
        anchors.fill: parent
        source: "assets/icons/background.png"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.7
        mipmap: true
        cache: true

        // Añadir esta transición
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

    LeftMenu { id: leftMenu }

    FilterListview { id: collectionsItem }
    ListviewHome {
        id: listviewContainer
        recentlyAddedMoviesModelLimited: collectionsItem.recentlyAddedMoviesModelLimited
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

    MovieDetails {
        id: movieDetails
        anchors.fill: parent
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

    // Añadir este componente junto a los otros componentes en theme.qml
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

    Delegate { id: movieDelegate }

    Keys.onPressed: {
        switch (event.key) {
            case Qt.Key_Left:
                //console.log("Tecla Left presionada")
                event.accepted = true
                if (currentFocus === "gridViewTitles") {
                    gridViewTitles.hideGrid();
                } else if (currentFocus === "yearList") {
                    // Manejo de retroceso desde yearList
                    Utils.hideYearList();
                    // Asegurarnos que listviewContainer esté visible
                    listviewContainer.visible = true;
                    leftMenu.menuList.focus = true;
                } else if (currentFocus === "ratingList") {
                    // Manejo de retroceso desde ratingList
                    ratingList.hideRatingList();
                    // Asegurarnos que listviewContainer esté visible
                    listviewContainer.visible = true;
                    leftMenu.menuList.focus = true;
                } else if (currentFocus !== "menu") {
                    // Limpia la imagen de fondo explícitamente antes de cambiar el foco
                    backgroundImage.source = "";
                    currentMovie = null;
                    // Asegúrate de que el overlay tenga la opacidad correcta
                    overlayImage.opacity = 0.7;
                    // Ahora cambia el foco al menú
                    currentFocus = "menu";
                    leftMenu.menuList.focus = true;
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
            leftMenu.menuList.focus = true;
            backgroundImage.source = "";
            overlayImage.opacity = 0.7;
            currentMovie = null;
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
