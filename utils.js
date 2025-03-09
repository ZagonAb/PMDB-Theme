// utils.js
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

    if (gameItem._cachedPath !== undefined) {
        return gameItem._cachedPath;
    }

    if (gameItem.files && gameItem.files.count > 0) {
        var mainFile = gameItem.files.get(0);
        gameItem._cachedPath = mainFile.path;
        return gameItem._cachedPath;
    }

    gameItem._cachedPath = "";
    return "";
}
