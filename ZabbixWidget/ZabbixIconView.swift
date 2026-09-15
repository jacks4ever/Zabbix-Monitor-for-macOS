import SwiftUI

/// The Zabbix mark drawn as vector geometry, matching the `ZabbixIcon` artwork the
/// menu bar app uses: a filled rounded tile with the "Z" cut out of it via the
/// even-odd fill rule, so the widget background shows through the letter.
///
/// This is drawn rather than loaded from `Image("ZabbixIcon")` because the bitmap
/// cannot be transparent through the Z — knocking the glyph out of a PNG's alpha
/// channel does not survive WidgetKit's rendering. Building the tile and the glyph
/// as one `Path` with `FillStyle(eoFill: true)` makes the Z a genuine hole in a
/// single shape rather than two composited layers.
///
/// Proportions are measured from the original artwork so the widget and menu bar
/// marks line up: glyph spanning 25%-75% horizontally and 19.5%-80.5% vertically,
/// bars 11.5% of glyph height, diagonal run 26% of glyph width, corner radius 22.5%.
struct ZabbixIconView: View {
    var size: CGFloat = 28

    private let brand = Color(red: 203 / 255, green: 36 / 255, blue: 21 / 255)

    var body: some View {
        ZabbixMark()
            .fill(brand, style: FillStyle(eoFill: true))
            .frame(width: size, height: size)
    }
}

/// Rounded tile with the letter Z subtracted from it.
struct ZabbixMark: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path(
            roundedRect: rect,
            cornerRadius: min(rect.width, rect.height) * 0.225,
            style: .continuous
        )
        path.addPath(letterZ(in: rect))
        return path
    }

    private func letterZ(in rect: CGRect) -> Path {
        let x0 = rect.minX + rect.width * 0.25
        let x1 = rect.minX + rect.width * 0.75
        let y0 = rect.minY + rect.height * 0.195
        let y1 = rect.minY + rect.height * 0.805
        let bar = (y1 - y0) * 0.115     // thickness of the horizontal strokes
        let run = (x1 - x0) * 0.26      // horizontal run of the diagonal stroke

        var path = Path()
        path.move(to: CGPoint(x: x0, y: y0))
        path.addLine(to: CGPoint(x: x1, y: y0))
        path.addLine(to: CGPoint(x: x0 + run, y: y1 - bar))
        path.addLine(to: CGPoint(x: x1, y: y1 - bar))
        path.addLine(to: CGPoint(x: x1, y: y1))
        path.addLine(to: CGPoint(x: x0, y: y1))
        path.addLine(to: CGPoint(x: x1 - run, y: y0 + bar))
        path.addLine(to: CGPoint(x: x0, y: y0 + bar))
        path.closeSubpath()
        return path
    }
}
