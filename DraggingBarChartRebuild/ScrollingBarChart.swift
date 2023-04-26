//
//  ScrollingChart.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 4/21/23.
//


import SwiftUI
import Charts

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
    private var translation: DragGesture.Value?

    @State
    private var isLongPressActive: Bool = false

    private func dragGesture(contentWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($translation) { value, state, _ in
                state = value
            }
            .onEnded { value in
                guard !isLongPressActive else {
                    isLongPressActive = false
                    return
                }

                chartContentOffset += value.translation.width

                let barCount = Double(dataSource.visibleBarCount)
                let unitWidth = contentWidth / barCount

                let unitOffset = (value.translation.width / unitWidth).rounded(.toNearestOrAwayFromZero)
                var predictedUnitOffset = (value.predictedEndTranslation.width / unitWidth).rounded(.toNearestOrAwayFromZero)

                // If swipe carefully, change to the nearest time unit
                // If swipe fast enough, change to the next page
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
                        .offset(x: isLongPressActive ? 0.0 : (translation?.translation.width ?? 0.0))
                        .frame(
                            width: chartGeometry.size.width * 3,
                            height: containerGeometry.size.height
                        )
                        .chartOverlay(alignment: .topLeading) { chart in
                            if isLongPressActive, let translation {
                                GeometryReader { geometry in
                                    let originX = geometry[chart.plotAreaFrame].origin.x
                                    let translationX = min(max(translation.location.x, 0), geometry.size.width)
                                    let currentX = translationX - originX

                                    Color.black
                                        .frame(
                                            width: 1,
                                            height: chart.plotAreaSize.height,
                                            alignment: .leading
                                        )
                                        .offset(x: translationX)

                                    if let value = chart.value(atX: currentX, as: Date.self),
                                       let selectedBar = dataSource.indexOfDate(closestTo: value) {
                                        Text("\(selectedBar.date)")
                                            .padding()
                                            .offset(x: translation.location.x)
                                    }
                                }
                            }
                        }
                        .onLongPressGesture {
                            self.isLongPressActive = true
                        }
                        .simultaneousGesture(dragGesture(contentWidth: chartGeometry.size.width))
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

    private var chart: some ChartContent {
        ForEach(dataSource.data, id: \.date) { item in
            BarMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Value", min(item.value, animatedUpperBound))
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
            .frame(height: 300)
            .scenePadding(.horizontal)
    }
}
