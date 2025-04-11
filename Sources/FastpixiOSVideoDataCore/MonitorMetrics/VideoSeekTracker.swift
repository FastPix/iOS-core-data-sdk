import Foundation

public  class VideoSeekTracker {
    
    public var dispatchNucleusEvent: NucleusState
    public var isVideoSeeked: Bool = false
    public var captureSeekStartTime: Int = 0
    
    init(nucleusState: NucleusState) {
        self.dispatchNucleusEvent = nucleusState
        self.isVideoSeeked = false
        self.captureSeekStartTime = 0
    }
    
    public func processEvent(nucleusState: NucleusState) {
        guard let eventName = nucleusState.data["event_name"] as? String else {
            return
        }
        
        self.dispatchNucleusEvent = nucleusState  // Update with the latest state
        let viewerTimestamp = nucleusState.data["viewer_timestamp"] as? Int
        if (eventName == "seeking") {
            handleSeeking(viewerTimestamp: viewerTimestamp ?? 0)
        } else if (eventName == "seeked") {
            handleSeeked(viewerTimestamp: viewerTimestamp ?? 0)
        } else if (eventName == "viewCompleted") {
            handleViewCompleted(viewerTimestamp: viewerTimestamp ?? 0)
        } else if (eventName == "configureView") {
            self.isVideoSeeked = false
            self.captureSeekStartTime = 0
        }
    }
    
    public func handleSeeking(viewerTimestamp: Int) {
        if (self.isVideoSeeked && viewerTimestamp - self.captureSeekStartTime <= 2000) {
            self.captureSeekStartTime = viewerTimestamp
        } else {
            if (self.isVideoSeeked) {
                seeker(viewerTimestamp: viewerTimestamp)
            }
            self.isVideoSeeked = true
            self.dispatchNucleusEvent.isVideoSeeking = true
            self.captureSeekStartTime = viewerTimestamp
            self.dispatchNucleusEvent.data["view_seek_count"] = (self.dispatchNucleusEvent.data["view_seek_count"] as? Int ?? 0) + 1
            self.dispatchNucleusEvent.filterData(eventName: "seeking")
        }
    }
    
    public func handleSeeked(viewerTimestamp: Int) {
        seeker(viewerTimestamp: viewerTimestamp)
    }
    
    public func handleViewCompleted(viewerTimestamp: Int) {
        if (self.isVideoSeeked){
            seeker(viewerTimestamp: viewerTimestamp)
            self.dispatchNucleusEvent.filterData(eventName: "seeked")
        }
        self.isVideoSeeked = false
        self.dispatchNucleusEvent.isVideoSeeking = false
        self.captureSeekStartTime = 0
    }
    
    public func seeker(viewerTimestamp: Int) {
        let seekedTime = Int(Date().timeIntervalSince1970 * 1000)
        let elapsedSeekTime = (viewerTimestamp ?? seekedTime) - (self.captureSeekStartTime ?? seekedTime)
        self.dispatchNucleusEvent.data["view_seek_duration"] = (self.dispatchNucleusEvent.data["view_seek_duration"] as? Int ?? 0) + elapsedSeekTime
        self.dispatchNucleusEvent.data["view_max_seek_time"] = max((self.dispatchNucleusEvent.data["view_max_seek_time"] as? Int ?? 0 ), elapsedSeekTime)
        self.isVideoSeeked = false
        self.dispatchNucleusEvent.isVideoSeeking = false
        self.captureSeekStartTime = 0
    }
}
