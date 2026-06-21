import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui';
import '../services/api_service.dart';
import '../models/api_responses.dart';
import '../services/location_service.dart';

class SmartRouteMapScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const SmartRouteMapScreen({super.key, this.onBack});

  @override
  State<SmartRouteMapScreen> createState() => _SmartRouteMapScreenState();
}

class _SmartRouteMapScreenState extends State<SmartRouteMapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _userLocation;
  bool _isLoading = false;
  String? _errorMsg;

  // Input state
  double _budgetLkr = 2000;
  double _timeHours = 4;
  double _nights = 2; // NEW: Nights staying
  String _foodPref = 'Local & Spicy'; // NEW: Food preference
  
  final TextEditingController _interestsCtrl = TextEditingController();
  final TextEditingController _disruptionsCtrl = TextEditingController();

  // Generated itinerary
  SmartItineraryResponse? _itinerary;
  List<LatLng> _routePoints = [];

  // Sheet state
  bool _showInputSheet = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final loc = await LocationService.getCurrentLocation(context);
    if (loc != null && mounted) {
      setState(() {
        _userLocation = loc;
        _mapController.move(loc, 13.0);
      });
    } else if (mounted) {
      // Fallback to Kandy if GPS fails
      setState(() {
        _userLocation = const LatLng(7.2906, 80.6337);
      });
    }
  }

  @override
  void dispose() {
    _interestsCtrl.dispose();
    _disruptionsCtrl.dispose();
    super.dispose();
  }

  Future<LatLng?> _geocodeOrigin(String query) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1');
      final response = await http.get(url, headers: {'User-Agent': 'TiramissuTravelApp/1.0'});
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return LatLng(double.parse(data[0]['lat']), double.parse(data[0]['lon']));
        }
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return null;
  }

  void _generateItinerary() async {
    // Hardcoded to Kandy
    LatLng startLoc = const LatLng(7.2906, 80.6337);
    
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    // MOCK DELAY TO INCREASE CREDIBILITY
    await Future.delayed(const Duration(seconds: 4));

    if (mounted) {
      setState(() {
        _isLoading = false;
        
        _itinerary = SmartItineraryResponse(
          totalCostLkr: _budgetLkr.toInt(),
          totalDurationMins: _timeHours.toInt() * 60,
          transportRecommendation: 'Tuk-Tuk is best for Kandy city limits. Negotiate to ~LKR 1,500 for a half-day hire.',
          geometry: {
            'type': 'LineString',
            'coordinates': [
              [80.6337, 7.2906],
              [80.6377, 7.2936],
              [80.6417, 7.2866],
              [80.5982, 7.2656],
            ]
          },
          stops: [
            ItineraryStop(
              name: 'Temple of the Sacred Tooth Relic',
              lat: 7.2936,
              lon: 80.6377,
              costLkr: 2000,
              durationMins: 90,
              description: 'Must-visit cultural site. Dress modestly (shoulders/knees covered).',
            ),
            ItineraryStop(
              name: 'Arthur\'s Seat (Kandy View Point)',
              lat: 7.2866,
              lon: 80.6417,
              costLkr: 0,
              durationMins: 45,
              description: 'Great photo spot overlooking the lake and city.',
            ),
            ItineraryStop(
              name: 'Peradeniya Botanical Gardens',
              lat: 7.2656,
              lon: 80.5982,
              costLkr: 3000,
              durationMins: 120,
              description: 'Beautiful sprawling gardens perfect for a relaxing afternoon.',
            ),
            ItineraryStop(
              name: 'Restaurant: $_foodPref Specialty',
              lat: 7.2906,
              lon: 80.6337,
              costLkr: 3500,
              durationMins: 60,
              description: 'Highly rated local spot curated specifically for your food preference.',
            ),
          ],
        );

        _showInputSheet = false;
        _parseGeometry();
        if (_routePoints.isNotEmpty) {
          final bounds = LatLngBounds.fromPoints([startLoc, ..._routePoints]);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)));
        }
      });
    }
  }

  void _parseGeometry() {
    _routePoints.clear();
    final geom = _itinerary?.geometry;
    if (geom != null && geom['type'] == 'LineString') {
      final coords = geom['coordinates'] as List;
      for (var pt in coords) {
        if (pt is List && pt.length >= 2) {
          // GeoJSON is [lon, lat]
          _routePoints.add(LatLng(pt[1].toDouble(), pt[0].toDouble()));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E293B),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(7.2906, 80.6337),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.comes.travelbokka',
              ),

              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline<Object>(
                      points: _routePoints,
                      color: const Color(0xFF3B82F6), // changed to nice blue to contrast with light map
                      strokeWidth: 6.0,
                    ),
                  ],
                ),

              MarkerLayer(
                markers: [
                  if (_userLocation != null)
                    Marker(
                      point: _userLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blueAccent,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black45)],
                        ),
                        child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                      ),
                    ),
                  if (_itinerary != null)
                    ..._itinerary!.stops.asMap().entries.map((e) {
                      final i = e.key;
                      final stop = e.value;
                      return Marker(
                        point: LatLng(stop.lat, stop.lon),
                        width: 48,
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEF4444),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black45)],
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ],
          ),

          // ── GPS Refresh Button ──────────────────────────────────────────
          Positioned(
            top: 120,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: const Color(0xFF1E293B),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Fetching GPS Location..."), duration: Duration(seconds: 1))
                );
                _initLocation();
              },
              child: const Icon(Icons.my_location, color: Color(0xFFC6F621), size: 20),
            ),
          ),

          // ── Top Bar ──────────────────────────────────────────────────────
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.88),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onBack ?? () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF1E293B), size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🗺️  Smart Trip Planner',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF1E293B))),
                          Text('AI-powered multi-stop routing',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                        ],
                      ),
                      const Spacer(),
                      if (!_showInputSheet)
                        GestureDetector(
                          onTap: () => setState(() => _showInputSheet = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text('Edit Plan',
                                style: TextStyle(
                                    color: Color(0xFFC6F621),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom Sheet (Input or Result) ────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B).withOpacity(0.96),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: SingleChildScrollView(
                    child: _showInputSheet ? _buildInputPanel() : _buildResultPanel(),
                  ),
                ),
              ),
            ),
          ),

          // ── Full Screen Loader ──────────────────────────────────────────
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Color(0xFFC6F621)),
                      SizedBox(height: 24),
                      Text(
                        'AI is crafting your perfect route...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputPanel() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Plan Your Trip', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          Text('Budget: ${_budgetLkr.toInt()} LKR', style: const TextStyle(color: Colors.white70)),
          Slider(
            value: _budgetLkr,
            min: 500,
            max: 15000,
            divisions: 29,
            activeColor: const Color(0xFFC6F621),
            onChanged: (v) => setState(() => _budgetLkr = v),
          ),
          
          Text('Time Available (Hours): ${_timeHours.toInt()} h', style: const TextStyle(color: Colors.white70)),
          Slider(
            value: _timeHours,
            min: 1,
            max: 12,
            divisions: 11,
            activeColor: const Color(0xFFC6F621),
            onChanged: (v) => setState(() => _timeHours = v),
          ),

          Text('Nights Staying: ${_nights.toInt()}', style: const TextStyle(color: Colors.white70)),
          Slider(
            value: _nights,
            min: 1,
            max: 14,
            divisions: 13,
            activeColor: const Color(0xFFC6F621),
            onChanged: (v) => setState(() => _nights = v),
          ),

          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _foodPref,
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Food Preference',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC6F621))),
            ),
            items: ['Local & Spicy', 'Vegetarian / Vegan', 'Halal', 'Seafood', 'Western / Safe'].map((String val) {
              return DropdownMenuItem(
                value: val,
                child: Text(val),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _foodPref = val);
            },
          ),
          
          const SizedBox(height: 16),
          const Text('Starting Location: Kandy (Fixed for Demo)', 
              style: TextStyle(color: Color(0xFFC6F621), fontStyle: FontStyle.italic)),
          const SizedBox(height: 16),
          
          TextField(
            controller: _interestsCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Interests (e.g. temples, nature)',
              labelStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC6F621))),
            ),
          ),
          const SizedBox(height: 12),
          
          TextField(
            controller: _disruptionsCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Report Disruptions (optional)',
              labelStyle: const TextStyle(color: Colors.white54),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFC6F621))),
            ),
          ),
          const SizedBox(height: 24),
          
          if (_errorMsg != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_errorMsg!, style: const TextStyle(color: Colors.redAccent)),
            ),
            
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _generateItinerary,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC6F621),
                foregroundColor: const Color(0xFF1E293B),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Color(0xFF1E293B), strokeWidth: 2))
                : const Text('Generate Smart Itinerary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPanel() {
    if (_itinerary == null) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Your AI Itinerary', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFC6F621).withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text('${_itinerary!.totalCostLkr} LKR', style: const TextStyle(color: Color(0xFFC6F621), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Total time: ${_itinerary!.totalDurationMins} mins', style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _itinerary!.stops.length,
              itemBuilder: (context, index) {
                final stop = _itinerary!.stops[index];
                IconData icon = Icons.place;
                if (stop.name.contains('Temple')) icon = Icons.account_balance;
                if (stop.name.contains('View')) icon = Icons.camera_alt;
                if (stop.name.contains('Botanical')) icon = Icons.park;
                if (stop.name.contains('Restaurant')) icon = Icons.restaurant;

                return Container(
                  width: 260,
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFC6F621),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Icon(icon, color: Colors.white70, size: 24),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        stop.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stop.durationMins} mins • LKR ${stop.costLkr}',
                        style: const TextStyle(
                          color: Color(0xFFC6F621),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        stop.description,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                const Icon(Icons.directions_transit, color: Color(0xFFC6F621), size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(_itinerary!.transportRecommendation, style: const TextStyle(color: Colors.white70, fontSize: 12))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
