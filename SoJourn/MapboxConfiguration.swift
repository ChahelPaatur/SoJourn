import Foundation
import MapboxMaps

// This class helps initialize Mapbox SDK with the proper token
class MapboxConfiguration {
    static let shared = MapboxConfiguration()
    
    private init() {
        // Initialize on first access
    }
    
    func configure() {
        // Verify token exists in Info.plist
        if let token = Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") as? String {
            print("Mapbox access token found in Info.plist")
            
            // Set up any global Mapbox configuration here if needed in the future
            
            #if DEBUG
            print("Mapbox SDK configured successfully")
            #endif
        } else {
            print("ERROR: MBXAccessToken not found in Info.plist!")
        }
    }
} 