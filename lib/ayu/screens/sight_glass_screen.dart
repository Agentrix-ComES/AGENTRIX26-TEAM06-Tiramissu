import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';

class SightGlassScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const SightGlassScreen({super.key, this.onBack});

  @override
  _SightGlassScreenState createState() => _SightGlassScreenState();
}

class _SightGlassScreenState extends State<SightGlassScreen> {
  File? _image;
  bool _isScanning = false;
  bool _showResults = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _takePhoto();
    });
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    
    if (photo != null) {
      setState(() {
        _image = File(photo.path);
        _isScanning = true;
        _showResults = false;
      });

      // Simulate the Gemini 1.5 Vision API processing time
      await Future.delayed(const Duration(seconds: 3));

      if (mounted) {
        setState(() {
          _isScanning = false;
          _showResults = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B), // Dark background for the scanner
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Sight-Glass AI", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: widget.onBack != null 
          ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)
          : null,
      ),
      body: Stack(
        children: [
          // 1. The Camera View / Placeholder
          Positioned.fill(
            child: _image != null
                ? Image.file(_image!, fit: BoxFit.cover)
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.camera_alt_outlined, size: 80, color: Colors.white38),
                        SizedBox(height: 16),
                        Text("Point at a menu or landmark", style: TextStyle(color: Colors.white54, fontSize: 16)),
                      ],
                    ),
                  ),
          ),

          // 2. The Scanning Overlay (Shows while waiting for backend)
          if (_isScanning)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.6),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      CircularProgressIndicator(color: Color(0xFFC6F621)),
                      SizedBox(height: 20),
                      Text("Travel Bokka is thinking...", 
                        style: TextStyle(color: Color(0xFFC6F621), fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),

          // 3. The Result Card (Glassmorphism)
          if (_showResults)
            Positioned(
              bottom: 130,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.account_balance_rounded, color: Color(0xFFC6F621)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text("Temple of the Sacred Tooth Relic", 
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Text("Historical Significance", style: TextStyle(color: Color(0xFFC6F621), fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 4),
                          Text("A world-renowned Buddhist temple located in the royal palace complex of the former Kingdom of Kandy. It houses the sacred relic of the tooth of the Buddha, which has played a major role in local politics since ancient times—it's believed that whoever holds the relic holds the governance of the country.", style: TextStyle(color: Colors.white70, height: 1.4)),
                          SizedBox(height: 16),
                          Text("Key Details", style: TextStyle(color: Color(0xFFC6F621), fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 4),
                          Text("• Rituals (Tevava) are performed three times daily: at dawn, at noon, and in the evening.\n• Dress Code: White attire is heavily preferred; shoulders and knees must be strictly covered.\n• The golden canopy over the main shrine was built in 1987.\n• Esala Perahera, a grand cultural festival with decorated elephants and traditional dancers, is held annually in July/August.", style: TextStyle(color: Colors.white70, height: 1.4)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // 4. The Action Button
          if (!_isScanning)
            Positioned(
              bottom: 40, // Keeps button at the bottom always
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _takePhoto,
                  child: Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC6F621),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: const Color(0xFFC6F621).withOpacity(0.4), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.camera, size: 32, color: Color(0xFF1E293B)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
