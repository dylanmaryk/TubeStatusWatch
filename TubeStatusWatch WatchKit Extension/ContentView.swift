//
//  ContentView.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 27/06/2020.
//

import ClockKit
import SwiftUI

struct CircularComplicationSliceViewModel {
    let fillColor: Color
    let borderColor: Color
}

struct PieChartSliceData {
    let value: Double
    let fillColor: Color
    let borderColor: Color
}

struct PieChartSliceViewModel: Hashable {
    let startAngle: Angle
    let endAngle: Angle
    let arcColor: Color
    let borderColor: Color
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
                                          arcColor: $0.fillColor,
                                          borderColor: $0.borderColor)
        }
    }
}

struct PieChartSlice: View {
    private static let borderWidth: CGFloat = 5
    
    let geometry: GeometryProxy
    let viewModel: PieChartSliceViewModel
    
    var borderPath: Path {
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
    
    var arcPath: Path {
        let chartSize = geometry.size.width
        let radius = chartSize / 2
        let centerX = radius
        let centerY = radius
        var path = Path()
        path.move(to: CGPoint(x: centerX, y: centerY))
        path.addArc(center: CGPoint(x: centerX, y: centerY),
                    radius: radius - Self.borderWidth,
                    startAngle: viewModel.startAngle,
                    endAngle: viewModel.endAngle,
                    clockwise: false)
        return path
    }
    
    var body: some View {
        borderPath.fill(viewModel.borderColor)
        arcPath.fill(viewModel.arcColor)
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
    let viewModels: [CircularComplicationSliceViewModel]
    
    var pieChartSliceData: [PieChartSliceData] {
        viewModels.map { PieChartSliceData(value: 1, fillColor: $0.fillColor, borderColor: $0.borderColor) }
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
    private static let circularOneLineContentView = CircularComplicationContentView(viewModels: [CircularComplicationSliceViewModel(fillColor: Color("bakerloo"),
                                                                                                                                    borderColor: .green)])
    private static let circularTwoLinesContentView = CircularComplicationContentView(viewModels: [CircularComplicationSliceViewModel(fillColor: Color("bakerloo"),
                                                                                                                                     borderColor: .green),
                                                                                                  CircularComplicationSliceViewModel(fillColor: Color("central"),
                                                                                                                                     borderColor: .yellow)])
    private static let circularThreeLinesContentView = CircularComplicationContentView(viewModels: [CircularComplicationSliceViewModel(fillColor: Color("bakerloo"),
                                                                                                                                       borderColor: .green),
                                                                                                    CircularComplicationSliceViewModel(fillColor: Color("central"),
                                                                                                                                       borderColor: .yellow),
                                                                                                    CircularComplicationSliceViewModel(fillColor: Color("circle"),
                                                                                                                                       borderColor: .red)])
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
            CLKComplicationTemplateGraphicCornerTextView(textProvider: CLKTextProvider(format: "✅ Bakerloo"),
                                                         label: Label(title: {}, icon: {}))
                .previewContext()
            CLKComplicationTemplateGraphicCornerTextView(textProvider: CLKTextProvider(format: "❌ Bakerloo"),
                                                         label: Label(title: {}, icon: {}))
                .previewContext()
            CLKComplicationTemplateGraphicExtraLargeCircularStackViewText(content: circularOneLineContentView,
                                                                          textProvider: CLKTextProvider(format: "Good"))
                .previewContext()
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
        }
    }
}
