//
//  DataSource.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 4/25/23.
//

import Foundation

struct ChartData: Equatable {
    let date: Date
    let value: Double
}

class DataSource: ObservableObject {
    let visibleBarCount: Int = 4

    private(set) var upperBound: CGFloat = 0
    private(set) var data: [ChartData] = []
    private(set) var yAxisMarkValues: [Int] = []

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
            return .init(date: date, value: value)
        }
        upperBound = data[visibleBarCount..<2*visibleBarCount].map(\.value).max() ?? 0
        yAxisMarkValues = (stride(from: 0, through: upperBound, by: upperBound / 3.0).map { $0 } + [upperBound * 1.25]).map(Int.init)
        objectWillChange.send()
    }

    func chartData(closestTo date: Date) -> ChartData? {
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

    func visibleData(of data: ChartData?) -> ChartData? {
        guard let data else { return nil }
        let isPresent = self.data[visibleBarCount..<2*visibleBarCount].contains { value in
            value.date == data.date && value.value == data.value
        }
        guard isPresent else {
            return nil
        }
        return data
    }
}

