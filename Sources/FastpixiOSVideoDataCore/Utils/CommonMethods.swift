import Foundation
import AVFoundation

// UUID & Identifier Generation Methods (Placeholder functions)
func buildUUID() -> String {
    return UUID().uuidString.lowercased()
}

func generateIdToken() -> String {
    return UUID().uuidString.lowercased()
}

func generateRandomIdentifier() -> String {
    return UUID().uuidString.lowercased()
}

func getHostAndDomainName(from urlString: String?) -> (String?, String?) {
    guard let urlString = urlString,
          let url = URL(string: urlString),
          let host = url.host else {
        return ("localhost", nil)
    }
    
    let hostComponents = host.components(separatedBy: ".")
    
    // Extract domain (last two components)
    let domain = hostComponents.count > 1 ? hostComponents.suffix(2).joined(separator: ".") : nil
    
    return (host, domain)
}

/// Extracts only the hostname from a URL string.
/// - Parameter urlString: The URL as a string.
/// - Returns: The hostname, or `nil` if extraction fails.
func getHostName(from urlString: String?) -> String? {
    return getHostAndDomainName(from: urlString).0
}

/// Extracts only the domain name from a URL string.
/// - Parameter urlString: The URL as a string.
/// - Returns: The domain name, or `nil` if extraction fails.
func getDomainName(from urlString: String?) -> String? {
    return getHostAndDomainName(from: urlString).1
}

// Assign Unique Element ID (Placeholder for UI element handling in UIKit/AppKit)
func getElementId(from attr: String) -> String {
    return attr.isEmpty ? generateIdToken() : attr
}

// Video Element Analysis (Placeholder for HTML video handling)
func analyzeVideo(target: String) -> (String?, String, String) {
    let failureMessage = "video"
    return (target, target, failureMessage)
}

// Merge Objects
func mergeObjects<T: Any>(_ objects: T...) -> T where T: AnyObject {
    return objects.reduce(objects.first!) { (merged, obj) -> T in
        return obj
    }
}

// Increment a Metric
func metricUpdation(targetObject: inout [String: Int], eventName: String, incrementValue: Int = 1) {
    targetObject[eventName, default: 0] += incrementValue
}

// Check Do Not Track
func checkDoNotTrack() -> Bool {
    return false // Safari doesn't support Do Not Track anymore
}

// Event Listener Manager
class ListenerManager {
    private var events: [String: [((Any?) -> Void)]] = [:]
    
    func on(eventName: String, callback: @escaping (Any?) -> Void) {
        events[eventName, default: []].append(callback)
    }
    
    func off(eventName: String, callback: @escaping (Any?) -> Void) {
        events[eventName]?.removeAll { $0 as AnyObject === callback as AnyObject }
    }
    
    func emit(eventName: String, data: Any?) {
        events[eventName]?.forEach { $0(data) }
    }
}

// Timestamp Utility
struct Timestamp {
    static func now() -> TimeInterval {
        return Date().timeIntervalSince1970 * 1000
    }
}

// Performance Timing
struct CustomTimerModule {
    static func isPerformanceAvailable() -> Bool {
        return true // Placeholder for performance APIs
    }
    
    static func getDomContentLoadedEnd() -> TimeInterval? {
        return nil
    }
    
    static func getNavigationStartTime() -> TimeInterval? {
        return nil
    }
}

// Network Connection Type Detection
func checkNetworkBandwidth() -> String? {
    return nil // Network monitoring is not directly available in Swift
}

func getNetworkConnection() -> String? {
    switch checkNetworkBandwidth() {
    case "cellular": return "cellular"
    case "ethernet": return "wired"
    case "wifi": return "wifi"
    default: return "other"
    }
}

// Allowed Request Headers
let headerRequests: [String] = [
    "x-cdn", "content-type", "content-length", "last-modified", "server",
    "x-request-id", "cf-ray", "x-amz-cf-id", "x-akamai-request-id"
]

// Filter Headers by Allowed List
func filterHeadersByAllowedList(headerString: String) -> [String: String] {
    var filteredHeaders: [String: String] = [:]
    let allowedHeaders = Set(headerRequests.map { $0.lowercased() })
    
    let lines = headerString.split(separator: "\n").map { String($0) }
    for line in lines {
        let parts = line.split(separator: ":", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
        if parts.count == 2, allowedHeaders.contains(parts[0].lowercased()) {
            filteredHeaders[parts[0]] = parts[1]
        }
    }
    
    return filteredHeaders
}

// Utility Methods
struct UtilityMethods {
    static func convertSecToMs(seconds: Double) -> Int {
        return Int(seconds * 1000)
    }
    static func isolateHostAndDomainName(from url: String) -> (String?, String?) {
        return getHostAndDomainName(from: url)
    }
    static func fetchDomain(url: String) -> String? {
        return getDomainName(from: url)
    }
    static func fetchHost(url: String) -> String? {
        return getHostName(from: url)
    }
    static func generateIdToken() -> String {
        return generateIdToken()
    }
    static func getUUID() -> String {
        return buildUUID()
    }
    static func now() -> Int {
        return Int(Timestamp.now())
    }
}

// Exposing utilities
let utilityMethods = UtilityMethods.self
