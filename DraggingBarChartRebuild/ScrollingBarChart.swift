//
//  ScrollingChart.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 4/21/23.
//

import SwiftUI
import Charts

class DataSource: ObservableObject {
    let visibleBarCount: Int = 7
    let barWidth: CGFloat = 24

    private(set) var upperBound: CGFloat = 0
    private(set) var data: [(date: Date, value: Double)] = []

    private let calendar: Calendar = {
        Calendar.init(identifier: .gregorian)
    }()

    init() {
        setUnitOffset(0)
    }


    func setUnitOffset(_ offset: Int) {
        let initDate = calendar.startOfDay(for: Date().addingTimeInterval(TimeInterval(offset + 1 * 24 * 3600)))
        data = (-visibleBarCount..<(2*visibleBarCount)).map { i in
            return (date: initDate.addingTimeInterval(Double(i) * Double(24) * Double(3600)), value: abs(CGFloat(i + offset) * CGFloat(10)))
        }
        upperBound = data[visibleBarCount..<2*visibleBarCount].map(\.value).max() ?? 0
        objectWillChange.send()
    }
}

struct ScrollingBarChart: View {
    @Environment(\.locale) private var locale

    private let pagingAnimationDuration: CGFloat = 1.2

    @StateObject
    private var dataSource = DataSource()

    @State
    private var currentUnitOffset: Int = .zero

    @State
    private var chartContentOffset: CGFloat = .zero

    @State
    private var chartContentWidth: CGFloat = .zero {
        didSet {
            print("*** chartContentWidth: \(chartContentWidth)")
        }
    }

    @GestureState
    private var translation: CGFloat = .zero

    private var unitWidth: CGFloat {
        let barCount: Double = Double(dataSource.visibleBarCount)
        let usedBarSpace = barCount * dataSource.barWidth
        let remainingSpace = chartContentWidth - usedBarSpace
        print("*** chartContentWidth: \(chartContentWidth)")
        let spaceBetweenBars = remainingSpace/barCount
        print("*** spaceBetweenBars: \(spaceBetweenBars)")
        let unitWidth = spaceBetweenBars + dataSource.barWidth
        print("*** unitWidth: \(unitWidth)")
        return unitWidth
    }

    private var drag: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($translation) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                chartContentOffset += value.translation.width

                let binCount = CGFloat(dataSource.visibleBarCount)

                let unitOffset = (value.translation.width / unitWidth).rounded(.toNearestOrEven)
                print("*** translation: \(value.translation.width)")
                print("*** unitOffset: \(unitOffset)")
                var predictedUnitOffset = (value.predictedEndTranslation.width / unitWidth).rounded(.toNearestOrAwayFromZero)

                 // If swipe carefully, change to the nearest time unit
                 // If swipe fast enough, change to the next page
                predictedUnitOffset = max(-binCount, min(binCount, predictedUnitOffset))
                print("*** predictedOffset: \(predictedUnitOffset)")
                withAnimation(.easeOut(duration: pagingAnimationDuration)) {
                    if predictedUnitOffset.magnitude >= Double(dataSource.visibleBarCount) {
                        chartContentOffset = predictedUnitOffset * unitWidth
                    } else {
                        chartContentOffset = unitOffset * unitWidth
                    }

                }

                currentUnitOffset -= Int(chartContentOffset / unitWidth)

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(pagingAnimationDuration))
                    dataSource.setUnitOffset(currentUnitOffset)
                    chartContentOffset = 0
                }
            }
    }

    var body: some View {
        GeometryReader { containerGeometry in
            HStack(spacing: 0) {
                GeometryReader { chartGeometry in
                    ScrollView(.horizontal) {
                        Chart {
                            chart
                        }
                        .chartXAxis {
                            AxisMarks(
                                format: .dateTime.weekday().locale(locale),
                                preset: .extended,
                                values: .stride(by: .day)
                            )
                        }
                        .chartYAxis {
                            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) {
                                AxisGridLine()
                            }
                        }
                        .offset(x: chartContentOffset - chartGeometry.size.width)
                        .offset(x: translation)
                        .frame(
                            width: chartGeometry.size.width * 3,
                            height: containerGeometry.size.height
                        )
                        .gesture(drag)
                    }
                    .frame(
                        width: chartGeometry.size.width,
                        height: chartGeometry.size.height,
                        alignment: .leading
                    )
                    .measuring(\.size.width, assign: $chartContentWidth)
                }

                chartYAxis
            }
            .frame(height: containerGeometry.size.height)
        }
    }

    private var chart: some ChartContent {
        ForEach(dataSource.data, id: \.date) { item in
            BarMark(
                x: .value("Day", item.date, unit: .weekday),
                y: .value("Value", min(item.value, dataSource.upperBound)),
                width: .fixed(dataSource.barWidth)
            )
        }
    }

    private var chartYAxis: some View {
        Chart {
            chart
        }
        .foregroundStyle(.clear)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 4))
        }
        .chartPlotStyle { plot in
            plot.frame(width: 0)
        }
    }
}


struct ScrollingBarChart_Previews: PreviewProvider {
    static var previews: some View {
        ScrollingBarChart()
    }
}
