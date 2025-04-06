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

Component {
    id: movieDelegate

    Item {
        id: delegateRoot
        width: listviewContainer.delegateWidth
        height: listviewContainer.delegateHeight

        property bool isFocused: ListView.isCurrentItem && ListView.view.focus
        property var game: modelData
        property var cachedData: null
        property real borderWidth: Math.max(2, 4 * listviewContainer.scaleFactor)
        property real titlePanelHeight: Math.min(60, 50 * listviewContainer.scaleFactor)
        property real titleFontSize: Math.min(16, 14 * listviewContainer.scaleFactor)
        property real loadingSpinnerSize: Math.min(50, 40 * listviewContainer.scaleFactor)
        scale: isFocused ? 1.01 : 1.0

        Behavior on scale {
            NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
        }

        Component.onCompleted: {
            if (game) {
                cachedData = {
                    title: game.title || "",
                    posterUrl: game.assets ? (game.assets.poster || game.assets.boxFront || "") : "",
                    hasPoster: game.assets && (game.assets.poster || game.assets.boxFront)
                };
            }
        }

        Rectangle {
            id: shadow
            anchors.fill: parent
            anchors.margins: -borderWidth
            color: "transparent"
            border.color: "#006dc7"
            border.width: delegateRoot.isFocused ? borderWidth : 0
            visible: delegateRoot.isFocused
            z: 100
        }

        Rectangle {
            id: posterContainer
            anchors.fill: parent
            color: "#022441"
            radius: 4
            clip: true

            Image {
                id: poster
                anchors.fill: parent
                source: cachedData ? cachedData.posterUrl : ""
                fillMode: Image.PreserveAspectCrop
                mipmap: true
                asynchronous: true
                cache: true
                sourceSize {
                    width: delegateRoot.width * 1.5
                    height: delegateRoot.height * 1.5
                }
                visible: status === Image.Ready
            }
        }

        Rectangle {
            id: titlePanel
            anchors.bottom: parent.bottom
            width: parent.width
            height: titlePanelHeight
            color: "#aa000000"
            radius: 0
            visible: cachedData && (!cachedData.hasPoster || !poster.visible)

            Text {
                anchors.centerIn: parent
                text: cachedData ? cachedData.title : ""
                color: "white"
                font {
                    family: global.fonts.sans
                    pixelSize: titleFontSize
                    bold: delegateRoot.isFocused
                }
                elide: Text.ElideRight
                width: parent.width - (listviewContainer.listMargin * 2)
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Rectangle {
            id: loadingIndicator
            anchors.fill: parent
            color: "#022441"
            radius: 4
            visible: poster.status !== Image.Ready

            Image {
                id: loadingSpinner
                anchors.centerIn: parent
                width: loadingSpinnerSize
                height: loadingSpinnerSize
                source: "assets/icons/loading-spinner.svg"
                mipmap: true
                visible: poster.status === Image.Loading

                RotationAnimator on rotation {
                    running: loadingSpinner.visible && poster.status === Image.Loading
                    loops: Animator.Infinite
                    from: 0
                    to: 360
                    duration: 1000
                }
            }

            Text {
                anchors {
                    bottom: parent.bottom
                    horizontalCenter: parent.horizontalCenter
                    margins: listviewContainer.listMargin
                }
                text: cachedData ? cachedData.title : ""
                color: "white"
                font {
                    family: global.fonts.sans
                    pixelSize: titleFontSize
                }
                elide: Text.ElideRight
                width: parent.width - (listviewContainer.listMargin * 2)
                horizontalAlignment: Text.AlignHCenter
                visible: cachedData && cachedData.title
            }
        }

        Keys.onPressed: function(event) {
            if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                event.accepted = true;
                if (game) {
                    launchTimer.start();
                }
            } else if (api.keys.isCancel(event)) {
                event.accepted = true;
                backgroundImage.source = "";
                currentMovie = null;
                overlayImage.opacity = 0.7;
                currentFocus = "menu";
                leftMenu.menuList.focus = true;
            }
        }

        Timer {
            id: launchTimer
            interval: 150
            repeat: false
            onTriggered: {
                if (game) {
                    game.launch();
                }
            }
        }
    }
}
