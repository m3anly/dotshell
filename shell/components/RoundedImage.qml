import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property alias source: picture.source
    property alias sourceSize: picture.sourceSize
    property alias asynchronous: picture.asynchronous
    property alias cache: picture.cache
    property real radius: 0
    readonly property alias status: picture.status
    readonly property Image image: picture

    Image {
        id: picture

        readonly property real ratio: implicitHeight > 0 ? implicitWidth / implicitHeight : 1

        width: Math.max(root.width, root.height * ratio)
        height: Math.max(root.height, root.width / ratio)
        x: (root.width - width) / 2
        y: (root.height - height) / 2
        fillMode: Image.PreserveAspectCrop
        opacity: 0
    }

    Shape {
        anchors.fill: parent
        visible: picture.status === Image.Ready
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillItem: picture
            fillTransform: PlanarTransform.fromAffineMatrix(picture.width / Math.max(1, picture.implicitWidth), 0, 0, picture.height / Math.max(1, picture.implicitHeight), picture.x, picture.y)

            PathRectangle {
                width: root.width
                height: root.height
                radius: root.radius
            }
        }
    }
}
