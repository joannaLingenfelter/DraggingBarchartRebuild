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
    fileprivate(set) var isVirtual = false
}

class DataSource: ObservableObject {
    let visibleBarCount: Int = 4

    private let allData: [ChartData]

    private(set) var upperBound: CGFloat = 0
    private(set) var data: [ChartData] = []
//    private(set) var yAxisMarkValues: [Int] = []

    private static let calendar = Calendar(identifier: .gregorian)

    private var calendar: Calendar {
        DataSource.calendar
    }

    init() {
        allData = (0 ..< 24).map { offset -> ChartData in
            let startOfToday = DataSource.calendar.startOfDay(for: .now)
            let date = DataSource.calendar.date(byAdding: .day, value: offset, to: startOfToday)!
            let value = CGFloat(offset).magnitude * CGFloat(10)
            return .init(date: date, value: value)
        }
        setLeadingVisibleData(allData.first!)
    }

    func setLeadingVisibleData(_ initialData: ChartData) {
        print("*** setLeadingVisibleData:")
        print("***    - initial: \(initialData.date.formatted(.dateTime.day().month().year()))")
        guard let index = self.allData.firstIndex(of: initialData) else {
            return
        }
        print("***    - index: \(index)")
        let desiredRange = (index - visibleBarCount) ..< (index + 2 * visibleBarCount)

        print("***    - desiredRange: \(desiredRange)")
//        var clampedRange = desiredRange.clamped(to: allData.indices)
//        if clampedRange.count < 3 * visibleBarCount {
//            clampedRange = clampedRange.lowerBound ..< clampedRange.lowerBound + (3 * visibleBarCount)
////            clampedRange.upperBound += (3 * visibleBarCount) - clampedRange.count
//        }
//        print("***    - clampedRange: \(clampedRange)")

//        var newData = [ChartData]()
//        let leadingDifference = max(clampedRange.lowerBound - desiredRange.lowerBound, 0)
//        for index in (0..<leadingDifference) {
//            newData.insert(ChartData(date: <#T##Date#>, value: <#T##Double#>), at: <#T##Int#>)
//        }
        data = desiredRange.map { index in
            if allData.indices.contains(index) {
                print("*** Got a match: \(index)")
                return allData[index]
            } else {
                print("*** No match: \(index)")
                let startOfToday = DataSource.calendar.startOfDay(for: .now)
                let date = DataSource.calendar.date(byAdding: .day, value: index, to: startOfToday)!
                return ChartData(date: date, value: 0.0, isVirtual: true)
            }
        }
        print("***    - data.count: \(data.count)")

        let visibleData = data.filter { !$0.isVirtual }.prefix(visibleBarCount)
        upperBound = visibleData.map(\.value).max() ?? .zero
        print("***    - upperBound: \(upperBound)")
        
//        data = (0..<(3*visibleBarCount)).map { i -> ChartData in
//            let totalOffset = i + offset
//            let startOfToday = calendar.startOfDay(for: .now)
//            let date = calendar.date(byAdding: .day, value: totalOffset, to: startOfToday)!
//            let value = CGFloat(totalOffset).magnitude * CGFloat(10)
//            return .init(date: date, value: value)
//        }
//        upperBound = data[0..<visibleBarCount].map(\.value).max() ?? 0
//        yAxisMarkValues = (stride(from: 0, through: upperBound, by: upperBound / 3.0).map { $0 } + [upperBound * 1.25]).map(Int.init)
        objectWillChange.send()
    }

//    private func data(for offset: Int) -> [ChartData] {
//        (0..<(3*visibleBarCount)).map { i -> ChartData in
//            let totalOffset = i + offset
//            let startOfToday = calendar.startOfDay(for: .now)
//            let date = calendar.date(byAdding: .day, value: totalOffset, to: startOfToday)!
//            let value = CGFloat(totalOffset).magnitude * CGFloat(10)
//            return .init(date: date, value: value)
//        }
//    }

//    private func indexOfChartData(_ data: ChartData) -> Int? {
//        self.data.firstIndex(of: data)
//    }

    func chartData(closestTo date: Date) -> ChartData? {
        allData.sorted { lhs, rhs in
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
        let isPresent = self.data.contains { value in
            value.date == data.date && value.value == data.value
        }
        guard isPresent else {
            return nil
        }
        return data
    }
}

