import Foundation
import UIKit
import Network

typealias EventMetaData = [String: Any]

public  class PlybackPulseHadler {
    
    public var dispatchNucleusEvent: NucleusState
    public var tokenId: String?
    public var actionableData: [String: Any]?
    public var userData: [String: Any]
    public var previousBeaconData: [String: Any]?
    public var previousVideoState: [String: Any] = [:]
    public var eventDispatcher: ConnectionHandler?
    public var getFastPixAPI: String?
    public var connectionType = ""
    public var keyParams: [String] = [
        "workspace_id",
        "view_id",
        "view_sequence_number",
        "player_sequence_number",
        "beacon_domain",
        "player_playhead_time",
        "viewer_timestamp",
        "event_name",
        "video_id",
        "player_instance_id",
    ];
    public var videoMetadataParams: [String] = [
        "video_source_width",
        "video_source_height",
        "player_width",
        "player_height",
        "player_is_paused",
        "player_autoplay_on",
        "video_source_duration"
    ];
    public var eventHandler = ["viewBegin", "error", "ended", "viewCompleted"];
    
    public init(nucleusState: NucleusState) {
        self.dispatchNucleusEvent = nucleusState
        self.actionableData = nucleusState.metadata
        self.tokenId = nucleusState.metadata["workspace_id"] as? String
        self.previousBeaconData = nil
        self.userData = FastPixUserDefaults.getViewerCookie()
        self.getFastPixAPI = formulateBeaconUrl(workspace: self.tokenId ?? "", config: self.actionableData ?? [:])
        self.eventDispatcher = ConnectionHandler(api: self.getFastPixAPI ?? "")
    }
    
    public func sendData(event: String, eventAttr: [String: Any]) {
        if  eventAttr["view_id"] != nil {
            let sessionData = FastPixUserDefaults.updateCookies()
            let deviceDetails = [
                "device_name": getDeviceModelName(),
                "device_model": getDeviceModelIdentifier() ,
                "os_version": getOSVersion()  ,
                "os_name": getOSName()   ,
                "browser_version": getAppVersion(),
                "browser": getAppName(),
                "device_category": getDeviceCategory()
            ]
            var fetchedVideoState : [String : Any] = [:]
            if (event != "viewCompleted") {
                fetchedVideoState = self.dispatchNucleusEvent.getVideoData()
            }
            let mergedData = mergeDictionaries(
                eventAttr,
                sessionData,
                deviceDetails,
                fetchedVideoState,
                self.userData,
                [
                    "event_name": event,
                    "workspace_id": self.tokenId ?? "",
                    "viewer_connection_type": getConnectionType()
                ]
            )
            var cloneBeaconObj = cloneBeaconData(eventName: event, dataObj: mergedData) ?? [:]
            if event == "variantChanged" {
                cloneBeaconObj["video_source_bitrate"] = eventAttr["video_source_bitrate"]
                cloneBeaconObj["video_source_height"] = eventAttr["video_source_height"] ?? self.previousBeaconData?["video_source_height"]
                cloneBeaconObj["video_source_width"] = eventAttr["video_source_width"] ?? self.previousBeaconData?["video_source_width"]
            }
            let formattedEvent = ConvertEventNamesToKeys.formatEventData(cloneBeaconObj)
            
            if (self.tokenId != nil) {
                self.eventDispatcher?.scheduleEvent(data: formattedEvent)
                
                if (event == "viewCompleted") {
                    self.eventDispatcher?.destroy(onDestroy: true)
                } else if (eventHandler.contains(event)) {
                    self.eventDispatcher?.processEventQueue()
                }
            }
        }
    }
    
    public func getConnectionType() -> String {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = "wifi"
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = "cellular"
                } else {
                    self.connectionType = "otherNetwork"
                }
            }
        }
        return connectionType
    }

    public func getDeviceCategory() -> String {
        
        switch UIDevice.current.userInterfaceIdiom {
        case .phone: return "Mobile"
        case .pad: return "iPad"
        case .tv: return "Apple TV"
        case .carPlay: return "CarPlay"
        case .mac: return "MacBook"
        default: return "Unknown"
        }
        
    }
    
    public func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version)(\(build))"
        }
        return ""
    }
    
    public func getAppName() -> String {
        let appName = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ??
        Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Unknown App"
        return appName ?? ""
    }
        
    // Method to get the OS Name
    public func getOSName() -> String {
        return UIDevice.current.systemName ?? ""
    }
    
    public func getDeviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        return identifier ?? ""
    }
    
    public func getOSVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    public func getDeviceModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machine = withUnsafeBytes(of: &systemInfo.machine) { bytes in
            return String(cString: bytes.baseAddress!.assumingMemoryBound(to: CChar.self))
        }
        
        return mapToDeviceName(identifier: machine)
    }

    // Mapping iOS device identifiers to human-readable names
    public func mapToDeviceName(identifier: String) -> String {
        let deviceMap: [String: String] = [
            // iPhone 16 Series (Speculative for 2024)
            "iPhone17,1": "iPhone 16",
            "iPhone17,2": "iPhone 16 Plus",
            "iPhone17,3": "iPhone 16 Pro",
            "iPhone17,4": "iPhone 16 Pro Max",
            
            // iPhone 15 Series (2023)
            "iPhone15,4": "iPhone 15",
            "iPhone15,5": "iPhone 15 Plus",
            "iPhone16,1": "iPhone 15 Pro",
            "iPhone16,2": "iPhone 15 Pro Max",
            
            // iPhone 14 Series (2022)
            "iPhone14,7": "iPhone 14",
            "iPhone14,8": "iPhone 14 Plus",
            "iPhone15,2": "iPhone 14 Pro",
            "iPhone15,3": "iPhone 14 Pro Max",
            
            // iPhone 13 Series (2021)
            "iPhone14,4": "iPhone 13 mini",
            "iPhone14,5": "iPhone 13",
            "iPhone14,2": "iPhone 13 Pro",
            "iPhone14,3": "iPhone 13 Pro Max",
            
            // iPhone 12 Series (2020)
            "iPhone13,1": "iPhone 12 mini",
            "iPhone13,2": "iPhone 12",
            "iPhone13,3": "iPhone 12 Pro",
            "iPhone13,4": "iPhone 12 Pro Max",
            
            // iPhone 11 Series (2019)
            "iPhone12,1": "iPhone 11",
            "iPhone12,3": "iPhone 11 Pro",
            "iPhone12,5": "iPhone 11 Pro Max",
            
            // iPhone XR, XS, XS Max (2018)
            "iPhone11,8": "iPhone XR",
            "iPhone11,2": "iPhone XS",
            "iPhone11,4": "iPhone XS Max",
            "iPhone11,6": "iPhone XS Max (Global)",
            
            // iPhone X (2017)
            "iPhone10,3": "iPhone X",
            "iPhone10,6": "iPhone X (Global)",
            
            // iPhone 8 Series (2017)
            "iPhone10,1": "iPhone 8",
            "iPhone10,4": "iPhone 8 (Global)",
            "iPhone10,2": "iPhone 8 Plus",
            "iPhone10,5": "iPhone 8 Plus (Global)",
            
            // iPhone 7 Series (2016)
            "iPhone9,1": "iPhone 7",
            "iPhone9,3": "iPhone 7 (Global)",
            "iPhone9,2": "iPhone 7 Plus",
            "iPhone9,4": "iPhone 7 Plus (Global)",
            
            // iPhone 6S Series (2015)
            "iPhone8,1": "iPhone 6s",
            "iPhone8,2": "iPhone 6s Plus",
            
            // iPhone 6 Series (2014)
            "iPhone7,2": "iPhone 6",
            "iPhone7,1": "iPhone 6 Plus",
            
            // iPhone SE Series
            "iPhone8,4": "iPhone SE (1st generation)",
            "iPhone12,8": "iPhone SE (2nd generation)",
            "iPhone14,6": "iPhone SE (3rd generation)",
            
            // iPhone 5 Series (2012-2013)
            "iPhone5,1": "iPhone 5 (GSM)",
            "iPhone5,2": "iPhone 5 (Global)",
            "iPhone5,3": "iPhone 5c (GSM)",
            "iPhone5,4": "iPhone 5c (Global)",
            "iPhone6,1": "iPhone 5s (GSM)",
            "iPhone6,2": "iPhone 5s (Global)",
            
            // iPhone 4 Series (2010-2011)
            "iPhone3,1": "iPhone 4 (GSM)",
            "iPhone3,2": "iPhone 4 (GSM Rev A)",
            "iPhone3,3": "iPhone 4 (CDMA)",
            "iPhone4,1": "iPhone 4S",
            
            // iPhone 3 Series (2008-2009)
            "iPhone1,2": "iPhone 3G",
            "iPhone2,1": "iPhone 3GS",
            
            // Original iPhone (2007)
            "iPhone1,1": "iPhone (1st generation)",

            // Apple TV
             "AppleTV2,1": "Apple TV (2nd generation)",
             "AppleTV3,1": "Apple TV (3rd generation)",
             "AppleTV3,2": "Apple TV (3rd generation, Rev A)",
             "AppleTV5,3": "Apple TV HD",
             "AppleTV6,2": "Apple TV 4K",
             "AppleTV11,1": "Apple TV 4K (2nd generation)",
             "AppleTV14,1": "Apple TV 4K (3rd generation, Wi-Fi)",
             "AppleTV14,2": "Apple TV 4K (3rd generation, Wi-Fi + Ethernet)"
        ]
        
        return deviceMap[identifier] ?? identifier // Return the identifier if not found
    }
    
    public func destroy() {
        self.eventDispatcher?.destroy(onDestroy: false)
    }
    
    func cloneBeaconData(eventName: String, dataObj: [String: Any]) -> [String: Any]? {
        var clonedObj: [String: Any] = [:]
            
        if eventName == "viewBegin" || eventName == "viewCompleted" {
            clonedObj = dataObj
            
            if eventName == "viewCompleted" {
                previousBeaconData = nil
            }
            previousBeaconData = clonedObj
        } else {
            for param in keyParams {
                if let value = dataObj[param] {
                    clonedObj[param] = value
                }
            }
            
            if let trimmedState = getTrimmedState(currentData: dataObj) {
                for (key, value) in trimmedState {
                    clonedObj[key] = value
                }
            }
            
            if ["requestCompleted", "requestFailed", "requestCanceled"].contains(eventName) {
                for (key, value) in dataObj {
                    if key.hasPrefix("request") {
                        clonedObj[key] = value
                    }
                }
            }
            previousBeaconData = clonedObj
        }
        if eventName == "viewCompleted" {
            var updatedClonedObj = clonedObj  // Start with a copy of the dictionary
            for param in videoMetadataParams {
                if clonedObj.keys.contains(param) {
                    updatedClonedObj.removeValue(forKey: param) // Remove the key if it exists
                }
            }
            updatedClonedObj["player_playhead_time"] = self.dispatchNucleusEvent.getCurrentPlayheadTime()
            return updatedClonedObj
        }
        return clonedObj
    }
    
    func getTrimmedState(currentData: [String: Any]) -> [String: Any]? {
        guard let previousData = previousBeaconData else {
            previousBeaconData = currentData
            return currentData
        }
        
        if !NSDictionary(dictionary: previousData).isEqual(to: currentData) {
            var trimmedData: [String: Any] = [:]
            
            for (key, value) in currentData {
                if previousVideoState[key] as? NSObject != value as? NSObject {
                    trimmedData[key] = value
                }
            }
            previousVideoState = currentData
            return trimmedData
        }
        return [:]
    }
    
    public func mergeDictionaries(_ dictionaries: [String: Any]...) -> [String: Any] {
        var mergedDictionary: [String: Any] = [:]
        
        for dictionary in dictionaries {
            for (key, value) in dictionary {
                if !(value is NSNull) {
                    mergedDictionary[key] = value
                }
            }
        }
        
        return mergedDictionary
    }
    
    public func formulateBeaconUrl(workspace: String, config: [String: Any], customDomain: String? = nil, customScheme: String = "https") -> String {
        let beaconDomain = customDomain ?? config["beaconDomain"] as? String ?? "metrix.ws"
        let finalWorkspace = workspace.isEmpty ? "workspaceId" : workspace
        return "\(customScheme)://\(finalWorkspace).\(beaconDomain)"
    }
}
