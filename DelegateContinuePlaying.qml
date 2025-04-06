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

Component {
    id: movieDelegateContinuePlaying

    Item {
        id: delegateRoot
        width: listviewContainer.delegateWidth
        height: listviewContainer.delegateHeight

        property bool isFocused: ListView.isCurrentItem && ListView.view.focus
        property var game: modelData
        property var cachedData: null
        property real progressPercentage: 0

        property real borderWidth: Math.max(2, 4 * listviewContainer.scaleFactor)
        property real titlePanelHeight: Math.min(60, 50 * listviewContainer.scaleFactor)
        property real titleFontSize: Math.min(16, 14 * listviewContainer.scaleFactor)
        property real loadingSpinnerSize: Math.min(50, 40 * listviewContainer.scaleFactor)

        Component.onCompleted: {
            if (game) {
                var durationValue = game.extra ? game.extra["duration"] || game.extra["duration"] : null;
                var watchedTime = Utils.getLastPosition(game.title) / 1000; // Convertir a segundos
                var totalDuration = 0;
                if (durationValue) {
                    totalDuration = parseInt(durationValue) * 60;
                } else {
                    //console.log("ADVERTENCIA! No hay depuración);
                }
                progressPercentage = totalDuration > 0 ? Math.min(watchedTime / totalDuration, 1.0) : 0;

                cachedData = {
                    title: game.title || "",
                    posterUrl: game.assets ? (game.assets.poster || game.assets.boxFront || "") : "",
                    hasPoster: game.assets && (game.assets.poster || game.assets.boxFront),
                    progress: progressPercentage,
                    watchedTime: watchedTime,
                    totalDuration: totalDuration
                };
            }
        }

        Rectangle {
            id: selectionRect
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
                layer.enabled: delegateRoot.isFocused
                layer.effect: null
            }
        }

        Rectangle {
            id: darkenOverlay
            anchors.fill: parent
            color: "#80000000"
            visible: poster.status === Image.Ready
        }

        Image {
            id: continueIcon
            anchors.centerIn: parent
            width: parent.width * 0.75
            height: parent.height * 0.5
            source: "assets/icons/continue.png"
            visible: poster.status === Image.Ready
            mipmap: true
        }

        Rectangle {
            id: progressBarContainer
            anchors {
                left: parent.left
                right: parent.right
                top: parent.bottom
                topMargin: 10
            }
            height: 6
            color: "#33ffffff"
            visible: true
            z: 200

            Rectangle {
                id: progressBarFill
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: parent.width * progressPercentage
                color: "#006dc7"
            }
        }

        Rectangle {
            id: titlePanel
            anchors.bottom: parent.bottom
            width: parent.width
            height: 40
            color: "#aa000000"
            visible: cachedData && !cachedData.hasPoster

            Text {
                anchors.centerIn: parent
                text: cachedData ? cachedData.title : ""
                color: "white"
                font { family: global.fonts.sans; pixelSize: 14 }
                elide: Text.ElideRight
                width: parent.width - 20
                horizontalAlignment: Text.AlignHCenter
            }
        }

        Rectangle {
            id: loadingIndicator
            anchors.fill: parent
            color: "transparent"
            visible: poster.status !== Image.Ready

            Image {
                id: loadingSpinner
                anchors.centerIn: parent
                width: 40
                height: 40
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

        transitions: Transition {
            from: ""
            to: "selected"
            reversible: true
            NumberAnimation { properties: "scale"; duration: 150; easing.type: Easing.OutQuad }
        }
    }
}
