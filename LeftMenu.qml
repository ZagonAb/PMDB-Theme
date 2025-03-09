// LeftMenu.qml
import QtQuick 2.15

Rectangle {
    id: leftMenu
    width: parent.width * 0.2
    height: parent.height
    color: "#aa000000"

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 20
        }
        spacing: 10

        Image {
            id: titleIcon
            source: "assets/icons/logo.svg"
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter
            asynchronous: true
            mipmap: true
        }

        Text {
            text: "TMDB-THEME"
            color: "white"
            font { family: global.fonts.sans; pixelSize: 18; bold: true }
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    ListView {
        id: menuList
        width: parent.width
        height: contentHeight
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
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
            width: parent.width
            height: 80
            color: ListView.isCurrentItem && menuList.focus ? "#022441" : "transparent"

            Row {
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: 20
                }
                spacing: 40

                Image {
                    id: icon
                    source: model.icon
                    width: 40
                    height: 40
                    anchors.verticalCenter: parent.verticalCenter
                    asynchronous: true
                    mipmap: true
                }

                Text {
                    text: model.name
                    color: "white"
                    font { family: global.fonts.sans; pixelSize: 28 }
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    currentFocus = "menu"
                    menuList.currentIndex = index
                    handleMenuSelection(model.name)
                }
            }
        }

        // Manejar la tecla de "Enter" o "Aceptar" para abrir el GridView
        Keys.onPressed: {
            if (api.keys.isAccept(event)) {
                event.accepted = true;
                var selectedOption = menuList.model.get(menuList.currentIndex).name;
                handleMenuSelection(selectedOption);
            }
        }

        Keys.onRightPressed: {
            currentFocus = "random"
        }

        Keys.onUpPressed: decrementCurrentIndex()
        Keys.onDownPressed: incrementCurrentIndex()
    }

    function handleMenuSelection(option) {
        switch (option) {
            case "Movies":
                gridViewMovies.currentModel = collectionsItem.recentlyAddedMoviesModel;
                gridViewMovies.isVisible = true;
                currentFocus = "gridView";
                break;
            case "Continue":
                gridViewMovies.currentModel = collectionsItem.continuePlayingMovies;
                gridViewMovies.isVisible = true;
                currentFocus = "gridView";
                break;
            case "Favorites":
                gridViewMovies.currentModel = collectionsItem.favoriteMovies;
                gridViewMovies.isVisible = true;
                currentFocus = "gridView";
                break;
            case "Titles":
                gridViewTitles.currentModel = collectionsItem.baseMoviesFilter;
                gridViewTitles.isVisible = true;
                currentFocus = "gridViewTitles";
                break;
            default:
                gridViewMovies.isVisible = false;
                gridViewTitles.isVisible = false;
                break;
        }
    }
}
