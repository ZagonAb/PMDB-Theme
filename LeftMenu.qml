// LeftMenu.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: leftMenu
    width: parent.width * 0.2
    height: parent.height
    color: "#aa000000"

    // Propiedades configurables para ajustar tamaños
    property real scaleFactor: Math.min(width / 200, height / 800) // Factor de escala base
    property real titleIconSize: 40 * scaleFactor // Tamaño del ícono del título
    property real titleFontSize: 18 * scaleFactor // Tamaño de fuente del título
    property real menuIconSize: 40 * scaleFactor // Tamaño de íconos del menú
    property real menuFontSize: 28 * scaleFactor // Tamaño de fuente del menú
    property real menuItemHeight: 80 * scaleFactor // Altura de cada elemento del menú
    property real menuItemSpacing: 40 * scaleFactor // Espaciado entre ícono y texto
    property real menuMargin: 20 * scaleFactor // Margen izquierdo del menú

    // Timer para inicializar GenreList con un pequeño retraso
    /*Timer {
        id: genreListTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (genreList.isVisible) {
                genreList.focus = true;
                if (genreList.genereListView) {
                    genreList.genereListView.focus = true;
                }
            }
        }
    }*/

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
            source: "assets/icons/logo.svg"
            width: leftMenu.titleIconSize
            height: leftMenu.titleIconSize
            anchors.verticalCenter: parent.verticalCenter
            asynchronous: true
            mipmap: true
        }

        Text {
            text: "TMDB-THEME"
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
        focus: currentFocus === "menu"
        model: ListModel {
            ListElement { name: "Movies"; icon: "assets/icons/movies.svg" }
            ListElement { name: "Genres"; icon: "assets/icons/genre.svg" }
            ListElement { name: "Titles"; icon: "assets/icons/title.svg" }
            ListElement { name: "Years"; icon: "assets/icons/year.svg" }
            ListElement { name: "Rating"; icon: "assets/icons/rating.svg" }
            ListElement { name: "Continue"; icon: "assets/icons/continueplaying.svg" }
            ListElement { name: "Favorites"; icon: "assets/icons/favorite.svg" }
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
        }

        // Manejar la tecla de "Enter" o "Aceptar" para abrir el GridView
        Keys.onPressed: {
            if (api.keys.isAccept(event)) {
                event.accepted = true;
                if (currentIndex >= 0 && currentIndex < model.count) {
                    var selectedOption = model.get(currentIndex).name;
                    handleMenuSelection(selectedOption);
                }
            }
        }

        // Update in LeftMenu.qml
        Keys.onRightPressed: {
            currentFocus = "recently"
        }

        Keys.onUpPressed: decrementCurrentIndex()
        Keys.onDownPressed: incrementCurrentIndex()
    }

    // Función para recalcular los tamaños cuando cambie la resolución
    function updateSizes() {
        scaleFactor = Math.min(width / 200, height / 800)
    }

    // Conectamos los cambios de tamaño para actualizar los valores
    onWidthChanged: updateSizes()
    onHeightChanged: updateSizes()

    function handleMenuSelection(option) {
        try {
            switch (option) {
                case "Movies":
                    if (collectionsItem && collectionsItem.recentlyAddedMoviesModel) {
                        gridViewMovies.currentModel = collectionsItem.recentlyAddedMoviesModel;
                        gridViewMovies.isVisible = true;
                        currentFocus = "gridView";
                    }
                    break;
                case "Years":
                    // Ocultar listviewContainer cuando se accede a YearList
                    listviewContainer.visible = false;
                    yearList.isVisible = true;

                    // Nos aseguramos de resetear la selección
                    yearList.selectedYear = -1;
                    yearList.isExpanded = false;

                    // Actualizamos la lista de años (opcional, puede que ya esté actualizada)
                    yearList.updateYearsList();

                    // Damos el foco a la lista de años
                    currentFocus = "yearList";
                    yearList.focus = true; // Asegurar que YearList tenga el foco
                    break;
                case "Rating":
                    // Ocultar listviewContainer cuando se accede a RatingList
                    listviewContainer.visible = false;
                    ratingList.isVisible = true;

                    // Nos aseguramos de resetear la selección
                    ratingList.selectedRatingRange = "";
                    ratingList.isExpanded = false;

                    // Actualizamos la lista de calificaciones
                    ratingList.updateRatingsList();

                    // Damos el foco a la lista de calificaciones
                    currentFocus = "ratingList";
                    ratingList.focus = true; // Asegurar que RatingList tenga el foco
                    break;
                case "Genres":
                    // Ocultar listviewContainer cuando se accede a GenreList
                    listviewContainer.visible = false;

                    // Hacer visible la vista de géneros
                    genreList.isVisible = true;
                    genreList.genereVisible = true;
                    genreList.isExpanded = true;

                    currentFocus = "genreList";
                    genreList.focus = true;
                    //genreListTimer.start();

                    break;
                case "Continue":
                    if (collectionsItem && collectionsItem.continuePlayingMovies) {
                        gridViewMovies.currentModel = collectionsItem.continuePlayingMovies;
                        gridViewMovies.isVisible = true;
                        currentFocus = "gridView";
                    }
                    break;
                case "Favorites":
                    if (collectionsItem && collectionsItem.favoriteMovies) {
                        gridViewMovies.currentModel = collectionsItem.favoriteMovies;
                        gridViewMovies.isVisible = true;
                        currentFocus = "gridView";
                    }
                    break;
                case "Titles":
                    if (collectionsItem && collectionsItem.baseMoviesFilter) {
                        gridViewTitles.currentModel = collectionsItem.baseMoviesFilter;
                        gridViewTitles.isVisible = true;
                        currentFocus = "gridViewTitles";
                    }
                    break;
                default:
                    gridViewMovies.isVisible = false;
                    gridViewTitles.isVisible = false;
                    currentFocus = "menu";
                    currentMovie = Utils.resetBackground(backgroundImage, overlayImage);
                    break;
            }
        } catch (e) {
            console.log("Error al manejar la selección del menú: " + e);
            // Retorno seguro al menú principal en caso de error
            gridViewMovies.isVisible = false;
            gridViewTitles.isVisible = false;
            currentFocus = "menu";
            backgroundImage.source = "";
            overlayImage.opacity = 0.7;
            currentMovie = null;
        }
    }
}
