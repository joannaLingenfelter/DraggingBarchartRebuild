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

struct Payment: Identifiable, Equatable {
    let dueDate: Date
    let plans: [Plan]
    let id = UUID()

    var totalPaymentAmount: Double {
        plans.map(\.minimumMonthlyPaymentAmount).reduce(0, +)
    }
}

struct Plan: Identifiable, Equatable {
    let paymentDates: [Date]
    let minimumMonthlyPaymentAmount: Double
    let id = UUID()
    let name: String
}

class DataSource: ObservableObject {
    let visibleBarCount: Int = 4

    private(set) var upperBound: CGFloat = 0
    private(set) var data: [Payment] = []
    private(set) var yAxisMarkValues: [Int] = []

    private let calendar = Calendar(identifier: .gregorian)

    init() {
        setUnitOffset(0)
    }

    func setUnitOffset(_ offset: Int) {
        data = (-visibleBarCount..<(2*visibleBarCount)).map { i -> Payment in
            let totalOffset = i + offset
            let startOfToday = calendar.startOfDay(for: .now)
            let paymentDueDate = calendar.date(byAdding: .month, value: totalOffset, to: startOfToday)!

            let value = CGFloat(totalOffset).magnitude * CGFloat(10)
            let numberOfPlans = min(totalOffset.magnitude, 5)
            var plans: [Plan] = []
            for i in 0...numberOfPlans {
                let minimumAmount = CGFloat(totalOffset).magnitude * CGFloat(10) + CGFloat(25.0 * CGFloat(i))
                var paymentDueDates: [Date] {
                    let date1 = paymentDueDate
                    let date2 = calendar.date(byAdding: .month, value: offset, to: date1)!
                    let date3 = calendar.date(byAdding: .month, value: offset, to: date2)!
                    let date4 = calendar.date(byAdding: .month, value: offset, to: date3)!

                    return [date1, date2, date3, date4]
                }

                let plan = Plan(paymentDates: paymentDueDates, minimumMonthlyPaymentAmount: minimumAmount, name: "Plan \(i)")
                plans.append(plan)
            }

            return .init(dueDate: paymentDueDate, plans: plans)
        }
        upperBound = data[visibleBarCount..<2*visibleBarCount].map(\.totalPaymentAmount).max() ?? 0
        print("***upper bound: \(upperBound)")
        yAxisMarkValues = (stride(from: 0, through: upperBound, by: upperBound / 3.0).map { $0 } + [upperBound * 1.25]).map(Int.init)
        objectWillChange.send()
    }

    func indexOfDate(closestTo date: Date) -> Payment? {
        data.sorted { lhs, rhs in
            if calendar.isDate(date, inSameDayAs: lhs.dueDate) {
                return true
            } else if calendar.isDate(date, inSameDayAs: rhs.dueDate) {
                return false
            } else {
                return lhs.dueDate.timeIntervalSince(date).magnitude < rhs.dueDate.timeIntervalSince(date).magnitude
            }
        }
        .first
    }

    func visibleData(of data: Payment?) -> Payment? {
        guard let data else { return nil }
        let isPresent = self.data[visibleBarCount..<2*visibleBarCount].contains { value in
            value.dueDate == data.dueDate
        }
        guard isPresent else {
            return nil
        }
        return data
    }
}
