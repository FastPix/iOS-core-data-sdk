import Foundation

public class PlaybackPulseHandler {
    
    public var timerInterval: Timer? = nil
    public var playHeadProgressing: Bool = false
    public var dispatchNucleusEvent: NucleusState // Declare dispatchNucleusEvent as a stored property
    
    init(nucleusState: NucleusState) {
        self.timerInterval = nil
        self.playHeadProgressing = false
        self.dispatchNucleusEvent = nucleusState
    }
    
    func processEvent(nucleusState: NucleusState) {
        
        guard let eventName = nucleusState.data["event_name"] as? String else {
            return
        }
        
        self.dispatchNucleusEvent = nucleusState  // Update with the latest state
        switch eventName {
        case "play", "buffering", "viewBegin":
            startTimer()
            
        case "playing":
            self.playHeadProgressing = true
            self.dispatchNucleusEvent.isVideoPlaying = true
            startTimer()
            
        case "pause", "ended", "viewCompleted", "error":
            stopPulseTimer()
            
        case "seeked":
            let isPlayerPaused = nucleusState.data["player_is_paused"] as? Bool ?? false
            isPlayerPaused ? stopPulseTimer() : startTimer()
        
        case "timeupdate":
            if (timerInterval != nil) {
                self.dispatchNucleusEvent.dispatchEvent(event: "pulseStart", eventmetadata: [:])
            }
            
        default:
            break
        }
    }
    
    func startTimer() {
        if timerInterval == nil {
            timerInterval = Timer.scheduledTimer(withTimeInterval: 0.025, repeats: true) { [weak self] _ in
                self?.dispatchNucleusEvent.dispatchEvent(event: "pulseStart", eventmetadata: [:])
            }
        }
    }
    
    func stopPulseTimer() {
        if let timer = timerInterval {
            timer.invalidate()
            timerInterval = nil
            playHeadProgressing = false
            self.dispatchNucleusEvent.isVideoPlaying = false
            dispatchNucleusEvent.dispatchEvent(event: "pulseEnd", eventmetadata: [:])
        }
    }
}
