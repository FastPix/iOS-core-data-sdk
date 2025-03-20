import Foundation

let fastPixUserDefaultsKey = "FastPixUserSession"

struct FastPixUserDefaults {
    
    static func getViewerData() -> [String: Any] {
        if let data = UserDefaults.standard.dictionary(forKey: fastPixUserDefaultsKey) {
            return data
        }
        return [:]
    }

    static func updateViewerData(data: [String: Any]) {
        var existingData = getViewerData()
        for (key, value) in data {
            existingData[key] = value
        }
        UserDefaults.standard.setValue(existingData, forKey: fastPixUserDefaultsKey)
        UserDefaults.standard.synchronize() 
    }

    static func getViewerCookie() -> [String: Any] {
        var data = getViewerData()
        let fpViewerId = data["fpviid"] as? String ?? UUID().uuidString.lowercased()
        let fpSampleNumber = data["fpsanu"] as? Double ?? Double.random(in: 0...1)
        
        data["fpviid"] = fpViewerId.lowercased()
        data["fpsanu"] = fpSampleNumber
        
        updateViewerData(data: data)
        
        return [
            "fastpix_viewer_id": fpViewerId.lowercased(),
            "fastpix_sample_number": fpSampleNumber
        ]
    }

    // MARK: - Update Cookies Equivalent
    static func updateCookies() -> [String: Any] {
        var data = getViewerData()
        let currentTime = Int(Date().timeIntervalSince1970 * 1000)

        if data["fpviid"] == nil || data["fpsanu"] == nil {
            data["fpviid"] = UUID().uuidString.lowercased()
            data["fpsanu"] = Double.random(in: 0...1)
        }

        if let lastSessionTime = data["snst"] as? Int,
           let sessionID = data["snid"] as? String,
           currentTime - lastSessionTime > 86400000 {
            data["snst"] = currentTime
            data["snid"] = UUID().uuidString.lowercased()
        } else if data["snid"] == nil || data["snst"] == nil {
            data["snst"] = currentTime
            data["snid"] = UUID().uuidString.lowercased()
        }
        
        data["snepti"] = currentTime + 1500000
        updateViewerData(data: data)

        return [
            "session_id": (data["snid"] as? String)?.lowercased() ?? "",
            "session_start": data["snst"] as? Int ?? Int(Date().timeIntervalSince1970 * 1000),
            "session_expiry_time": data["snepti"] as? Int ?? Int(Date().timeIntervalSince1970 * 1000)
        ]
    }
}
