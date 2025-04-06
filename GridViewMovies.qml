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
import QtQuick.Window 2.15
import "utils.js" as Utils

FocusScope {
    id: gridViewRoot

    property real scrollPosition: 0
    property real scrollBarSize: 0

    function updateScrollBar() {
        if (gridView.contentHeight <= gridView.height) {
            scrollBar.visible = false;
            return;
        }

        scrollBarSize = Math.max(20, (gridView.height / gridView.contentHeight) * gridView.height);
        scrollPosition = (gridView.contentY / (gridView.contentHeight - gridView.height)) * (gridView.height - scrollBarSize);
        scrollPosition = Math.max(0, Math.min(scrollPosition, gridView.height - scrollBarSize));
        scrollBar.visible = true;
    }

    function resetGridView() {
        Utils.resetGridView(gridView);
    }

    Connections {
        target: gridView
        function onContentYChanged() { updateScrollBar(); }
        function onHeightChanged() { updateScrollBar(); }
        function onContentHeightChanged() { updateScrollBar(); }
    }

    Connections {
        target: Window.window
        function onWidthChanged() { updateScrollBar(); }
        function onHeightChanged() { updateScrollBar(); }
    }

    function hideGrid() {
        isVisible = false;
        hasFocus = false;
        backgroundImage.source = "";
        overlayImage.opacity = 0.7;
        currentFocus = "menu";
        currentMovie = null;

        if (root.leftMenu && root.leftMenu.menuList) {
            root.leftMenu.menuList.focus = true;
        } else {
            //console.log("Advertencia: No se pudo establecer foco en menuList");
        }
        listviewContainer.visible = true;
        gridViewRoot.visible = false;
    }

    function printModelDates() {
        for (var i = 0; i < currentModel.count && i < 5; i++) {
            var movie = currentModel.get(i);
            if (movie && movie.extra && movie.extra["added-date"]) {
                //console.log(i + ": " + movie.title + " - " + movie.extra["added-date"]);
            } else {
                //console.log(i + ": " + movie.title + " - No date");
            }
        }
    }

    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        bottom: parent.bottom
    }

    property var currentModel: null
    property bool isVisible: false
    property bool hasFocus: false

    onIsVisibleChanged: {
        if (isVisible) {
            listviewContainer.visible = false;
            gridViewRoot.visible = true;
            gridViewRoot.focus = true;
            gridView.focus = true;
            hasFocus = true;
        } else {
            listviewContainer.visible = true;
            gridViewRoot.visible = false;
            gridViewRoot.focus = false;
            hasFocus = false;
        }
    }

    onCurrentModelChanged: {
        if (currentModel) {
            //console.log("Model changed, has " + currentModel.count + " items");
            printModelDates();
        }
    }

    GridView {
        id: gridView
        anchors {
            left: parent.left
            right: scrollBar.left
            top: parent.top
            bottom: parent.bottom
        }
        width: parent.width * 0.9
        cellWidth: width / 5
        cellHeight: cellWidth * 1.5
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
                    Utils.showDetails(movieDetails, currentModel.get(currentIndex), "gridView");
                    gridViewRoot.visible = false;
                }
            }
        }

        interactive: true
        boundsBehavior: Flickable.StopAtBounds
        onMovementEnded: updateScrollBar()
        onContentYChanged: updateScrollBar()
    }

    Rectangle {
        id: scrollBar
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        width: 10
        color: "transparent"
        visible: false

        Rectangle {
            id: scrollBarHandle
            anchors {
                left: parent.left
                right: parent.right
            }
            height: scrollBarSize
            y: scrollPosition
            color: "#006dc7"
            radius: 0
        }
    }

    Component {
        id: gridDelegate

        Item {
            width: gridView.cellWidth
            height: gridView.cellHeight
            Item {
                anchors.fill: parent
                anchors.margins: 10

                Rectangle {
                    id: posterContainer
                    anchors.fill: parent
                    color: "#022441"
                    radius: 4
                    clip: true

                    Image {
                        id: boxFront
                        anchors.fill: parent
                        source: modelData.assets ? modelData.assets.boxFront : ""
                        fillMode: Image.PreserveAspectCrop
                        mipmap: true
                        asynchronous: true
                        cache: true
                        sourceSize { width: 200; height: 300 }
                        visible: status === Image.Ready
                        layer.enabled: gridView.currentIndex === index
                        layer.effect: null
                    }
                }

                Rectangle {
                    id: titlePanel
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 40
                    color: "#aa000000"
                    visible: !modelData.assets.boxFront || boxFront.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: modelData ? modelData.title : ""
                        color: "white"
                        font { family: global.fonts.sans; pixelSize: 14 }
                        elide: Text.ElideRight
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                Rectangle {
                    id: selectionRect
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "#006dc7"
                    border.width: gridView.currentIndex === index ? 3 : 0
                    visible: gridView.currentIndex === index
                    z: 100
                }
            }
        }
    }
}
