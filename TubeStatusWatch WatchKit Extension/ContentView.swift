//
//  ContentView.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 27/06/2020.
//

import ClockKit
import SwiftUI

struct PieChartSliceData {
    let value: Double
    let color: Color
}

struct PieChartSliceViewModel: Hashable {
    let startAngle: Angle
    let endAngle: Angle
    let color: Color
    let isOnlySlice: Bool
}

class PieChartData {
    let viewModels: [PieChartSliceViewModel]
    
    init(data: [PieChartSliceData]) {
        let totalValue = data.reduce(0) { $0 + $1.value }
        var currentAngle = -90.0
        viewModels = data.map {
            let startAngle = Angle.degrees(currentAngle)
            let angle = $0.value * 360 / totalValue
            currentAngle += angle
            let endAngle = Angle.degrees(currentAngle)
            return PieChartSliceViewModel(startAngle: startAngle,
                                          endAngle: endAngle,
                                          color: $0.color,
                                          isOnlySlice: data.count == 1)
        }
    }
}

struct PieChartSlice: View {
    let geometry: GeometryProxy
    let viewModel: PieChartSliceViewModel
    
    var path: Path {
        let chartSize = geometry.size.width
        let radius = chartSize / 2
        let centerX = radius
        let centerY = radius
        var path = Path()
        path.move(to: CGPoint(x: centerX, y: centerY))
        path.addArc(center: CGPoint(x: centerX, y: centerY),
                    radius: radius,
                    startAngle: viewModel.startAngle,
                    endAngle: viewModel.endAngle,
                    clockwise: false)
        return path
    }
    
    var body: some View {
        path.fill(viewModel.color)
            .overlay(path.stroke(Color.white, lineWidth: viewModel.isOnlySlice ? 0 : 1))
    }
}

struct PieChart: View {
    let data: PieChartData
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(data.viewModels, id: \.self) { viewModel in
                    PieChartSlice(geometry: geometry, viewModel: viewModel)
                }
            }
        }
    }
}

struct CircularComplicationContentView: View {
    let colors: [Color]
    
    var pieChartSliceData: [PieChartSliceData] {
        colors.map { PieChartSliceData(value: 1, color: $0) }
    }
    
    var body: some View {
        PieChart(data: PieChartData(data: pieChartSliceData))
    }
}

struct RectangularComplicationContentView: View {
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(color)
                .transition(.slide)
            VStack {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
            }
        }
    }
}

struct PieChart_Previews: PreviewProvider {
    static var previews: some View {
        PieChart(data: PieChartData(data: [PieChartSliceData(value: 1, color: .red),
                                           PieChartSliceData(value: 2, color: .green),
                                           PieChartSliceData(value: 3, color: .blue)]))
    }
}

struct ContentView_Previews: PreviewProvider {
    private static let circularContentViewOneLine = CircularComplicationContentView(colors: [Color("bakerloo")])
    private static let circularContentViewTwoLines = CircularComplicationContentView(colors: [Color("bakerloo"),
                                                                                              Color("central")])
    private static let circularContentViewThreeLines = CircularComplicationContentView(colors: [Color("bakerloo"),
                                                                                                Color("central"),
                                                                                                Color("circle")])
    private static let rectangularContentView = RectangularComplicationContentView(title: "Bakerloo",
                                                                                   subtitle: "Good Service",
                                                                                   color: Color("bakerloo"))
    
    static var previews: some View {
        Group {
//            CLKComplicationTemplateGraphicCircularClosedGaugeView
//            CLKComplicationTemplateGraphicCircularOpenGaugeView
//            CLKComplicationTemplateGraphicCircularStackViewText
//            CLKComplicationTemplateGraphicCircularView(contentView)
//                .previewContext()
//            CLKComplicationTemplateGraphicCornerCircularView(contentView)
//                .previewContext()
//            CLKComplicationTemplateGraphicCornerGaugeView
//            CLKComplicationTemplateGraphicCornerTextView
//            CLKComplicationTemplateGraphicExtraLargeCircularClosedGaugeView
//            CLKComplicationTemplateGraphicExtraLargeCircularOpenGaugeView
//            CLKComplicationTemplateGraphicExtraLargeCircularStackViewText
            CLKComplicationTemplateGraphicExtraLargeCircularView(circularContentViewOneLine)
                .previewContext()
            CLKComplicationTemplateGraphicExtraLargeCircularView(circularContentViewTwoLines)
                .previewContext()
            CLKComplicationTemplateGraphicExtraLargeCircularView(circularContentViewThreeLines)
                .previewContext()
            CLKComplicationTemplateGraphicRectangularFullView(rectangularContentView)
                .previewContext()
//            CLKComplicationTemplateGraphicRectangularLargeView
//            CLKComplicationTemplateGraphicRectangularStandardBodyView
//            CLKComplicationTemplateGraphicRectangularTextGaugeView
        }
    }
}
