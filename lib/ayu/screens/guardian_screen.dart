import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';
import 'alerts_screen.dart';

/// Guardian screen — camera AR overlay, interactive mic, animated scam alert, and live analysis box.
class GuardianScreen extends StatefulWidget {
  const GuardianScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<GuardianScreen> createState() => _GuardianScreenState();
}

class _GuardianScreenState extends State<GuardianScreen>
    with TickerProviderStateMixin {
  bool _scamVisible = false;
  bool _isRecording = false;

  late AnimationController _pulse0, _pulse1, _pulse2;
  late AnimationController _scamSlide;
  late Animation<Offset> _scamOffset;

  // Real-time audio and WebSocket
  final _record = AudioRecorder();
  WebSocketChannel? _channel;
  StreamSubscription<Uint8List>? _audioStream;

  String _currentStatus = 'Tap microphone to start listening';

  // Live Analysis History
  final List<Map<String, String>> _analysisHistory = [];
  final ScrollController _scrollController = ScrollController();

  // Active Scam Alert data
  String _threatMessage = '';
  String _actionSuggested = '';
  String _transcriptSnippet = '';

  @override
  void initState() {
    super.initState();

    // Three staggered pulse rings
    _pulse0 = _makePulse(0);
    _pulse1 = _makePulse(500);
    _pulse2 = _makePulse(1000);

    _scamSlide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scamOffset = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _scamSlide, curve: Curves.easeOutBack));

    _initWebSocket();
  }

  Future<void> _initWebSocket() async {
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final wsUrl = Uri.parse(
      'ws://$host:8000/api/guardian/stream?context=Tuk-tuk+negotiation+Kandy',
    );

    _channel = WebSocketChannel.connect(wsUrl);

    _channel!.stream.listen(
      (message) {
        final data = jsonDecode(message);

        if (data['type'] == 'READY') {
          debugPrint('WebSocket ready');
          return;
        }

        if (data['type'] == 'ERROR') {
          setState(() {
            _currentStatus = data['message'] ?? 'An error occurred';
          });
          return;
        }

        if (data['mode'] == 'guardian') {
          // INTERCEPTED FOR DEMO MOCK: we ignore real backend websocket data for now
          // so it doesn't overwrite our King Coconut mock.
          return;
          
          final status = data['status'];
          final englishText = data['english_text'] ?? '';
          final threatMsg = data['threat_message'] ?? '';
          final actSuggested = data['action_suggested'] ?? '';
          final originalText = data['original_text'] ?? '';

          if (englishText.isNotEmpty) {
            setState(() {
              _currentStatus = 'Analysis complete.';
              _analysisHistory.insert(0, {
                'status': status,
                'original': originalText,
                'english': englishText,
                'threat': threatMsg,
                'action': actSuggested,
              });
            });
            _scrollToTop();
          }

          if (status == 'SCAM' || status == 'WARNING') {
            setState(() {
              _scamVisible = true;
              _threatMessage = threatMsg.isEmpty
                  ? 'Suspicious activity detected.'
                  : threatMsg;
              _actionSuggested = actSuggested.isEmpty
                  ? 'Proceed with caution.'
                  : actSuggested;
              _transcriptSnippet = data['transcript_snippet'] ?? '';
            });
            if (!_scamSlide.isCompleted) {
              _scamSlide.forward();
            }
          }
        }
      },
      onError: (err) {
        debugPrint('WebSocket error: $err');
        setState(() => _currentStatus = 'Connection error');
      },
      onDone: () {
        debugPrint('WebSocket closed');
        setState(() {
          _isRecording = false;
          _currentStatus = 'Disconnected';
        });
      },
    );
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (await _record.hasPermission()) {
      setState(() {
        _isRecording = true;
        _currentStatus = 'Listening...';
        _scamVisible = false; // dismiss old scam alert
      });
      _scamSlide.reverse();

      final stream = await _record.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );

      _audioStream = stream.listen((data) {
        if (_channel != null && _isRecording) {
          final base64Audio = base64Encode(data);
          _channel!.sink.add('base64:$base64Audio');
        }
      });
    } else {
      setState(() => _currentStatus = 'Microphone permission denied');
    }
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _currentStatus = 'Analyzing audio...';
    });

    // Stop grabbing audio
    await _record.stop();
    
    // Tell backend to immediately process the buffer (ignored by frontend now)
    _channel?.sink.add('FLUSH');

    // --- MOCK KING COCONUT SCAM FOR DEMO ---
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _currentStatus = 'Translating local dialect...');
    
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _currentStatus = 'Checking against local prices...');
    
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      final threatMsg = "The vendor is quoting LKR 2,500 for a King Coconut. The fair local price is LKR 150-200. This is a severe overcharge.";
      
      setState(() {
        _currentStatus = 'Analysis complete.';
        _scamVisible = true;
        _threatMessage = threatMsg;
        _actionSuggested = "Decline politely and walk away. Fair price is ~LKR 200.";
        _transcriptSnippet = "අයියේ මේ තැඹිලි ගෙඩියක් දෙදහස් පන්සීයක් වෙනවා.";
        
        _analysisHistory.insert(0, {
          'status': 'SCAM',
          'original': 'අයියේ මේ තැඹිලි ගෙඩියක් දෙදහස් පන්සීයක් වෙනවා.',
          'english': 'Brother, one King Coconut is 2,500 rupees.',
          'threat': threatMsg,
          'action': 'Decline politely and walk away. Fair price is ~LKR 200.',
        });
      });
      _scrollToTop();
      _scamSlide.forward();
      
      // ADD TO GLOBAL ALERTS SCREEN
      globalAlerts.insert(0, AlertItem(
        id: DateTime.now().millisecondsSinceEpoch,
        level: AlertLevel.danger,
        title: 'Scam: Overpriced King Coconut',
        body: threatMsg,
        location: 'Current Location',
        time: 'Just now',
        read: false,
        quoted: 'LKR 2,500',
        fair: 'LKR 200',
      ));
    }
  }

  AnimationController _makePulse(int delayMs) {
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    Future.delayed(Duration(milliseconds: delayMs), () {
      if (mounted) ctrl.repeat();
    });
    return ctrl;
  }

  @override
  void dispose() {
    _pulse0.dispose();
    _pulse1.dispose();
    _pulse2.dispose();
    _scamSlide.dispose();
    _scrollController.dispose();

    _audioStream?.cancel();
    _record.dispose();
    _channel?.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            _scamVisible
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.15),
            BlendMode.srcOver,
          ),
          child: Image.network(
            'https://images.unsplash.com/photo-1772729629782-558d884c5d96?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=1080',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: const Color(0xFF1A2A1A)),
          ),
        ),
        // Top vignette
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 160,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x8C000000), Colors.transparent],
              ),
            ),
          ),
        ),
        // Scan-line overlay (only when no scam alert)
        if (!_scamVisible) _ScanLinesOverlay(),
        // Back button
        Positioned(
          top: 40,
          left: 20,
          child: _CircleButton(icon: Icons.arrow_back, onTap: widget.onBack),
        ),
        // "GUARDIAN ACTIVE" label
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.4),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.shield_rounded,
                    size: 13,
                    color: AyuColors.lime,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'GUARDIAN ACTIVE',
                    style: AyuText.label(
                      color: AyuColors.white,
                      size: 12,
                      weight: FontWeight.w700,
                      letterSpacing: 0.04 * 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (_isRecording) _PulsingDot(),
                ],
              ),
            ),
          ),
        ),

        // Live Analysis Box
        if (!_scamVisible)
          Positioned(
            bottom: 240,
            left: 20,
            right: 20,
            height: 200,
            child: _LiveAnalysisBox(
              history: _analysisHistory,
              scrollController: _scrollController,
            ),
          ),

        // Interactive Mic Button
        if (!_scamVisible)
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                GestureDetector(
                  onTap: _toggleRecording,
                  child: _MicPulseRings(
                    ctrl0: _pulse0,
                    ctrl1: _pulse1,
                    ctrl2: _pulse2,
                    isRecording: _isRecording,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Text(
                    _currentStatus,
                    style: AyuText.label(
                      color: AyuColors.white,
                      size: 13,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Scam alert bottom card
        if (_scamVisible)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _scamOffset,
              child: _ScamAlertCard(
                threatMessage: _threatMessage,
                actionSuggested: _actionSuggested,
                transcriptSnippet: _transcriptSnippet,
                onDecline: () {
                  _scamSlide.reverse().then((_) {
                    if (mounted) setState(() => _scamVisible = false);
                  });
                },
                onFairPrice: () {
                  _scamSlide.reverse().then((_) {
                    if (mounted) setState(() => _scamVisible = false);
                  });
                },
              ),
            ),
          ),
      ],
    );
  }
}

// ── Live Analysis Box Widget ────────────────────────────────────────────────

class _LiveAnalysisBox extends StatelessWidget {
  const _LiveAnalysisBox({
    required this.history,
    required this.scrollController,
  });

  final List<Map<String, String>> history;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  border: Border(
                    bottom: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.analytics_rounded,
                      size: 14,
                      color: AyuColors.sageAccent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'LIVE ANALYSIS',
                      style: AyuText.label(
                        color: AyuColors.sageAccent,
                        size: 11,
                        weight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // List of history
              Expanded(
                child: history.isEmpty
                    ? Center(
                        child: Text(
                          "Tap the mic to start analyzing conversations.",
                          style: AyuText.body(
                            color: Colors.white.withOpacity(0.5),
                            size: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        reverse: true,
                        itemCount: history.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = history[index];
                          final isSafe = item['status'] == 'SAFE';
                          final statusColor = isSafe
                              ? AyuColors.success
                              : AyuColors.warning;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '"${item['english']}"',
                                style: AyuText.body(
                                  color: Colors.white,
                                  size: 14,
                                  weight: FontWeight.w600,
                                ),
                              ),
                              if (item['original'] != item['english']) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item['original'] ?? '',
                                  style: AyuText.body(
                                    color: Colors.white.withOpacity(0.5),
                                    size: 12,
                                  ).copyWith(fontStyle: FontStyle.italic),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: statusColor.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      isSafe
                                          ? Icons.check_circle_rounded
                                          : Icons.info_outline_rounded,
                                      size: 14,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item['action'] ?? '',
                                        style: AyuText.body(
                                          color: isSafe
                                              ? AyuColors.sageLightBg
                                              : AyuColors.warningLight,
                                          size: 13,
                                          weight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Utilities ───────────────────────────────────────────────────────────────

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AyuColors.white),
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_c),
    child: Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AyuColors.danger,
        shape: BoxShape.circle,
      ),
    ),
  );
}

class _ArCard extends StatelessWidget {
  const _ArCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.icon,
    this.accent = false,
  });
  final String label, value, sub;
  final IconData icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: accent
              ? AyuColors.lime.withOpacity(0.2)
              : Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accent
                ? AyuColors.lime.withOpacity(0.4)
                : Colors.white.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 11, color: AyuColors.lime),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: AyuText.label(
                      color: accent
                          ? AyuColors.lime
                          : Colors.white.withOpacity(0.7),
                      size: 10,
                      weight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: AyuText.body(
                size: 18.4,
                weight: FontWeight.w800,
                color: AyuColors.white,
              ),
            ),
            Text(
              sub,
              style: AyuText.label(
                color: Colors.white.withOpacity(0.6),
                size: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicPulseRings extends StatelessWidget {
  const _MicPulseRings({
    required this.ctrl0,
    required this.ctrl1,
    required this.ctrl2,
    required this.isRecording,
  });

  final AnimationController ctrl0, ctrl1, ctrl2;
  final bool isRecording;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isRecording) ...[
            _PulseRing(ctrl: ctrl0, maxRadius: 58),
            _PulseRing(ctrl: ctrl1, maxRadius: 48),
            _PulseRing(ctrl: ctrl2, maxRadius: 38),
          ],
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isRecording
                  ? AyuColors.lime
                  : Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isRecording
                    ? Colors.transparent
                    : Colors.white.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Icon(
              isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
              size: 24,
              color: isRecording ? AyuColors.navy : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.ctrl, required this.maxRadius});
  final AnimationController ctrl;
  final double maxRadius;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ctrl.value;
        return CustomPaint(
          size: Size(maxRadius * 2, maxRadius * 2),
          painter: _RingPainter(
            radius: 20 + (maxRadius - 20) * t,
            opacity: (1.0 - t) * 0.6,
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.radius, required this.opacity});
  final double radius;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      size.center(Offset.zero),
      radius,
      Paint()
        ..color = AyuColors.lime.withOpacity(opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.radius != radius || old.opacity != opacity;
}

class _ScanLinesOverlay extends StatefulWidget {
  @override
  State<_ScanLinesOverlay> createState() => _ScanLinesOverlayState();
}

class _ScanLinesOverlayState extends State<_ScanLinesOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0, end: 0.06).animate(_ctrl),
    child: Container(child: CustomPaint(painter: _ScanLinePainter())),
  );
}

class _ScanLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AyuColors.lime.withOpacity(0.12)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _ScamAlertCard extends StatelessWidget {
  const _ScamAlertCard({
    required this.onDecline,
    required this.onFairPrice,
    required this.threatMessage,
    required this.actionSuggested,
    required this.transcriptSnippet,
  });
  final VoidCallback onDecline;
  final VoidCallback onFairPrice;
  final String threatMessage;
  final String actionSuggested;
  final String transcriptSnippet;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AyuColors.danger.withOpacity(0.25),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AyuColors.danger.withOpacity(0.25),
              blurRadius: 40,
              offset: const Offset(0, -4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 60,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Alert header strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AyuColors.danger.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: AyuColors.danger,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SCAM ALERT DETECTED',
                    style: AyuText.label(
                      color: AyuColors.danger,
                      size: 13.6,
                      weight: FontWeight.w800,
                      letterSpacing: 0.04 * 14,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onDecline,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AyuColors.danger.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: AyuColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Threat Assessment',
                    style: AyuText.body(size: 16.8, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),

                  // The actual threat explanation
                  Text(
                    threatMessage,
                    style: AyuText.body(
                      color: AyuColors.danger,
                      size: 14,
                      weight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Snippet that triggered it
                  if (transcriptSnippet.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '"$transcriptSnippet"',
                        style: AyuText.body(
                          color: const Color(0xFF64748B),
                          size: 13,
                        ).copyWith(fontStyle: FontStyle.italic),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Action suggested
                  Text(
                    'Action: $actionSuggested',
                    style: AyuText.body(
                      color: AyuColors.navy,
                      size: 14,
                      weight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'Decline',
                          icon: Icons.thumb_down_rounded,
                          color: AyuColors.white,
                          bgColor: AyuColors.danger,
                          onTap: onDecline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionButton(
                          label: 'Dismiss',
                          icon: Icons.check_circle_outline_rounded,
                          color: AyuColors.success,
                          bgColor: Colors.transparent,
                          border: Border.all(
                            color: AyuColors.success,
                            width: 2,
                          ),
                          onTap: onFairPrice,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    this.border,
  });
  final String label;
  final IconData icon;
  final Color color, bgColor;
  final BoxBorder? border;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _p;
  @override
  void initState() {
    super.initState();
    _p = AnimationController(
      vsync: this,
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
      duration: const Duration(milliseconds: 100),
    );
  }

  @override
  void dispose() {
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => _p.reverse(),
    onTapUp: (_) {
      _p.forward();
      widget.onTap();
    },
    onTapCancel: () => _p.forward(),
    child: AnimatedBuilder(
      animation: _p,
      builder: (_, child) => Transform.scale(scale: _p.value, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(50),
          border: widget.border,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 15, color: widget.color),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: AyuText.body(
                size: 14.4,
                weight: FontWeight.w700,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
