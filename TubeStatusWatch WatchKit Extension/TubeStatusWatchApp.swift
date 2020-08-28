//
//  TubeStatusWatchApp.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 27/06/2020.
//

import ClockKit
import SwiftUI

struct LineSettingButton: View {
    private static let cornerRadius: CGFloat = 9
    
    @ObservedObject var lineSetting: LineSetting
    @Binding var selectedLineIds: [String]
    
    var body: some View {
        Button {
            lineSetting.isSelected.toggle()
            lineSetting.isSelected
                ? selectedLineIds.append(lineSetting.id)
                : selectedLineIds.removeAll { $0 == lineSetting.id }
        } label: {
            HStack {
                Text(lineSetting.name)
                Spacer()
                lineSetting.isSelected ? Image(systemName: "checkmark") : nil
            }
        }
        .listRowBackground(
            ZStack {
                let backgroundColor = Color(lineSetting.id)
                let borderColor = backgroundColor == Color("northern") ? Color(.darkGray) : nil
                RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                    .fill(backgroundColor)
                if let borderColor = borderColor {
                    RoundedRectangle(cornerRadius: Self.cornerRadius, style: .continuous)
                        .stroke(borderColor)
                }
            }
        )
    }
}

struct LineSettingList: View {
    let lineSettings: [LineSetting]
    @Binding var selectedLineIds: [String]
    
    var body: some View {
        List {
            ForEach(lineSettings) { lineSetting in
                LineSettingButton(lineSetting: lineSetting, selectedLineIds: $selectedLineIds)
            }
        }
    }
}

struct LineUpdateItemStatusSeverity: View {
    let statusSeverityDescription: String?
    let statusSeverityColor: Color?
    let reason: String?
    
    var body: some View {
        if let statusSeverityDescription = statusSeverityDescription {
            Text(statusSeverityDescription)
                .font(.headline)
                .foregroundColor(statusSeverityColor)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        if let reason = reason {
            Text(reason)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct LineUpdateItem: View {
    let name: String
    let lineStatuses: [LineStatus]
    
    var body: some View {
        VStack {
            Text(name)
                .font(.title3)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(lineStatuses, id: \.self) { lineStatus in
                LineUpdateItemStatusSeverity(statusSeverityDescription: lineStatus.statusSeverityDescription,
                                             statusSeverityColor: StatusSeverityMapper
                                                .color(for: lineStatus.statusSeverity),
                                             reason: lineStatus.reason)
            }
        }
    }
}

struct LineUpdateList: View {
    let lines: [Line]
    
    var body: some View {
        List {
            ForEach(lines) { line in
                if !line.lineStatuses.isEmpty {
                    LineUpdateItem(name: line.name, lineStatuses: line.lineStatuses)
                }
            }
        }
    }
}

@main
struct TubeStatusWatchApp: App {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) private var extensionDelegate
    @AppStorage("selectedLineIds") private var selectedLineIdsString = ""
    @AppStorage("selectedLineUpdates") private var selectedLineUpdatesData: Data?
    @State private var isSheetPresented = false
    
    var body: some Scene {
        let selectedLineIds = Binding(
            get: { selectedLineIdsString.componentsOrEmpty(separatedBy: ",") },
            set: { selectedLineIdsString = $0.sorted(by: <).joined(separator: ",") }
        )
        let lineSettings = LineData.lineIds.enumerated().map { index, lineId in
            LineSetting(id: lineId,
                        name: LineData.lineNames[index],
                        isSelected: selectedLineIds.wrappedValue.contains(lineId))
        }
        
        WindowGroup {
            LineSettingList(lineSettings: lineSettings, selectedLineIds: selectedLineIds)
                .onAppear {
                    isSheetPresented = !(selectedLineUpdatesData?.decoded(to: [Line].self)?.isEmpty ?? true)
                }
                .onChange(of: selectedLineUpdatesData) { data in
                    isSheetPresented = !(data?.decoded(to: [Line].self)?.isEmpty ?? true)
                }
                .sheet(isPresented: $isSheetPresented, onDismiss: { selectedLineUpdatesData = nil }) {
                    if let lines = selectedLineUpdatesData?.decoded(to: [Line].self) {
                        LineUpdateList(lines: lines)
                    }
                }
        }
    }
}

class ExtensionDelegate: NSObject, WKExtensionDelegate {
    func applicationDidEnterBackground() {
        let complicationServer = CLKComplicationServer.sharedInstance()
        complicationServer.activeComplications?.forEach(complicationServer.reloadTimeline)
        complicationServer.reloadComplicationDescriptors()
    }
}

struct TubeStatusWatchApp_Previews: PreviewProvider {
    static var previews: some View {
        let lineSettings = [LineSetting(id: "bakerloo", name: "Bakerloo", isSelected: true),
                            LineSetting(id: "central", name: "Central", isSelected: false),
                            LineSetting(id: "circle", name: "Circle", isSelected: false)]
        let selectedLineSettingIds = Binding(
            get: { ["bakerloo"] },
            set: { _ in }
        )
        
        Group {
            LineSettingList(lineSettings: lineSettings, selectedLineIds: selectedLineSettingIds)
            LineUpdateList(lines: .samples)
        }
    }
}
