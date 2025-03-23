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

function showDetails(movieDetails, movie, previousFocus) {
    if (movieDetails && movie) {
        movieDetails.currentMovie = movie;
        movieDetails.previousFocus = previousFocus || ""; // Asegúrate de que previousFocus no sea undefined
        movieDetails.visible = true;
        movieDetails.focus = true;
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
        //console.log("Advertencia: lastPosition o duration no están definidos.");
        return 0;
    }

    // Convertir la duración de minutos a milisegundos
    var totalDurationMs = duration * 60 * 1000;

    // Depuración: Mostrar la duración total en milisegundos
    //console.log("Duración total en milisegundos:", totalDurationMs);

    // Calcular el porcentaje de progreso
    var progress = lastPosition / totalDurationMs;

    // Depuración: Mostrar el progreso calculado antes de asegurar que no exceda el 100%
    //console.log("Progreso calculado (antes de asegurar 100%):", progress);

    // Asegurarnos de que el progreso no exceda el 100%
    return Math.min(progress, 1.0);
}

// Función para actualizar el progreso en el delegado
function updateProgress(game) {
    if (!game) return null;

    // Obtener la duración y la última posición
    var durationValue = game.extra && game.extra["duration"] ? game.extra["duration"][0] : null;
    var lastPosition = game.extra && game.extra["lastposition"] ? game.extra["lastposition"][0] : null;

    // Calcular el porcentaje de progreso
    var progressPercentage = getProgressPercentage(lastPosition, durationValue);

    // Devolver los datos actualizados
    return {
        title: game.title || "",
        posterUrl: game.assets ? (game.assets.poster || game.assets.boxFront || "") : "",
        hasPoster: game.assets && (game.assets.poster || game.assets.boxFront),
        progress: progressPercentage,
        lastPosition: lastPosition,
        totalDuration: durationValue ? durationValue * 60 * 1000 : 0 // Convertir a milisegundos
    };
}


function getLastPosition(title) {
    try {
        // Ruta relativa al archivo tmdb-theme.json en la misma carpeta del tema
        var filePath = "tmdb-theme.json";
        var file = new XMLHttpRequest();
        file.open("GET", filePath, false); // Sincrónico para simplificar
        file.send(null);

        if (file.status === 200) {
            var jsonData = JSON.parse(file.responseText);
            if (jsonData[title] && jsonData[title]["x-lastPosition"]) {
                return jsonData[title]["x-lastPosition"]; // Devuelve el tiempo en milisegundos
            }
        }
    } catch (e) {
        //console.error("Error al leer el archivo JSON:", e);
    }
    return 0; // Si no se encuentra el título o hay un error, devuelve 0
}

// Función para obtener la imagen de fondo de una película de forma segura
function getBackgroundImage(movie) {
    if (!movie) return "";
    if (!movie.assets) return "";

    // Intenta devolver screenshot o background, o cadena vacía si ninguno existe
    return (movie.assets.screenshot || movie.assets.background || "");
}

// Función para resetear el fondo y devolver null
function resetBackground(backgroundImage, overlayImage) {
    if (backgroundImage) {
        backgroundImage.source = "";
    }

    if (overlayImage) {
        overlayImage.opacity = 0.7;
    }

    return null;
}

// Función para forzar una actualización del modelo
function forceModelUpdate(model) {
    if (!model) return;

    // Una manera de forzar una actualización es cambiar una propiedad
    // Esta es una implementación genérica, puedes adaptarla según tus necesidades
    try {
        // Si el modelo tiene un método de actualización, úsalo
        if (typeof model.update === "function") {
            model.update();
        }
        // O puedes intentar otras técnicas como:
        // - Si es un ListModel, puedes recorrerlo y tocar una propiedad
        // - Si es un proxyModel, puedes reajustar los filtros
    } catch (e) {
        console.log("Error al actualizar el modelo: " + e);
    }
}

// Función para manejar de forma segura el acceso a los elementos del modelo
function safeModelGet(model, index) {
    if (!model) return null;
    if (typeof model.count === "undefined") return null;
    if (index < 0 || index >= model.count) return null;

    try {
        return model.get(index);
    } catch (e) {
        console.log("Error al acceder al modelo en el índice " + index + ": " + e);
        return null;
    }
}

// Función auxiliar para verificar si una lista está vacía
function isModelEmpty(model) {
    return !model || !model.count || model.count <= 0;
}

function formatVideoPath(gameItem) {
    // Primero obtenemos la ruta completa usando la función existente
    var fullPath = getMainVideoPathCached(gameItem);

    if (!fullPath || fullPath === "") {
        return "No disponible";
    }

    // Dividir la ruta por las barras
    var parts = fullPath.split('/');

    // Si la ruta es muy larga, la acortamos para mostrar "Disco X/.../nombre_archivo.extensión"
    if (parts.length > 2) {
        // Tomamos el primer segmento (que podría ser "Disco X")
        var firstPart = parts[0];

        // Si el primer segmento está vacío (porque la ruta comienza con '/'), usamos el segundo
        if (firstPart === "") {
            firstPart = parts[1]; // Tomamos el primer directorio real
        }

        // Tomamos el último segmento (nombre del archivo con extensión)
        var lastPart = parts[parts.length - 1];

        // Formateamos como "Disco X/.../nombre_archivo.extensión"
        return firstPart + "/.../" + lastPart;
    }

    // Si la ruta es corta, la devolvemos tal cual
    return fullPath;
}

function hideYearList() {
    isVisible = false;
    isExpanded = false;
    selectedYear = -1;
    // Mostrar listviewContainer al salir
    listviewContainer.visible = true;
    yearList.visible = false;
    currentFocus = "menu";
}

// Añadir esta función en utils.js
function hideRatingList() {
    ratingList.isVisible = false;
    ratingList.visible = false;
    listviewContainer.visible = true;
    currentFocus = "menu";
    leftMenu.menuList.focus = true;
}
