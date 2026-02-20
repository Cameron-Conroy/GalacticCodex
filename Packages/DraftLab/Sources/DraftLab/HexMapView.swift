import SwiftUI

/// Renders a 5-tile slice as a hex strip preview using SwiftUI Canvas.
public struct HexMapView: View {
    public let tiles: [SliceTile]
    public let highlightedTiles: Set<Int>
    public var tileSize: CGFloat

    public init(tiles: [SliceTile], highlightedTiles: Set<Int> = [], tileSize: CGFloat = 40) {
        self.tiles = tiles
        self.highlightedTiles = highlightedTiles
        self.tileSize = tileSize
    }

    public var body: some View {
        Canvas { context, size in
            let centerY = size.height / 2
            let spacing = tileSize * 1.8
            let startX = (size.width - spacing * CGFloat(tiles.count - 1)) / 2

            for (index, tile) in tiles.enumerated() {
                let center = CGPoint(x: startX + CGFloat(index) * spacing, y: centerY)
                let highlighted = highlightedTiles.contains(tile.tileNumber)
                drawHex(context: context, center: center, size: tileSize, tile: tile, highlighted: highlighted)
            }
        }
        .frame(height: tileSize * 2.5)
    }

    private func drawHex(context: GraphicsContext, center: CGPoint, size: CGFloat, tile: SliceTile, highlighted: Bool) {
        let path = hexPath(center: center, size: size)

        let fillColor: Color = if highlighted {
            .yellow.opacity(0.3)
        } else if tile.planets.isEmpty {
            .red.opacity(0.25)
        } else {
            .blue.opacity(0.2)
        }

        context.fill(path, with: .color(fillColor))
        context.stroke(path, with: .color(highlighted ? .yellow : .gray), lineWidth: highlighted ? 2 : 1)

        let res = tile.planets.reduce(0) { $0 + $1.resources }
        let inf = tile.planets.reduce(0) { $0 + $1.influence }
        let label = "\(res)/\(inf)"
        context.draw(
            Text(label).font(.system(size: size * 0.3)).foregroundStyle(.primary),
            at: center
        )
    }

    private func hexPath(center: CGPoint, size: CGFloat) -> Path {
        Path { path in
            for i in 0..<6 {
                let angle = CGFloat(i) * .pi / 3 - .pi / 6
                let point = CGPoint(
                    x: center.x + size * cos(angle),
                    y: center.y + size * sin(angle)
                )
                if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
            }
            path.closeSubpath()
        }
    }
}
