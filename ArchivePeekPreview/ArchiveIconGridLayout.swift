import CoreGraphics

/// Layout metrics shared by the SwiftUI icon grid and AppKit click hit-testing.
enum ArchiveIconGridLayout {
    static let horizontalPadding: CGFloat = 16
    static let topPadding: CGFloat = 8
    static let minColumnWidth: CGFloat = 88
    static let maxColumnWidth: CGFloat = 120
    static let columnSpacing: CGFloat = 16
    static let rowSpacing: CGFloat = 28
    static let iconSize: CGFloat = 64
    static let iconLabelSpacing: CGFloat = 6
    static let labelHeight: CGFloat = 34
    static let cellVerticalPadding: CGFloat = 12

    static var cellHeight: CGFloat {
        iconSize + iconLabelSpacing + labelHeight + cellVerticalPadding
    }

    /// Returns the index of the icon cell at `point`, or nil if the click missed every item.
    static func nodeIndex(at point: CGPoint, viewSize: CGSize, nodeCount: Int) -> Int? {
        guard nodeCount > 0 else { return nil }

        let gridWidth = viewSize.width - horizontalPadding * 2
        guard gridWidth > 0 else { return nil }

        let localX = point.x - horizontalPadding
        let localY = point.y - topPadding
        guard localX >= 0, localY >= 0 else { return nil }

        let columnCount = columnCount(for: gridWidth)
        let columnWidth = columnWidth(for: gridWidth, columnCount: columnCount)
        let strideX = columnWidth + columnSpacing
        let strideY = cellHeight + rowSpacing

        let column = Int(localX / strideX)
        let row = Int(localY / strideY)
        guard column >= 0, column < columnCount, row >= 0 else { return nil }

        let cellX = CGFloat(column) * strideX
        let cellY = CGFloat(row) * strideY
        let cellRect = CGRect(x: cellX, y: cellY, width: columnWidth, height: cellHeight)
        guard cellRect.contains(CGPoint(x: localX, y: localY)) else { return nil }

        let index = row * columnCount + column
        guard index >= 0, index < nodeCount else { return nil }
        return index
    }

    private static func columnCount(for gridWidth: CGFloat) -> Int {
        var count = max(1, Int((gridWidth + columnSpacing) / (minColumnWidth + columnSpacing)))
        while columnWidth(for: gridWidth, columnCount: count) > maxColumnWidth {
            count += 1
        }
        return count
    }

    private static func columnWidth(for gridWidth: CGFloat, columnCount: Int) -> CGFloat {
        (gridWidth - CGFloat(columnCount - 1) * columnSpacing) / CGFloat(columnCount)
    }
}
