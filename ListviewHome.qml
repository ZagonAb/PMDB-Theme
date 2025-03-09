// ListviewHome.qml
import QtQuick 2.15

Item {
    id: listviewContainer
    anchors {
        left: leftMenu.right
        right: parent.right
        top: parent.top
        bottom: parent.bottom
    }

    // Define propiedades para los modelos
    property var randomMoviesModel
    property var unplayedMoviesModel
    property var continuePlayingMovies
    property var favoriteMovies

    // Expón las listas como propiedades públicas
    property alias randomMoviesList: randomMoviesList
    property alias unplayedMoviesList: unplayedMoviesList
    property alias continuePlayingList: continuePlayingList
    property alias favoriteList: favoriteList

    // Expón el Flickable como propiedad pública
    property alias contentFlickable: contentFlickable

    // Expón las secciones como propiedades públicas
    property alias randomMoviesSection: randomMoviesSection
    property alias unplayedMoviesSection: unplayedMoviesSection
    property alias continuePlayingSection: continuePlayingSection
    property alias favoriteSection: favoriteSection

    // Propiedad para controlar si la interfaz ya ha sido interactuada
    property bool hasUserInteracted: false

    Flickable {
        id: contentFlickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: mainColumn.height
        clip: true

        Behavior on contentY {
            NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
        }

        Column {
            id: mainColumn
            width: parent.width
            spacing: 10

            Item {
                id: randomMoviesSection
                width: parent.width
                height: 400

                Text {
                    id: randomMoviesTitle
                    text: "Random movies"
                    color: "white"
                    font { family: global.fonts.sans; pixelSize: 28 }
                    anchors { left: parent.left; top: parent.top; margins: 20 }
                }

                ListView {
                    id: randomMoviesList
                    orientation: Qt.Horizontal
                    focus: currentFocus === "random"
                    anchors {
                        top: randomMoviesTitle.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 20
                    }
                    model: randomMoviesModel
                    delegate: movieDelegate
                    spacing: 20
                    cacheBuffer: width * 3
                    displayMarginBeginning: 200
                    displayMarginEnd: 200
                    reuseItems: true
                    highlightMoveDuration: 200
                    highlightResizeDuration: 0
                    maximumFlickVelocity: 2500
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 1500

                    onCurrentIndexChanged: {
                        if (currentFocus === "random" && currentIndex >= 0) {
                            currentMovie = randomMoviesModel.get(currentIndex);
                            backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : "";
                            game = randomMoviesModel.get(currentIndex);
                        }
                    }
                }
            }

            Item {
                id: unplayedMoviesSection
                width: parent.width
                height: 400
                visible: unplayedMoviesModel.count > 0

                Text {
                    id: unplayedMoviesTitle
                    text: "Unwatched movies"
                    color: "white"
                    font { family: global.fonts.sans; pixelSize: 28 }
                    anchors { left: parent.left; top: parent.top; margins: 20 }
                }

                ListView {
                    id: unplayedMoviesList
                    orientation: Qt.Horizontal
                    focus: currentFocus === "unplayed"
                    anchors {
                        top: unplayedMoviesTitle.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 20
                    }
                    model: unplayedMoviesModel
                    delegate: movieDelegate
                    spacing: 20

                    cacheBuffer: width * 3
                    displayMarginBeginning: 200
                    displayMarginEnd: 200
                    reuseItems: true
                    highlightMoveDuration: 200
                    highlightResizeDuration: 0
                    maximumFlickVelocity: 2500
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 1500

                    onCurrentIndexChanged: {
                        if (currentFocus === "unplayed" && currentIndex >= 0 && hasUserInteracted) {
                            currentMovie = unplayedMoviesModel.get(currentIndex);
                            backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : ""; // Actualizar la imagen de fondo
                            game = unplayedMoviesModel.get(currentIndex);
                        }
                    }
                }
            }

            Item {
                id: continuePlayingSection
                width: parent.width
                height: 400
                visible: continuePlayingMovies.count > 0

                Text {
                    id: continuePlayingTitle
                    text: "In progress movies"
                    color: "white"
                    font { family: global.fonts.sans; pixelSize: 28 }
                    anchors { left: parent.left; top: parent.top; margins: 20 }
                }

                ListView {
                    id: continuePlayingList
                    orientation: Qt.Horizontal
                    focus: currentFocus === "continue"
                    anchors {
                        top: continuePlayingTitle.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 20
                    }
                    model: continuePlayingMovies
                    delegate: DelegateContinuePlaying {} // Usa el nuevo delegate
                    spacing: 20

                    cacheBuffer: width * 3
                    displayMarginBeginning: 200
                    displayMarginEnd: 200
                    reuseItems: true
                    highlightMoveDuration: 200
                    highlightResizeDuration: 0
                    maximumFlickVelocity: 2500
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 1500

                    onCurrentIndexChanged: {
                        if (currentFocus === "continue" && currentIndex >= 0 && hasUserInteracted) {
                            currentMovie = continuePlayingMovies.get(currentIndex);
                            backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : ""; // Actualizar la imagen de fondo
                            game = continuePlayingMovies.get(currentIndex);
                        }
                    }
                }
            }

            Item {
                id: favoriteSection
                width: parent.width
                height: 400
                visible: favoriteMovies.count > 0

                Text {
                    id: favoriteTitle
                    text: "Favorite movies"
                    color: "white"
                    font { family: global.fonts.sans; pixelSize: 28 }
                    anchors { left: parent.left; top: parent.top; margins: 20 }
                }

                ListView {
                    id: favoriteList
                    orientation: Qt.Horizontal
                    focus: currentFocus === "favorites"
                    anchors {
                        top: favoriteTitle.bottom
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        margins: 20
                    }
                    model: favoriteMovies
                    delegate: movieDelegate
                    spacing: 20

                    cacheBuffer: width * 3
                    displayMarginBeginning: 200
                    displayMarginEnd: 200
                    reuseItems: true
                    highlightMoveDuration: 200
                    highlightResizeDuration: 0
                    maximumFlickVelocity: 2500
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 1500

                    onCurrentIndexChanged: {
                        if (currentFocus === "favorites" && currentIndex >= 0 && hasUserInteracted) {
                            currentMovie = favoriteMovies.get(currentIndex);
                            backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : ""; // Actualizar la imagen de fondo
                            game = favoriteMovies.get(currentIndex);
                        }
                    }
                }
            }
        }
    }

    // Función para marcar que el usuario ha interactuado con la interfaz
    function setUserInteracted() {
        hasUserInteracted = true;
    }

    // Conectar la interacción del usuario (por ejemplo, al presionar una tecla)
    Keys.onPressed: {
        if (!hasUserInteracted) {
            setUserInteracted();
        }
    }
}
