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

class PieChartViewModel {
    let sliceViewModels: [PieChartSliceViewModel]
    
    init(data: [PieChartSliceData]) {
        let totalValue = data.reduce(0) { $0 + $1.value }
        var currentAngle = -90.0
        sliceViewModels = data.map {
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
    
    private var borderPath: Path {
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
    
    private var arcPath: Path {
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
    let viewModel: PieChartViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(viewModel.sliceViewModels, id: \.self) { viewModel in
                    PieChartSlice(geometry: geometry, viewModel: viewModel)
                }
            }
        }
    }
}

struct CircularComplicationContentView: View {
    let viewModels: [CircularComplicationSliceViewModel]
    
    private var pieChartSliceData: [PieChartSliceData] {
        viewModels.map { PieChartSliceData(value: 1, fillColor: $0.fillColor, borderColor: $0.borderColor) }
    }
    
    var body: some View {
        PieChart(viewModel: PieChartViewModel(data: pieChartSliceData))
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let firstSliceViewModel = CircularComplicationSliceViewModel(fillColor: Color("bakerloo"),
                                                                     borderColor: .green)
        let secondSliceViewModel = CircularComplicationSliceViewModel(fillColor: Color("central"),
                                                                      borderColor: .yellow)
        let thirdSliceViewModel = CircularComplicationSliceViewModel(fillColor: Color("circle"),
                                                                     borderColor: .red)
        let circularOneLineContentView = CircularComplicationContentView(viewModels: [firstSliceViewModel])
        let circularTwoLinesContentView = CircularComplicationContentView(viewModels: [firstSliceViewModel,
                                                                                       secondSliceViewModel])
        let circularThreeLinesContentView = CircularComplicationContentView(viewModels: [firstSliceViewModel,
                                                                                         secondSliceViewModel,
                                                                                         thirdSliceViewModel])
        let rectangularFullContentView = RectangularFullComplicationContentView(title: "Bakerloo",
                                                                                subtitle: "Good Service",
                                                                                color: Color("bakerloo"))
        
        Group {
            CLKComplicationTemplateGraphicExtraLargeCircularView(circularOneLineContentView)
                .previewContext()
            CLKComplicationTemplateGraphicExtraLargeCircularView(circularTwoLinesContentView)
                .previewContext()
            CLKComplicationTemplateGraphicExtraLargeCircularView(circularThreeLinesContentView)
                .previewContext()
            CLKComplicationTemplateGraphicRectangularFullView(rectangularFullContentView)
                .previewContext()
        }
    }
}
