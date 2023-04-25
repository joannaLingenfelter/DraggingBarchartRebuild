//
//  ContentView.swift
//  DraggingBarChartRebuild
//
//  Created by Jo Lingenfelter on 4/21/23.
//

import SwiftUI
import Charts

struct ContentView: View {
    var body: some View {
        ScrollingBarChart()
        .frame(height: 300)
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
