//
//  ContentView.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 4/21/23.
//

import SwiftUI
import Charts

struct ContentView: View {
    @State private var unitOffset: Int = 0
    @State var upperBound: Double?

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
        ScrollingBarChart()
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
