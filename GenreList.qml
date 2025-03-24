// GenreList.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils

FocusScope {
    id: genreList

    property var currentModel: null
    property bool isVisible: false
    property bool isExpanded: false
    property string selectedGenre: ""
    property bool genereVisible: isVisible

    property real scaleFactor: Math.min(width / 400, height / 1000)
    property real menuFontSize: 28 * scaleFactor
    property real labelHeight: 30

    visible: isVisible
    focus: isVisible

    // utils.js
    function hideGenreList() {
        genreList.hide();
        currentFocus = "menu";
        leftMenu.menuList.focus = true;
    }

    function isMovie(item) {
        if (!item.collections) return false;
        for (var j = 0; j < item.collections.count; j++) {
            if (item.collections.get(j).shortName === "movies") {
                return true;
            }
        }
        return false;
    }

    // Function to normalize and extract base genres
    function normalizeGenre(genre) {
        // Trim whitespace and convert to title case
        var normalizedGenre = genre.trim()
        .split(' ')
        .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
        .join(' ');

        // Extract the first word as the base genre
        return normalizedGenre.split(' ')[0];
    }

    // Función principal para crear categorías de géneros
    function createCategoriesFromGenres() {
        var allGenres = {};

        // Obtener todas las películas
        for (var i = 0; i < api.allGames.count; i++) {
            var movie = api.allGames.get(i);
            if (!isMovie(movie) || !movie.genre) continue;

            // Separar los géneros y procesarlos
            var genreList = movie.genre.split(',');
            genreList.forEach(function(genre) {
                // Extraer categoría base (primera palabra, convertida a minúsculas)
                var baseCategory = genre.trim().split(/[\s\/-]/)[0].toLowerCase();
                if (!allGenres[baseCategory]) {
                    allGenres[baseCategory] = [];
                }
                allGenres[baseCategory].push(movie.title);
            });
        }

        // Convertir a array para el modelo
        var categoriesArray = [];
        Object.keys(allGenres).forEach(function(category) {
            categoriesArray.push({
                name: category,
                count: allGenres[category].length,
                games: allGenres[category]
            });
        });

        // Ordenar por cantidad (descendente)
        categoriesArray.sort((a, b) => b.count - a.count);
        return categoriesArray;
    }

    // Modelo para películas filtradas por género
    /*ListModel {
        id: genreFilteredModel

        function filterCategory(category) {
            clear();
            for (var i = 0; i < api.allGames.count; i++) {
                var movie = api.allGames.get(i);
                if (!isMovie(movie) || !movie.genre) continue;

                var movieCategories = movie.genre.split(',').map(function(genre) {
                    return genre.trim().split(/[\s\/-]/)[0].toLowerCase();
                });

                if (movieCategories.includes(category.toLowerCase())) {
                    append(movie);
                }
            }
            updateInitialImages();
        }
    }*/

    // Agrega esta función en la sección de funciones de GenreList.qml
    function formatGenreText(genreText, selectedGenre) {
        if (!genreText || !selectedGenre) return genreText;

        var genres = genreText.split(',');
        var result = [];

        for (var i = 0; i < genres.length; i++) {
            var genre = genres[i].trim();
            var baseGenre = genre.split(/[\s\/-]/)[0].toLowerCase();
            var selectedBase = selectedGenre.split(/[\s\/-]/)[0].toLowerCase();

            if (baseGenre === selectedBase) {
                result.push('<font color="#ff6600">' + genre + '</font>');
            } else {
                result.push('<font color="#a0a0a0">' + genre + '</font>');
            }
        }

        return result.join(', ');
    }

    ListModel {
        id: genreFilteredModel

        function filterCategory(category) {
            clear();
            var tempMovies = [];

            // Primero recolectamos todas las películas que coinciden
            for (var i = 0; i < api.allGames.count; i++) {
                var movie = api.allGames.get(i);
                if (!isMovie(movie)) continue;

                    var movieCategories = movie.genre ?
                    movie.genre.split(',').map(function(genre) {
                        return genre.trim().split(/[\s\/-]/)[0].toLowerCase();
                    }) : [];

                if (movieCategories.includes(category.toLowerCase())) {
                    tempMovies.push(movie);
                }
            }

            // Orden aleatorio usando el algoritmo Fisher-Yates
            for (var j = tempMovies.length - 1; j > 0; j--) {
                var randomIndex = Math.floor(Math.random() * (j + 1));
                [tempMovies[j], tempMovies[randomIndex]] = [tempMovies[randomIndex], tempMovies[j]];
            }

            // Agregamos al modelo en orden aleatorio
            tempMovies.forEach(function(movie) {
                append(movie);
            });

            updateInitialImages();
        }
    }

    Text {
        id: heading
        text: "Movies / Genres"
        color: "white"
        font {
            family: global.fonts.sans
            pixelSize: Math.max(12, genreList.width * 0.03)
            bold: true
        }
        anchors {
            top: parent.top
            left: parent.left
            margins: 30
        }
    }

    Rectangle {
        id: container
        anchors {
            top: heading.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 10
        }
        color: "transparent"

        Component.onCompleted: {
            if (genresListView.model.length > 0) {
                genresListView.currentIndex = 0;
            }
        }

        // UI Layout
        Row {
            anchors.fill: parent
            spacing: 10

            // ListView to display genres
            ListView {
                id: genresListView
                width: parent.width * 0.15
                height: parent.height * 0.90
                focus: true  // Ensure this is set to true
                anchors.verticalCenter: parent.verticalCenter

                property int indexToPosition: -1
                property var categoriesModel: []
                property string selectedCategory: ""

                model: categoriesModel

                delegate: Rectangle {
                    width: genresListView.width - 20
                    height: 60
                    color: ListView.isCurrentItem && genresListView.focus ? "#006dc7" : "transparent"
                    radius: 5

                    Row {
                        width: parent.width // Asegurar que el Row ocupe el ancho completo del padre
                        height: parent.height // Asegurar que el Row ocupe la altura completa del padre
                        spacing: 10 // Espaciado entre los elementos del Row

                        Text {
                            text: modelData.name.charAt(0).toUpperCase() + modelData.name.slice(1)
                            color: "white"
                            font {
                                family: global.fonts.sans
                                pixelSize: genreList.menuFontSize
                                bold: true
                            }
                            width: parent.width // Ajustar el ancho del Text al ancho del Row
                            height: parent.height // Ajustar la altura del Text a la altura del Row
                            horizontalAlignment: Text.AlignHCenter // Centrar el texto horizontalmente
                            verticalAlignment: Text.AlignVCenter // Centrar el texto verticalmente
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                genresListView.currentIndex = index;
                            }
                        }
                    }
                }

                onCurrentIndexChanged: {
                    indexToPosition = currentIndex;
                    if (currentIndex >= 0 && currentIndex < model.length) {
                        selectedCategory = model[currentIndex].name;
                        genreFilteredModel.filterCategory(selectedCategory);
                        console.log("Género seleccionado: " + selectedCategory + ", películas: " + genreFilteredModel.count);
                    }
                }

                // Reemplaza el bloque Keys.onPressed actual con este:
                Keys.onPressed: {
                    if (event.key === Qt.Key_Up) {
                        event.accepted = true;
                        if (genresListView.currentIndex > 0) {
                            genresListView.currentIndex--;
                            selectedGenre = genresListView.categoriesModel[genresListView.currentIndex].name;
                        }
                    } else if (event.key === Qt.Key_Down) {
                        event.accepted = true;
                        if (genresListView.currentIndex < genresListView.categoriesModel.length - 1) {
                            genresListView.currentIndex++;
                            selectedGenre = genresListView.categoriesModel[genresListView.currentIndex].name;
                        }
                    } else if (event.key === Qt.Key_Right) {
                        event.accepted = true;
                        moviesGridView.focus = true;
                    } else if (event.key === Qt.Key_Left) {
                        event.accepted = true; // Evita que el evento se propague al padre
                        // No hacemos nada, evitamos que salga del GenreList
                    } else if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        isVisible = false;
                        listviewContainer.visible = true;
                        currentFocus = "menu";
                        leftMenu.menuList.focus = true;
                        isExpanded = false;

                        if (genresListView.categoriesModel.length > 0) {
                            selectedGenre = genresListView.categoriesModel[0].name;
                        }

                    }
                }

                // Añade esto para manejar cuando el componente recibe foco:
                onFocusChanged: {
                    if (focus && genresListView) {
                        genresListView.focus = true;
                        if (genresListView.categoriesModel.length > 0) {
                            genresListView.currentIndex = 0;
                        }
                    }
                }
            }

            GridView {
                id: moviesGridView
                width: parent.width - genresListView.width - 20
                height: parent.height
                cellWidth: width / 4
                cellHeight: height / 2
                clip: true

                model: genreFilteredModel

                delegate: Item {
                    id: delegateMovies
                    width: moviesGridView.cellWidth
                    height: moviesGridView.cellHeight

                    Rectangle {
                        width: parent.width * 0.8
                        height: parent.height * 0.8
                        color: "transparent"
                        border.color: "#006dc7"
                        border.width: moviesGridView.currentIndex === index ? Math.max(2, parent.width * 0.015) : 0
                        visible: moviesGridView.currentIndex === index && moviesGridView.focus
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 0
                        z: 100
                    }

                    Column {
                        anchors.fill: parent
                        spacing: 10

                        Item {
                            id: contentContainer
                            width: parent.width
                            height: parent.height

                            Rectangle {
                                id: posterContainer
                                width: parent.width * 0.8
                                height: parent.height * 0.8 // Reducimos un poco para dar espacio a los textos
                                color: "#022441"
                                radius: 4
                                clip: true
                                anchors.horizontalCenter: parent.horizontalCenter

                                Image {
                                    source: model.assets.boxFront
                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    mipmap: true

                                    Text {
                                        visible: parent.status !== Image.Ready
                                        anchors.centerIn: parent
                                        text: "......"
                                        color: "white"
                                    }
                                }
                            }

                            Text {
                                id: movieTitle
                                text: model.title
                                /*font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(12, delegateMovies.width * 0.03)
                                    bold: true
                                }*/

                                font {
                                    family: global.fonts.sans
                                    pixelSize: delegateMovies.menuFontSize
                                    bold: true
                                }

                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width * 0.8
                                color: "white"
                                anchors.top: posterContainer.bottom
                                anchors.topMargin: 10
                            }

                            Text {
                                text: formatGenreText(model.genre, genresListView.selectedCategory)
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(10, delegateMovies.width * 0.045)
                                }
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: parent.width * 0.8
                                color: "#a0a0a0" // Color por defecto (será sobrescrito por el rich text)
                                anchors.top: movieTitle.bottom
                                anchors.topMargin: 5
                                textFormat: Text.RichText // Esto permite usar HTML básico para el formato
                            }
                        }
                    }
                }

                onCurrentIndexChanged: {
                    if (currentIndex !== -1 && count > 0) {
                        var movie = genreFilteredModel.get(currentIndex);
                    }
                }

                // Handle navigation keys in GridView
                Keys.onPressed: {
                    if (event.key === Qt.Key_Left) {
                        event.accepted = true;
                        if (moviesGridView.currentIndex === 0) {
                            genresListView.focus = true;
                        } else {
                            moviesGridView.moveCurrentIndexLeft();
                        }
                    } else if (event.key === Qt.Key_Right) {
                        event.accepted = true;
                        moviesGridView.moveCurrentIndexRight();
                    } else if (event.key === Qt.Key_Up) {
                        event.accepted = true;
                        moviesGridView.moveCurrentIndexUp();
                    } else if (event.key === Qt.Key_Down) {
                        event.accepted = true;
                        moviesGridView.moveCurrentIndexDown();
                    } else if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        genresListView.focus = true;
                    }
                }
            }
        }
    }
    onIsVisibleChanged: {
        if (isVisible) {
            console.log("GenreList se hizo visible");

            // Siempre regenerar las categorías para asegurar datos actualizados
            genresListView.categoriesModel = createCategoriesFromGenres();

            if (genresListView.categoriesModel.length > 0) {
                // Inicializar con el primer género
                genresListView.currentIndex = 0;
                genresListView.selectedCategory = genresListView.categoriesModel[0].name;
                genreFilteredModel.filterCategory(genresListView.selectedCategory);

                // Explicitly set focus and ensure it's done immediately
                genresListView.forceActiveFocus();
                genresListView.focus = true;

                gameGridView.focus = false;
                gameGridView.currentIndex = 0;

                console.log("Inicializado con género: " + genresListView.selectedCategory +
                ", películas encontradas: " + genreFilteredModel.count);
            }
        }
    }
}
