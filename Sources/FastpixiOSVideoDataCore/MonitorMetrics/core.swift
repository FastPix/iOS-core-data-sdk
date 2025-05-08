import Foundation
import UIKit

public class NucleusState {
    
    let commonMethods = utilityMethods
    lazy var wallClockTime: WallClockTime = WallClockTime(nucleusState: self)
    lazy var playbackPulseHandler: PlaybackPulseHandler = PlaybackPulseHandler(nucleusState: self)
    lazy var seekingHandler: VideoSeekTracker = VideoSeekTracker(nucleusState: self)
    lazy var resolutionHandler: VideoResolutionHandler = VideoResolutionHandler(nucleusState: self)
    lazy var bufferMonitorHandler: VideoBufferMonitor = VideoBufferMonitor(nucleusState: self)
    lazy var bufferProcessorHandler: VideoBufferProcessor = VideoBufferProcessor(nucleusState: self)
    lazy var startupMetricsHandler: VideoStartupMetricsHandler = VideoStartupMetricsHandler(nucleusState: self)
    lazy var videoProgressHandler: VideoProgressMonitor = VideoProgressMonitor(nucleusState: self)
    lazy var playheadPositionHandler: PlayheadPositionHandler = PlayheadPositionHandler(nucleusState: self)
    lazy var playbackEventHandler: PlybackPulseHadler = PlybackPulseHadler(nucleusState: self)
    lazy var requestMetricsHandler: RequestMonitor = RequestMonitor(nucleusState: self)
    lazy var playbackFailureHandler: VideoErrorHandler = VideoErrorHandler(nucleusState: self)
    
    public var key: String
    public var metadata: [String: Any]
    public var data: [String: Any] = [:]
    public var lastCheckedEventTime: Int
    public var playerInitializationTime: Int
    public var utilMethods: Any
    public var getVideoData: () -> [String:Any]
    public var getCurrentPlayheadTime: () -> Int
    public var isVideoPlaying: Bool
    public var isVideoBuffering: Bool
    public var isVideoSeeking: Bool
    public var isVideoErrorOccured: Bool
    public var playerDestroyed: Bool
    public var throbInterval: Timer?
    public var mapEvents: [String] = [
        "playerReady",
        "variantChanged",
        "viewBegin",
        "ended",
        "pause",
        "play",
        "playing",
        "buffering",
        "buffered",
        "seeked",
        "error",
        "pulse",
        "requestCompleted",
        "requestFailed",
        "requestCanceled"
    ]
    
    public init(key: String, passableMetadata: [String: Any], fetchPlayheadTime: @escaping () -> Int,
                fetchVideoState: @escaping () -> [String:Any]) {
        self.key = key
        self.metadata = passableMetadata["data"] as! [String : Any]
        self.utilMethods = commonMethods
        self.getVideoData = fetchVideoState
        self.getCurrentPlayheadTime = fetchPlayheadTime
        self.playerInitializationTime = commonMethods.now()
        self.isVideoPlaying = false
        self.isVideoBuffering = false
        self.isVideoSeeking = false
        self.isVideoErrorOccured = false
        self.playerDestroyed = false
        self.data = [
            "player_sequence_number": 1, 
            "view_sequence_number": 1,
            "player_instance_id": commonMethods.getUUID().lowercased(),
            "beacon_domain": (passableMetadata["configDomain"] as? String) ?? "metrix.ws",
            "workspace_id": (self.metadata["workspace_id"] as? String) ?? "workspaceId"
        ]

        self.lastCheckedEventTime = 0
        self.dispatchEvent(event: "configureView", eventmetadata: [:])
        
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIScreen.didDisconnectNotification, object: nil)
    }
    
    func emitEvents(event: String, eventmetadata: [String: Any]) {
        let currentTime = commonMethods.now()
        let getCurrentVideoState = self.getVideoData()
        
        self.data["event_name"] = event
        self.data["viewer_timestamp"] = currentTime
        if (event != "viewCompleted") {
            self.data.merge(eventmetadata) { (_, new) in new }
            self.data.merge(getCurrentVideoState) { (_, new) in new }
        }
        
        if (event == "configureView") {
            self.playerDestroyed = false
            refreshViewData()
            refreshVideoData()
            appendVideoState()
            self.playerInitializationTime = commonMethods.now()
            self.data.merge(self.metadata) { (_, new) in new }
            initializeView()
        }
        
        if event == "variantChanged" {
            self.data["video_source_bitrate"] = eventmetadata["video_source_bitrate"] ?? self.data["video_source_bitrate"]
        }

        playbackFailureHandler.processEvent(nucleusState: self, metadata: eventmetadata)
        seekingHandler.processEvent(nucleusState: self)
        requestMetricsHandler.processEvent(nucleusState: self, metadata: eventmetadata)
        playheadPositionHandler.processEvent(nucleusState: self)
        playbackPulseHandler.processEvent(nucleusState: self)
        resolutionHandler.processEvent(nucleusState: self)
        wallClockTime.processEvent(nucleusState: self)
        videoProgressHandler.processEvent(nucleusState: self)
        bufferMonitorHandler.processEvent(nucleusState: self)
        bufferProcessorHandler.processEvent(nucleusState: self)
        startupMetricsHandler.processEvent(nucleusState: self)
        
        if (event == "destroy") {
            demolishView()
            dispatchEvent(event: "configureView", eventmetadata: [:])
        }
        
        if (mapEvents.contains(event)) {
            appendVideoState()
            validateData()
            filterData(eventName: event)
        }
        
        self.lastCheckedEventTime = currentTime
    }
    
    @objc func appWillTerminate() {
        demolishView()
    }
    
    func dispatchEvent(event: String, eventmetadata: [String: Any]) {
        if (event == "play") {
            if (self.data["view_start"] == nil) {
                emitEvents(event: "viewBegin", eventmetadata: ["view_start" : Int(Date().timeIntervalSince1970 * 1000)])
            }
        }
        
        if (event == "videoChange") {
            demolishView()
            dispatchEvent(event: "configureView", eventmetadata: eventmetadata)
        }
        emitEvents(event: event, eventmetadata: eventmetadata)
    }
    
    func demolishView() {
        if self.playerDestroyed as? Bool ?? false {
            return
        }
        
        self.playerDestroyed = true
        
        if self.data["view_start"] != nil {
            self.dispatchEvent(event: "viewCompleted", eventmetadata: [:])
            self.filterData(eventName: "viewCompleted")
            playbackEventHandler.destroy()
        }
    }
    
    func initializeView() {
        self.data["view_id"] = UUID().uuidString.lowercased()
        self.data["player_view_count"] = (self.data["player_view_count"] as? Int ?? 0) + 1
        self.playerInitializationTime = Int(Date().timeIntervalSince1970 * 1000)
    }
    
    func appendVideoState() {
        self.data["player_playhead_time"] = self.getCurrentPlayheadTime()
        self.validateData()
    }
    
    func validateData() {
        let numericalKeys = [
            "player_width",
            "player_height"
        ]
        
        let urlKeys = ["player_source_url", "video_source_url"]
        
        for numericalKey in numericalKeys {
            if let value = self.data[numericalKey] as? String, let intValue = Int(value) {
                self.data[numericalKey] = intValue
            } else {
                self.data[numericalKey] = nil
            }
        }
        
        for urlKey in urlKeys {
            if let value = self.data[urlKey] as? String {
                let lowercased = value.lowercased()
                if lowercased.hasPrefix("data:") || lowercased.hasPrefix("blob:") {
                    self.data[urlKey] = "MSE style URL"
                }
            }
        }
    }
    
    func filterData(eventName: String) {
        guard let _ = self.data["view_id"] else { return }
        
        if let playerDuration = self.data["player_source_duration"] as? Int,
           let videoDuration = self.data["video_source_duration"] as? Int {
            self.data["video_source_is_live"] = (playerDuration > 0 || videoDuration > 0)
        } else if self.data["video_source_duration"] == nil {
            self.data["video_source_is_live"] = true
        }
        
        if let videoSourceUrl = (self.data["video_source_url"] as? String) ?? (self.data["player_source_url"] as? String) {
            self.data["video_source_domain"] = commonMethods.fetchDomain(url: videoSourceUrl)
            self.data["video_source_hostname"] = commonMethods.fetchHost(url: videoSourceUrl)
        }
        
        let updatedData = self.data
        playbackEventHandler.sendData(event: eventName, eventAttr: updatedData)
        
        self.data["view_sequence_number"] = (self.data["view_sequence_number"] as? Int ?? 0) + 1
        self.data["player_sequence_number"] = (self.data["player_sequence_number"] as? Int ?? 0) + 1
        
        handlePulseEvent(event: updatedData)
        
        if eventName == "viewCompleted" {
            self.data.removeValue(forKey: "view_id")
        }
    }
    
    func handlePulseEvent(event: [String: Any]) {
        guard let playerPaused = event["player_is_paused"] as? Bool,
              let errorStatus = self.isVideoErrorOccured as? Bool else {
            return
        }
        
        self.throbInterval?.invalidate()
        
        if !errorStatus {
            self.throbInterval = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
                if !playerPaused {
                    self?.emitPulse()
                }
            }
        }
    }
    
    func emitPulse() {
        dispatchEvent(event: "pulse", eventmetadata: [:])
    }

    deinit {
        // Remove observer for app termination to avoid potential retain cycles or memory leaks
        NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
        
        // Remove observer for screen disconnection
        NotificationCenter.default.removeObserver(self, name: UIScreen.didDisconnectNotification, object: nil)
    }

    func refreshViewData() {
        self.data.keys.forEach { key in
            if key.hasPrefix("view_") {
                self.data.removeValue(forKey: key)
            }
        }
        self.data["view_sequence_number"] = 1
    }
    
    func refreshVideoData() {
        self.data.keys.forEach { key in
            if key.hasPrefix("video_") {
                self.data.removeValue(forKey: key)
            }
        }
    }}

public class FastpixMetrix {
    
    private var playerInitKey: [String: NucleusState]
    
    public init() {
        self.playerInitKey = [:]
    }
    
    public func configure(key: String,
                          passableMetadata: [String: Any],
                          fetchPlayheadTime: @escaping () -> Int,
                          fetchVideoState: @escaping () -> [String:Any]) {
        if playerInitKey[key] == nil {
            playerInitKey[key] = NucleusState(key: key, passableMetadata: passableMetadata, fetchPlayheadTime: fetchPlayheadTime, fetchVideoState: fetchVideoState)
        }
    }
    
    /// **Dispatch an event to a specific player instance**
    public func dispatch(key: String, event: String, metadata: [String: Any]) {
        if let nucleusInstance = playerInitKey[key] {
            nucleusInstance.dispatchEvent(event: event, eventmetadata: metadata)
        }
    }
}
