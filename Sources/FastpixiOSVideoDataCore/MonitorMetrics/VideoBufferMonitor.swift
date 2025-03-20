import Foundation

public  class VideoBufferMonitor {
    
    public var dispatchNucleusEvent: NucleusState
    public var lastCheckedTime: Int = 0
    public var lastPlayHeadTime: Int = 0
    public var lastUpdatedTime: Int = 0
    public var viewBufferStarTime: Int = 0
    public var isBuffering: Bool = false
    
    public init(nucleusState: NucleusState) {
        self.dispatchNucleusEvent = nucleusState
        self.lastCheckedTime = 0
        self.lastPlayHeadTime = 0
        self.lastUpdatedTime = 0
        self.viewBufferStarTime = 0
        self.isBuffering = false
    }
    
    public func processEvent(nucleusState: NucleusState) {
        guard let eventName = nucleusState.data["event_name"] as? String else {
            return
        }
        
        self.dispatchNucleusEvent = nucleusState  // Update with the latest state
        let timestamp = nucleusState.data["viewer_timestamp"] as? Int ?? 0
        switch eventName {
        case "pulseStart":
            checkForBuffering(timestamp: timestamp)
            
        case "seeking", "viewCompleted", "pulseEnd":
            handleBufferingEnd(timestamp: timestamp)
            
        case "configureView":
            clearBufferingState()
            self.isBuffering = false
            
        default:
            break
        }
    }
    
    func updateBufferTiming(timestamp: Int) {
        self.lastCheckedTime = timestamp
        self.lastUpdatedTime = timestamp
        self.lastPlayHeadTime = self.dispatchNucleusEvent.getCurrentPlayheadTime()
        
    }
    
    func clearBufferingState() {
        self.lastCheckedTime = 0
        self.lastUpdatedTime = 0
        self.lastPlayHeadTime = 0
    }
    
    func triggerBufferingEvent(timestamp: Int) {
        self.isBuffering = true
        self.dispatchNucleusEvent.isVideoBuffering = true
        self.dispatchNucleusEvent.dispatchEvent(event: "buffering", eventmetadata: ["viewer_timestamp": timestamp])
    }
    
    func triggerBufferedEvent(timestamp: Int) {
        self.isBuffering = false
        self.dispatchNucleusEvent.isVideoBuffering = false
        self.dispatchNucleusEvent.dispatchEvent(event: "buffered", eventmetadata: ["viewer_timestamp": timestamp])
    }
    
    func bufferHasSignificantProgress(timestamp: Int) -> Bool {
        let playheadDifference = self.dispatchNucleusEvent.getCurrentPlayheadTime() - self.lastPlayHeadTime
        let viewerTimeDifference = timestamp - self.lastUpdatedTime
        
        return playheadDifference > 0 && viewerTimeDifference - playheadDifference > 250
    }
    
    func handleImmediateBuffering(timestamp: Int) {
        let playheadDifference = self.dispatchNucleusEvent.getCurrentPlayheadTime() - self.lastPlayHeadTime
        let viewerTimeDifference = timestamp - self.lastUpdatedTime
        let bufferedTimeStamp = self.lastUpdatedTime + viewerTimeDifference - playheadDifference
        
        self.dispatchNucleusEvent.dispatchEvent(event: "buffering", eventmetadata: ["viewer_timestamp": timestamp])
        self.dispatchNucleusEvent.dispatchEvent(event: "buffered", eventmetadata: ["viewer_timestamp": bufferedTimeStamp])
        self.lastCheckedTime = 0
    }
    
    func checkForBuffering(timestamp: Int) {
        
        if (self.dispatchNucleusEvent.isVideoSeeking || !self.dispatchNucleusEvent.isVideoPlaying) {
            handleBufferingEnd(timestamp: timestamp)
        } else {
            
            if (self.lastCheckedTime == 0) {
                updateBufferTiming(timestamp: timestamp)
            }
            
            if (self.lastCheckedTime > 0) {
                let currentPlayheadTime = self.dispatchNucleusEvent.getCurrentPlayheadTime()
                
                if (self.lastPlayHeadTime == currentPlayheadTime) {
                    let elapsed = timestamp - self.lastUpdatedTime
                    if (elapsed >= 1000 && !self.isBuffering) {
                        triggerBufferingEvent(timestamp: timestamp)
                    }
                    self.lastCheckedTime = timestamp
                } else {
                    handleBufferingEnd(timestamp: timestamp, reset: true)
                }
            }
        }
    }
    
    func handleBufferingEnd(timestamp: Int, reset: Bool = false) {
        if (self.isBuffering) {
            triggerBufferedEvent(timestamp: timestamp)
        } else {
            if (self.lastCheckedTime == 0) {
                return;
            }
            
            if (bufferHasSignificantProgress(timestamp: timestamp)) {
                handleImmediateBuffering(timestamp: timestamp)
            }
        }
        
        if (reset) {
            updateBufferTiming(timestamp: timestamp)
        } else{
            clearBufferingState()
        }
    }
}
