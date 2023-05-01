//
//  CGRect+Translations.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 5/1/23.
//

import Foundation

extension CGRect {

    func translatedBy(x: CGFloat, y: CGFloat = .zero) -> CGRect {
        self.applying(.identity.translatedBy(x: x, y: y))
    }

    func translatedBy(y: CGFloat) -> CGRect {
        self.applying(.identity.translatedBy(x: .zero, y: y))
    }

    mutating func translateBy(x: CGFloat, y: CGFloat = .zero) {
        self = self.translatedBy(x: x, y: y)
    }

    mutating func translateBy(y: CGFloat) {
        self.translateBy(x: .zero, y: y)
    }

    mutating func insettingBy(dx: CGFloat, dy: CGFloat = .zero) {
        self = self.insetBy(dx: dx, dy: dy)
    }

    mutating func insettingBy(dy: CGFloat) {
        self.insettingBy(dx: .zero, dy: dy)
    }
}
