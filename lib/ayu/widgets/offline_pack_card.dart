import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';

class OfflinePackCard extends StatefulWidget {
  final String title;
  final String subtitle;

  const OfflinePackCard({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  _OfflinePackCardState createState() => _OfflinePackCardState();
}

class _OfflinePackCardState extends State<OfflinePackCard> {
  bool _isDownloading = false;
  bool _isDownloaded = false;

  void _triggerDownload() async {
    setState(() {
      _isDownloading = true;
    });

    // Fake the network delay for the pitch video
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isDownloading = false;
      _isDownloaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: Offset(0, 10),
              )
            ],
          ),
          child: Row(
            children: [
              // Icon Container
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isDownloaded ? Color(0xFFC6F621) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isDownloaded ? Icons.check_circle : Icons.wifi_off_rounded,
                  color: _isDownloaded ? Color(0xFF1E293B) : Color(0xFF10B981),
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _isDownloaded 
                          ? "Itinerary, Rules & Fares saved." 
                          : widget.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              // Action Button
              GestureDetector(
                onTap: _isDownloaded || _isDownloading ? null : _triggerDownload,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isDownloaded ? Colors.transparent : Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Center(
                    child: _isDownloading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFFC6F621),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Icon(
                            _isDownloaded ? Icons.check : Icons.download_rounded,
                            color: _isDownloaded ? Color(0xFF10B981) : Color(0xFFC6F621),
                          ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
