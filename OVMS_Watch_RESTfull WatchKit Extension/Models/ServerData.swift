//
//  ServerData.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import Foundation
import ClockKit
import WatchKit
import SwiftUI
import CommonCrypto

enum Endpoint {
    static let identifierKey = "identifier"
    case charge
    case status
    case vehicles
    case vehicle
    case cookie
    case token
    case location
    var path: String {
        switch self {
        case .charge:
            return "/api/charge/"
        case .status:
            return "/api/status/"
        case .vehicles:
            return "/api/vehicles"
        case .vehicle:
            return "/api/vehicle/"
        case .cookie:
            return "/api/cookie"
        case .token:
            return "/api/token"
        case .location:
            return "/api/location/"
        }
    }
    var identifier: String {
        switch self {
        case .charge:
            return "Charge"
        case .status:
            return "Status"
        case .vehicles:
            return "Vehicles"
        case .vehicle:
            return "Vehicle"
        case .cookie:
            return "Cookie"
        case .token:
            return "Token"
        case .location:
            return "Location"
        }
    }
}

enum Mode {
    static let identifierKey = "identifier"
    case driving
    case charging
    case idle
    var identifier: String {
        switch self {
        case .driving:
            return "D"
        case .charging:
            return "C"
        case .idle:
            return "I"
        }
    }
}

enum DownloadStatus {
    case notStarted
    case queued
    case inProgress(Double)
    case completed
    case failed(Error)
  }

public var lastSOC = 0
var currentToken = Token.initial
var vehicles = Vehicle.dummy
let keyChainService = KeychainService()
var userName = ""
var timer = Timer()

class ServerData: NSObject, ObservableObject {
    
    static let shared = ServerData()
    
    var charge: Charge = Charge.dummy
    var status: Status = Status.dummy
    var location: Location = Location.dummy
    @Published var chargePercent: Double = Double(Charge.dummy.soc) ?? 0.0
    @Published var currMode: String = "I"
    /// The current status of the session
    private var downloadStatus = DownloadStatus.notStarted
    private var backgroundTasks = [WKURLSessionRefreshBackgroundTask]()
    private var sessionID: String {
        "\(Bundle.main.bundleIdentifier!).background"
      }
    
    var mode: Mode = .idle
    
    private var urlSession: URLSession!
    @Published var tasks: [URLSessionTask] = []
    var backgroundTask: URLSessionDataTask?
    var backgroundDownload: URLSessionDownloadTask?
    var downloadData: Data = Data()
    var endpoint = Endpoint.charge
    var endpointToggle = false
    
    var completionHandler : ((_ update: Bool) -> Void)?
    
    private lazy var backgroundURLSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: sessionID)
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    func startBackgroundDownload(refreshInterval: TimeInterval) {
            
            switch mode {
            case .charging: endpoint = Endpoint.charge
            case .driving: endpoint = endpointToggle == true ? Endpoint.location : Endpoint.status
            default: endpoint = Endpoint.status
            }
            let scheduledDate = Date().addingTimeInterval(refreshInterval)
            
            if let url = URL(string: getURL(for: endpoint)!) {
                
                let bgDload = backgroundURLSession.downloadTask(with: url)
                bgDload.earliestBeginDate = scheduledDate
                bgDload.countOfBytesClientExpectsToSend = 200
                bgDload.countOfBytesClientExpectsToReceive = 1024
                //BackgroundURLSessions.sharedInstance().sessions[sessionID] = self
                
                print("Next download update = \(scheduledDate.formatted(date: .omitted, time: .standard))")
                bgDload.resume()
                downloadStatus = .queued
            }
    }
    
    // Add the Background Refresh Task to the list so it can be set to
    // completed when the URL task is done.
    func addBackgroundRefreshTask(_ task: WKURLSessionRefreshBackgroundTask) {
        backgroundTasks.append(task)
    }

    func getVehicle() async {
        var request: URLRequest
        if let url = URL(string: getURL(for: Endpoint.vehicle)!) {
            request = URLRequest(url: url)
            do {
                let ( data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
                let vehicle = try JSONDecoder().decode(Vehicle.self, from: data)
                print("Vehicle: \(vehicle)")
                return
            }
            catch {
                return
            }
        }
    }
}

func getURL(for endpoint: Endpoint) -> String? {
    var vehicleID = vehicles[0].id
    if endpoint.identifier == "Vehicles" || endpoint.identifier == "Cookie" {
        vehicleID = ""
    }
    if endpoint.identifier == "Token" {
        vehicleID = "/\(currentToken.token)"
    }
    var password = keyChainService.retrievePassword(for: userName) ?? ""
    if currentToken.token != "" && endpoint.identifier != "Token" {
        password = currentToken.token
    }
    var urlComponents = URLComponents()
    urlComponents.scheme = "https"
    urlComponents.host = "api.openvehicles.com"
    urlComponents.port = 6869
    urlComponents.path = "\(endpoint.path)\(vehicleID)/"
    urlComponents.query = "username=\(userName)&password=\(String(describing: password))"
    return urlComponents.url?.absoluteString
}

func updateActiveComplications() {
    print("Updating Active Compications")
    let complicationServer = CLKComplicationServer.sharedInstance()
    if let activeComplications = complicationServer.activeComplications {
        for complication in activeComplications {
            complicationServer.reloadTimeline(for: complication)
        }
    }
}

func updateComplications(soc: String) {
    let currentSOC = Int(round(Double(soc) ?? 0))
    if currentSOC != lastSOC {
        lastSOC = currentSOC
        print("SOC changed to \(lastSOC). Updating Active complications")
        let complicationServer = CLKComplicationServer.sharedInstance()
        if let activeComplications = complicationServer.activeComplications {
            for complication in activeComplications {
                complicationServer.reloadTimeline(for: complication)
            }
        }
        
    }
}

extension ServerData: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo loc: URL) {

        // We don't need more updates on this session, so let it go.
        //BackgroundURLSessions.sharedInstance().sessions[sessionID] = nil
        if loc.isFileURL {
            do {
                downloadData = try Data(contentsOf: loc)
            } catch {
                print("could not read data from \(loc)")
            }
        }
        DispatchQueue.main.async { [self] in
            saveDownloadedData(downloadData)
            currMode = mode.identifier
            self.downloadStatus = .completed
        }
        for task in backgroundTasks {
            task.setTaskCompletedWithSnapshot(false)
        }
    }
    
    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        
        var time:Double = 0.0
        if error != nil {
            print("Download Error in task: \(task.taskIdentifier)")
            //task.cancel()
        } else {
            //task.cancel()
            endpointToggle = !endpointToggle
            switch mode {
            case .charging:
                var chargePower = Int(round(Double(charge.chargepower) ?? 1.0))
                if chargePower < 1 { chargePower = 1 }
                print("Charge power = \(chargePower)")
                time = Double(150 / chargePower)
            case .driving:
                /*
                 var locationPower = Int(round(Double(location.power) ?? 1.0))
                 if locationPower < 5 { locationPower = 5 } else if locationPower > 100 {locationPower = 100}
                 print("Location.power = \(locationPower)")
                 time = Double(150 / locationPower)
                 */
                time = 120
            default:
                time = 15*60
            }
            time = 15*60
            print("Task finished: \(task.taskIdentifier) - Refresh time = \(time)")
            startBackgroundDownload(refreshInterval: time)
        }
        
        print("Session didCompleteWithError \(error.debugDescription)")
        DispatchQueue.main.async {
            self.completionHandler?(error == nil)
            self.completionHandler = nil
        }
    }
    
    private func saveDownloadedData(_ data: Data) {
        // Move or quickly process this file before you return from this function.
        // The file is in a temporary location and will be deleted.
        print("Download Finished")
        do {
            switch mode {
            case .charging:
                charge = try JSONDecoder().decode(Charge.self, from: downloadData)
                chargePercent = Double(charge.soc) ?? 0.0
                if charge.charging == 0 {
                    mode = charge.caron == 0 ? .idle : .driving
                }
            case .idle:
                status = try JSONDecoder().decode(Status.self, from: downloadData)
                chargePercent = Double(status.soc) ?? 0.0
                if status.charging != 0 {
                    mode = .charging
                } else {
                    mode = status.caron == 0 ? .idle : .driving
                }
            case .driving:
                if endpointToggle == true {
                    location = try JSONDecoder().decode(Location.self, from: downloadData)
                } else {
                    status = try JSONDecoder().decode(Status.self, from: downloadData)
                    chargePercent = Double(status.soc) ?? 0.0
                    if status.charging != 0 {
                        mode = .charging
                    } else {
                        mode = status.caron == 0 ? .idle : .driving
                    }
                }
            }
            updateActiveComplications()
            print("Mode: \(currMode) SOC:\(charge.soc)/ \(status.soc) @ \(Date.now.formatted(date: .omitted, time: .standard)) Charge:\(charge.chargestate)/\(status.chargestate) Car:\(charge.caron == 0 ? "OFF" : "ON")/\(status.caron == 0 ? "OFF" : "ON")")
        }
        catch {
            print("Error converting server response to json - Endpoint = \(endpoint) Mode = \(mode)")
        }
    }
    
    func refresh(_ completionHandler: @escaping (_ update: Bool) -> Void) {
        self.completionHandler = completionHandler
    }

}

extension ServerData: WKExtensionDelegate {
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        //print("Finished Launching")
    }
    
    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        //print("Became Active")
        //startBackgroundTask(refreshInterval: 10)
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        //print("Resign Active")
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let urlBackgroundTask as WKURLSessionRefreshBackgroundTask:
                print("WKURLSessionRefreshBackgroundTask task received")
                refresh() { (update: Bool) -> Void in
                    if update {
                        print("Updating complications")
                        updateActiveComplications()
                    }
                }
                currMode = mode.identifier
                chargePercent = Double(charge.soc) ?? 0.0
                updateActiveComplications()
                //self.addBackgroundRefreshTask(urlBackgroundTask)
                urlBackgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                print("WKSnapshotRefreshBackgroundTask task received")
                refresh() { (update: Bool) -> Void in
                    if update {
                        print("Updating complications")
                        updateActiveComplications()
                    }
                }
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }
}
