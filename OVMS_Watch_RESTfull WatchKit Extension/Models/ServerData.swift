//
//  ServerData.swift
//  OVMS_Watch_RESTfull WatchKit Extension
//
//  Created by Peter Harry on 21/7/2022.
//

import Foundation
import ClockKit
import WatchKit

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
/*
enum Mode: Int {
    case driving = 1, charging, idle
}
*/
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
    
    var mode: Mode = .idle
    
    private var urlSession: URLSession!
    @Published var tasks: [URLSessionTask] = []
    var backgroundTask: URLSessionDataTask?
    var backgroundDownload: URLSessionDownloadTask?
    var downloadData: Data = Data()
    var endpoint = Endpoint.charge
    var endpointToggle = false
    
    private lazy var backgroundURLSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "BackgroundData")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()
    
    func startBackgroundDownload(refreshInterval: TimeInterval) {
        backgroundDownload?.cancel()
        //var endpoint: Endpoint
        switch mode {
        case .charging: endpoint = Endpoint.charge
        case .driving: endpoint = endpointToggle == true ? Endpoint.location : Endpoint.status
        default: endpoint = Endpoint.status
        }
        let now = Date()
        let scheduledDate = now.addingTimeInterval(refreshInterval)
        
        if let url = URL(string: getURL(for: endpoint)!) {
            let config = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).background")
            config.isDiscretionary = false
            config.sessionSendsLaunchEvents = true
            if urlSession == nil {
                urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
            }
            
            backgroundDownload = urlSession.downloadTask(with: url)
            backgroundDownload?.earliestBeginDate = scheduledDate
            print("Next download update = \(scheduledDate.formatted(date: .omitted, time: .standard))")
            backgroundDownload?.resume()
        }
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

func updateComplications(soc: String) {
    let currentSOC = Int(round(Double(soc) ?? 0))
    if currentSOC != lastSOC {
        lastSOC = currentSOC
        print("SOC changed to \(lastSOC). Updating complications")
        let server = CLKComplicationServer.sharedInstance()
        server.activeComplications?.forEach { complication in
            server.extendTimeline(for: complication)
        }
    }
}

extension ServerData: URLSessionDownloadDelegate {
    
    func urlSession(_: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        var time:Double = 0.0
        if error != nil {
            print("Download Error in task: \(task.taskIdentifier)")
            task.cancel()
        } else {
            task.cancel()
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
                time = 30
            default:
                time = 3600.0
            }
            // Set refresh interval to 30 secs if not idle otherwise 1hr if Idle.
            print("Task finished: \(task.taskIdentifier) - Refresh time = \(time)")
            startBackgroundDownload(refreshInterval: time)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo loc: URL) {
        print("Download Finished")
        if loc.isFileURL {
            do {
                downloadData = try Data(contentsOf: loc)
            } catch {
                print("could not read data from \(loc)")
            }
        }
        do {
            switch mode {
            case .charging:
                charge = try JSONDecoder().decode(Charge.self, from: downloadData)
                updateComplications(soc: charge.soc)
                if charge.charging == 0 {
                    mode = charge.caron == 0 ? .idle : .driving
                }
            case .idle:
                status = try JSONDecoder().decode(Status.self, from: downloadData)
                updateComplications(soc: status.soc)
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
                    if status.charging != 0 {
                        mode = .charging
                    } else {
                        mode = status.caron == 0 ? .idle : .driving
                    }
                }
            }
            /*
            if mode == .charging {
                charge = try JSONDecoder().decode(Charge.self, from: downloadData)
                updateComplications(soc: charge.soc)
                if charge.charging == 0 {
                    mode = charge.caron == 0 ? .idle : .driving
                }
            } else {
                status = try JSONDecoder().decode(Status.self, from: downloadData)
                updateComplications(soc: status.soc)
                if status.charging != 0 {
                    mode = .charging
                } else {
                    mode = status.caron == 0 ? .idle : .driving
                }
            } */
        }
        catch {
            print("Error converting server response to json")
            print("Endpoint = \(endpoint) Mode = \(mode)")
        }
        DispatchQueue.main.async { [self] in
            currMode = mode.identifier
            /*
            switch mode {
            case .charging:
                currMode = "C"
            case .driving:
                currMode = "D"
            default:
                currMode = "I"
            }
             */
            chargePercent = Double(charge.soc) ?? 0.0
        }
        print("Mode: \(currMode) SOC:\(charge.soc)/ \(status.soc) @ \(Date.now.formatted(date: .omitted, time: .standard)) Charge:\(charge.chargestate)/\(status.chargestate) Car:\(charge.caron == 0 ? "OFF" : "ON")/\(status.caron == 0 ? "OFF" : "ON")")
    }
}

extension ServerData: WKExtensionDelegate {
    
    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.
        print("Finished Launching")
    }
    
    func applicationDidBecomeActive() {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        print("Became Active")
        //startBackgroundTask(refreshInterval: 10)
    }
    
    func applicationWillResignActive() {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, etc.
        print("Resign Active")
    }
    
    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let urlBackgroundTask as WKURLSessionRefreshBackgroundTask:
                print("application task received, start URL session")
                currMode = mode.identifier
                /*
                switch mode {
                case .charging:
                    currMode = "C"
                case .driving:
                    currMode = "D"
                default:
                    currMode = "I"
                }
                 */
                chargePercent = Double(charge.soc) ?? 0.0
                //let backgroundConfigObject = URLSessionConfiguration.background(withIdentifier: urlBackgroundTask.sessionIdentifier)
                //let backgroundUrlSession = URLSession(configuration: backgroundConfigObject, delegate: self, delegateQueue: nil) //set to nil in task:didCompleteWithError: delegate method
                //let pendingBackgroundURLTask = urlBackgroundTask //Saved for .setTaskComplete() in downloadTask:didFinishDownloadingTo location: (or if error non nil in task:didCompleteWithError:)
                urlBackgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
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
