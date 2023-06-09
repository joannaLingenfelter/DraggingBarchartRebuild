//
//  ScrollingChart.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 4/21/23.
//


import SwiftUI
import Charts

//extension ChartContent {
//    func foregroundStyle<D: Plottable>(by value: PlottableValue<D>?) -> some ChartContent {
//        if let value {
//            return self.foregroundStyle(by: value)
//        }
//
//        return self
//    }
//}

struct ScrollingBarChart: View {
    @Environment(\.locale) private var locale

    @StateObject
    private var dataSource = DataSource()

    @State
    private var currentUnitOffset: Int = .zero

    @State
    private var chartContentOffset: CGFloat = .zero

    @State
    private var animatedUpperBound: CGFloat = .zero

    @State
    private var selectedChartData: Payment?

    @GestureState
    private var translation: CGFloat = .zero

    private let pagingAnimationDuration: CGFloat = 0.2
    private let barWidth: CGFloat = 32

    private var artificialUpperBound: Int {
        Int(animatedUpperBound * 1.5)
    }

    private func dragGesture(contentWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0.5)
            .updating($translation) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                chartContentOffset += value.translation.width

                let barCount = Double(dataSource.visibleBarCount)
                let unitWidth = contentWidth / barCount

                let unitOffset = (value.translation.width / unitWidth).rounded(.toNearestOrAwayFromZero)
                var predictedUnitOffset = (value.predictedEndTranslation.width / unitWidth).rounded(.toNearestOrAwayFromZero)

                predictedUnitOffset = max(-barCount, min(barCount, predictedUnitOffset))

                withAnimation(.easeOut(duration: pagingAnimationDuration)) {
                    if predictedUnitOffset.magnitude >= Double(dataSource.visibleBarCount) {
                        chartContentOffset = predictedUnitOffset * unitWidth
                    } else {
                        chartContentOffset = unitOffset * unitWidth
                    }
                }

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(pagingAnimationDuration))
                    currentUnitOffset -= Int(chartContentOffset / unitWidth)
                    dataSource.setUnitOffset(currentUnitOffset)
                    chartContentOffset = 0
                }
            }
    }


    @ChartContentBuilder
    func chart(showsBars: Bool) -> some ChartContent {
        ForEach(dataSource.data) { payment in
            ForEach(payment.plans) { plan in

                let barMark = BarMark(
                    x: .value("Day", payment.dueDate, unit: .month),
                    y: .value("Value", min(plan.minimumMonthlyPaymentAmount, animatedUpperBound)),
                    width: .fixed(barWidth),
                    stacking: .standard
                )

                if showsBars {
                    barMark
                        .foregroundStyle(by: .value("Plan Name", plan.name))
                } else {
                    barMark
                }
            }
        }
    }

    private var chartYAxis: some View {
        Chart {
            chart(showsBars: false)
        }
        .chartYScale(domain: 0 ... artificialUpperBound)
        .foregroundStyle(.clear)
        .chartYAxis {
            AxisMarks(
                position: .trailing,
                values: .automatic(desiredCount: 4)
            )
        }
        .chartPlotStyle { plot in
            plot.frame(width: 0)
        }
    }

    @State
    private var isLollipopVisible = false

    @State
    private var animatedSelectedContent: Payment?

    var body: some View {
        GeometryReader { containerGeometry in
            HStack(spacing: 0) {
                GeometryReader { chartGeometry in
                    ScrollView(.horizontal) {
                        Chart {
                            chart(showsBars: true)
                        }
                        .chartYScale(domain: 0 ... artificialUpperBound)
                        .chartXAxis {
                            AxisMarks(
                                format: .dateTime.month().locale(locale),
                                preset: .extended,
                                values: .stride(by: .month)
                            )
                        }
                        .chartYAxis {
                            AxisMarks(
                                position: .trailing,
                                values: .automatic(desiredCount: 4))
                            {
                                AxisGridLine()
                            }
                        }
                        .offset(x: chartContentOffset - chartGeometry.size.width)
                        .offset(x: translation)
                        .frame(
                            width: chartGeometry.size.width * 3,
                            height: containerGeometry.size.height
                        )
                        .chartLegend(alignment:.center)
                        .chartOverlay(alignment: .topLeading) { chart in
                            GeometryReader { geometry in
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture(coordinateSpace: .local) { location in
                                        let originX = geometry[chart.plotAreaFrame].origin.x
                                        let clampedLocationX = min(max(location.x, 0), geometry.size.width)
                                        let currentX = clampedLocationX - originX

                                        if let selectedDate = chart.value(atX: currentX, as: Date.self),
                                           let selectedBar = dataSource.indexOfDate(closestTo: selectedDate) {
                                            if let selectedChartData {
                                                if selectedBar == selectedChartData {
                                                    self.selectedChartData = nil
                                                } else {
                                                    self.selectedChartData = selectedBar
                                                }
                                            } else {
                                                self.selectedChartData = selectedBar
                                            }
                                        }
                                    }
                                    .simultaneousGesture(dragGesture(contentWidth: chartGeometry.size.width))
                            }
                        }
                        .chartOverlay { chart in
                            if let selectedChartData = dataSource.visibleData(of: animatedSelectedContent) {
                                let unitWidth = unitWidth(contentWidth: chartGeometry.size.width)
                                LollipopOverlay(
                                    selectedChartData: selectedChartData,
                                    chart: chart,
                                    containerSize: chartGeometry.size,
                                    unitWidth: unitWidth
                                )
                                .opacity(isLollipopVisible ? 1.0 : 0.0)
                            }
                        }
                        .animating(changeOf: dataSource.upperBound,
                                   into: $animatedUpperBound,
                                   animation: .spring())
                        .animating(changeOf: selectedChartData,
                                   into: $animatedSelectedContent,
                                   filter: { (oldValue, newValue) in
                                        [oldValue, newValue].contains(nil)
                                   },
                                   animation: .easeInOut)
                        .animating(changeOf: selectedChartData,
                                   into: $isLollipopVisible,
                                   using: { value in
                                        value != nil
                                   },
                                   animation: .easeInOut)
                    }
                    .scrollDisabled(true)
                    .frame(
                        width: chartGeometry.size.width,
                        height: chartGeometry.size.height,
                        alignment: .leading
                    )
                    .coordinateSpace(name: "Chart")
                }
                chartYAxis
            }
            .frame(height: containerGeometry.size.height)
        }
    }

    private func unitWidth(contentWidth: CGFloat) -> CGFloat {
        contentWidth / Double(dataSource.visibleBarCount)
    }
}

struct ScrollingBarChart_Previews: PreviewProvider {
    static var previews: some View {
        ScrollingBarChart()
            .frame(height: 300)
            .scenePadding(.horizontal)
    }
}
