import SwiftUI

struct IntegratedIslandShellShape: InsettableShape {
    var compactWidth: CGFloat
    var headerHeight: CGFloat
    var topCornerRadius: CGFloat = 7
    var headerBottomCornerRadius: CGFloat = 12
    var panelCornerRadius: CGFloat = 22
    var transitionDepth: CGFloat = 24
    var shoulderCutInset: CGFloat = 28
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let effectiveCompactWidth = min(max(0, compactWidth - (insetAmount * 2)), insetRect.width)
        let effectiveHeaderHeight = min(max(0, headerHeight - insetAmount), insetRect.height)
        let compactLeft = insetRect.midX - (effectiveCompactWidth / 2)
        let compactRight = insetRect.midX + (effectiveCompactWidth / 2)
        let headerBottom = insetRect.minY + effectiveHeaderHeight
        let transitionY = min(insetRect.maxY - panelCornerRadius, headerBottom + transitionDepth)

        let topRadius = min(topCornerRadius, effectiveCompactWidth / 2, effectiveHeaderHeight / 2)
        let headerBottomRadius = min(
            headerBottomCornerRadius,
            effectiveCompactWidth / 2,
            max(0, transitionY - headerBottom)
        )
        let bottomRadius = min(panelCornerRadius, insetRect.width / 2, insetRect.height / 2)
        let maxShoulderRun = max(0, (insetRect.maxX - compactRight) - bottomRadius)
        let shoulderRun = min(maxShoulderRun, max(0, shoulderCutInset - insetAmount))
        let rightShoulderEnd = CGPoint(x: compactRight + headerBottomRadius + shoulderRun, y: transitionY)
        let leftShoulderStart = CGPoint(x: compactLeft - headerBottomRadius, y: headerBottom)
        let leftShoulderEnd = CGPoint(x: compactLeft - headerBottomRadius - shoulderRun, y: transitionY)

        var path = Path()
        path.move(to: CGPoint(x: compactLeft + topRadius, y: insetRect.minY))
        path.addLine(to: CGPoint(x: compactRight - topRadius, y: insetRect.minY))
        path.addQuadCurve(
            to: CGPoint(x: compactRight, y: insetRect.minY + topRadius),
            control: CGPoint(x: compactRight, y: insetRect.minY)
        )
        path.addLine(to: CGPoint(x: compactRight, y: headerBottom - headerBottomRadius))
        path.addQuadCurve(
            to: CGPoint(x: compactRight + headerBottomRadius, y: headerBottom),
            control: CGPoint(x: compactRight, y: headerBottom)
        )
        path.addLine(to: rightShoulderEnd)
        path.addLine(to: CGPoint(x: insetRect.maxX, y: transitionY))
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - bottomRadius))
        path.addQuadCurve(
            to: CGPoint(x: insetRect.maxX - bottomRadius, y: insetRect.maxY),
            control: CGPoint(x: insetRect.maxX, y: insetRect.maxY)
        )
        path.addLine(to: CGPoint(x: insetRect.minX + bottomRadius, y: insetRect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: insetRect.minX, y: insetRect.maxY - bottomRadius),
            control: CGPoint(x: insetRect.minX, y: insetRect.maxY)
        )
        path.addLine(to: CGPoint(x: insetRect.minX, y: transitionY))
        path.addLine(to: leftShoulderEnd)
        path.addLine(to: leftShoulderStart)
        path.addQuadCurve(
            to: CGPoint(x: compactLeft, y: headerBottom - headerBottomRadius),
            control: CGPoint(x: compactLeft, y: headerBottom)
        )
        path.addLine(to: CGPoint(x: compactLeft, y: insetRect.minY + topRadius))
        path.addQuadCurve(
            to: CGPoint(x: compactLeft + topRadius, y: insetRect.minY),
            control: CGPoint(x: compactLeft, y: insetRect.minY)
        )
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}
