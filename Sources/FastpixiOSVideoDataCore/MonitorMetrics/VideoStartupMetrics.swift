import Foundation

public  class VideoStartupMetricsHandler {
    
    public var dispatchNucleusEvent: NucleusState
    public var viewTimeToFirstFrame: Int = 0
    
    public init(nucleusState: NucleusState) {
        self.dispatchNucleusEvent = nucleusState
        self.viewTimeToFirstFrame = 0
    }
    
    public func processEvent(nucleusState: NucleusState) {
        guard let eventName = nucleusState.data["event_name"] as? String else {
            return
        }
        
        self.dispatchNucleusEvent = nucleusState  // Update with the latest state
        let timestamp = nucleusState.data["viewer_timestamp"] as? Int ?? 0
        switch eventName {
        case "playing":
            handleTimeToFirstFrame(timestamp: timestamp)
            
        case "configureView":
            self.viewTimeToFirstFrame = 0
            
        default:
            break
        }
    }
    
    public func handleTimeToFirstFrame(timestamp: Int) {
        let currentTime = Int(Date().timeIntervalSince1970 * 1000)
        self.dispatchNucleusEvent.wallClockTime.captureCurrentWallClockTime(wallClockTimeStamp: currentTime)
        
        if self.viewTimeToFirstFrame == 0 {
            if (self.dispatchNucleusEvent.playerInitializationTime > 0) {
                self.dispatchNucleusEvent.data["view_time_to_first_frame"] = currentTime - (self.dispatchNucleusEvent.playerInitializationTime as? Int ?? 0 )
            } else if (self.dispatchNucleusEvent.data["view_start"] as! Int > 0) {
                self.dispatchNucleusEvent.data["view_time_to_first_frame"] = currentTime - (self.dispatchNucleusEvent.data["view_start"] as? Int ?? 0 )
            } else if ((self.dispatchNucleusEvent.data["view_watch_time"] as? Int ?? 0 ) > 0) {
                self.dispatchNucleusEvent.data["view_time_to_first_frame"] = self.dispatchNucleusEvent.data["view_watch_time"]
            }
            
            viewTimeToFirstFrame = self.dispatchNucleusEvent.data["view_time_to_first_frame"] as? Int ?? 0
        }
    }
}
