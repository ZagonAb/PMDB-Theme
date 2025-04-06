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

Item {
    id: listviewContainer
    anchors {
        left: leftMenu.right
        right: parent.right
        top: parent.top
        bottom: parent.bottom
    }

    property var randomMoviesModel
    property var unplayedMoviesModel
    property var continuePlayingMovies
    property var favoriteMovies
    property var recentlyAddedMoviesModelLimited

    property alias randomMoviesList: randomMoviesList
    property alias unplayedMoviesList: unplayedMoviesList
    property alias continuePlayingList: continuePlayingList
    property alias favoriteList: favoriteList
    property alias recentlyMoviesList: recentlyMoviesList
    property alias contentFlickable: contentFlickable
    property alias randomMoviesSection: randomMoviesSection
    property alias unplayedMoviesSection: unplayedMoviesSection
    property alias continuePlayingSection: continuePlayingSection
    property alias favoriteSection: favoriteSection
    property alias recentlyAddedSection: recentlyAddedSection

    property bool hasUserInteracted: false
    property real scaleFactor: Math.min(width / 1280, height / 720)
    property real sectionHeight: 320 * scaleFactor
    property real sectionSpacing: 25 * scaleFactor
    property real listMargin: 15 * scaleFactor
    property real titleSize: 18 * scaleFactor
    property real delegateWidth: 180 * scaleFactor
    property real delegateHeight: 270 * scaleFactor
    property real delegateSpacing: 10 * scaleFactor

    function updateSizes() {
        scaleFactor = Math.min(width / 1280, height / 720)
        sectionHeight = Math.min(Math.max(280, 320 * scaleFactor), 360)
        delegateWidth = Math.min(Math.max(150, 180 * scaleFactor), 220)
        delegateHeight = Math.min(Math.max(225, 270 * scaleFactor), 330)
        delegateSpacing = Math.min(Math.max(8, 10 * scaleFactor), 15)
        titleSize = Math.min(Math.max(16, 18 * scaleFactor), 24)
    }

    onWidthChanged: updateSizes()
    onHeightChanged: updateSizes()

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
            spacing: listviewContainer.sectionSpacing

            Item {
                id: recentlyAddedSection
                width: parent.width
                height: listviewContainer.sectionHeight

                Text {
                    id: recentlyMoviesTitle
                    text: "Recently added"
                    color: "white"
                    font {
                        family: global.fonts.sans
                        pixelSize: listviewContainer.titleSize
                        bold: true
                    }
                    anchors {
                        left: parent.left
                        top: parent.top
                        margins: listviewContainer.listMargin
                    }
                }

                ListView {
                    id: recentlyMoviesList
                    orientation: Qt.Horizontal
                    focus: currentFocus === "recently"
                    anchors {
                        top: recentlyMoviesTitle.bottom
                        topMargin: listviewContainer.listMargin * 0.5
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: listviewContainer.listMargin
                        rightMargin: listviewContainer.listMargin
                    }
                    model: recentlyAddedMoviesModelLimited
                    delegate: movieDelegate
                    spacing: listviewContainer.delegateSpacing
                    cacheBuffer: width * 3
                    displayMarginBeginning: listviewContainer.delegateWidth * 2
                    displayMarginEnd: listviewContainer.delegateWidth * 2
                    reuseItems: true
                    highlightMoveDuration: 200
                    highlightResizeDuration: 0
                    maximumFlickVelocity: 2500
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 1500

                    preferredHighlightBegin: 0
                    preferredHighlightEnd: listviewContainer.delegateWidth

                    onCurrentIndexChanged: {
                        if (currentFocus === "recently" && currentIndex >= 0) {
                            currentMovie = recentlyAddedMoviesModelLimited.get(currentIndex);
                            backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : "";
                            game = recentlyAddedMoviesModelLimited.get(currentIndex);
                        }
                    }
                }
            }

            Item {
                id: randomMoviesSection
                width: parent.width
                height: listviewContainer.sectionHeight

                Text {
                    id: randomMoviesTitle
                    text: "Random movies"
                    color: "white"

                    font {
                        family: global.fonts.sans
                        pixelSize: listviewContainer.titleSize
                        bold: true
                    }

                    anchors {
                        left: parent.left
                        top: parent.top
                        margins: listviewContainer.listMargin
                    }
                }

                ListView {
                    id: randomMoviesList
                    orientation: Qt.Horizontal
                    focus: currentFocus === "random"

                    anchors {
                        top: randomMoviesTitle.bottom
                        topMargin: listviewContainer.listMargin * 0.5
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: listviewContainer.listMargin
                        rightMargin: listviewContainer.listMargin
                    }

                    model: randomMoviesModel
                    delegate: movieDelegate
                    spacing: listviewContainer.delegateSpacing
                    cacheBuffer: width * 3
                    displayMarginBeginning: listviewContainer.delegateWidth * 2
                    displayMarginEnd: listviewContainer.delegateWidth * 2
                    reuseItems: true
                    highlightMoveDuration: 200
                    highlightResizeDuration: 0
                    maximumFlickVelocity: 2500
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 1500
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: listviewContainer.delegateWidth

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
                height: listviewContainer.sectionHeight
                visible: unplayedMoviesModel.count > 0

                Text {
                    id: unplayedMoviesTitle
                    text: "Unwatched movies"
                    color: "white"

                    font {
                        family: global.fonts.sans
                        pixelSize: listviewContainer.titleSize
                        bold: true
                    }

                    anchors {
                        left: parent.left
                        top: parent.top
                        margins: listviewContainer.listMargin
                    }
                }

                ListView {
                    id: unplayedMoviesList
                    orientation: Qt.Horizontal
                    focus: currentFocus === "unplayed"
                    anchors {
                        top: unplayedMoviesTitle.bottom
                        topMargin: listviewContainer.listMargin * 0.5
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: listviewContainer.listMargin
                        rightMargin: listviewContainer.listMargin
                    }
                    model: unplayedMoviesModel
                    delegate: movieDelegate
                    spacing: listviewContainer.delegateSpacing
                    cacheBuffer: width * 3
                    displayMarginBeginning: listviewContainer.delegateWidth * 2
                    displayMarginEnd: listviewContainer.delegateWidth * 2
                    reuseItems: true
                    highlightMoveDuration: 200
                    highlightResizeDuration: 0
                    maximumFlickVelocity: 2500
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 1500

                    preferredHighlightBegin: 0
                    preferredHighlightEnd: listviewContainer.delegateWidth

                    onCurrentIndexChanged: {
                        if (currentFocus === "unplayed" && currentIndex >= 0 && hasUserInteracted) {
                            currentMovie = unplayedMoviesModel.get(currentIndex);
                            backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : "";
                            game = unplayedMoviesModel.get(currentIndex);
                        }
                    }
                }
            }

            Item {
                id: continuePlayingSection
                width: parent.width
                height: listviewContainer.sectionHeight
                visible: continuePlayingMovies.count > 0

                Text {
                    id: continuePlayingTitle
                    text: "In progress movies"
                    color: "white"

                    font {
                        family: global.fonts.sans
                        pixelSize: listviewContainer.titleSize
                        bold: true
                    }

                    anchors {
                        left: parent.left
                        top: parent.top
                        margins: listviewContainer.listMargin
                    }
                }

                ListView {
                    id: continuePlayingList
                    orientation: Qt.Horizontal
                    focus: currentFocus === "continue"
                    anchors {
                        top: continuePlayingTitle.bottom
                        topMargin: listviewContainer.listMargin * 0.5
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: listviewContainer.listMargin
                        rightMargin: listviewContainer.listMargin
                    }
                    model: continuePlayingMovies
                    delegate: DelegateContinuePlaying {}
                    spacing: listviewContainer.delegateSpacing
                    cacheBuffer: width * 3
                    displayMarginBeginning: listviewContainer.delegateWidth * 2
                    displayMarginEnd: listviewContainer.delegateWidth * 2
                    reuseItems: true
                    highlightMoveDuration: 200
                    highlightResizeDuration: 0
                    maximumFlickVelocity: 2500
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 1500
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: listviewContainer.delegateWidth

                    onCurrentIndexChanged: {
                        if (currentFocus === "continue" && currentIndex >= 0 && hasUserInteracted) {
                            currentMovie = continuePlayingMovies.get(currentIndex);
                            backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : "";
                            game = continuePlayingMovies.get(currentIndex);
                        }
                    }
                }
            }

            Item {
                id: favoriteSection
                width: parent.width
                height: listviewContainer.sectionHeight
                visible: favoriteMovies.count > 0

                Text {
                    id: favoriteTitle
                    text: "Favorite movies"
                    color: "white"

                    font {
                        family: global.fonts.sans
                        pixelSize: listviewContainer.titleSize
                        bold: true
                    }

                    anchors {
                        left: parent.left
                        top: parent.top
                        margins: listviewContainer.listMargin
                    }
                }

                ListView {
                    id: favoriteList
                    orientation: Qt.Horizontal
                    focus: currentFocus === "favorites"

                    anchors {
                        top: favoriteTitle.bottom
                        topMargin: listviewContainer.listMargin * 0.5
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: listviewContainer.listMargin
                        rightMargin: listviewContainer.listMargin
                    }

                    model: favoriteMovies
                    delegate: movieDelegate
                    spacing: listviewContainer.delegateSpacing
                    cacheBuffer: width * 3
                    displayMarginBeginning: listviewContainer.delegateWidth * 2
                    displayMarginEnd: listviewContainer.delegateWidth * 2
                    reuseItems: true
                    highlightMoveDuration: 200
                    highlightResizeDuration: 0
                    maximumFlickVelocity: 2500
                    boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: 1500
                    preferredHighlightBegin: 0
                    preferredHighlightEnd: listviewContainer.delegateWidth

                    onCurrentIndexChanged: {
                        if (currentFocus === "favorites" && currentIndex >= 0 && hasUserInteracted) {
                            currentMovie = favoriteMovies.get(currentIndex);
                            backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : "";
                            game = favoriteMovies.get(currentIndex);
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        updateSizes();
    }

    function setUserInteracted() {
        hasUserInteracted = true;
    }

    Keys.onPressed: {
        if (!hasUserInteracted) {
            setUserInteracted();
        }
    }
}
