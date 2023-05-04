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

    @StateObject
    private var dataSource = DataSource()

    @State
    private var currentUnitOffset: Int = .zero

    @State
    private var chartContentOffset: CGFloat = .zero

    @State
    private var animatedUpperBound: CGFloat = .zero

    @State
    private var selectedChartData: ChartData? {
        didSet {
            print("selectedData: \(selectedChartData)")
        }
    }

    @GestureState
    private var translation: CGFloat = .zero

    private let pagingAnimationDuration: CGFloat = 0.2
    private let barWidth: CGFloat = 32

    private var artificialUpperBound: Int {
        Int(animatedUpperBound * 1.5)
    }

    private func dragGesture(contentWidth: CGFloat, chart: ChartProxy, containerGeometry: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0.5)
            .updating($translation) { value, state, _ in
                state = value.translation.width
            }
            .onEnded { value in
                chartContentOffset += value.translation.width
                print("*** chartContentOffset: \(chartContentOffset)")

                let chartOriginX = containerGeometry[chart.plotAreaFrame].origin.x
                print("*** originX: \(chartOriginX)")

                let containerOriginX = -chartOriginX
                print("*** containerOriginX: \(containerOriginX)")

                let clampedOriginX = min(containerOriginX, chart.plotAreaSize.width - contentWidth)
                print("*** clampedOriginX: \(clampedOriginX)")

                let leadingXValue = chart.value(atX: clampedOriginX, as: Date.self)!
                print("*** leadingXValue: \(leadingXValue.formatted(date: .abbreviated, time: .omitted))")

                let chartData = dataSource.chartData(closestTo: leadingXValue)!
                print("*** chartData: \(chartData.date.formatted(date: .abbreviated, time: .omitted))")

                let chartPosition = chart.position(forX: chartData.date)!
                print("*** chartPosition: \(chartPosition)")

                let finalOffset = -chartPosition


                withAnimation(.easeOut(duration: pagingAnimationDuration)) {
                    chartContentOffset = finalOffset
                }

                Task { @MainActor in
                    try? await Task.sleep(for: .seconds(pagingAnimationDuration))
//                    currentUnitOffset -= Int(chartContentOffset / unitWidth)
                    dataSource.setLeadingVisibleData(chartData)
                    chartContentOffset = 0
                }
            }
    }

    @ChartContentBuilder
    func chart(showsAnnotations: Bool) -> some ChartContent {
        ForEach(dataSource.data, id: \.date) { item in
            BarMark(
                x: .value("Day", item.date, unit: .day),
                y: .value("Value", min(item.value, animatedUpperBound)),
                width: .fixed(barWidth),
                stacking: .unstacked
            )
//            .annotation {
//                if showsAnnotations {
//                    Text(item.date.formatted(date: .abbreviated, time: .omitted))
//                        .foregroundColor(item.isVirtual ? .orange : .black)
//                }
//            }
        }
    }

    private var chartYAxis: some View {
        Chart {
            chart(showsAnnotations: false)
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
    private var animatedSelectedContent: ChartData?

    var body: some View {
        GeometryReader { containerGeometry in
            HStack(spacing: 0) {
                GeometryReader { chartGeometry in
                    ScrollView(.horizontal) {
                        Chart {
                            chart(showsAnnotations: true)
                        }
                        .chartYScale(domain: 0 ... artificialUpperBound)
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
                        .chartOverlay(alignment: .topLeading) { chart in
                            GeometryReader { geometry in
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture(coordinateSpace: .local) { location in
                                        let originX = geometry[chart.plotAreaFrame].origin.x
                                        let clampedLocationX = min(max(location.x, 0), geometry.size.width)
                                        let currentX = clampedLocationX - originX

                                        if let selectedDate = chart.value(atX: currentX, as: Date.self),
                                           let selectedBar = dataSource.chartData(closestTo: selectedDate) {
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
                                    .simultaneousGesture(dragGesture(contentWidth: chartGeometry.size.width, chart: chart, containerGeometry: geometry))
                            }
                        }
                        .chartOverlay { chart in
                            if let selectedChartData = dataSource.visibleData(of: animatedSelectedContent) {
                                LollipopOverlay(
                                    selectedChartData: selectedChartData,
                                    chart: chart,
                                    containerSize: chartGeometry.size
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
}

struct ScrollingBarChart_Previews: PreviewProvider {
    static var previews: some View {
        ScrollingBarChart()
            .frame(height: 300)
            .scenePadding(.horizontal)
    }
}
