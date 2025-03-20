import Foundation

public  class VideoProgressMonitor {
    
    public var dispatchNucleusEvent: NucleusState
    public var playbackTimeTrackerLastPosition: Int = 0
    public var prevplaybackTime: Int = 0
    public var prevProgressPlaybackTime: Int = 0
    public var playbackProgressCallback = false
    
    public init(nucleusState: NucleusState) {
        self.dispatchNucleusEvent = nucleusState
        self.playbackTimeTrackerLastPosition = 0
        self.prevplaybackTime = 0
        self.prevProgressPlaybackTime = 0
        self.playbackProgressCallback = false
    }
    
    public func processEvent(nucleusState: NucleusState) {
        guard let eventName = nucleusState.data["event_name"] as? String else {
            return
        }
        
        self.dispatchNucleusEvent = nucleusState  // Update with the latest state
        switch eventName {
        case "pulseStart":
            onPulseStartPlaybackMonitoring()
            
        case "playing" , "seeked":
            initiatePlaybackMonitoring()
            
        case "seeking", "pulseEnd":
            stopPlaybackMonitoring()
            
        case "configureView":
            resetState()
            
        default:
            break
        }
    }
    
    public func onPulseStartPlaybackMonitoring() {
        if (self.playbackProgressCallback) {
            refreshPlaybackMonitoring()
        }
    }
    
    public func initiatePlaybackMonitoring() {
        if (!self.playbackProgressCallback) {
            refreshPlaybackMonitoring()
            self.playbackProgressCallback = true
            self.playbackTimeTrackerLastPosition = self.dispatchNucleusEvent.getCurrentPlayheadTime()
        }
    }
    
    public func stopPlaybackMonitoring() {
        if (self.playbackProgressCallback) {
            refreshPlaybackMonitoring()
            self.playbackProgressCallback = false
            self.playbackTimeTrackerLastPosition = 0
            self.prevProgressPlaybackTime = 0
        }
    }
    
    public func refreshPlaybackMonitoring() {
        let playbackTimer = self.dispatchNucleusEvent.getCurrentPlayheadTime()
        let playbackProgressTime = Int(Date().timeIntervalSince1970 * 1000)
        var total = 0
        
        if (self.playbackTimeTrackerLastPosition >= 0 && playbackTimer > self.playbackTimeTrackerLastPosition) {
            total = playbackTimer - self.playbackTimeTrackerLastPosition
        }
        
        if (total > 0  && total <= 1000) {
            self.dispatchNucleusEvent.data["view_content_playback_time"] = (self.dispatchNucleusEvent.data["view_content_playback_time"] as? Int ?? 0) + total
        }
        
        self.playbackTimeTrackerLastPosition = playbackTimer
        self.prevplaybackTime = playbackProgressTime
    }
    
    public func resetState() {
        self.playbackTimeTrackerLastPosition = 0
        self.prevplaybackTime = Int(Date().timeIntervalSince1970 * 1000)
        self.playbackProgressCallback = false
        self.prevProgressPlaybackTime = 0
    }
}
