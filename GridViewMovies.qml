// GridViewMovies.qml
import QtQuick 2.15
import QtQuick.Window 2.15
import "utils.js" as Utils

FocusScope {
    id: gridViewRoot

    // Propiedad para controlar la posición del ScrollBar
    property real scrollPosition: 0

    // Propiedad para controlar el tamaño del ScrollBar
    property real scrollBarSize: 0

    function updateScrollBar() {
        if (gridView.contentHeight <= gridView.height) {
            scrollBar.visible = false;
            return;
        }

        // Calcular posición y tamaño
        scrollBarSize = Math.max(20, (gridView.height / gridView.contentHeight) * gridView.height);
        scrollPosition = (gridView.contentY / (gridView.contentHeight - gridView.height)) * (gridView.height - scrollBarSize);

        // Limitar valores para evitar desbordamientos
        scrollPosition = Math.max(0, Math.min(scrollPosition, gridView.height - scrollBarSize));
        scrollBar.visible = true;
    }

    Connections {
        target: gridView
        function onContentYChanged() { updateScrollBar(); }
        function onHeightChanged() { updateScrollBar(); }
        function onContentHeightChanged() { updateScrollBar(); }
    }

    Connections {
        target: Window.window // Corrige la referencia a Window
        function onWidthChanged() { updateScrollBar(); }
        function onHeightChanged() { updateScrollBar(); }
    }

    function hideGrid() {
        isVisible = false;
        hasFocus = false;

        // Limpia la imagen de fondo explícitamente
        backgroundImage.source = "";
        currentMovie = null;

        // Asegúrate de que el overlay tenga la opacidad correcta
        overlayImage.opacity = 0.7;

        // Ahora cambia el foco al menú
        currentFocus = "menu";

        leftMenu.menuList.focus = true;

        // Asegúrate de que listviewContainer sea visible
        listviewContainer.visible = true;

        // Si es necesario, forzar una actualización
        gridViewRoot.visible = false;
    }

    function printModelDates() {
        //console.log("Checking model dates:");
        for (var i = 0; i < currentModel.count && i < 5; i++) {
            var movie = currentModel.get(i);
            if (movie && movie.extra && movie.extra["added-date"]) {
                //console.log(i + ": " + movie.title + " - " + movie.extra["added-date"]);
            } else {
                //console.log(i + ": " + movie.title + " - No date");
            }
        }
    }

    anchors {
        left: parent.left
        right: parent.right
        top: parent.top
        bottom: parent.bottom
    }

    property var currentModel: null
    property bool isVisible: false

    // Propiedad para controlar el foco
    property bool hasFocus: false

    // En GridViewMovies.qml - Asegúrate de que esto sea correcto
    onIsVisibleChanged: {
        if (isVisible) {
            listviewContainer.visible = false;
            gridViewRoot.visible = true; // Asegúrate de que esto esté establecido
            gridViewRoot.focus = true;
            gridView.focus = true;
            hasFocus = true;
        } else {
            listviewContainer.visible = true;
            gridViewRoot.visible = false; // Asegúrate de que esto esté establecido
            gridViewRoot.focus = false;
            hasFocus = false;
        }
    }

    onCurrentModelChanged: {
        if (currentModel) {
            //console.log("Model changed, has " + currentModel.count + " items");
            printModelDates();
        }
    }


    // GridView
    GridView {

        id: gridView
        anchors {
            left: parent.left
            right: scrollBar.left
            top: parent.top
            bottom: parent.bottom
        }
        width: parent.width * 0.9 // 90% del ancho total
        //anchors.horizontalCenter: parent.horizontalCenter // Centrado horizontalmente
        cellWidth: width / 5
        cellHeight: cellWidth * 1.5
        model: currentModel
        delegate: gridDelegate
        focus: hasFocus


        // Cambiar el foco cuando se selecciona un elemento
        onCurrentIndexChanged: {
            if (currentIndex >= 0) {
                currentMovie = currentModel.get(currentIndex);
                backgroundImage.source = currentMovie ? currentMovie.assets.screenshot || currentMovie.assets.background : "";
            }
        }

        Keys.onLeftPressed: moveCurrentIndexLeft()
        Keys.onRightPressed: moveCurrentIndexRight()
        Keys.onUpPressed: moveCurrentIndexUp()
        Keys.onDownPressed: moveCurrentIndexDown()

        Keys.onPressed: {
            if (api.keys.isCancel(event)) {
                event.accepted = true;
                hideGrid(); // Llamamos a una función para ocultar el grid
            } else if (api.keys.isAccept(event)) {
                event.accepted = true;
                if (currentIndex >= 0) {
                    Utils.showDetails(movieDetails, currentModel.get(currentIndex), "gridView"); // Pasar "gridView" como previousFocus
                    gridViewRoot.visible = false; // Ocultar el grid al mostrar los detalles
                }
            }
        }

        // Añadir estas propiedades al GridView
        interactive: true // Permite desplazamiento táctil/ratón
        boundsBehavior: Flickable.StopAtBounds // Evita desplazamiento infinito

        // Forzar la actualización del ScrollBar al desplazar
        onMovementEnded: updateScrollBar()
        onContentYChanged: updateScrollBar() // ¡Asegúrate de que esto esté presente!
    }

    Rectangle {
        id: scrollBar
        anchors {
            right: parent.right
            top: parent.top
            bottom: parent.bottom
        }
        width: 10
        color: "transparent"
        visible: false // Inicialmente oculto

        Rectangle {
            id: scrollBarHandle
            anchors {
                left: parent.left
                right: parent.right
            }
            height: scrollBarSize
            y: scrollPosition
            color: "#006dc7"
            radius: 0


        }
    }

    Component {
        id: gridDelegate

        Item {
            width: gridView.cellWidth
            height: gridView.cellHeight

            // Contenedor real con márgenes para crear el espaciado
            Item {
                // Crear márgenes dentro de cada celda para simular el espaciado
                anchors.fill: parent
                anchors.margins: 10  // Esto crea un espacio de 20px entre elementos (10px de cada lado)

                Rectangle {
                    id: posterContainer
                    anchors.fill: parent
                    color: "#022441"
                    radius: 4
                    clip: true

                    Image {
                        id: boxFront
                        anchors.fill: parent
                        source: modelData.assets ? modelData.assets.boxFront : ""
                        fillMode: Image.PreserveAspectCrop
                        mipmap: true
                        asynchronous: true
                        cache: true
                        sourceSize { width: 200; height: 300 }
                        visible: status === Image.Ready
                        //layer.enabled: delegateRoot.isFocused
                        layer.enabled: gridView.currentIndex === index
                        layer.effect: null
                    }
                }


                Rectangle {
                    id: titlePanel
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 40
                    color: "#aa000000"
                    // Mostrar el título si no hay imagen o si la imagen está cargando
                    visible: !modelData.assets.boxFront || boxFront.status !== Image.Ready

                    Text {
                        anchors.centerIn: parent
                        text: modelData ? modelData.title : ""
                        color: "white"
                        font { family: global.fonts.sans; pixelSize: 14 }
                        elide: Text.ElideRight
                        width: parent.width - 20
                        horizontalAlignment: Text.AlignHCenter
                    }
                }


                Rectangle {
                    id: selectionRect
                    anchors.fill: parent
                    color: "transparent"
                    border.color: "#006dc7"
                    border.width: gridView.currentIndex === index ? 4 : 0
                    visible: gridView.currentIndex === index
                    z: 100
                }
            }
        }
    }
}
