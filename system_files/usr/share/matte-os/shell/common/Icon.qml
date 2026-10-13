import QtQuick
import QtQuick.Shapes

// A line icon drawn from SVG path data on a 24 x 24 grid (Lucide-style), so the shell needs no icon font.
Item {
    id: root

    property string path: ""
    property color color: "white"
    property real size: 16
    property real strokeWidth: 1.8
    property bool filled: false

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.filled ? "transparent" : root.color
            strokeWidth: root.filled ? 0 : root.strokeWidth
            fillColor: root.filled ? root.color : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin

            PathSvg {
                path: root.path
            }
        }
    }
}
