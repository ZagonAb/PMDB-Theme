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

function getRandomIndices(count) {
    var indices = [];
    for (var i = 0; i < count; ++i) {
        indices.push(i);
    }
    indices.sort(function() { return 0.5 - Math.random() });
    return indices;
}

function getCachedGameData(game, gameDataCache) {
    if (!game) return null;

    var gameId = game.gameId || game.id || JSON.stringify(game.title);
    if (gameDataCache[gameId]) {
        return gameDataCache[gameId];
    }

    var cachedData = {
        title: game.title,
        poster: game.assets && (game.assets.poster || game.assets.boxFront) || "",
        background: game.assets && game.assets.background || "",
    };

    gameDataCache[gameId] = cachedData;
    return cachedData;
}

function getMainVideoPathCached(gameItem) {
    if (!gameItem) return "";

    if (gameItem._mainVideoPath !== undefined) {
        return gameItem._mainVideoPath;
    }

    var path = "";
    if (gameItem.files && gameItem.files.count > 0) {
        var mainFile = gameItem.files.get(0);
        path = mainFile.path;
    }

    Object.defineProperty(gameItem, '_mainVideoPath', {
        value: path,
        writable: true,
        enumerable: false,
        configurable: true
    });

    return path;
}

function showDetails(movieDetails, movie, previousFocus) {
    if (movieDetails && movie) {
        movieDetails.currentMovie = movie;
        movieDetails.previousFocus = previousFocus || "";
        movieDetails.visible = true;
        movieDetails.focus = true;

        // Forzar la actualización del texto del botón Favorite
        if (movieDetails.btnFavorite && movieDetails.btnFavorite.favoriteText) {
            movieDetails.btnFavorite.favoriteText.text = isGameFavorite(movie.title) ? "Remove from favorites" : "Add to favorites";
        }
    }
}

function hideDetails(movieDetails) {
    if (movieDetails) {
        movieDetails.visible = false;
        movieDetails.focus = false;
        movieDetails.currentMovie = null;
    }
}

function getProgressPercentage(lastPosition, duration) {
    if (!lastPosition || !duration) {
        //console.log("Advertencia: lastPosition no esta definido.");
        return 0;
    }
    var totalDurationMs = duration * 60 * 1000;
    //console.log("Duración total en milisegundos:", totalDurationMs);
    var progress = lastPosition / totalDurationMs;
    //console.log("Progreso calculado (antes de asegurar 100%):", progress);
    return Math.min(progress, 1.0);
}

function updateProgress(game) {
    if (!game) return null;
    var durationValue = game.extra && game.extra["duration"] ? game.extra["duration"][0] : null;
    var lastPosition = game.extra && game.extra["lastposition"] ? game.extra["lastposition"][0] : null;
    var progressPercentage = getProgressPercentage(lastPosition, durationValue);

    return {
        title: game.title || "",
        posterUrl: game.assets ? (game.assets.poster || game.assets.boxFront || "") : "",
        hasPoster: game.assets && (game.assets.poster || game.assets.boxFront),
        progress: progressPercentage,
        lastPosition: lastPosition,
        totalDuration: durationValue ? durationValue * 60 * 1000 : 0
    };
}

function getLastPosition(title) {
    try {
        var filePath = "database.json";
        var file = new XMLHttpRequest();
        file.open("GET", filePath, false);
        file.send(null);

        if (file.status === 200) {
            var jsonData = JSON.parse(file.responseText);
            if (jsonData[title] && jsonData[title]["x-lastPosition"]) {
                return jsonData[title]["x-lastPosition"];
            }
        }
    } catch (e) {
        //console.error("Error al leer el archivo JSON:", e);
    }
    return null; // Cambiado de 0 a null para indicar que no hay progreso
}

function getBackgroundImage(movie) {
    if (!movie) return "";
    if (!movie.assets) return "";
    return (movie.assets.screenshot || movie.assets.background || "");
}

function resetBackground(backgroundImage, overlayImage) {
    if (backgroundImage) {
        backgroundImage.source = "";
    }

    if (overlayImage) {
        overlayImage.opacity = 0.7;
    }

    return null;
}

function forceModelUpdate(model) {
    if (!model) return;

    try {
        if (typeof model.update === "function") {
            model.update();
        }

    } catch (e) {
        //console.log("Error al actualizar el modelo: " + e);
    }
}

function safeModelGet(model, index) {
    if (!model) return null;
    if (typeof model.count === "undefined") return null;
    if (index < 0 || index >= model.count) return null;

    try {
        return model.get(index);
    } catch (e) {
        //console.log("Error al acceder al modelo en el índice " + index + ": " + e);
        return null;
    }
}

function isModelEmpty(model) {
    return !model || !model.count || model.count <= 0;
}

function formatVideoPath(gameItem, showFullPath = false) {
    var fullPath = getMainVideoPathCached(gameItem);
    if (!fullPath || fullPath === "") return "No disponible";

    if (showFullPath) {
        return fullPath;
    }

    var diskMatch = fullPath.match(/(Disco [A-Z0-9]+|Disco_[A-Z0-9]+|Disk [A-Z0-9]+|Disk_[A-Z0-9]+|Volume [A-Z0-9]+|Volume_[A-Z0-9]+)/i);
    var diskName = diskMatch ? diskMatch[0] : "source";

    var fileName = fullPath.split(/[\\/]/).pop();

    return diskName + "/.../" + fileName;
}

function getMovieFilePath(movie, showFullPath = false) {
    if (!movie || !movie.title) return "No disponible";

    for (var i = 0; i < api.collections.count; ++i) {
        var collection = api.collections.get(i);
        if (collection.shortName.toLowerCase() === "movies") {
            for (var j = 0; j < collection.games.count; ++j) {
                var game = collection.games.get(j);
                if (game.title === movie.title) {
                    return formatVideoPath(game, showFullPath);
                }
            }
        }
    }
    return "No disponible";
}

function hideYearList() {
    isVisible = false;
    isExpanded = false;
    selectedYear = -1;
    listviewContainer.visible = true;
    yearList.visible = false;
    currentFocus = "menu";
    setMenuFocus();
}

function hideRatingList() {
    ratingList.isVisible = false;
    ratingList.visible = false;
    listviewContainer.visible = true;
    currentFocus = "menu";
    setMenuFocus();
}

function launchGameFromMoviesCollection(title) {
    for (var i = 0; i < api.collections.count; ++i) {
        var collection = api.collections.get(i);
        if (collection.shortName.toLowerCase() === "movies") {
            for (var j = 0; j < collection.games.count; ++j) {
                var game = collection.games.get(j);
                if (game.title === title) {
                    game.launch();
                    return true;
                }
            }
        }
    }
    //console.error("Juego no encontrado en la colección 'movies'");
    return false;
}

function isGameFavorite(title) {
    for (var i = 0; i < api.collections.count; ++i) {
        var collection = api.collections.get(i);
        if (collection.shortName.toLowerCase() === "movies") {
            for (var j = 0; j < collection.games.count; ++j) {
                var game = collection.games.get(j);
                if (game.title === title) {
                    return game.favorite;
                }
            }
        }
    }
    return false;
}

function toggleGameFavorite(title) {
    for (var i = 0; i < api.collections.count; ++i) {
        var collection = api.collections.get(i);
        if (collection.shortName.toLowerCase() === "movies") {
            for (var j = 0; j < collection.games.count; ++j) {
                var game = collection.games.get(j);
                if (game.title === title) {
                    game.favorite = !game.favorite;
                    return game.favorite;
                }
            }
        }
    }
    return false;
}

function getFavoriteButtonText(title) {
    return isGameFavorite(title) ? "Remove from favorites" : "Add to favorites";
}

function updateBackground() {
    if (resultsGrid.focus && resultsGrid.currentIndex >= 0 && searchResultsModel.count > 0) {
        currentMovie = searchResultsModel.get(resultsGrid.currentIndex)
        backgroundImage.source = currentMovie ? Utils.getBackgroundImage(currentMovie) : ""
    }
}

function highlightSearchText(fullText, searchTerm) {
    if (!fullText || !searchTerm || searchTerm.length === 0) {
        return fullText;
    }

    var lowerFullText = fullText.toLowerCase();
    var lowerSearchTerm = searchTerm.toLowerCase();
    var result = "";
    var lastIndex = 0;
    var index = lowerFullText.indexOf(lowerSearchTerm);

    while (index >= 0) {
        result += fullText.substring(lastIndex, index);
        result += "<font color='#ff6600'>" + fullText.substring(index, index + searchTerm.length) + "</font>";

        lastIndex = index + searchTerm.length;
        index = lowerFullText.indexOf(lowerSearchTerm, lastIndex);
    }
    result += fullText.substring(lastIndex);
    return result;
}

function resetGridView(gridView) {
    if (!gridView) return;

    try {
        gridView.currentIndex = 0;
        if (gridView.contentY !== undefined) {
            gridView.contentY = 0;
        }
        if (gridView.updateScrollBar !== undefined) {
            gridView.updateScrollBar();
        }
    } catch (e) {
        //console.log("Error al resetear GridView:", e);
    }
}

function setMenuFocus() {
    if (leftMenu && leftMenu.menuList) {
        setMenuFocus();
        return true;
    }
    var menu = null;
    for (var i = 0; i < children.length; i++) {
        if (children[i].objectName === "leftMenu") {
            menu = children[i];
            break;
        }
    }

    if (menu && menu.menuList) {
        menu.menuList.focus = true;
        return true;
    }

    //console.log("Advertencia: No se pudo establecer foco en menuList después de búsqueda alternativa");
    return false;
}

function wasPlayedRecently(lastPlayed) {
    if (!lastPlayed || lastPlayed.toString() === "Invalid Date") {
        return false;
    }

    var currentDate = new Date();
    var playedDate = new Date(lastPlayed);
    var timeDiff = currentDate.getTime() - playedDate.getTime();
    var daysDiff = timeDiff / (1000 * 3600 * 24);

    return daysDiff <= 7;
}

function hasSignificantPlayTime(playTime) {
    return playTime && playTime >= 60;
}

function isRecentlyPlayedSignificantly(game) {
    if (!game) return false;

    var wasRecentlyPlayed = wasPlayedRecently(game.lastPlayed);
    var wasPlayedLongEnough = hasSignificantPlayTime(game.playTime);

    return wasRecentlyPlayed && wasPlayedLongEnough;
}
