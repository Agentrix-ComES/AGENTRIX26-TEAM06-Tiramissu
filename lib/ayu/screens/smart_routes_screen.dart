import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../models/api_responses.dart';

/// Available interest categories for route recommendations.
const List<_InterestOption> _interestOptions = [
  _InterestOption(icon: Icons.temple_buddist, label: 'Temples', value: 'temples'),
  _InterestOption(icon: Icons.park, label: 'Nature', value: 'nature'),
  _InterestOption(icon: Icons.museum, label: 'Museums', value: 'museums'),
  _InterestOption(icon: Icons.restaurant, label: 'Food', value: 'food'),
  _InterestOption(icon: Icons.shopping_bag, label: 'Shopping', value: 'shopping'),
  _InterestOption(icon: Icons.beach_access, label: 'Beaches', value: 'beaches'),
  _InterestOption(icon: Icons.history_edu, label: 'History', value: 'history'),
  _InterestOption(icon: Icons.photo_camera, label: 'Photography', value: 'photography'),
];

class _InterestOption {
  final IconData icon;
  final String label;
  final String value;
  const _InterestOption({required this.icon, required this.label, required this.value});
}

/// Transport mode options.
const List<_TransportMode> _transportModes = [
  _TransportMode(icon: Icons.directions_car, label: 'Car/Taxi', value: 'car', baseCostPerKm: 45),
  _TransportMode(icon: Icons.directions_bus, label: 'Bus', value: 'bus', baseCostPerKm: 5),
  _TransportMode(icon: Icons.train, label: 'Train', value: 'train', baseCostPerKm: 8),
  _TransportMode(icon: Icons.two_wheeler, label: 'Tuk-tuk', value: 'tuktok', baseCostPerKm: 35),
  _TransportMode(icon: Icons.walking, label: 'Walking', value: 'walking', baseCostPerKm: 0),
];

class _TransportMode {
  final IconData icon;
  final String label;
  final String value;
  final double baseCostPerKm;
  const _TransportMode({required this.icon, required this.label, required this.value, required this.baseCostPerKm});
}

/// Enhanced Routes screen with intelligent planning, GPS, preferences, and dynamic recalibration.
class SmartRoutesScreen extends StatefulWidget {
  const SmartRoutesScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<SmartRoutesScreen> createState() => _SmartRoutesScreenState();
}

class _SmartRoutesScreenState extends State<SmartRoutesScreen> with SingleTickerProviderStateMixin {
  // State variables
  bool _isLoading = false;
  bool _isNavigating = false;
  String? _errorMessage;
  RoutePlanResponse? _currentRoute;
  
  // Input controllers
  final _destCtrl = TextEditingController();
  final _disruptionCtrl = TextEditingController();
  final _focusNode = FocusNode();
  
  // User preferences
  double _budget = 1000; // Rs
  int _timeAvailable = 120; // minutes
  String _selectedTransport = 'any';
  final Set<String> _selectedInterests = {};
  
  // Location
  Position? _currentLocation;
  String _locationText = 'Getting location...';
  
  // UI state
  bool _showSuggestions = false;
  int _activeModeIndex = 0;
  
  late AnimationController _dashAnim;
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _dashAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _getCurrentLocation();
    
    _focusNode.addListener(() {
      setState(() => _showSuggestions = _focusNode.hasFocus);
    });
  }
  
  Future<void> _getCurrentLocation() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null) {
      setState(() {
        _currentLocation = pos;
        _locationText = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
      });
    } else {
      setState(() {
        _locationText = 'Colombo 3 (fallback)';
      });
    }
  }

  @override
  void dispose() {
    _dashAnim.dispose();
    _destCtrl.dispose();
    _disruptionCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _toggleInterest(String value) {
    setState(() {
      if (_selectedInterests.contains(value)) {
        _selectedInterests.remove(value);
      } else {
        _selectedInterests.add(value);
      }
    });
  }
  
  Future<void> _planRoute() async {
    if (_destCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a destination');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final response = await ApiService.planRoute(
      origin: _locationText,
      destination: _destCtrl.text.trim(),
      interests: _selectedInterests.toList(),
      budget: _budget,
      timeAvailableMinutes: _timeAvailable,
      disruptions: _disruptionCtrl.text.trim().isEmpty ? null : _disruptionCtrl.text.trim(),
      preferredTransportMode: _selectedTransport,
    );
    
    setState(() {
      _isLoading = false;
      if (response.success) {
        _currentRoute = response;
        _isNavigating = true;
      } else {
        _errorMessage = response.error ?? 'Failed to plan route';
      }
    });
  }
  
  void _recalibrateRoute() async {
    if (_disruptionCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please describe the disruption or news');
      return;
    }
    await _planRoute();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Map background
        ColorFiltered(
          colorFilter: ColorFilter.matrix([
            0.75, 0, 0, 0, 0,
            0, 0.75, 0, 0, 0,
            0, 0, 0.75, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: Image.network(
            'https://images.unsplash.com/photo-1740812517495-812e90ca01b1?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFFD8E4D0)),
          ),
        ),
        // Tint overlay
        Container(color: const Color(0x40F0F5EB)),
        
        // Back button
        Positioned(
          top: 40,
          left: 20,
          child: GestureDetector(
            onTap: _isNavigating ? () => setState(() => _isNavigating = false) : widget.onBack,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 2))
                ],
              ),
              child: Icon(Icons.arrow_back, size: 17, color: AyuColors.navy),
            ),
          ),
        ),
        
        // My location button
        Positioned(
          top: 40,
          right: 20,
          child: GestureDetector(
            onTap: _getCurrentLocation,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 12, offset: const Offset(0, 2))
                ],
              ),
              child: Icon(Icons.my_location_rounded, size: 17, color: AyuColors.sageDeep),
            ),
          ),
        ),
        
        // Main content
        Positioned(
          top: 96,
          left: 16,
          right: 16,
          bottom: 0,
          child: Column(
            children: [
              // Search & Preferences Panel
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDestinationPanel(),
                      if (_showSuggestions) ...[
                        const SizedBox(height: 8),
                        _buildSuggestionsDropdown(),
                      ],
                      const SizedBox(height: 12),
                      _buildInterestSelector(),
                      const SizedBox(height: 12),
                      _buildBudgetSlider(),
                      const SizedBox(height: 12),
                      _buildTimeSlider(),
                      const SizedBox(height: 12),
                      _buildTransportSelector(),
                      const SizedBox(height: 12),
                      _buildDisruptionInput(),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Action Button
              _buildActionButton(),
              
              const SizedBox(height: 16),
              
              // Route Results (if navigating)
              if (_isNavigating && _currentRoute != null)
                Expanded(
                  flex: 1,
                  child: _buildRouteResults(),
                ),
            ],
          ),
        ),
        
        // Loading overlay
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(color: AyuColors.lime),
            ),
          ),
      ],
    );
  }
  
  Widget _buildDestinationPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Origin
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AyuColors.navy, width: 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _locationText,
                    style: AyuText.body(color: AyuColors.textMuted, size: 14, weight: FontWeight.w500),
                  ),
                ),
                const Icon(Icons.gps_fixed_rounded, size: 14, color: AyuColors.sageDeep),
              ],
            ),
          ),
          Divider(height: 1, color: const Color(0xFFF0F1EC)),
          // Destination
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AyuColors.lime),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _destCtrl,
                    focusNode: _focusNode,
                    style: AyuText.body(size: 14, weight: FontWeight.w600, color: AyuColors.navy),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      hintText: 'Where to?',
                      hintStyle: AyuText.body(size: 14, color: AyuColors.textSubtle),
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),
                const Icon(Icons.search_rounded, size: 14, color: AyuColors.textSubtle),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuggestionsDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: ['Gangarama Temple', 'Galle Face Green', 'National Museum'].map((name) {
          return GestureDetector(
            onTap: () {
              _destCtrl.text = name;
              setState(() => _showSuggestions = false);
              _focusNode.unfocus();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF0F1EC))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AyuColors.sageBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.location_on, size: 14, color: AyuColors.sageDeep),
                  ),
                  const SizedBox(width: 12),
                  Text(name, style: AyuText.body(size: 13.6, weight: FontWeight.w700)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildInterestSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Interests', style: AyuText.body(size: 14, weight: FontWeight.w700, color: AyuColors.navy)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _interestOptions.map((opt) {
              final isSelected = _selectedInterests.contains(opt.value);
              return GestureDetector(
                onTap: () => _toggleInterest(opt.value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AyuColors.navy : AyuColors.sageBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(opt.icon, size: 14, color: isSelected ? AyuColors.lime : AyuColors.textSubtle),
                      const SizedBox(width: 6),
                      Text(opt.label, style: AyuText.label(
                        size: 12,
                        weight: FontWeight.w600,
                        color: isSelected ? AyuColors.white : AyuColors.textMuted,
                      )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBudgetSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget', style: AyuText.body(size: 14, weight: FontWeight.w700, color: AyuColors.navy)),
              Text('Rs ${_budget.toInt()}', style: AyuText.body(size: 14, weight: FontWeight.w700, color: AyuColors.lime)),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _budget,
            min: 0,
            max: 5000,
            divisions: 50,
            activeColor: AyuColors.lime,
            inactiveColor: AyuColors.sageBg,
            onChanged: (v) => setState(() => _budget = v),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimeSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Time Available', style: AyuText.body(size: 14, weight: FontWeight.w700, color: AyuColors.navy)),
              Text('${(_timeAvailable / 60).toStringAsFixed(1)}h', style: AyuText.body(size: 14, weight: FontWeight.w700, color: AyuColors.lime)),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _timeAvailable.toDouble(),
            min: 15,
            max: 480,
            divisions: 31,
            activeColor: AyuColors.lime,
            inactiveColor: AyuColors.sageBg,
            onChanged: (v) => setState(() => _timeAvailable = v.toInt()),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTransportSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preferred Transport', style: AyuText.body(size: 14, weight: FontWeight.w700, color: AyuColors.navy)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _transportModes.asMap().entries.map((entry) {
              final i = entry.key;
              final mode = entry.value;
              final isActive = (i == 0 && _selectedTransport == 'any') || _selectedTransport == mode.value;
              return GestureDetector(
                onTap: () => setState(() {
                  _activeModeIndex = i;
                  _selectedTransport = i == 0 ? 'any' : mode.value;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? AyuColors.navy : AyuColors.sageBg,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(mode.icon, size: 15, color: isActive ? AyuColors.lime : AyuColors.textSubtle),
                      const SizedBox(width: 6),
                      Text(mode.label, style: AyuText.label(
                        size: 12,
                        weight: FontWeight.w600,
                        color: isActive ? AyuColors.white : AyuColors.textMuted,
                      )),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDisruptionInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AyuColors.danger.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_rounded, size: 16, color: AyuColors.danger),
              const SizedBox(width: 8),
              Text('Disruptions / News', style: AyuText.body(size: 14, weight: FontWeight.w700, color: AyuColors.danger)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _disruptionCtrl,
            maxLines: 3,
            style: AyuText.body(size: 13, color: AyuColors.navy),
            decoration: InputDecoration(
              hintText: 'E.g., "Road closed due to protest", "Train cancelled"...',
              hintStyle: AyuText.body(size: 13, color: AyuColors.textSubtle),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AyuColors.divider),
              ),
              filled: true,
              fillColor: AyuColors.sageBg.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _recalibrateRoute,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AyuColors.danger,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded, size: 16, color: AyuColors.white),
                  const SizedBox(width: 8),
                  Text('Recalibrate Route', style: AyuText.button(color: AyuColors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _planRoute,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isLoading ? AyuColors.textMuted : AyuColors.lime,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AyuColors.navy),
              )
            else ...[
              const Icon(Icons.navigation_rounded, size: 17, color: AyuColors.navy),
              const SizedBox(width: 10),
              Text(_isNavigating ? 'Update Route' : 'Plan Smart Route', style: AyuText.button(color: AyuColors.navy)),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildRouteResults() {
    if (_currentRoute == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 40, offset: const Offset(0, -4))
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AyuColors.divider,
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary
                  if (_currentRoute!.summary != null)
                    Text(_currentRoute!.summary!, style: AyuText.body(size: 14, color: AyuColors.navy)),
                  
                  const SizedBox(height: 12),
                  
                  // Stats row
                  Row(
                    children: [
                      _StatChip(icon: Icons.route, label: '${_currentRoute!.totalDistanceKm.toStringAsFixed(1)} km'),
                      const SizedBox(width: 8),
                      _StatChip(icon: Icons.access_time, label: '${_currentRoute!.totalDurationMinutes.toInt()} min'),
                      const SizedBox(width: 8),
                      _StatChip(icon: Icons.money, label: 'Rs ${_currentRoute!.estimatedCost.toInt()}'),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Recommendations
                  if (_currentRoute!.recommendations.isNotEmpty) ...[
                    Text('Recommended Stops', style: AyuText.body(size: 14, weight: FontWeight.w700, color: AyuColors.navy)),
                    const SizedBox(height: 8),
                    ..._currentRoute!.recommendations.map((rec) => _RecommendationCard(rec: rec)),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Turn-by-turn preview
                  if (_currentRoute!.steps.isNotEmpty) ...[
                    Text('Next Turns', style: AyuText.body(size: 14, weight: FontWeight.w700, color: AyuColors.navy)),
                    const SizedBox(height: 8),
                    ..._currentRoute!.steps.take(3).map((step) => _TurnStep(step: step)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AyuColors.sageBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AyuColors.sageDeep),
          const SizedBox(width: 4),
          Text(label, style: AyuText.label(size: 11, weight: FontWeight.w600, color: AyuColors.navy)),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final RouteRecommendation rec;
  const _RecommendationCard({required this.rec});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AyuColors.sageBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(rec.name, style: AyuText.body(size: 13, weight: FontWeight.w700, color: AyuColors.navy)),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 12, color: AyuColors.star),
                  const SizedBox(width: 4),
                  Text(rec.rating.toStringAsFixed(1), style: AyuText.label(size: 11, weight: FontWeight.w600, color: AyuColors.navy)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(rec.type, style: AyuText.label(size: 10, color: AyuColors.textSubtle)),
          const SizedBox(height: 6),
          Text(rec.description, style: AyuText.label(size: 11, color: AyuColors.textMuted)),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('${rec.distanceFromRoute.toStringAsFixed(1)} km off route', style: AyuText.label(size: 10, color: AyuColors.sage)),
              const SizedBox(width: 12),
              Text('~${rec.estimatedDurationMinutes} min', style: AyuText.label(size: 10, color: AyuColors.sage)),
              const Spacer(),
              Text('Rs ${rec.cost.toInt()}', style: AyuText.label(size: 10, weight: FontWeight.w600, color: AyuColors.lime)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TurnStep extends StatelessWidget {
  final NavigationStep step;
  const _TurnStep({required this.step});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AyuColors.navy,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getManeuverIcon(step.maneuverType),
              size: 14,
              color: AyuColors.lime,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.instruction, style: AyuText.body(size: 12.5, weight: FontWeight.w500, color: AyuColors.navy)),
                const SizedBox(height: 2),
                Text(
                  '${(step.distanceMeters / 1000).toStringAsFixed(2)} km • ${(step.durationSeconds / 60).toInt()} min',
                  style: AyuText.label(size: 10.5, color: AyuColors.textSubtle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getManeuverIcon(String type) {
    switch (type.toLowerCase()) {
      case 'left': return Icons.turn_left_rounded;
      case 'right': return Icons.turn_right_rounded;
      case 'uturn': return Icons.u_turn_left_rounded;
      case 'arrive': return Icons.location_on_rounded;
      default: return Icons.navigation_rounded;
    }
  }
}
