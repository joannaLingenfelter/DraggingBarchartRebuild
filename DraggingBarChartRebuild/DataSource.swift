//
//  DataSource.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 4/25/23.
//

import Foundation

typealias ChartData = (date: Date, value: Double)

class DataSource: ObservableObject {
    let visibleBarCount: Int = 7

    private(set) var upperBound: CGFloat = 0
    private(set) var data: [ChartData] = []

    private let calendar = Calendar(identifier: .gregorian)

    init() {
        setUnitOffset(0)
    }

    func setUnitOffset(_ offset: Int) {
        data = (-visibleBarCount..<(2*visibleBarCount)).map { i -> ChartData in
            let totalOffset = i + offset
            let startOfToday = calendar.startOfDay(for: .now)
            let date = calendar.date(byAdding: .day, value: totalOffset, to: startOfToday)!
            let value = CGFloat(totalOffset).magnitude * CGFloat(10)
            return (date: date, value: value)
        }
        upperBound = data[visibleBarCount..<2*visibleBarCount].map(\.value).max() ?? 0
        objectWillChange.send()
    }

    func indexOfDate(closestTo date: Date) -> ChartData? {
        data.sorted { lhs, rhs in
            if calendar.isDate(date, inSameDayAs: lhs.date) {
                return true
            } else if calendar.isDate(date, inSameDayAs: rhs.date) {
                return false
            } else {
                return lhs.date.timeIntervalSince(date).magnitude < rhs.date.timeIntervalSince(date).magnitude
            }
        }
        .first
    }
}
