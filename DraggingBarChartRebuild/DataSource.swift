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
    private(set) var slicedData: [ChartData] = []

    private static let calendar = Calendar(identifier: .gregorian)

    private var calendar: Calendar {
        DataSource.calendar
    }

    private static var startOfCurrentMonth: Date {
        let firstOfMonthComponents = DateComponents(day: 1, hour: 0)
        let startOfMonth = DataSource.calendar.nextDate(after: .now,
                                                        matching: firstOfMonthComponents,
                                                        matchingPolicy: .nextTime,
                                                        direction: .backward)!
        return startOfMonth
    }

    init() {
        allData = (0 ..< 24).map { offset -> ChartData in
            let startOfMonth = DataSource.startOfCurrentMonth
            let date = DataSource.calendar.date(byAdding: .month, value: offset, to: startOfMonth)!
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

        slicedData = desiredRange.map { index in
            if allData.indices.contains(index) {
                print("*** Got a match: \(index)")
                return allData[index]
            } else {
                print("*** No match: \(index)")
                let startOfMonth = DataSource.startOfCurrentMonth
                let date = DataSource.calendar.date(byAdding: .month, value: index, to: startOfMonth)!
                return ChartData(date: date, value: 0.0, isVirtual: true)
            }
        }
        print("***    - data.count: \(slicedData.count)")

        let calculatedUpperBound = slicedData.filter { !$0.isVirtual }.map(\.value).max() ?? .zero

        // Layout warning happens even when this is commented out
        upperBound = calculatedUpperBound
        print("***    - upperBound: \(upperBound)")

        objectWillChange.send()
    }

    func chartData(closestTo date: Date, granularity: Calendar.Component = .month) -> ChartData? {
        allData.sorted { lhs, rhs in
            let deltaLhs = calendar.dateComponents([granularity], from: lhs.date, to: date)
            let deltaRhs = calendar.dateComponents([granularity], from: rhs.date, to: date)
            return deltaLhs.value(for: granularity)!.magnitude < deltaRhs.value(for: granularity)!.magnitude
        }
        .first
    }

    func visibleData(of data: ChartData?) -> ChartData? {
        guard let data else { return nil }
        let isPresent = self.slicedData.contains { value in
            value.date == data.date && value.value == data.value
        }
        guard isPresent else {
            return nil
        }
        return data
    }

    func leadingEdgeLastAvailableDate() -> ChartData? {
        guard let lastIndex = self.allData.indices.last else {
            return nil
        }
        guard let leadingLastIndex = self.allData.index(lastIndex, offsetBy: -visibleBarCount + 1, limitedBy: 0) else {
            return nil
        }
        let result = self.allData[leadingLastIndex]
        return result
    }
}

