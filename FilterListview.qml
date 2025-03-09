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

                return isMovieCollection && modelData.playCount === 0;
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
                var addedDate = modelData && modelData.extra ? modelData.extra["added-date"] : null;
                return addedDate !== null && addedDate !== undefined && addedDate !== "";
            }
        }

        sorters: ExpressionSorter {
            expression: {
                var addedDate = modelData && modelData.extra ? modelData.extra["added-date"] : null;
                if (!addedDate) return 0;
                var date = new Date(addedDate);
                return isNaN(date.getTime()) ? 0 : date.getTime();
            }
            ascendingOrder: false
        }
    }

    ListModel {
        id: recentlyAddedMoviesModel

        Component.onCompleted: {
            // Crear una lista temporal para ordenar
            var tempList = [];

            // Recopilar todas las películas con fecha de adición
            for (var i = 0; i < baseMoviesFilter.count; i++) {
                var movie = baseMoviesFilter.get(i);

                if (movie && movie.extra && movie.extra["added-date"]) {
                    var addedDate = movie.extra["added-date"];
                    var date = new Date(addedDate);

                    if (!isNaN(date.getTime())) {
                        tempList.push({
                            movieData: movie,
                            timestamp: date.getTime()
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

            console.log("recentlyAddedMoviesModel populated with " + recentlyAddedMoviesModel.count + " movies");
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
