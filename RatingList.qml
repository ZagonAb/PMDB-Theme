// RatingList.qml
import QtQuick 2.15
import QtQuick.Layouts 1.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils

FocusScope {
    id: ratingList

    property var currentModel: null
    property bool isVisible: false
    property bool isExpanded: false
    property string selectedRatingRange: ""

    property real scaleFactor: Math.min(width / 200, height / 800)
    property real menuFontSize: 28 * scaleFactor

    visible: isVisible
    focus: isVisible

    // Función para filtrar películas por colección
    function filterMoviesByCollection(collectionName) {
        var filteredMovies = [];
        for (var i = 0; i < api.allGames.count; i++) {
            var movie = api.allGames.get(i);
            for (var j = 0; j < movie.collections.count; j++) {
                if (movie.collections.get(j).shortName === collectionName) {
                    filteredMovies.push(movie);
                    break;
                }
            }
        }
        return filteredMovies;
    }

    function createCategoriesFromRatings() {
        var moviesByRating = new Map();

        // Crear rangos más precisos y sin superposiciones
        var ratingRanges = [
            { label: "9.0", min: 0.90, max: 1.0 },
            { label: "8.5", min: 0.85, max: 0.899 },
            { label: "8.1", min: 0.81, max: 0.849 },
            { label: "7.9", min: 0.79, max: 0.809 },
            { label: "7.5", min: 0.75, max: 0.789 },
            { label: "7.4", min: 0.74, max: 0.749 },
            { label: "7.3", min: 0.73, max: 0.739 },
            { label: "7.2", min: 0.72, max: 0.729 },
            { label: "7.0", min: 0.70, max: 0.719 },
            { label: "6.0", min: 0.60, max: 0.699 },
            { label: "5.0", min: 0.50, max: 0.599 },
            { label: "4.0", min: 0.40, max: 0.499 },
            { label: "3.0", min: 0.30, max: 0.399 },
            { label: "2.0", min: 0.20, max: 0.299 },
            { label: "1.0", min: 0.10, max: 0.199 },
            { label: "0.0", min: 0.0, max: 0.099 }
        ];

        // Inicializar los mapas para cada rango
        for (var j = 0; j < ratingRanges.length; j++) {
            moviesByRating.set(ratingRanges[j].label, []);
        }

        // Agrupar películas por rangos de calificación
        for (var k = 0; k < baseMoviesFilter.count; k++) {
            var movie = baseMoviesFilter.get(k);
            var rating = movie.rating; // Ya está en escala 0-1

            // Determinar a qué rango pertenece esta película
            var placed = false;
            for (var l = 0; l < ratingRanges.length; l++) {
                // Usar una pequeña tolerancia para manejar errores de punto flotante
                if (rating >= ratingRanges[l].min && rating <= ratingRanges[l].max) {
                    moviesByRating.get(ratingRanges[l].label).push(movie);
                    placed = true;
                    break;
                }
            }

            // Si no se colocó en ningún rango (por si acaso)
            if (!placed) {
                console.log("Película no clasificada realmente: " + movie.title + " - Rating: " + rating);
                // Asignar al rango 0.0 como fallback
                moviesByRating.get("0.0").push(movie);
            }
        }

        // Convertir el mapa a un array
        var ratingsArray = [];
        for (var m = 0; m < ratingRanges.length; m++) {
            var label = ratingRanges[m].label;
            var movies = moviesByRating.get(label);
            if (movies.length > 0) {
                ratingsArray.push({
                    label: label,
                    count: movies.length,
                    movies: movies,
                    min: ratingRanges[m].min,
                    max: ratingRanges[m].max
                });
            }
        }

        // Ordenar por mejor calificación primero
        ratingsArray.sort((a, b) => parseFloat(b.label) - parseFloat(a.label));

        return ratingsArray;
    }

    // Función para cargar la lista de rangos de calificación en ratingListModel
    function updateRatingsList() {
        ratingListModel.clear();
        var ratingsData = createCategoriesFromRatings();

        for (var i = 0; i < ratingsData.length; i++) {
            ratingListModel.append({
                label: ratingsData[i].label,
                count: ratingsData[i].count,
                movies: ratingsData[i].movies,
                min: ratingsData[i].min,
                max: ratingsData[i].max
            });
        }
    }

    Text {
        id: heading
        text: "Movies / Ratings"
        color: "white"
        font {
            family: global.fonts.sans
            pixelSize: Math.max(12, ratingList.width * 0.03)
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

        // Modelo para almacenar la lista de rangos de calificación disponibles
        ListModel {
            id: ratingListModel
        }

        // Filtra solo las películas en la colección "movies"
        ListModel {
            id: baseMoviesFilter
        }

        // Ordena películas por calificación
        SortFilterProxyModel {
            id: moviesByRatingFilter
            sourceModel: baseMoviesFilter
            sorters: RoleSorter { roleName: "rating"; sortOrder: Qt.DescendingOrder }
        }

        // Filtra películas por rango de calificación seleccionado
        SortFilterProxyModel {
            id: filteredMoviesByRating
            sourceModel: baseMoviesFilter
            filters: [
                RangeFilter {
                    id: ratingMinFilter
                    roleName: "rating"
                    minimumValue: -1  // Se establecerá cuando se seleccione un rango
                    maximumValue: 2   // Valor predeterminado, cambiará cuando se seleccione un rango
                },
                ValueFilter {
                    id: ratingNoRatingFilter
                    roleName: "rating"
                    enabled: false    // Activado solo para "No Rating"
                    value: 0.0
                }
            ]
            // Ordenar las películas por calificación (de mayor a menor)
            sorters: RoleSorter {
                roleName: "rating"
                sortOrder: Qt.DescendingOrder
            }
        }

        // Diseño de la UI
        Row {
            anchors.fill: parent
            spacing: 10

            ListView {
                id: ratingsListView
                width: parent.width * 0.10
                height: parent.height * 0.90
                model: ratingListModel
                currentIndex: 0
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2 // Espaciado más compacto, como en la imagen

                delegate: Rectangle {
                    id: ratingDelegate
                    width: ratingsListView.width - 20
                    height: 60 // Altura más compacta como en la imagen
                    color: ListView.isCurrentItem && ratingsListView.focus ? "#006dc7" : "transparent"
                    radius: 5 // Sin bordes redondeados


                    Row {
                        anchors {
                            verticalCenter: parent.verticalCenter
                            left: parent.left
                            leftMargin: 10
                        }
                        spacing: 4

                        Text {
                            text: "★" // Estrella
                            color: "#ffcc00" // Color amarillo/dorado para la estrella
                            font {
                                pixelSize: 18
                                bold: true
                            }
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: model.label // Muestra el label
                            color: "white"
                            font {
                                family: global.fonts.sans
                                pixelSize: 18
                                bold: true
                            }

                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            ratingsListView.currentIndex = index;
                            setFilterForRating(model.min, model.max, model.label);
                        }
                    }
                }

                // Manejar la navegación con las teclas de dirección y la tecla "Cancel"
                Keys.onPressed: {
                    if (event.key === Qt.Key_Up) {
                        event.accepted = true;
                        if (ratingsListView.currentIndex > 0) {
                            ratingsListView.currentIndex--;
                            var item = ratingListModel.get(ratingsListView.currentIndex);
                            setFilterForRating(item.min, item.max, item.label);
                        }
                    } else if (event.key === Qt.Key_Down) {
                        event.accepted = true;
                        if (ratingsListView.currentIndex < ratingListModel.count - 1) {
                            ratingsListView.currentIndex++;
                            var item = ratingListModel.get(ratingsListView.currentIndex);
                            setFilterForRating(item.min, item.max, item.label);
                        }
                    } else if (event.key === Qt.Key_Right) {
                        event.accepted = true;
                        // Mover el foco al GridView
                        moviesGridView.focus = true;
                    } else if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        // Reiniciar los filtros al salir
                        if (ratingListModel.count > 0) {
                            var firstItem = ratingListModel.get(0);
                            setFilterForRating(firstItem.min, firstItem.max, firstItem.label);
                        }

                        // Llamar a la función para salir de RatingList
                        Utils.hideRatingList();
                    }
                }

                // Asegurarse de que el ListView tenga el foco al entrar
                focus: true
            }

            GridView {
                id: moviesGridView
                width: parent.width - ratingsListView.width - 20
                height: parent.height
                cellWidth: width / 4  // 4 columnas
                cellHeight: height / 2 // 2 filas
                clip: true // Para evitar que los elementos se salgan del área visible

                model: filteredMoviesByRating

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
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle {
                                id: posterContainer
                                width: parent.width * 0.8
                                height: parent.height * 0.7
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

                            Column {
                                anchors {
                                    top: posterContainer.bottom
                                    topMargin: 5
                                    horizontalCenter: parent.horizontalCenter
                                }
                                width: parent.width * 0.8
                                spacing: 5

                                Text {
                                    text: model.title
                                    font {
                                        family: global.fonts.sans
                                        pixelSize: Math.max(10, delegateMovies.width * 0.03)
                                        bold: true
                                    }
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                    width: parent.width
                                    color: "white"
                                    elide: Text.ElideRight
                                    maximumLineCount: 2
                                }

                                Text {
                                    text: "Rating: " + Math.round(model.rating * 100) + "%"
                                    font {
                                        family: global.fonts.sans
                                        pixelSize: Math.max(8, delegateMovies.width * 0.025)
                                    }
                                    horizontalAlignment: Text.AlignHCenter
                                    width: parent.width
                                    color: "#FFD700" // Color dorado para las calificaciones
                                    visible: model.rating > 0
                                }
                            }
                        }
                    }
                }

                // Manejar la navegación con las teclas de dirección en el GridView
                Keys.onPressed: {
                    if (event.key === Qt.Key_Left) {
                        event.accepted = true;
                        if (moviesGridView.currentIndex === 0) {
                            // Si estamos en el índice 0 del GridView, volver al ListView
                            ratingsListView.focus = true;
                        } else {
                            // Mover al ítem anterior en el GridView
                            moviesGridView.moveCurrentIndexLeft();
                        }
                    } else if (event.key === Qt.Key_Right) {
                        event.accepted = true;
                        // Mover al siguiente ítem en el GridView
                        moviesGridView.moveCurrentIndexRight();
                    } else if (event.key === Qt.Key_Up) {
                        event.accepted = true;
                        // Mover al ítem de arriba en el GridView
                        moviesGridView.moveCurrentIndexUp();
                    } else if (event.key === Qt.Key_Down) {
                        event.accepted = true;
                        // Mover al ítem de abajo en el GridView
                        moviesGridView.moveCurrentIndexDown();
                    } else if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        // Volver al ListView cuando se presiona la tecla Cancel
                        ratingsListView.focus = true;
                    } else if (api.keys.isAccept(event)) {
                        event.accepted = true;
                        if (moviesGridView.currentIndex >= 0 && filteredMoviesByRating.count > 0) {
                            // Acción para abrir los detalles de la película seleccionada
                            var selectedMovie = filteredMoviesByRating.get(moviesGridView.currentIndex);
                            if (selectedMovie) {
                                currentMovie = selectedMovie;
                                // Abrir detalles de la película o reproducirla directamente
                            }
                        }
                    }
                }

                // Asegurarse de que el GridView tenga el foco al entrar desde el ListView
                focus: false
            }
        }

        Component.onCompleted: {
            var movies = filterMoviesByCollection("movies");
            baseMoviesFilter.clear();
            for (var i = 0; i < movies.length; i++) {
                baseMoviesFilter.append(movies[i]);
            }
            updateRatingsList();

            // Seleccionar el primer rango de calificación al cargar
            if (ratingListModel.count > 0) {
                ratingsListView.currentIndex = 0;
                var firstItem = ratingListModel.get(0);
                setFilterForRating(firstItem.min, firstItem.max, firstItem.label);
            }
        }
    }

    function setFilterForRating(min, max, label) {
        console.log("Filtrando por: " + label + " (min: " + min + ", max: " + max + ")");

        if (label === "0.0") {
            // Modificar para mostrar todas las películas sin calificación
            ratingMinFilter.enabled = true;
            ratingNoRatingFilter.enabled = false;
            ratingMinFilter.minimumValue = 0.0;
            ratingMinFilter.maximumValue = 0.099; // Incluir películas con ratings muy bajos
        } else {
            // Configurar filtro de rango para películas con calificación
            ratingMinFilter.enabled = true;
            ratingNoRatingFilter.enabled = false;
            ratingMinFilter.minimumValue = min - 0.0001; // Pequeña tolerancia
            ratingMinFilter.maximumValue = max + 0.0001; // Pequeña tolerancia
        }
        selectedRatingRange = label;

        // Asegurarnos de que el GridView se actualice correctamente
        moviesGridView.currentIndex = 0;
        moviesGridView.positionViewAtBeginning();
    }
}
