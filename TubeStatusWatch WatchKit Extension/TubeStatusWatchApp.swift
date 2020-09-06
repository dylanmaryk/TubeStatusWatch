//
//  TubeStatusWatchApp.swift
//  TubeStatusWatch WatchKit Extension
//
//  Created by Dylan Maryk on 27/06/2020.
//

import ClockKit
import Combine
import Purchases
import SwiftUI

// MARK: - Upgrade

typealias Package = Purchases.Package
typealias PurchaserInfo = Purchases.PurchaserInfo

struct UpgradeSheet: View {
    let upgradeSheetViewModel: UpgradeSheetViewModel
    @Binding var isSheetPresented: Bool
    @Binding var isUpgraded: Bool
    
    @State private var errorDescription: String?
    
    var body: some View {
        ZStack {
            ScrollView {
                Text("Upgrade")
                    .bold()
                Text(upgradeSheetViewModel.localizedDescription.replacingOccurrences(of: "\\n", with: "\n"))
                Button("\(upgradeSheetViewModel.localizedPrice) One-time") {
                    Purchases.shared.purchasePackage(upgradeSheetViewModel.package) { _, purchaserInfo, error, _ in
                        enableUpgrade(basedOn: purchaserInfo, and: error)
                    }
                }
                Button("Restore Purchases") {
                    Purchases.shared.restoreTransactions { purchaserInfo, error in
                        enableUpgrade(basedOn: purchaserInfo, and: error)
                    }
                }
            }
        }
        .alert(item: $errorDescription) { errorDescription in
            Alert(title: Text(errorDescription))
        }
    }
    
    private func enableUpgrade(basedOn purchaserInfo: PurchaserInfo?, and error: Error?) {
        if let error = error {
            errorDescription = error.localizedDescription
            return
        }
        if purchaserInfo?.entitlements.all["pro"]?.isActive == true {
            isSheetPresented = false
            isUpgraded = true
        }
    }
}

struct UpgradeButton: View {
    private static let labelPadding: CGFloat = 9
    
    @Binding var isUpgraded: Bool
    @Binding var isLoading: Bool
    
    @StateObject private var upgradeSheetViewModel = UpgradeSheetViewModel()
    @State private var errorDescription: String?
    @State private var isSheetPresented = false
    
    var body: some View {
        Button {
            isLoading = true
            Purchases.shared.offerings { offerings, error in
                isLoading = false
                if let error = error {
                    errorDescription = error.localizedDescription
                    return
                }
                guard let currentOffering = offerings?.current,
                      let firstPackage = currentOffering.availablePackages.first else {
                    return
                }
                upgradeSheetViewModel.localizedDescription = currentOffering.serverDescription
                upgradeSheetViewModel.localizedPrice = firstPackage.localizedPriceString
                upgradeSheetViewModel.package = firstPackage
                isSheetPresented = true
            }
        } label: {
            VStack {
                Text("UPGRADE")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Unlock multiple lines & complications")
                    .font(.footnote)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.init(top: Self.labelPadding, leading: 0, bottom: Self.labelPadding, trailing: 0))
        }
        .sheet(isPresented: $isSheetPresented) {
            UpgradeSheet(upgradeSheetViewModel: upgradeSheetViewModel,
                         isSheetPresented: $isSheetPresented,
                         isUpgraded: $isUpgraded)
        }
        .alert(item: $errorDescription) { errorDescription in
            Alert(title: Text(errorDescription))
        }
    }
}

// MARK: - Line Settings

struct LineSettingButton: View {
    private static let cornerRadius: CGFloat = 9
    
    @ObservedObject var lineSetting: LineSetting
    @Binding var selectedLineIds: [String]
    let canSelectMultipleLines: Bool
    
    var body: some View {
        Button {
            lineSetting.isSelected.toggle()
            if lineSetting.isSelected, canSelectMultipleLines {
                selectedLineIds.append(lineSetting.id)
            } else if lineSetting.isSelected {
                selectedLineIds = [lineSetting.id]
            } else {
                selectedLineIds.removeAll { $0 == lineSetting.id }
            }
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
    @Binding var isUpgraded: Bool
    
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            List {
                if !isUpgraded {
                    UpgradeButton(isUpgraded: $isUpgraded, isLoading: $isLoading)
                }
                ForEach(lineSettings) { lineSetting in
                    LineSettingButton(lineSetting: lineSetting,
                                      selectedLineIds: $selectedLineIds,
                                      canSelectMultipleLines: isUpgraded)
                }
            }
            if isLoading {
                ProgressView()
            }
        }
    }
}

// MARK: - Line Updates

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
    let lastRetrievedUpdatesDate: Date
    
    private var lastRetrievedUpdatesText: String {
        let currentDate = Date()
        let relativeDateString = currentDate.timeIntervalSince(lastRetrievedUpdatesDate) > 60
            ? RelativeDateTimeFormatter().localizedString(for: lastRetrievedUpdatesDate, relativeTo: currentDate)
            : "Just now"
        return "Last updated:\n\(relativeDateString)"
    }
    
    var body: some View {
        List {
            Text(lastRetrievedUpdatesText)
                .bold()
                .listRowBackground(Color.clear)
            ForEach(lines) { line in
                if !line.lineStatuses.isEmpty {
                    LineUpdateItem(name: line.name, lineStatuses: line.lineStatuses)
                }
            }
        }
    }
}

// MARK: - App

@main
struct TubeStatusWatchApp: App {
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) private var extensionDelegate
    @AppStorage("selectedLineIds") private var selectedLineIdsString = ""
    @AppStorage("lineUpdates") private var lineUpdatesData: Data?
    @AppStorage("lastRetrievedUpdates") private var lastRetrievedUpdatesData: Data?
    @AppStorage("isUpgraded") private var isUpgraded = false
    @State private var isSheetPresented = false
    
    init() {
        _isSheetPresented = State(initialValue: lineUpdatesData?.decoded(to: [Line].self) != nil
                                    && !selectedLineIdsString.isEmpty)
    }
    
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
            LineSettingList(lineSettings: lineSettings, selectedLineIds: selectedLineIds, isUpgraded: $isUpgraded)
                .sheet(isPresented: $isSheetPresented) {
                    let lines = lineUpdatesData?.decoded(to: [Line].self)
                    let lastRetrievedUpdatesDate = lastRetrievedUpdatesData?.decoded(to: Date.self)
                    let selectedLines = lines?.filter { selectedLineIds.wrappedValue.contains($0.id) }
                    if let selectedLines = selectedLines,
                       !selectedLines.isEmpty,
                       let lastRetrievedUpdatesDate = lastRetrievedUpdatesDate {
                        LineUpdateList(lines: selectedLines, lastRetrievedUpdatesDate: lastRetrievedUpdatesDate)
                    }
                }
        }
    }
}

class ExtensionDelegate: NSObject, WKExtensionDelegate, URLSessionDownloadDelegate {
    private static let backgroundRefreshIntervalInMinutes = 15.0
    private static let urlString = "https://api.tfl.gov.uk/line/mode/dlr,overground,tflrail,tram,tube/status?app_key=%@"
    private static let apiKeyInfoDictionaryKey = "TflApiKey"
    private static let purchasesApiKey = "iZVFjadDximLFdOcVsNZqtCpipfRvApB"
    
    private var sessionCancellable: AnyCancellable?
    private var pendingBackgroundTasks: [WKURLSessionRefreshBackgroundTask] = []
    
    private var url: URL? {
        let apiKey = Bundle.main.object(forInfoDictionaryKey: Self.apiKeyInfoDictionaryKey)
        return URL(string: String(format: Self.urlString, apiKey as! String))
    }
    
    @AppStorage("lineUpdates") private var lineUpdatesData: Data?
    @AppStorage("lastRetrievedUpdates") private var lastRetrievedUpdatesData: Data?
    @AppStorage("isUpgraded") private var isUpgraded = false
    
    func applicationDidFinishLaunching() {
        scheduleBackgroundRefresh()
        Purchases.debugLogsEnabled = true
        Purchases.configure(withAPIKey: Self.purchasesApiKey)
    }
    
    func applicationWillEnterForeground() {
        sessionCancellable = URLSession.shared
            .dataTaskPublisher(for: url!)
            .map { $0.data }
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: {
                self.lineUpdatesData = $0
                self.lastRetrievedUpdatesData = try? JSONEncoder().encode(Date())
            }
    }
    
    func applicationDidEnterBackground() {
        let complicationServer = CLKComplicationServer.sharedInstance()
        complicationServer.activeComplications?.forEach(complicationServer.reloadTimeline)
        complicationServer.reloadComplicationDescriptors()
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        for task in backgroundTasks {
            switch task {
            case let appTask as WKApplicationRefreshBackgroundTask:
                let configuration = URLSessionConfiguration
                    .background(withIdentifier: "io.dylanmaryk.TubeStatusWatch.task")
                let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
                let downloadTask = session.downloadTask(with: url!)
                downloadTask.resume()
                scheduleBackgroundRefresh()
                appTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                let configuration = URLSessionConfiguration
                    .background(withIdentifier: urlSessionTask.sessionIdentifier)
                _ = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
                pendingBackgroundTasks.append(urlSessionTask)
            default:
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
    
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        lineUpdatesData = try? Data(contentsOf: location)
        lastRetrievedUpdatesData = try? JSONEncoder().encode(Date())
        let complicationServer = CLKComplicationServer.sharedInstance()
        complicationServer.activeComplications?.forEach(complicationServer.reloadTimeline)
        pendingBackgroundTasks.forEach { $0.setTaskCompletedWithSnapshot(false) }
    }
    
    private func scheduleBackgroundRefresh() {
        WKExtension.shared()
            .scheduleBackgroundRefresh(withPreferredDate: Date()
                                        .addingTimeInterval(Self.backgroundRefreshIntervalInMinutes * 60),
                                       userInfo: nil,
                                       scheduledCompletion: { _ in })
    }
}

// MARK: - Previews

struct TubeStatusWatchApp_Previews: PreviewProvider {
    static var previews: some View {
        let lineSettings = [LineSetting(id: "bakerloo", name: "Bakerloo", isSelected: true),
                            LineSetting(id: "central", name: "Central", isSelected: false),
                            LineSetting(id: "circle", name: "Circle", isSelected: false)]
        let upgradeSheetViewModel = UpgradeSheetViewModel(localizedDescription: "The standard set of packages",
                                                          localizedPrice: "£0.99",
                                                          package: Package())
        
        Group {
            LineSettingList(lineSettings: lineSettings,
                            selectedLineIds: .constant(["bakerloo"]),
                            isUpgraded: .constant(false))
            UpgradeSheet(upgradeSheetViewModel: upgradeSheetViewModel,
                         isSheetPresented: .constant(true),
                         isUpgraded: .constant(false))
            LineUpdateList(lines: .samples, lastRetrievedUpdatesDate: Date().addingTimeInterval(-3660))
        }
    }
}
