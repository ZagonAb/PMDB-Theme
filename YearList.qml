// YearList.qml (actualizado)
import QtQuick 2.15
import QtQuick.Layouts 1.15
import SortFilterProxyModel 0.2
import "utils.js" as Utils

FocusScope {
    id: yearList

    property var currentModel: null
    property bool isVisible: false
    property bool isExpanded: false
    property int selectedYear: -1

    property real scaleFactor: Math.min(width / 200, height / 800) // Factor de escala base
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

    // Función para agrupar películas por año usando un Map
    function createCategoriesFromYears() {
        var moviesByYear = new Map();

        for (var i = 0; i < baseMoviesFilter.count; i++) {
            var movie = baseMoviesFilter.get(i);
            var year = movie.releaseYear;

            if (!moviesByYear.has(year)) {
                moviesByYear.set(year, []);
            }
            moviesByYear.get(year).push(movie);
        }

        var yearsArray = Array.from(moviesByYear.entries()).map(([year, movies]) => ({
            year: parseInt(year),
                                                                                     count: movies.length,
                                                                                     movies: movies
        }));

        yearsArray.sort((a, b) => b.year - a.year);
        return yearsArray;
    }

    // Función para cargar la lista de años en yearsListModel
    function updateYearsList() {
        yearsListModel.clear();
        var yearsData = createCategoriesFromYears();

        for (var i = 0; i < yearsData.length; i++) {
            yearsListModel.append({
                year: yearsData[i].year,
                count: yearsData[i].count,
                movies: yearsData[i].movies
            });
        }
    }

    Text {
        id: heading
        text: "Movies / Years"
        color: "white"
        font {
            family: global.fonts.sans
            pixelSize: Math.max(12, yearList.width * 0.03)  // Tamaño responsivo
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

        // Modelo para almacenar la lista de años disponibles
        ListModel {
            id: yearsListModel
        }

        // Filtra solo las películas en la colección "movies"
        ListModel {
            id: baseMoviesFilter
        }

        // Ordena películas por año de lanzamiento (releaseYear)
        SortFilterProxyModel {
            id: moviesByYearFilter
            sourceModel: baseMoviesFilter
            sorters: RoleSorter { roleName: "releaseYear"; sortOrder: Qt.DescendingOrder }
        }

        // Filtra películas por año seleccionado
        SortFilterProxyModel {
            id: filteredMoviesByYear
            sourceModel: baseMoviesFilter
            filters: ValueFilter {
                id: yearFilter
                roleName: "releaseYear"
                value: -1 // Valor predeterminado, cambiará cuando se seleccione un año
            }
        }

        // Diseño de la UI
        Row {
            anchors.fill: parent
            spacing: 10

            // ListView para mostrar los años
            ListView {
                id: yearsListView
                width: parent.width * 0.10
                height: parent.height * 0.90
                model: yearsListModel
                currentIndex: 0 // Inicializar con el primer índice seleccionado
                anchors.verticalCenter: parent.verticalCenter

                delegate: Rectangle {
                    id: yearDelegate
                    width: yearsListView.width - 20
                    height: 60
                    color: ListView.isCurrentItem && yearsListView.focus ? "#006dc7" : "transparent"
                    radius: 5

                    Row {
                        width: parent.width // Asegurar que el Row ocupe el ancho completo del padre
                        height: parent.height // Asegurar que el Row ocupe la altura completa del padre
                        spacing: 10 // Espaciado entre los elementos del Row

                        Text {
                            text: model.year
                            color: "white"
                            font {
                                family: global.fonts.sans
                                pixelSize: yearList.menuFontSize
                                bold: true
                            }
                            width: parent.width // Ajustar el ancho del Text al ancho del Row
                            height: parent.height // Ajustar la altura del Text a la altura del Row
                            horizontalAlignment: Text.AlignHCenter // Centrar el texto horizontalmente
                            verticalAlignment: Text.AlignVCenter // Centrar el texto verticalmente
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            yearsListView.currentIndex = index; // Asegurar que el ListView seleccione el año correcto
                            yearFilter.value = model.year; // Actualizar el filtro con el año seleccionado
                            //console.log("Año seleccionado:", model.year); // Debug
                        }
                    }
                }

                // Manejar la navegación con las teclas de dirección y la tecla "Cancel"
                Keys.onPressed: {
                    if (event.key === Qt.Key_Up) {
                        event.accepted = true;
                        if (yearsListView.currentIndex > 0) {
                            yearsListView.currentIndex--;
                            yearFilter.value = yearsListModel.get(yearsListView.currentIndex).year;
                            //console.log("Año seleccionado:", yearFilter.value); // Debug
                        }
                    } else if (event.key === Qt.Key_Down) {
                        event.accepted = true;
                        if (yearsListView.currentIndex < yearsListModel.count - 1) {
                            yearsListView.currentIndex++;
                            yearFilter.value = yearsListModel.get(yearsListView.currentIndex).year;
                            //console.log("Año seleccionado:", yearFilter.value); // Debug
                        }
                    } else if (event.key === Qt.Key_Right) {
                        event.accepted = true;
                        // Mover el foco al GridView
                        moviesGridView.focus = true;
                    } else if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        // Reiniciar el yearFilter.value al año correspondiente al índice 0 del ListView
                        if (yearsListModel.count > 0) {
                            var firstYear = yearsListModel.get(0).year;
                            yearFilter.value = firstYear; // Reiniciar el filtro con el primer año
                            //console.log("Reiniciando año al salir:", firstYear); // Debug
                        }

                        Utils.hideYearList(); // Llamar a la función para salir de YearList
                    }
                }

                // Asegurarse de que el ListView tenga el foco al entrar
                focus: true
            }

            GridView {
                id: moviesGridView
                width: parent.width - yearsListView.width - 20
                height: parent.height
                cellWidth: width / 4  // 4 columnas
                cellHeight: height / 2 // 2 filas
                clip: true // Para evitar que los elementos se salgan del área visible

                model: filteredMoviesByYear

                delegate: Item {
                    id: delegateMovies
                    width: moviesGridView.cellWidth
                    height: moviesGridView.cellHeight

                    Rectangle {
                        width: parent.width * 0.8
                        height: parent.height * 0.8
                        color: "transparent"
                        border.color: "#006dc7"
                        border.width: moviesGridView.currentIndex === index ? Math.max(2, parent.width * 0.015) : 0  // Ancho proporcional
                        visible: moviesGridView.currentIndex === index && moviesGridView.focus // Solo visible si el ítem está seleccionado y el GridView tiene el foco
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 0
                        z: 100
                    }

                    Column {
                        anchors.fill: parent // Ocupar todo el espacio del delegado
                        spacing: 10 // Espaciado entre los elementos

                        Item {
                            id: contentContainer
                            width: parent.width
                            height: parent.height // Ajusta la altura para dar espacio suficiente a ambos elementos
                            anchors.horizontalCenter: parent.horizontalCenter // Centrar el contenedor en el delegado

                            Rectangle {
                                id: posterContainer
                                width: parent.width * 0.8
                                height: parent.height * 0.8
                                color: "#022441"
                                radius: 4
                                clip: true
                                anchors.horizontalCenter: parent.horizontalCenter // Centrar horizontalmente

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
                                text: model.title
                                font {
                                    family: global.fonts.sans
                                    pixelSize: Math.max(12, delegateMovies.width * 0.03)
                                    bold: true
                                }
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.WordWrap
                                anchors.horizontalCenter: parent.horizontalCenter // Centrar horizontalmente
                                width: parent.width * 0.8 // Ajustar a la misma anchura que el posterContainer
                                color: "white"
                                anchors.top: posterContainer.bottom // Coloca el texto directamente debajo del poster
                                anchors.topMargin: 10 // Espaciado entre la imagen y el texto
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
                            yearsListView.focus = true;
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
                        yearsListView.focus = true;
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
            updateYearsList();

            // Seleccionar el primer año al cargar
            if (yearsListModel.count > 0) {
                yearsListView.currentIndex = 0; // Asegurar que el ListView esté en el índice 0
                var firstYear = yearsListModel.get(0).year;
                yearFilter.value = firstYear; // Actualizar el filtro con el primer año
                //console.log("Año seleccionado al iniciar:", firstYear); // Debug
                //console.log("Índice actual del ListView:", yearsListView.currentIndex); // Debug
            }
        }

    }


}
