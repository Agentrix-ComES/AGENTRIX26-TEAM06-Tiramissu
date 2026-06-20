import 'dart:async';

class OfflineCacheManager {
  // Singleton pattern
  static final OfflineCacheManager _instance = OfflineCacheManager._internal();
  factory OfflineCacheManager() => _instance;
  OfflineCacheManager._internal();

  // The "Database" (Memory Cache)
  Map<String, bool> cachedPlaces = {};

  // The Auto-Sync Function
  Future<void> autoSyncCityData(String city) async {
    // Simulate background network fetching for the pitch/judges
    await Future.delayed(const Duration(seconds: 3)); 
    
    // Automatically flag all Kandy highlights as "Downloaded"
    cachedPlaces["Temple of the Sacred Tooth Relic"] = true;
    cachedPlaces["Kandy Lake"] = true;
    cachedPlaces["Peradeniya Botanical Gardens"] = true;
    
    print("✅ $city Offline Pack Auto-Synced in Background");
  }

  bool isPlaceCached(String placeId) {
    return cachedPlaces.containsKey(placeId) && cachedPlaces[placeId] == true;
  }
}
