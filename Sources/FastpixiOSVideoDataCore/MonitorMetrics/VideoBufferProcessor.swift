import Foundation

public  class VideoBufferProcessor {
    
    public var dispatchNucleusEvent: NucleusState
    public var viewBufferStarTime: Int = 0
    
    public init(nucleusState: NucleusState) {
        self.dispatchNucleusEvent = nucleusState
        self.viewBufferStarTime = 0
    }
    
    public func processEvent(nucleusState: NucleusState) {
        guard let eventName = nucleusState.data["event_name"] as? String else {
            return
        }
        
        self.dispatchNucleusEvent = nucleusState  // Update with the latest state
        let timestamp = nucleusState.data["viewer_timestamp"] as? Int ?? 0
        switch eventName {
        case "pulseStart":
            processBufferMetrics(timestamp: timestamp)
            
        case "buffering":
            handleBufferStartMetrics(timestamp: timestamp)
            
        case "buffered":
            handleBufferEndMetrics(timestamp: timestamp)
            
        case "configureView":
            self.viewBufferStarTime = 0
            
        default:
            break
        }
    }
    
    func handleBufferStartMetrics(timestamp: Int) {
        if self.viewBufferStarTime == 0 {  // Buffering just started
            let getViewBufferCount = self.dispatchNucleusEvent.data["view_rebuffer_count"] as? Int ?? 0
            self.dispatchNucleusEvent.data["view_rebuffer_count"] = getViewBufferCount + 1
            print("The rebuffer count is : \(getViewBufferCount + 1)")
            self.viewBufferStarTime = timestamp
        }
    }
    
    func handleBufferEndMetrics(timestamp: Int) {
        processBufferMetrics(timestamp: timestamp)
        self.viewBufferStarTime = 0
    }
    
    func processBufferMetrics(timestamp: Int) {
        if self.viewBufferStarTime > 0 {
            let timeDifference = timestamp - self.viewBufferStarTime
            let getViewBufferDuration = self.dispatchNucleusEvent.data["view_rebuffer_duration"] as? Int ?? 0
            self.dispatchNucleusEvent.data["view_rebuffer_duration"] = abs(getViewBufferDuration + timeDifference)
            self.viewBufferStarTime = timestamp
        }
        
        let viewWatchTime = self.dispatchNucleusEvent.data["view_watch_time"] as? Int ?? 0
        let viewRebufferCount = self.dispatchNucleusEvent.data["view_rebuffer_count"] as? Int ?? 0
        let viewRebufferDuration = self.dispatchNucleusEvent.data["view_rebuffer_duration"] as? Int ?? 0
        
        if viewWatchTime > 0 {
            if viewRebufferCount > 0 {
                self.dispatchNucleusEvent.data["view_rebuffer_frequency"] = Float(viewRebufferCount) / Float(viewWatchTime)
            }
            if viewRebufferDuration > 0 {
                self.dispatchNucleusEvent.data["view_rebuffer_percentage"] = Float(viewRebufferDuration) / Float(viewWatchTime)
            }
        }
    }
}
