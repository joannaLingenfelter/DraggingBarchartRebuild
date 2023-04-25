//
//  DataSource.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 4/25/23.
//

import Foundation

class DataSource: ObservableObject {
    let visibleBarCount: Int = 7

    private(set) var upperBound: CGFloat = 0
    private(set) var data: [(date: Date, value: Double)] = []

    private let calendar = Calendar(identifier: .gregorian)

    init() {
        setUnitOffset(0)
    }

    func setUnitOffset(_ offset: Int) {
        data = (-visibleBarCount..<(2*visibleBarCount)).map { i -> (date: Date, value: Double) in
            let totalOffset = i + offset
            let startOfToday = calendar.startOfDay(for: .now)
            let date = calendar.date(byAdding: .day, value: totalOffset, to: startOfToday)!
            let value = CGFloat(totalOffset).magnitude * CGFloat(10)
            return (date: date, value: value)
        }
        upperBound = data[visibleBarCount..<2*visibleBarCount].map(\.value).max() ?? 0
        objectWillChange.send()
    }
}
