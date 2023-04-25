//
//  TestBarChart.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 4/21/23.
//

import SwiftUI
import Charts

struct BarChart: View {
    @Binding var unitOffset: Int
    @State var upperBound: Double?

    init(unitOffset: Binding<Int>) {
        self._unitOffset = unitOffset
    }

    private let calendar: Calendar = {
        Calendar.init(identifier: .gregorian)
    }()

    private var initDate: Date {
        calendar.startOfDay(for: Date().addingTimeInterval(TimeInterval(unitOffset * 24 * 3600)))
    }

    private var data: [(date: Date, value: Double)] {
        return (-7..<14).map { i in
            (date: initDate.addingTimeInterval(Double(i) * 24 * 3600), value: abs(Double(i + unitOffset) * 10))
        }
    }

    var body: some View {
        Chart {
            ForEach(data, id: \.date) { item in
                BarMark(
                    x: .value("Day", item.date, unit: .weekday),
                    y: .value("Value", min(item.value, upperBound ?? item.value))
                )
            }
        }
        .onAppear {
            upperBound = data[7..<14].map(\.value).max()
        }
        .onChange(of: unitOffset) { newValue in
            withAnimation(.spring()) {
                upperBound = data[7..<14].map(\.value).max()
            }
        }
    }
}
