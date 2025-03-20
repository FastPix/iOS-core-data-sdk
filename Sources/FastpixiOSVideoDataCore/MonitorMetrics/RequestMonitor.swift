import Foundation

public  class RequestMonitor {
    
    public var dispatchNucleusEvent: NucleusState
    public var requestCount: Int = 0
    public var processChunks: Int = 0
    public var totalBytes: Int = 0
    public var totalDuration: Int = 0
    public var totalLatency: Int = 0
    public var requestFailedCount: Int = 0
    
    public init(nucleusState: NucleusState) {
        self.dispatchNucleusEvent = nucleusState
        self.requestCount = 0
        self.processChunks = 0
        self.requestFailedCount = 0
        self.totalLatency = 0
    }
    
    public func processEvent(nucleusState: NucleusState, metadata: [String: Any]) {
        guard let eventName = nucleusState.data["event_name"] as? String else {
            return
        }
        
        self.dispatchNucleusEvent = nucleusState  // Update with the latest state
        switch eventName {
        case "requestCompleted":
            handleRequestCompleted(metadata: metadata)
            
        case "requestFailed":
            handleRequestFailed()
            
        default:
            break
        }
    }
    
    public func handleRequestCompleted(metadata: [String: Any]) {
        let requestStart = metadata["request_start"] as? Int ?? 0
        let responseStart = metadata["request_response_start"] as? Int ?? 0
        let responseEnd = metadata["request_response_end"] as? Int ?? 0
        let loadedBytes = metadata["request_bytes_loaded"] as? Int ?? 0
        
        self.requestCount += 1
        
        let latency = responseStart - requestStart
        
        let adjustedStart: Int
        if responseStart != 0 {
            adjustedStart = responseStart
        } else if requestStart != 0 {
            adjustedStart = requestStart
        } else {
            adjustedStart = 0
        }
        
        let duration = responseEnd - adjustedStart
        
        if (duration > 0 && loadedBytes > 0) {
            self.processChunks += 1
            self.totalBytes += loadedBytes
            self.totalDuration += duration
            
            let throughput = (loadedBytes / duration) * 8000
            self.dispatchNucleusEvent.data["view_min_request_throughput"] = min(self.dispatchNucleusEvent.data["view_min_request_throughput"] as? Float ?? 0.0, Float(throughput))
            self.dispatchNucleusEvent.data["view_avg_request_throughput"] = (self.totalBytes / self.totalDuration) * 8000
            self.dispatchNucleusEvent.data["view_request_count"] = self.requestCount
            
            if (latency > 0) {
                self.totalLatency += latency
                self.dispatchNucleusEvent.data["view_max_request_latency"] = max(self.dispatchNucleusEvent.data["view_max_request_latency"] as? Int ?? 0, latency)
                self.dispatchNucleusEvent.data["view_avg_request_latency"] = self.totalLatency / self.processChunks
            }
        }
    }
    
    public func handleRequestFailed() {
        self.requestCount += 1
        self.requestFailedCount += 1
        self.dispatchNucleusEvent.data["view_request_count"] = self.requestCount
        self.dispatchNucleusEvent.data["view_request_failed_count"] = self.requestFailedCount
    }
}
