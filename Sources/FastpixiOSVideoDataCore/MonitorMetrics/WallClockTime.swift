import Foundation

public class WallClockTime {
    
    public var dispatchNucleusEvent: NucleusState
    public var lastTrackedWallClockTime: Int = 0
    
    init (nucleusState: NucleusState) {
        self.dispatchNucleusEvent = nucleusState
        self.lastTrackedWallClockTime = 0
    }
    
    func processEvent(nucleusState: NucleusState) {
        guard let eventName = nucleusState.data["event_name"] as? String else {
            return
        }
        
        self.dispatchNucleusEvent = nucleusState
        
        if let wallClockTimeStamp = nucleusState.data["viewer_timestamp"] as? Int {
            if eventName == "pulseStart" {
                captureCurrentWallClockTime(wallClockTimeStamp: wallClockTimeStamp)
            } else if eventName == "pulseEnd" {
                endWallClockTimeCapture(wallClockTimeStamp: wallClockTimeStamp)
            }
        }
    }
    
    func captureCurrentWallClockTime(wallClockTimeStamp: Int) {
        if self.lastTrackedWallClockTime == 0 {
            self.lastTrackedWallClockTime = wallClockTimeStamp
        } else {
            if wallClockTimeStamp != 0 {
                let timeElapsed = wallClockTimeStamp - self.lastTrackedWallClockTime
                let previousWatchTime = self.dispatchNucleusEvent.data["view_watch_time"] as? Int ?? 0
                self.dispatchNucleusEvent.data["view_watch_time"] = previousWatchTime + timeElapsed
                self.lastTrackedWallClockTime = wallClockTimeStamp
            } else {
                self.lastTrackedWallClockTime = wallClockTimeStamp
            }
        }
    }
    
    func endWallClockTimeCapture(wallClockTimeStamp: Int) {
        captureCurrentWallClockTime(wallClockTimeStamp: wallClockTimeStamp)
        self.lastTrackedWallClockTime = 0
    }
}
