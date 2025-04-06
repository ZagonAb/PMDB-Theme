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
import "utils.js" as Utils
import QtGraphicalEffects 1.15
import "qrc:/qmlutils" as PegasusUtils

FocusScope {
    id: gridViewTitlesRoot

    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        bottom: parent.bottom
    }

    property var currentModel: null
    property bool isVisible: false
    property bool hasFocus: false
    property var currentMovie: null

    function hideGrid() {
        isVisible = false;
        hasFocus = false;
        backgroundImage.source = "";
        currentMovie = null;
        overlayImage.opacity = 0.7;
        currentFocus = "menu";
        Utils.setMenuFocus();
        listviewContainer.visible = true;
        gridViewTitlesRoot.visible = false;
    }

    function resetGridView() {
        Utils.resetGridView(gridView);
    }

    onIsVisibleChanged: {
        if (isVisible) {
            listviewContainer.visible = false;
            gridViewTitlesRoot.visible = true;
            gridViewTitlesRoot.focus = true;
            gridView.focus = true;
            hasFocus = true;
        } else {
            listviewContainer.visible = true;
            gridViewTitlesRoot.visible = false;
            gridViewTitlesRoot.focus = false;
            hasFocus = false;
        }
    }

    GridView {
        id: gridView
        anchors.fill: parent
        cellWidth: width / 2
        cellHeight: cellWidth * 0.43

        model: currentModel
        delegate: gridDelegate
        focus: hasFocus

        onCurrentIndexChanged: {
            if (currentIndex >= 0) {
                currentMovie = currentModel.get(currentIndex);
                backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : "";
            }
        }

        Keys.onLeftPressed: moveCurrentIndexLeft()
        Keys.onRightPressed: moveCurrentIndexRight()
        Keys.onUpPressed: moveCurrentIndexUp()
        Keys.onDownPressed: moveCurrentIndexDown()

        Keys.onPressed: {
            if (api.keys.isCancel(event)) {
                event.accepted = true;
                hideGrid();
            } else if (api.keys.isAccept(event)) {
                event.accepted = true;
                if (currentIndex >= 0) {
                    Utils.showDetails(movieDetails, currentModel.get(currentIndex), "gridViewTitles");
                    gridViewTitlesRoot.visible = false;
                }
            }
        }
    }

    Component {
        id: gridDelegate

        Item {
            width: gridView.cellWidth
            height: gridView.cellHeight

            Rectangle {
                id: cardContainer
                anchors.fill: parent
                anchors.margins: parent.width * 0.02
                color: "#232323"
                radius: 5

                Row {
                    anchors.fill: parent
                    anchors.margins: parent.width * 0.02
                    spacing: parent.width * 0.02

                    Rectangle {
                        width: parent.width * 0.3
                        height: parent.height
                        color: "transparent"

                        Image {
                            anchors.fill: parent
                            source: modelData.assets ? modelData.assets.boxFront : ""
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            asynchronous: true
                            cache: true
                            visible: status === Image.Ready
                        }
                    }

                    Column {
                        width: parent.width * 0.68
                        height: parent.height
                        spacing: parent.height * 0.05

                        Text {
                            text: modelData.title
                            color: "white"
                            font {
                                family: global.fonts.sans
                                pixelSize: Math.max(12, cardContainer.width * 0.03)
                                bold: true
                            }
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Row {
                            spacing: 5
                            width: parent.width

                            Text {
                                text: modelData.releaseYear || "N/A"
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, cardContainer.width * 0.025)
                                }
                            }
                            Text {
                                text: "|"
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, cardContainer.width * 0.025)
                                }
                            }
                            Text {
                                text: (modelData.rating * 100).toFixed(0) + "%" || "N/A"
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, cardContainer.width * 0.025)
                                }
                            }
                            Text {
                                text: "|"
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, cardContainer.width * 0.025)
                                }
                            }
                            Text {
                                text: modelData.genre || "N/A"
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, cardContainer.width * 0.025)
                                }
                                elide: Text.ElideRight
                                width: parent.width * 0.4
                            }
                        }

                        Item {
                            width: parent.width
                            height: parent.height * 0.5

                            Text {
                                id: staticDescription
                                anchors.fill: parent
                                text: modelData.description || "No description available."
                                color: "white"
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, cardContainer.width * 0.025)
                                }
                                wrapMode: Text.WordWrap
                                elide: Text.ElideRight
                                visible: gridView.currentIndex !== index
                            }

                            PegasusUtils.AutoScroll {
                                anchors.fill: parent
                                visible: gridView.currentIndex === index

                                Text {
                                    text: modelData.description || "No description available."
                                    color: "white"
                                    font {
                                        family: global.fonts.sans
                                        pixelSize: Math.max(10, cardContainer.width * 0.025)
                                    }
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                    horizontalAlignment: Text.AlignJustify
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            height: Math.max(20, cardContainer.width * 0.04)
                            text: Utils.formatVideoPath(modelData)
                            color: "#AAAAAA"
                            font {
                                family: global.fonts.sans
                                pixelSize: Math.max(12, cardContainer.width * 0.022)
                            }
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap

                            MouseArea {
                                id: pathMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    parent.text = (parent.elide === Text.ElideRight)
                                    ? Utils.formatVideoPath(modelData, true)
                                    : Utils.formatVideoPath(modelData);
                                    parent.elide = (parent.elide === Text.ElideRight)
                                    ? Text.ElideNone
                                    : Text.ElideRight;
                                    parent.wrapMode = (parent.wrapMode === Text.NoWrap)
                                    ? Text.Wrap
                                    : Text.NoWrap;
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "#006dc7"
                    border.width: gridView.currentIndex === index ? Math.max(2, parent.width * 0.007) : 0  // Ancho proporcional
                    visible: gridView.currentIndex === index
                    radius: 0
                    z: 100
                }
            }
        }
    }
}
