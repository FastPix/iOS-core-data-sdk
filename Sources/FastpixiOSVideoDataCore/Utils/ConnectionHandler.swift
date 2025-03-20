
import Foundation

public class ConnectionHandler {
    
    public let postApiUrl: String
    public var eventStack: [[String: Any]] = []
    public var checkPostData: Bool = false
    public var callPostTimer: Timer?
    public var destroyed: Bool = false
    public var chunkTimer: TimeInterval?
    
    init(api: String) {
        self.postApiUrl = api
    }
    
    // Schedule an event and trigger processing
    func scheduleEvent(data: [String: Any]) {
        eventStack.append(data)
        destroyed = false
        if callPostTimer == nil {
            triggerBeaconDispatch()
        }
    }
    
    // Process queued events
    func processEventQueue() {
        emitBeaconQueue()
        triggerBeaconDispatch()
    }
    
    // Destroy connection and process/purge queue
    func destroy(onDestroy: Bool) {
        destroyed = true
        
        if onDestroy {
            purgeBeaconQueue()
        } else {
            processEventQueue()
        }
        
        callPostTimer?.invalidate()
    }
    
    // Purge older events if queue exceeds 200 items
    private func purgeBeaconQueue() {
        let excessLength = eventStack.count - 200
        let trimmedStack = excessLength > 0 ? Array(eventStack.suffix(200)) : eventStack
        let postData = generatePayload(events: trimmedStack)
        
        makeApiCall(url: postApiUrl, payload: postData, destroyer: true) { _, _ in }
    }
    
    // Send events in batches
    private func emitBeaconQueue() {
        guard !checkPostData else { return }
        
        let stackedEvents = Array(eventStack.prefix(200))
        let payload = generatePayload(events: stackedEvents)
        let preApiCallTime = Date().timeIntervalSince1970
        
        eventStack = Array(eventStack.dropFirst(200))
        checkPostData = true
        
        makeApiCall(url: postApiUrl, payload: payload, destroyer: false) { _, error in
            if let error = error {
                self.eventStack.insert(contentsOf: stackedEvents, at: 0)

            }
            self.chunkTimer = Date().timeIntervalSince1970 - preApiCallTime
            self.checkPostData = false
        }
    }
    
    // Dispatch beacon event after 10s if not destroyed
    private func triggerBeaconDispatch() {
        callPostTimer?.invalidate()
        
        if !destroyed {
            callPostTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { _ in
                if !self.eventStack.isEmpty {
                    self.emitBeaconQueue()
                }
                self.triggerBeaconDispatch()
            }
        }
    }
    
    // Generate JSON payload for API request
    private func generatePayload(events: [[String: Any]]) -> String {
        var chunkDetails: [String: Any] = [
            "transmission_timestamp": Int(Date().timeIntervalSince1970)
        ]
        
        if let chunkTimer = chunkTimer {
            chunkDetails["rtt_ms"] = Int(chunkTimer * 1000)  // Convert to milliseconds
        }
        
        let payload: [String: Any] = [
            "metadata": chunkDetails,
            "events": events
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) {
            return String(data: jsonData, encoding: .utf8) ?? "{}"
        }
        
        return "{}"
    }
    
    // Perform an API request
    private func makeApiCall(url: String, payload: String, destroyer: Bool, completion: @escaping (Data?, String?) -> Void) {
        guard let url = URL(string: url) else {
            completion(nil, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = payload.data(using: .utf8)
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error.localizedDescription)
            } else {
                let httpResponse = response as? HTTPURLResponse
                completion(data, httpResponse?.statusCode == 200 ? nil : "Error")
            }
        }
        
        task.resume()
    }
}
