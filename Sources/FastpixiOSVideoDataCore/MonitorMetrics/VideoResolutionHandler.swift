import Foundation

public  class VideoResolutionHandler {
    
    public var dispatchNucleusEvent: NucleusState
    public var previousPlayheadPosition: Int = 0
    public var prevPlayerWidth: Int = 0
    public var prevPlayerHeight: Int = 0
    public var prevVideoHeight: Int = 0
    public var prevVideoWidth: Int = 0
    
    init(nucleusState: NucleusState) {
        self.dispatchNucleusEvent = nucleusState
        self.prevVideoWidth = 0
        self.prevVideoHeight = 0
        self.prevPlayerHeight = 0
        self.prevPlayerWidth = 0
        self.previousPlayheadPosition = 0
    }
    
    public func processEvent(nucleusState: NucleusState) {
        guard let eventName = nucleusState.data["event_name"] as? String else {
            return
        }
        
        self.dispatchNucleusEvent = nucleusState  // Update with the latest state
        switch eventName {
        case "playing":
            updateResolutionSize()
            
        case "pulse", "pause", "buffering", "seeking", "error":
            updateScalingSize()
            if eventName == "pulse" {
                updateResolutionSize()
            }
            
        case "configureView":
            self.previousPlayheadPosition = 0
            self.prevVideoWidth = 0
            self.prevVideoHeight = 0
            self.prevPlayerHeight = 0
            self.prevPlayerWidth = 0
            
        default:
            break
        }
    }
    
    public func updateResolutionSize() {
        let getVideoStateData = self.dispatchNucleusEvent.getVideoData()
        let getCurrentPlayheadTime = self.dispatchNucleusEvent.getCurrentPlayheadTime()
        
        self.prevVideoWidth = getVideoStateData["video_source_width"] as? Int ?? 0
        self.prevVideoHeight = getVideoStateData["video_source_height"] as? Int ?? 0
        self.prevPlayerHeight = getVideoStateData["player_height"] as? Int ?? 0
        self.prevPlayerWidth =  getVideoStateData["player_width"] as? Int ?? 0
        self.previousPlayheadPosition = getCurrentPlayheadTime
    }
    
    public func updateScalingSize() {
        let currentPlayheadPosition = self.dispatchNucleusEvent.getCurrentPlayheadTime()
        if (self.previousPlayheadPosition >= 0 && currentPlayheadPosition >= 0 && self.prevPlayerWidth > 0 && self.prevPlayerHeight > 0 && self.prevVideoHeight > 0 && self.prevVideoWidth > 0 ) {
            
            let playheadDiff = Int(currentPlayheadPosition) - self.previousPlayheadPosition
            if (playheadDiff < 0) {
                return;
            }
            let getMinRatio = min(Double(self.prevPlayerWidth) / Double(self.prevVideoWidth), Double(self.prevPlayerHeight) / Double(self.prevVideoHeight))
            let maxScale = max(0, getMinRatio - 1)
            let minScale = max(0, 1 - getMinRatio)
            let prevMaxUpscalePercent = self.dispatchNucleusEvent.data["view_max_upscale_percentage"] as? Float ?? 0.0
            let prevMaxDownscalePercent = self.dispatchNucleusEvent.data["view_max_downscale_percentage"] as? Float ?? 0.0
            let viewTotalContentPlaybackTime = self.dispatchNucleusEvent.data["view_total_content_playback_time"] as? Int ?? 0
            let viewTotalDownscaling = self.dispatchNucleusEvent.data["view_total_downscaling"] as? Float ?? 0.0
            let viewTotalUpscaling = self.dispatchNucleusEvent.data["view_total_upscaling"] as? Float ?? 0.0
            self.dispatchNucleusEvent.data["view_max_upscale_percentage"] = max(prevMaxUpscalePercent, Float(maxScale))
            self.dispatchNucleusEvent.data["view_max_downscale_percentage"] = max(prevMaxDownscalePercent, Float(minScale))
            self.dispatchNucleusEvent.data["view_total_content_playback_time"] = viewTotalContentPlaybackTime  + playheadDiff
            self.dispatchNucleusEvent.data["view_total_downscaling"] = viewTotalDownscaling + (Float(minScale * Double(playheadDiff)))
            self.dispatchNucleusEvent.data["view_total_upscaling"] = viewTotalUpscaling + Float(maxScale * Double(playheadDiff))
        }
    }
}
