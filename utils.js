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

function formatVideoPath(gameItem, showFullPath = false) {
    var fullPath = getMainVideoPathCached(gameItem);
    if (!fullPath || fullPath === "") return "No disponible";
    if (showFullPath) return fullPath;

    // Extraer el nombre del disco (asumiendo que está en la primera parte de la ruta)
    var diskMatch = fullPath.match(/(Disco [A-Z0-9]+|Disco_[A-Z0-9]+|Disk [A-Z0-9]+|Disk_[A-Z0-9]+)/i);
    var diskName = diskMatch ? diskMatch[0] : "Media";

    // Extraer el nombre del archivo
    var fileName = fullPath.split('/').pop();

    return diskName + "/.../" + fileName;
}

// Añade esto al final de utils.js
function getMovieFilePath(movie, showFullPath = false) {
    if (!movie || !movie.title) return "No disponible";

    // Buscar el juego por título en la colección de películas
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

// utils.js - Función alternativa
function launchGameFromMoviesCollection(title) {
    // Buscar la colección "movies" por shortName
    for (var i = 0; i < api.collections.count; ++i) {
        var collection = api.collections.get(i);
        if (collection.shortName.toLowerCase() === "movies") {
            // Buscar el juego por título
            for (var j = 0; j < collection.games.count; ++j) {
                var game = collection.games.get(j);
                if (game.title === title) {
                    game.launch();
                    return true;
                }
            }
        }
    }
    console.error("Juego no encontrado en la colección 'movies'");
    return false;
}

// utils.js - Nuevas funciones para manejar favoritos
function isGameFavorite(title) {
    for (var i = 0; i < api.collections.count; ++i) {
        var collection = api.collections.get(i);
        if (collection.shortName.toLowerCase() === "movies") {
            for (var j = 0; j < collection.games.count; ++j) {
                var game = collection.games.get(j);
                if (game.title === title) {
                    return game.favorite; // Devuelve true/false
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
                    game.favorite = !game.favorite; // Alterna el estado
                    return game.favorite; // Devuelve el nuevo estado
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

// utils.js - Añadir esta función
function highlightSearchText(fullText, searchTerm) {
    if (!fullText || !searchTerm || searchTerm.length === 0) {
        return fullText; // Devuelve el texto original si no hay término de búsqueda
    }

    var lowerFullText = fullText.toLowerCase();
    var lowerSearchTerm = searchTerm.toLowerCase();
    var result = "";
    var lastIndex = 0;
    var index = lowerFullText.indexOf(lowerSearchTerm);

    while (index >= 0) {
        // Añadir la parte antes de la coincidencia
        result += fullText.substring(lastIndex, index);

        // Añadir la parte coincidente con formato de resaltado
        result += "<font color='#ff6600'>" + fullText.substring(index, index + searchTerm.length) + "</font>";

        lastIndex = index + searchTerm.length;
        index = lowerFullText.indexOf(lowerSearchTerm, lastIndex);
    }

    // Añadir el resto del texto después de la última coincidencia
    result += fullText.substring(lastIndex);

    return result;
}

// Función genérica para resetear cualquier GridView
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
        console.log("Error al resetear GridView:", e);
    }
}


