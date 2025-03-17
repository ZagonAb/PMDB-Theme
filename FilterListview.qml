import QtQuick 2.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils

Item {
    id: collectionsItem
    property alias randomMoviesModel: randomMoviesModel
    property alias unplayedMoviesModel: unplayedMoviesModel
    property alias continuePlayingMovies: continuePlayingMovies
    property alias favoriteMovies: favoriteMovies
    property alias baseMoviesFilter: baseMoviesFilter
    property alias recentlyAddedMoviesFilter: recentlyAddedMoviesFilter
    property alias recentlyAddedMoviesModel: recentlyAddedMoviesModel
    property alias recentlyAddedMoviesModelLimited: recentlyAddedMoviesModelLimited

    SortFilterProxyModel {
        id: baseMoviesFilter
        sourceModel: api.allGames
        filters: ExpressionFilter {
            expression: {
                for (var i = 0; i < collections.count; i++) {
                    if (collections.get(i).shortName === "movies") {
                        return true;
                    }
                }
                return false;
            }
        }
    }

    SortFilterProxyModel {
        id: recentlyPlayedMovies
        sourceModel: baseMoviesFilter
        filters: ExpressionFilter {
            expression: lastPlayed != null && lastPlayed.toString() !== "Invalid Date"
        }
        sorters: RoleSorter { roleName: "lastPlayed"; sortOrder: Qt.DescendingOrder }
    }

    SortFilterProxyModel {
        id: continuePlayingMovies
        sourceModel: recentlyPlayedMovies
        filters: IndexFilter { minimumIndex: 0; maximumIndex: 9 }
    }

    SortFilterProxyModel {
        id: favoriteMovies
        sourceModel: baseMoviesFilter
        filters: ValueFilter { roleName: "favorite"; value: true }
    }

    SortFilterProxyModel {
        id: randomMoviesFilter
        sourceModel: api.allGames
        filters: ExpressionFilter {
            expression: {
                for (var i = 0; i < collections.count; i++) {
                    if (collections.get(i).shortName === "movies") {
                        return true;
                    }
                }
                return false;
            }
        }
    }

    SortFilterProxyModel {
        id: unplayedMoviesFilter
        sourceModel: api.allGames
        filters: ExpressionFilter {
            expression: {
                // Verificar que sea de la colección de movies y no haya sido jugada
                var isMovieCollection = false;
                for (var i = 0; i < collections.count; i++) {
                    if (collections.get(i).shortName === "movies") {
                        isMovieCollection = true;
                        break;
                    }
                }

                return isMovieCollection && playCount === 0;
            }
        }
    }

    SortFilterProxyModel {
        id: sortedTitlesModel
        sourceModel: baseMoviesFilter
        sorters: RoleSorter { roleName: "title"; sortOrder: Qt.AscendingOrder }
    }

    SortFilterProxyModel {
        id: recentlyAddedMoviesFilter
        sourceModel: baseMoviesFilter
        filters: ExpressionFilter {
            expression: {
                // Verifica que el timestamp esté definido y sea un número válido
                if (extra && extra["added-timestamp"]) {
                    var timestamp = extra["added-timestamp"];
                    return !isNaN(timestamp) && timestamp !== null && timestamp !== undefined;
                }
                return false; // Si no hay timestamp, excluir la película
            }
        }

        sorters: RoleSorter {
            roleName: "added-timestamp" // Usa el timestamp para ordenar
            sortOrder: Qt.DescendingOrder // Ordenar de más reciente a más antiguo
        }
    }

    ListModel {
        id: recentlyAddedMoviesModel

        Component.onCompleted: {
            // Crear una lista temporal para ordenar
            var tempList = [];

            // Recopilar todas las películas con timestamp de adición
            for (var i = 0; i < baseMoviesFilter.count; i++) {
                var movie = baseMoviesFilter.get(i);

                if (movie && movie.extra && movie.extra["added-timestamp"]) {
                    var timestamp = parseInt(movie.extra["added-timestamp"]); // Asegurarse de que sea un número
                    if (!isNaN(timestamp)) {
                        tempList.push({
                            movieData: movie,
                            timestamp: timestamp
                        });
                    }
                }
            }

            // Ordenar la lista por timestamp (más reciente primero)
            tempList.sort(function(a, b) {
                return b.timestamp - a.timestamp;
            });

            // Agregar las películas ordenadas al ListModel
            for (var j = 0; j < tempList.length; j++) {
                recentlyAddedMoviesModel.append(tempList[j].movieData);
            }

            //console.log("recentlyAddedMoviesModel populated with " + recentlyAddedMoviesModel.count + " movies");
        }
    }

    ListModel {
        id: recentlyAddedMoviesModelLimited

        Component.onCompleted: {
            // Crear una lista temporal para ordenar
            var tempList = [];

            // Recopilar todas las películas con timestamp de adición
            for (var i = 0; i < baseMoviesFilter.count; i++) {
                var movie = baseMoviesFilter.get(i);

                if (movie && movie.extra && movie.extra["added-timestamp"]) {
                    var timestamp = parseInt(movie.extra["added-timestamp"]); // Asegurarse de que sea un número
                    if (!isNaN(timestamp)) {
                        tempList.push({
                            movieData: movie,
                            timestamp: timestamp // Usar el timestamp directamente
                        });
                    }
                }
            }

            // Ordenar la lista por timestamp (más reciente primero)
            tempList.sort(function(a, b) {
                return b.timestamp - a.timestamp;
            });

            // Limitar la lista a 15 elementos
            var maxMovies = 15;
            var limitedList = tempList.slice(0, maxMovies);

            // Agregar las películas ordenadas y limitadas al ListModel
            for (var j = 0; j < limitedList.length; j++) {
                recentlyAddedMoviesModelLimited.append(limitedList[j].movieData);
            }

            //console.log("recentlyAddedMoviesModelLimited populated with " + recentlyAddedMoviesModelLimited.count + " movies");
        }
    }


    ListModel {
        id: unplayedMoviesModel

        Component.onCompleted: {
            var maxUnplayedMovies = 10;
            var randomIndices = Utils.getRandomIndices(unplayedMoviesFilter.count);
            for (var j = 0; j < maxUnplayedMovies && j < randomIndices.length; ++j) {
                var gameIndex = randomIndices[j];
                var game = unplayedMoviesFilter.get(gameIndex);
                unplayedMoviesModel.append(game);
            }
        }
    }

    ListModel {
        id: randomMoviesModel
        Component.onCompleted: {
            var maxGames = 15;
            var randomIndices = Utils.getRandomIndices(randomMoviesFilter.count);  // Usa Utils.getRandomIndices
            for (var j = 0; j < maxGames && j < randomIndices.length; ++j) {
                var gameIndex = randomIndices[j];
                var game = randomMoviesFilter.get(gameIndex);
                randomMoviesModel.append(game);
            }
        }
    }
}
