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
import SortFilterProxyModel 0.2
import "utils.js" as Utils

Item {
    id: collectionsItem

    function isRecentlyPlayedSignificantly(game) {
        return Utils.isRecentlyPlayedSignificantly(game);
    }

    function wasPlayedRecently(lastPlayed) {
        return Utils.wasPlayedRecently(lastPlayed);
    }

    function hasSignificantPlayTime(playTime) {
        return Utils.hasSignificantPlayTime(playTime);
    }

    property alias randomMoviesModel: randomMoviesModel
    property alias unplayedMoviesModel: unplayedMoviesModel
    property alias continuePlayingMovies: continuePlayingMovies
    property alias favoriteMovies: favoriteMovies
    property alias baseMoviesFilter: baseMoviesFilter
    property alias recentlyAddedMoviesFilter: recentlyAddedMoviesFilter
    property alias recentlyAddedMoviesModel: recentlyAddedMoviesModel
    property alias recentlyAddedMoviesModelLimited: recentlyAddedMoviesModelLimited
    property alias recentlyPlayedSignificantMovies: recentlyPlayedSignificantMovies



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
        id: recentlyPlayedSignificantMovies
        sourceModel: recentlyPlayedMovies
        filters: ExpressionFilter {
            expression: {
                return collectionsItem.isRecentlyPlayedSignificantly(model);
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
                if (extra && extra["added-timestamp"]) {
                    var timestamp = extra["added-timestamp"];
                    return !isNaN(timestamp) && timestamp !== null && timestamp !== undefined;
                }
                return false;
            }
        }

        sorters: RoleSorter {
            roleName: "added-timestamp"
            sortOrder: Qt.DescendingOrder
        }
    }

    ListModel {
        id: recentlyAddedMoviesModel

        Component.onCompleted: {
            var tempList = [];
            for (var i = 0; i < baseMoviesFilter.count; i++) {
                var movie = baseMoviesFilter.get(i);

                if (movie && movie.extra && movie.extra["added-timestamp"]) {
                    var timestamp = parseInt(movie.extra["added-timestamp"]);
                    if (!isNaN(timestamp)) {
                        tempList.push({
                            movieData: movie,
                            timestamp: timestamp
                        });
                    }
                }
            }
            tempList.sort(function(a, b) {
                return b.timestamp - a.timestamp;
            });

            for (var j = 0; j < tempList.length; j++) {
                recentlyAddedMoviesModel.append(tempList[j].movieData);
            }

            //console.log("recentlyAddedMoviesModel populated with " + recentlyAddedMoviesModel.count + " movies");
        }
    }

    ListModel {
        id: recentlyAddedMoviesModelLimited

        Component.onCompleted: {
            var tempList = [];
            for (var i = 0; i < baseMoviesFilter.count; i++) {
                var movie = baseMoviesFilter.get(i);

                if (movie && movie.extra && movie.extra["added-timestamp"]) {
                    var timestamp = parseInt(movie.extra["added-timestamp"]);
                    if (!isNaN(timestamp)) {
                        tempList.push({
                            movieData: movie,
                            timestamp: timestamp
                        });
                    }
                }
            }

            tempList.sort(function(a, b) {
                return b.timestamp - a.timestamp;
            });
            var maxMovies = 15;
            var limitedList = tempList.slice(0, maxMovies);
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
            var randomIndices = Utils.getRandomIndices(randomMoviesFilter.count);
            for (var j = 0; j < maxGames && j < randomIndices.length; ++j) {
                var gameIndex = randomIndices[j];
                var game = randomMoviesFilter.get(gameIndex);
                randomMoviesModel.append(game);
            }
        }
    }
}
