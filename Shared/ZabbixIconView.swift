import SwiftUI
import WidgetKit

/// The Zabbix mark drawn as vector geometry, shared by the widget and the menu bar
/// app so the two always match.
///
/// Drawn rather than loaded from `Image("ZabbixIcon")` because the bitmap cannot be
/// transparent through the Z: knocking the glyph out of a PNG's alpha channel does
/// not survive WidgetKit's rendering. Building the tile and the glyph into one
/// `Path` filled with the even-odd rule makes the Z a genuine hole in a single
/// shape rather than two composited layers.
struct ZabbixIconView: View {
    /// How the Z itself is rendered.
    enum GlyphStyle {
        /// Cut out of the tile, so whatever is behind shows through.
        case knockout
        /// Painted on top of the tile. Used in the app, where the popover material
        /// behind it is translucent and a hole would show the desktop through it.
        case filled(Color)
        /// Solid white in full colour, knocked out otherwise.
        ///
        /// In WidgetKit's vibrant and accented modes the system draws content as
        /// monochrome ink, so a painted white glyph disappears into the tile and
        /// the mark collapses into a featureless block. The knockout is what keeps
        /// the Z legible there. In full colour a painted glyph looks better and
        /// matches the menu bar, so pick per mode.
        case automatic
    }

    var size: CGFloat = 28
    var glyph: GlyphStyle = .automatic

    @Environment(\.widgetRenderingMode) private var renderingMode

    private let brand = Color(red: 203 / 255, green: 36 / 255, blue: 21 / 255)

    /// Resolves `.automatic` against the current rendering mode. Outside a widget
    /// the environment value is `.fullColor`, so the app gets the painted glyph.
    private var resolvedGlyph: GlyphStyle {
        guard case .automatic = glyph else { return glyph }
        return renderingMode == .fullColor ? .filled(.white) : .knockout
    }

    var body: some View {
        Group {
            if case .filled(let color) = resolvedGlyph {
                ZStack {
                    RoundedRectangle(cornerRadius: size * ZabbixMark.cornerRadiusRatio, style: .continuous)
                        .fill(brand)
                    ZabbixLetterZ()
                        .fill(color)
                }
            } else {
                ZabbixMark()
                    .fill(brand, style: FillStyle(eoFill: true))
            }
        }
        .frame(width: size, height: size)
    }
}

/// The rounded tile with the letter Z subtracted from it (via `eoFill`).
struct ZabbixMark: Shape {
    static let cornerRadiusRatio: CGFloat = 0.225

    func path(in rect: CGRect) -> Path {
        var path = Path(
            roundedRect: rect,
            cornerRadius: min(rect.width, rect.height) * Self.cornerRadiusRatio,
            style: .continuous
        )
        path.addPath(ZabbixLetterZ().path(in: rect))
        return path
    }
}

/// The letter Z as a closed polygon.
///
/// Proportions measured from the original artwork: glyph spans 25%-75%
/// horizontally and 19.5%-80.5% vertically, with bars 11.5% of glyph height.
///
/// Both ends of each bar are squared off with vertical edges. Running the diagonal
/// straight out of the top-right and bottom-left corners instead leaves sharp
/// points there, which is what the earlier version did.
struct ZabbixLetterZ: Shape {
    func path(in rect: CGRect) -> Path {
        let x0 = rect.minX + rect.width * 0.25
        let x1 = rect.minX + rect.width * 0.75
        let y0 = rect.minY + rect.height * 0.195
        let y1 = rect.minY + rect.height * 0.805
        let bar = (y1 - y0) * 0.115     // thickness of the horizontal strokes
        // Horizontal run of the diagonal. Chosen so the diagonal's vertical
        // thickness matches the original artwork now that the squared ends have
        // shortened it by one bar at each end.
        let run = (x1 - x0) * 0.21

        var path = Path()
        path.move(to: CGPoint(x: x0, y: y0))
        path.addLine(to: CGPoint(x: x1, y: y0))
        path.addLine(to: CGPoint(x: x1, y: y0 + bar))       // squared top-right end
        path.addLine(to: CGPoint(x: x0 + run, y: y1 - bar)) // diagonal, outer edge
        path.addLine(to: CGPoint(x: x1, y: y1 - bar))
        path.addLine(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x0, y: y1))
        path.addLine(to: CGPoint(x: x0, y: y1 - bar))       // squared bottom-left end
        path.addLine(to: CGPoint(x: x1 - run, y: y0 + bar)) // diagonal, inner edge
        path.addLine(to: CGPoint(x: x0, y: y0 + bar))
        path.closeSubpath()
        return path
    }
}
