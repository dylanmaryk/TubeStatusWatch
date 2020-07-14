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
            let startAngle = Angle(degrees: currentAngle)
            let angle = $0.value * 360 / totalValue
            currentAngle += angle
            let endAngle = Angle(degrees: currentAngle)
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
            .overlay(path.stroke(Color.white, lineWidth: viewModel.isOnlySlice ? 0 : 2))
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

struct CornerTextIconComplicationContentView: View {
    let color: Color
    
    var body: some View {
        Circle()
            .fill(color)
    }
}

struct RectangularFullComplicationContentView: View {
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

struct RectangularLargeComplicationContentView: View {
    let title: String
    let color: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 25, style: .continuous)
                .fill(color)
                .transition(.slide)
            VStack {
                Text(title)
                    .font(.headline)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    private static let circularOneLineContentView = CircularComplicationContentView(colors: [Color("bakerloo")])
    private static let circularTwoLinesContentView = CircularComplicationContentView(colors: [Color("bakerloo"),
                                                                                              Color("central")])
    private static let circularThreeLinesContentView = CircularComplicationContentView(colors: [Color("bakerloo"),
                                                                                                Color("central"),
                                                                                                Color("circle")])
    private static let rectangularFullContentView = RectangularFullComplicationContentView(title: "Bakerloo",
                                                                                           subtitle: "Good Service",
                                                                                           color: Color("bakerloo"))
    private static let rectangularLargeContentView = RectangularLargeComplicationContentView(title: "Good Service",
                                                                                             color: Color("bakerloo"))
    private static let cornerTextIconGreenContentView = CornerTextIconComplicationContentView(color: .green)
    private static let cornerTextIconRedContentView = CornerTextIconComplicationContentView(color: .red)
    
    static var previews: some View {
        Group {
            CLKComplicationTemplateGraphicCircularStackViewText(content: circularOneLineContentView,
                                                                textProvider: CLKTextProvider(format: "Good"))
                .previewContext()
            CLKComplicationTemplateGraphicCircularView(circularThreeLinesContentView)
                .previewContext()
            CLKComplicationTemplateGraphicCornerCircularView(circularThreeLinesContentView)
                .previewContext()
            CLKComplicationTemplateGraphicCornerTextView(textProvider: CLKTextProvider(format: "🟢 Bakerloo"),
                                                         label: Label(title: {}, icon: {}))
                .previewContext()
            CLKComplicationTemplateGraphicCornerTextView(textProvider: CLKTextProvider(format: "🔴 Bakerloo"),
                                                         label: Label(title: {}, icon: {}))
                .previewContext()
            CLKComplicationTemplateGraphicExtraLargeCircularStackViewText(content: circularOneLineContentView,
                                                                          textProvider: CLKTextProvider(format: "Good"))
                .previewContext()
//            CLKComplicationTemplateGraphicExtraLargeCircularView(circularOneLineContentView)
//                .previewContext()
//            CLKComplicationTemplateGraphicExtraLargeCircularView(circularTwoLinesContentView)
//                .previewContext()
            CLKComplicationTemplateGraphicExtraLargeCircularView(circularThreeLinesContentView)
                .previewContext()
            CLKComplicationTemplateGraphicRectangularFullView(rectangularFullContentView)
                .previewContext()
            CLKComplicationTemplateGraphicRectangularLargeView(headerTextProvider: CLKTextProvider(format: "Bakerloo"),
                                                               content: rectangularLargeContentView)
                .previewContext()
            CLKComplicationTemplateGraphicRectangularStandardBodyView(headerLabel: Label(title: {},
                                                                                         icon: { cornerTextIconGreenContentView }),
                                                                      headerTextProvider: CLKTextProvider(format: "Bakerloo"),
                                                                      body1TextProvider: CLKTextProvider(format: "Good Service"))
                .previewContext()
//            CLKComplicationTemplateGraphicRectangularStandardBodyView(headerLabel: Label(title: {},
//                                                                                         icon: { cornerTextIconRedContentView }),
//                                                                      headerTextProvider: CLKTextProvider(format: "Bakerloo"),
//                                                                      body1TextProvider: CLKTextProvider(format: "Good Service"))
//                .previewContext()
        }
    }
}
