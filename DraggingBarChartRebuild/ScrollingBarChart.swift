//
//  ScrollingChart.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 4/21/23.
//


import SwiftUI
import Charts

struct AnnotationBoundsPreferenceKey: PreferenceKey {
    static var defaultValue: Anchor<CGRect>? = nil

    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        if let nextValue = nextValue() {
            value = nextValue
        }
    }
}

struct ScrollingBarChart: View {
    @Environment(\.locale) private var locale

    private let pagingAnimationDuration: CGFloat = 0.2

    @StateObject
    private var dataSource = DataSource()

    @State
    private var currentUnitOffset: Int = .zero

    @State
    private var chartContentOffset: CGFloat = .zero

    @State
    private var animatedUpperBound: CGFloat = .zero

    @GestureState
    private var translation: CGFloat = .zero

    @State
    private var selectedChartData: ChartData?

    private func dragGesture(contentWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0.5)
            .updating($translation) { value, state, _ in
                state = value.translation.width
            }
            .onChanged { _ in
                guard selectedChartData == nil else {
                    selectedChartData = nil
                    return
                }
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

    var chart: some ChartContent {
        ForEach(dataSource.data, id: \.date) { item in
            BarMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Value", min(item.value, animatedUpperBound)),
                width: 24,
                stacking: .unstacked
            )

            BarMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Value", min(item.value, animatedUpperBound) * 1.25),
                width: 0,
                stacking: .unstacked
            )
            .accessibilityHidden(true)
        }
    }

    private var chartYAxis: some View {
        Chart {
            chart
        }
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
                        .chartOverlay { chart in
                            interactiveChartContent(chart: chart) { selectedBar in
                                ZStack {
                                    ZStack {
                                        Color.yellow
                                        Text("\(selectedBar.date)")
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .fixedSize()
                                    .anchorPreference(key: AnnotationBoundsPreferenceKey.self, value: .bounds) { rect in
                                        return rect
                                    }
                                }
                            }
                        }
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
                        .chartBackground(alignment: .topLeading) { chart in
                            interactiveChartContent(chart: chart) { _ in
                                Color.black
                                    .frame(
                                        width: 1,
                                        height: chart.plotAreaSize.height,
                                        alignment: .leading
                                    )
                            }
                        }
                        .animating(changeOf: dataSource.upperBound,
                                   into: $animatedUpperBound,
                                   animation: .spring())
                    }
                    .scrollDisabled(true)
                    .frame(
                        width: chartGeometry.size.width,
                        height: chartGeometry.size.height,
                        alignment: .leading
                    )
                }

                chartYAxis
            }
            .frame(height: containerGeometry.size.height)
        }
    }

    @ViewBuilder
    private func interactiveChartContent(chart: ChartProxy, @ViewBuilder content: @escaping (ChartData) -> some View) -> some View {
        if let selectedChartData {
            Color.clear
            GeometryReader { geometry in
                let originX = geometry[chart.plotAreaFrame].origin.x

                if let selectedChartData,
                   let chartX = chart.position(forX: selectedChartData.date) {
                    let chartXOffset = chartX + originX + unitWidth(contentWidth: geometry.size.width/3)/2
                    content(selectedChartData)
                        .offset(x: chartXOffset)
                }
            }
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
