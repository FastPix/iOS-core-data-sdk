
import Foundation

public  class VideoErrorHandler {
    
    public var hasErrorOccured: Bool = false
    public var dispatchNucleusEvent: NucleusState
    
    public init(nucleusState: NucleusState) {
        self.dispatchNucleusEvent = nucleusState
        self.hasErrorOccured = false
    }
    
    public func processEvent(nucleusState: NucleusState, metadata: [String: Any]) {
        guard let eventName = nucleusState.data["event_name"] as? String else {
            return
        }
        
        self.dispatchNucleusEvent = nucleusState
        switch eventName {
        case "error":
            handleErrorEvent(metadata: metadata)
            
        case "configureView":
            self.hasErrorOccured = false
            
        default:
            break
        }
    }
    
    public func handleErrorEvent(metadata: [String: Any]) {
        if (metadata["player_error_code"] != nil || metadata["player_error_context"] != nil || metadata["player_error_message"] != nil) {
            self.dispatchNucleusEvent.data["player_error_code"] = String(metadata["player_error_code"] as? String ?? "") ?? ""
            self.dispatchNucleusEvent.data["player_error_message"] = String(metadata["player_error_message"] as? String ?? "") ?? ""
            self.dispatchNucleusEvent.data["player_error_context"] = String(metadata["player_error_context"] as? String ?? "") ?? ""
        } else {
            self.dispatchNucleusEvent.data.removeValue(forKey: "player_error_code")
            self.dispatchNucleusEvent.data.removeValue(forKey: "player_error_message")
            self.dispatchNucleusEvent.data.removeValue(forKey: "player_error_description")
        }
    }
}
