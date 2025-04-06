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
    id: movieDetailsRoot
    visible: false
    z: 1000

    property var currentMovie: null
    property string previousFocus: ""
    property var externalMediaPlayer: null

    property var mediaPlayer: MediaPlayerComponent {
        id: internalMediaPlayer
        anchors.fill: parent
        z: 1001
        movieDetailsRoot: movieDetailsRoot
    }

    onExternalMediaPlayerChanged: {
        if (externalMediaPlayer) {
            mediaPlayer = externalMediaPlayer;
        }
    }

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : ""
        fillMode: Image.PreserveAspectCrop
        mipmap: true
        cache: true
    }

    Rectangle {
        id: overlay
        anchors.fill: parent
        color: "#022441"
        opacity: 0.8
    }

    Rectangle {
        id: videoOverlay
        anchors.fill: parent
        color: "#000000"
        opacity: mediaPlayer.visible ? 1 : 0.0
        z: 1001
        Behavior on opacity { NumberAnimation { duration: 200 } }
        visible: opacity > 0

        RadialGradient {
            anchors.fill: parent
            gradient: Gradient {


                GradientStop { position: 0.5; color: Qt.rgba(0.02, 0.36, 0.77, 0.3) } // Color claro en el centro
                GradientStop { position: 0.8; color: Qt.rgba(0.02, 0.36, 0.77, 0.1) } // Transición suave
                GradientStop { position: 1.0; color: "#000000" }
            }

            horizontalRadius: parent.width * 0.5
            verticalRadius: parent.height * 0.7
            source: videoOverlay
            visible: mediaPlayer.visible
        }

        Item {
            id: videoOverlayContent
            anchors.fill: parent

            Item {
                id: logoContainer
                width: parent.width
                height: parent.height * 0.2
                anchors.top: parent.top

                Image {
                    id: movieLogo
                    source: currentMovie ? currentMovie.assets.logo || "" : ""
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    cache: true
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.8, implicitWidth)
                    height: Math.min(parent.height * 0.8, implicitHeight)
                    opacity: mediaPlayer.visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                DropShadow {
                    anchors.fill: movieLogo
                    source: movieLogo
                    radius: 10
                    samples: 16
                    color: "#80000000"
                    visible: movieLogo.visible && movieLogo.source !== ""
                    transparentBorder: true
                    verticalOffset: 2
                }
            }

            Item {
                id: bottomContainer
                width: parent.width
                height: parent.height * 0.25
                anchors.bottom: parent.bottom

                Column {
                    width: parent.width
                    anchors.centerIn: parent
                    spacing:  parent.height * 0.1

                    Item {
                        width: parent.width
                        height: bottomContainer.height * 0.1

                        Row {
                            id: filePathRow
                            anchors.centerIn: parent
                            spacing: 10

                            Image {
                                source: "assets/icons/movie-file.svg"
                                width: 24
                                height: 24
                                mipmap: true
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                id: videoPathText
                                text: currentMovie ? Utils.getMovieFilePath(currentMovie) : "N/A"
                                color: "#AAAAAA"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: 14
                                }
                                elide: Text.ElideRight
                                wrapMode: Text.NoWrap
                                anchors.verticalCenter: parent.verticalCenter

                                Connections {
                                    target: movieDetailsRoot
                                    function onCurrentMovieChanged() {
                                        if (currentMovie) {
                                            videoPathText.text = Utils.getMovieFilePath(currentMovie);
                                            videoPathText.elide = Text.ElideRight;
                                            videoPathText.wrapMode = Text.NoWrap;
                                        }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        videoPathText.text = (videoPathText.elide === Text.ElideRight)
                                        ? Utils.getMovieFilePath(currentMovie, true)
                                        : Utils.getMovieFilePath(currentMovie);
                                        videoPathText.elide = (videoPathText.elide === Text.ElideRight)
                                        ? Text.ElideNone
                                        : Text.ElideRight;
                                        videoPathText.wrapMode = (videoPathText.wrapMode === Text.NoWrap)
                                        ? Text.Wrap
                                        : Text.NoWrap;
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: bottomContainer.height * 0.1
                        Row {
                            id: infoRow
                            anchors.centerIn: parent
                            spacing: 15

                            component InfoRectangle: Rectangle {
                                property alias text: label.text
                                width: label.implicitWidth + 20
                                height: 30
                                color: "transparent"
                                border.color: "#4D4D4D"
                                border.width: 1
                                radius: 4

                                Text {
                                    id: label
                                    anchors.centerIn: parent
                                    color: "white"
                                    font {
                                        family: global.fonts.sans
                                        pixelSize: 14
                                        bold: true
                                    }
                                }
                            }

                            Image {
                                source: "assets/icons/calen.svg"
                                width: 24
                                height: 24
                                anchors.verticalCenter: parent.verticalCenter
                                mipmap: true
                            }

                            InfoRectangle {
                                text: {
                                    if (!currentMovie || !currentMovie.release) return "N/A";
                                    var dateObj = new Date(currentMovie.release);
                                    if (isNaN(dateObj.getTime())) return "N/A";
                                    var day = dateObj.getDate();
                                    var month = dateObj.getMonth() + 1;
                                    return (day < 10 ? '0' : '') + day + '/' +
                                    (month < 10 ? '0' : '') + month + '/' +
                                    dateObj.getFullYear();
                                }
                            }

                            InfoRectangle {
                                text: currentMovie && currentMovie.extra && currentMovie.extra["duration"] ?
                                currentMovie.extra["duration"] + " min" : "N/A"
                            }

                            InfoRectangle {
                                text: currentMovie && currentMovie.extra && currentMovie.extra["codec"] ?
                                currentMovie.extra["codec"] : "N/A"
                            }

                            InfoRectangle {
                                text: currentMovie && currentMovie.extra && currentMovie.extra["resolution"] ?
                                currentMovie.extra["resolution"] : "N/A"
                            }

                            InfoRectangle {
                                text: currentMovie && currentMovie.extra && currentMovie.extra["aspect"] ?
                                currentMovie.extra["aspect"] : "N/A"
                            }

                            InfoRectangle {
                                text: currentMovie && currentMovie.extra && currentMovie.extra["audio"] ?
                                currentMovie.extra["audio"] : "N/A"
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: rectangleitem
        width: parent.width
        height: parent.height
        color: "transparent"
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        property real scaleRatio: Math.min(width / 1920, height / 1080)

        Item {
            id: itemContainer
            width: parent.width * 0.8
            height: parent.height * 0.7
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            Item {
                id: rowWrapper
                width: parent.width
                height: parent.height
                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: parent.width * 0.1
                }

                Row {
                    id: rowconteiner
                    width: parent.width * 0.9
                    height: parent.height * 0.9
                    anchors.centerIn: parent
                    spacing: 30 * rectangleitem.scaleRatio

                    Item {
                        id: leftColumn
                        width: parent.width * 0.25
                        height: parent.height

                        Image {
                            id: boxFrontImage
                            width: parent.width
                            height: width * 1.5
                            source: currentMovie ? currentMovie.assets.boxFront || "" : ""
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            cache: true
                            anchors.top: parent.top
                        }

                        FocusScope {
                            id: buttonsColumn
                            anchors {
                                top: boxFrontImage.bottom
                                left: parent.left
                                right: parent.right
                                topMargin: 20 * rectangleitem.scaleRatio
                            }
                            height: children[0].height
                            focus: movieDetailsRoot.focus

                            property int currentIndex: 0

                            Column {
                                id: buttonsLayout
                                width: parent.width
                                spacing: 12 * rectangleitem.scaleRatio

                                Rectangle {
                                    id: btnLaunch
                                    width: parent.width
                                    height: 46 * rectangleitem.scaleRatio
                                    color: btnLaunch.activeFocus ? "#006dc7" : "#044173"
                                    radius: 6 * rectangleitem.scaleRatio
                                    border.width: btnLaunch.activeFocus ? 2 : 0
                                    border.color: "white"
                                    focus: true

                                    Text {
                                        text: "Play Movie"
                                        color: "white"
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: Math.max(12, 18 * rectangleitem.scaleRatio)
                                            bold: true
                                        }
                                        anchors.centerIn: parent
                                    }

                                    Keys.onPressed: function(event) {
                                        if (api.keys.isAccept(event)) {
                                            event.accepted = true;

                                            if (typeof currentMovie.launch === "function") {
                                                currentMovie.launch();
                                            } else if (currentMovie && currentMovie.title) {
                                                Utils.launchGameFromMoviesCollection(currentMovie.title);
                                            } else {
                                                console.error("No hay título válido para lanzar.");
                                            }
                                        } else if (api.keys.isDown(event)) {
                                            event.accepted = true;
                                            btnFavorite.focus = true;
                                        } else if (api.keys.isCancel(event)) {
                                            event.accepted = true;
                                            event.accepted = true;
                                            Utils.hideDetails(movieDetailsRoot);
                                            if (previousFocus === "search") {
                                                searchMovie.restoreFocus();
                                            } else if (previousFocus === "gridView") {
                                                gridViewMovies.visible = true;
                                                gridViewMovies.focus = true;
                                            } else if (previousFocus === "gridViewTitles") {
                                                gridViewTitles.visible = true;
                                                gridViewTitles.focus = true;
                                            } else if (previousFocus === "GenreList") {
                                                genreList.visible = true;
                                                genreList.focus = true;
                                            } else if (previousFocus === "YearList") {
                                                yearList.visible = true;
                                                yearList.focus = true;
                                            } else if (previousFocus === "RatingList") {
                                                ratingList.visible = true;
                                                ratingList.focus = true;
                                            }
                                        }
                                    }


                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            btnLaunch.focus = true;
                                            if (currentMovie) {
                                                currentMovie.launch();
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: btnFavorite
                                    width: parent.width
                                    height: 46 * rectangleitem.scaleRatio
                                    color: btnFavorite.activeFocus ? "#006dc7" : "#044173"
                                    radius: 6 * rectangleitem.scaleRatio
                                    border.width: btnFavorite.activeFocus ? 2 : 0
                                    border.color: "white"

                                    Text {
                                        id: favoriteText
                                        text: currentMovie ? Utils.getFavoriteButtonText(currentMovie.title) : "Add to favorites"
                                        color: "white"
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: Math.max(12, 18 * rectangleitem.scaleRatio)
                                            bold: true
                                        }
                                        anchors.centerIn: parent
                                    }

                                    Connections {
                                        target: movieDetailsRoot
                                        function onCurrentMovieChanged() {
                                            if (currentMovie) {
                                                favoriteText.text = Utils.getFavoriteButtonText(currentMovie.title);
                                            }
                                        }
                                    }

                                    Keys.onPressed: function(event) {
                                        if (api.keys.isAccept(event)) {
                                            event.accepted = true;
                                            if (currentMovie) {
                                                var isNowFavorite = Utils.toggleGameFavorite(currentMovie.title);
                                                favoriteText.text = isNowFavorite ? "Remove from favorites" : "Add to favorites";
                                            }
                                        } else if (api.keys.isUp(event)) {
                                            event.accepted = true;
                                            btnLaunch.focus = true;
                                        } else if (api.keys.isDown(event)) {
                                            event.accepted = true;
                                            btnPlayTrailer.focus = true;
                                        } else if (api.keys.isCancel(event)) {
                                            event.accepted = true;
                                            Utils.hideDetails(movieDetailsRoot);
                                            if (previousFocus === "search") {
                                                searchMovie.restoreFocus();
                                            } else if (previousFocus === "gridView") {
                                                gridViewMovies.visible = true;
                                                gridViewMovies.focus = true;
                                            } else if (previousFocus === "gridViewTitles") {
                                                gridViewTitles.visible = true;
                                                gridViewTitles.focus = true;
                                            } else if (previousFocus === "GenreList") {
                                                genreList.visible = true;
                                                genreList.focus = true;
                                            } else if (previousFocus === "YearList") {
                                                yearList.visible = true;
                                                yearList.focus = true;
                                            } else if (previousFocus === "RatingList") {
                                                ratingList.visible = true;
                                                ratingList.focus = true;
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            btnFavorite.focus = true;
                                            if (currentMovie) {
                                                var isNowFavorite = Utils.toggleGameFavorite(currentMovie.title);
                                                favoriteText.text = isNowFavorite ? "Favorite -" : "Favorite +";
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: btnPlayTrailer
                                    width: parent.width
                                    height: 46 * rectangleitem.scaleRatio
                                    color: btnPlayTrailer.activeFocus ? "#006dc7" : "#044173"
                                    radius: 6 * rectangleitem.scaleRatio
                                    border.width: btnPlayTrailer.activeFocus ? 2 : 0
                                    border.color: "white"

                                    Text {
                                        text: "Play Trailer"
                                        color: "white"
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: Math.max(12, 18 * rectangleitem.scaleRatio)
                                            bold: true
                                        }
                                        anchors.centerIn: parent
                                    }

                                    Keys.onPressed: function(event) {
                                        if (api.keys.isAccept(event)) {
                                            event.accepted = true;
                                            if (currentMovie && currentMovie.assets && currentMovie.assets.video) {
                                                mediaPlayer.playVideo(currentMovie.assets.video);
                                            }
                                        } else if (api.keys.isUp(event)) {
                                            event.accepted = true;
                                            btnFavorite.focus = true;
                                        } else if (api.keys.isCancel(event)) {
                                            event.accepted = true;
                                            Utils.hideDetails(movieDetailsRoot);
                                            if (previousFocus === "search") {
                                                searchMovie.restoreFocus();
                                            } else if (previousFocus === "gridView") {
                                                gridViewMovies.visible = true;
                                                gridViewMovies.focus = true;
                                            } else if (previousFocus === "gridViewTitles") {
                                                gridViewTitles.visible = true;
                                                gridViewTitles.focus = true;
                                            } else if (previousFocus === "GenreList") {
                                                genreList.visible = true;
                                                genreList.focus = true;
                                            } else if (previousFocus === "YearList") {
                                                yearList.visible = true;
                                                yearList.focus = true;
                                            } else if (previousFocus === "RatingList") {
                                                ratingList.visible = true;
                                                ratingList.focus = true;
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            btnPlayTrailer.focus = true;
                                            if (currentMovie && currentMovie.assets && currentMovie.assets.video) {
                                                mediaPlayer.playVideo(currentMovie.assets.video);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        id: columnConteiner
                        width: parent.width - leftColumn.width - parent.spacing
                        anchors.verticalCenter: parent.verticalCenter
                        property int extraSpacing: parent.height * 0.1
                        height: Math.min(implicitHeight, parent.height * 0.7)
                        spacing: parent.height * 0.02

                        Text {
                            text: currentMovie ? currentMovie.title : ""
                            color: "white"
                            font {
                                family: global.fonts.sans
                                pixelSize: Math.max(28, 42 * rectangleitem.scaleRatio)
                                bold: true
                            }
                            width: parent.width
                        }

                        Row {
                            spacing: parent.height * 0.05

                            Row {
                                spacing: 15 * rectangleitem.scaleRatio

                                Text {
                                    text: "Rated"
                                    color: "white"

                                    anchors.verticalCenter: parent.verticalCenter

                                    font {
                                        family: global.fonts.sans
                                        pixelSize: Math.max(16, 22 * rectangleitem.scaleRatio)
                                    }
                                }

                                Item {
                                    width: classificationText.width + 20 * rectangleitem.scaleRatio
                                    height: classificationText.height + 8 * rectangleitem.scaleRatio

                                    Rectangle {
                                        id: ratedRectang
                                        anchors.fill: parent
                                        color: "transparent"
                                        border.color: "white"
                                        border.width: 1 * Math.max(0.5, rectangleitem.scaleRatio)
                                        radius: 4 * rectangleitem.scaleRatio
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        id: classificationText
                                        anchors.centerIn: parent
                                        text: currentMovie && currentMovie.extra && currentMovie.extra["classification"]
                                        ? currentMovie.extra["classification"] : "NR"
                                        color: "white"
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: Math.max(16, 22 * rectangleitem.scaleRatio)
                                        }
                                    }
                                }
                            }

                            Text {
                                text: currentMovie && currentMovie.releaseYear ? currentMovie.releaseYear : "N/A"
                                color: "white"
                                anchors.verticalCenter: parent.verticalCenter
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(16, 22 * rectangleitem.scaleRatio)
                                }
                            }

                            Text {
                                text: currentMovie && currentMovie.genre ? currentMovie.genre : "N/A"
                                color: "white"
                                anchors.verticalCenter: parent.verticalCenter
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(16, 22 * rectangleitem.scaleRatio)
                                }
                            }

                            // Duración
                            Text {
                                text: currentMovie && currentMovie.extra && currentMovie.extra["duration"] ?
                                currentMovie.extra["duration"] + " min" : "N/A"
                                color: "white"
                                anchors.verticalCenter: parent.verticalCenter
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(16, 22 * rectangleitem.scaleRatio)
                                }
                            }
                        }

                        Item {
                            height: 100 * rectangleitem.scaleRatio
                            width: parent.width

                            Row {
                                spacing: parent.height * 0.1

                                Item {
                                    width: 90 * rectangleitem.scaleRatio
                                    height: 90 * rectangleitem.scaleRatio

                                    Rectangle {
                                        id: backgroundCircle
                                        anchors.fill: parent
                                        radius: width / 2
                                        color: "#1A1A2E"
                                    }

                                    Canvas {
                                        id: ratingCanvas
                                        anchors.fill: parent
                                        antialiasing: true

                                        property real rating: currentMovie ? currentMovie.rating || 0 : 0
                                        property color ratingColor: getColorForRating(rating)

                                        function getColorForRating(rating) {
                                            if (rating >= 0.75) return "#A3E635";
                                            if (rating >= 0.6) return "#A3E635";
                                            if (rating >= 0.4) return "#FCD34D";
                                            return "#F87171";
                                        }

                                        onPaint: {
                                            var ctx = getContext("2d");
                                            var centerX = width / 2;
                                            var centerY = height / 2;
                                            var radius = width / 2 - 4 * rectangleitem.scaleRatio;

                                            ctx.beginPath();
                                            ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                                            ctx.lineWidth = 3 * rectangleitem.scaleRatio;
                                            ctx.strokeStyle = "#333344";
                                            ctx.stroke();

                                            if (rating > 0) {
                                                ctx.beginPath();
                                                ctx.arc(centerX, centerY, radius, -Math.PI/2, (2 * Math.PI * rating) - Math.PI/2);
                                                ctx.lineWidth = 3 * rectangleitem.scaleRatio;
                                                ctx.strokeStyle = ratingColor;
                                                ctx.stroke();
                                            }
                                        }

                                        onRatingChanged: requestPaint();
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: currentMovie ? Math.round(currentMovie.rating * 100) + "%" : "N/A"
                                        color: "white"
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: Math.max(10, 18 * rectangleitem.scaleRatio)
                                            bold: true
                                        }
                                    }
                                }

                                Text {
                                    text: "Rating\nScore"
                                    color: "white"
                                    font {
                                        family: global.fonts.sans
                                        pixelSize: Math.max(14, 22 * rectangleitem.scaleRatio)
                                        bold: true
                                    }
                                    lineHeight: 1.1
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Row {
                                    spacing: 4 * rectangleitem.scaleRatio
                                    leftPadding: 20 * rectangleitem.scaleRatio
                                    anchors.verticalCenter: parent.verticalCenter

                                    property var emojiList: ["🤩", "😍", "😃", "😊", "🙂", "😐", "😕", "😞", "😠", "😡"]

                                    function getEmojisForRating(rating) {
                                        var index = Math.min(Math.floor((1 - rating) * emojiList.length), emojiList.length - 3);
                                        if (rating < 0.1) {
                                            index = emojiList.length - 3;
                                        }
                                        return [
                                            emojiList[index],
                                            emojiList[Math.min(index + 1, emojiList.length - 1)],
                                            emojiList[Math.min(index + 2, emojiList.length - 1)]
                                        ];
                                    }

                                    property var currentEmojis: getEmojisForRating(currentMovie ? currentMovie.rating || 0 : 0)

                                    Repeater {
                                        model: 3

                                        Text {
                                            text: parent.currentEmojis[index]
                                            font.pixelSize: Math.max(24, 42 * rectangleitem.scaleRatio)
                                            opacity: index === 0 ? 1.0 : (index === 1 ? 0.7 : 0.4)
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    Connections {
                                        target: currentMovie
                                        function onRatingChanged() {
                                            currentEmojis = getEmojisForRating(currentMovie ? currentMovie.rating || 0 : 0);
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            text: currentMovie && currentMovie.extra && currentMovie.extra["tagline"] ?
                            currentMovie.extra["tagline"] : "no tagline available..."
                            color: "#CCCCCC"
                            font {
                                family: global.fonts.sans
                                pixelSize: Math.max(16, 24 * rectangleitem.scaleRatio)
                                italic: true
                            }
                            width: parent.width
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            text: "Overview"
                            color: "white"
                            font {
                                family: global.fonts.sans
                                pixelSize: Math.max(18, 26 * rectangleitem.scaleRatio)
                                bold: true
                            }
                            topPadding: 10 * rectangleitem.scaleRatio
                        }

                        Text {
                            text: currentMovie ? currentMovie.description || "No description available." : "No description available."
                            color: "white"
                            font {
                                family: global.fonts.sans
                                pixelSize: Math.max(18, 24 * rectangleitem.scaleRatio)
                            }
                            wrapMode: Text.WordWrap
                            width: parent.width
                            lineHeight: 1.0
                        }

                        Grid {
                            columns: 2
                            rowSpacing: 15 * rectangleitem.scaleRatio
                            columnSpacing: 30 * rectangleitem.scaleRatio
                            topPadding: parent.height * 0.01
                            width: parent.width

                            // Creadores
                            Repeater {
                                model: [
                                    { role: "Director", name: currentMovie ? currentMovie.developer || "N/A" : "N/A" },
                                    { role: "Publisher", name: currentMovie ? currentMovie.publisher || "N/A" : "N/A" },
                                ]

                                delegate: Column {
                                    width: parent.width / 2
                                    spacing: parent.height * 0.02

                                    Text {
                                        text: modelData.role
                                        color: "#BBBBBB"
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: Math.max(16, 24 * rectangleitem.scaleRatio)
                                            bold: true
                                        }
                                    }

                                    Text {
                                        text: modelData.name
                                        color: "white"
                                        font {
                                            family: global.fonts.sans
                                            pixelSize: Math.max(16, 24 * rectangleitem.scaleRatio)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        onWidthChanged: {
            scaleRatio = Math.min(width / 1920, height / 1080)
        }

        onHeightChanged: {
            scaleRatio = Math.min(width / 1920, height / 1080)
        }

        Component.onCompleted: {
            scaleRatio = Math.min(width / 1920, height / 1080)
        }
    }

    onVisibleChanged: {
        if (visible) {
            btnLaunch.focus = true;
        }
    }
}
