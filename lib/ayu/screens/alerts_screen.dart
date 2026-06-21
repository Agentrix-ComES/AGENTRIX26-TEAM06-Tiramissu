import 'package:flutter/material.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';

enum AlertLevel { danger, warning, safe, info }

class AlertItem {
  final int id;
  final AlertLevel level;
  final String title, body, location, time;
  bool read;
  final String? quoted, fair;

  AlertItem({
    required this.id,
    required this.level,
    required this.title,
    required this.body,
    required this.location,
    required this.time,
    required this.read,
    this.quoted,
    this.fair,
  });
}

class _LevelCfg {
  final Color bg, iconColor, badgeBg;
  final IconData icon;
  final String badge;
  const _LevelCfg({
    required this.bg,
    required this.icon,
    required this.iconColor,
    required this.badge,
    required this.badgeBg,
  });
}

const _levelConfig = {
  AlertLevel.danger: _LevelCfg(bg: AyuColors.dangerBg, icon: Icons.warning_amber_rounded, iconColor: AyuColors.danger, badge: 'Scam', badgeBg: Color(0xFFFFE5E5)),
  AlertLevel.warning: _LevelCfg(bg: AyuColors.warningBg, icon: Icons.trending_up_rounded, iconColor: AyuColors.warning, badge: 'Warning', badgeBg: AyuColors.warningLight),
  AlertLevel.safe: _LevelCfg(bg: AyuColors.successBg, icon: Icons.shield_rounded, iconColor: AyuColors.success, badge: 'Safe', badgeBg: Color(0xFFD1FAE5)),
  AlertLevel.info: _LevelCfg(bg: AyuColors.infoBg, icon: Icons.info_outline_rounded, iconColor: AyuColors.info, badge: 'Tip', badgeBg: AyuColors.infoLight),
};

List<AlertItem> _initialAlerts() => [
  AlertItem(id: 1, level: AlertLevel.danger, title: 'Scam: Overpriced Tuk-Tuk Fare', body: 'Driver quoted LKR 5,000 for a 1.2 km trip. Local average is LKR 1,200. Declined successfully.', location: 'Kandy Market', time: '2 min ago', read: false, quoted: 'LKR 5,000', fair: 'LKR 1,200'),
  AlertItem(id: 2, level: AlertLevel.warning, title: 'Suspicious Gem Vendor', body: 'Common scam: vendors claim gems are from a government auction. These are tourist traps near Kandy Lake.', location: 'Kandy Lake', time: '1 hr ago', read: false),
  AlertItem(id: 3, level: AlertLevel.safe, title: 'Fair Price Verified', body: 'Your tuk-tuk ride to Temple of the Sacred Tooth Relic was priced at LKR 1,100 — within the fair range.', location: 'Kandy City Center → Temple', time: '3 hrs ago', read: true),
  AlertItem(id: 4, level: AlertLevel.danger, title: 'Scam: Fake Tour Guide', body: 'An unlicensed guide charged LKR 8,000 for a \'private tour\'. Licensed guides charge LKR 2,000–3,000.', location: 'Kelaniya Temple', time: 'Yesterday', read: true, quoted: 'LKR 8,000', fair: 'LKR 2,500'),
  AlertItem(id: 5, level: AlertLevel.info, title: 'Safety Tip: Night Travel', body: 'After 10 PM, use Uber or PickMe apps instead of street tuk-tuks — better safety & fixed pricing.', location: 'General Advice', time: 'Yesterday', read: true),
  AlertItem(id: 6, level: AlertLevel.warning, title: 'Menu Overcharge at Restaurant', body: 'Sight-Glass detected tourist menu prices 3× higher than local menu at Kandy City Center area.', location: 'Kandy City Center', time: '2 days ago', read: true),
  AlertItem(id: 7, level: AlertLevel.safe, title: 'Route Saved Successfully', body: 'Your route to Sigiriya Rock Fortress has been saved. Estimated travel: 3 hrs 40 min.', location: 'Kandy → Sigiriya', time: '2 days ago', read: true),
];

// Global alerts state for cross-screen demo functionality
final List<AlertItem> globalAlerts = _initialAlerts();

/// Alerts & Scams screen — filterable expandable list.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<AlertItem> get _alerts => globalAlerts;
  String _filter = 'all';
  int? _expanded = 1;

  int get _unread => _alerts.where((a) => !a.read).length;

  List<AlertItem> get _filtered => _filter == 'all'
      ? _alerts
      : _alerts.where((a) => a.level.name == _filter).toList();

  void _markAllRead() => setState(() {
        for (final a in _alerts) {
          a.read = true;
        }
      });

  void _dismiss(int id) =>
      setState(() => _alerts.removeWhere((a) => a.id == id));

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AyuColors.sageBg,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (_filtered.isEmpty) _buildEmpty(),
                ..._filtered.map((alert) => _AlertCard(
                      alert: alert,
                      expanded: _expanded == alert.id,
                      onToggle: () {
                        setState(() {
                          if (!alert.read) alert.read = true;
                          _expanded =
                              _expanded == alert.id ? null : alert.id;
                        });
                      },
                      onDismiss: () => _dismiss(alert.id),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'danger', 'label': 'Scams'},
      {'key': 'warning', 'label': 'Warnings'},
      {'key': 'safe', 'label': 'Safe'},
      {'key': 'info', 'label': 'Tips'},
    ];

    return Container(
      color: AyuColors.sageBg,
      padding: const EdgeInsets.only(left: 20, right: 20, top: 50, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              GestureDetector(
                onTap: widget.onBack,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back, size: 16, color: AyuColors.navy),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Alerts & Scams', style: AyuText.h1().copyWith(fontSize: 21.6)),
                    if (_unread > 0)
                      Text('$_unread new alerts',
                          style: AyuText.label(
                              color: AyuColors.danger,
                              size: 12.5,
                              weight: FontWeight.w600)),
                  ],
                ),
              ),
              if (_unread > 0)
                GestureDetector(
                  onTap: _markAllRead,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AyuColors.sageLightBg,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text('Mark all read',
                        style: AyuText.label(
                            color: AyuColors.sageDeep,
                            size: 11.5,
                            weight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              _statChip('3', 'Scams blocked', AyuColors.danger, AyuColors.dangerBg),
              const SizedBox(width: 8),
              _statChip('₨11.8K', 'Money saved', AyuColors.success, AyuColors.successBg),
              const SizedBox(width: 8),
              _statChip('8', 'Tips received', AyuColors.info, AyuColors.infoBg),
            ],
          ),
          const SizedBox(height: 16),
          // Filter chips
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = filters[i];
                final active = _filter == f['key'];
                final hasDanger = f['key'] == 'danger' &&
                    _alerts
                        .where((a) => a.level == AlertLevel.danger && !a.read)
                        .isNotEmpty;
                return GestureDetector(
                  onTap: () => setState(() => _filter = f['key']!),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AyuColors.navy : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(50),
                      border: active
                          ? null
                          : Border.all(color: AyuColors.borderLight, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Text(f['label']!,
                            style: AyuText.label(
                                color: active ? AyuColors.white : AyuColors.textMuted,
                                size: 12,
                                weight: active ? FontWeight.w700 : FontWeight.w500)),
                        if (hasDanger) ...[
                          const SizedBox(width: 6),
                          Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: AyuColors.danger,
                                  shape: BoxShape.circle)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Text(value,
                style: AyuText.body(size: 17.6, weight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: AyuText.label(color: AyuColors.textSubtle, size: 9.9, weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
                color: AyuColors.sageLightBg, shape: BoxShape.circle),
            child: const Icon(Icons.notifications_none_rounded,
                size: 24, color: AyuColors.sage),
          ),
          const SizedBox(height: 12),
          Text('No alerts here',
              style: AyuText.body(weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Ayu is watching out for you 🛡️',
              style: AyuText.label(color: AyuColors.textSubtle, size: 13.1)),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.expanded,
    required this.onToggle,
    required this.onDismiss,
  });

  final AlertItem alert;
  final bool expanded;
  final VoidCallback onToggle;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final cfg = _levelConfig[alert.level]!;
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: alert.read ? Colors.white.withOpacity(0.85) : AyuColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: !alert.read
                ? AyuColors.danger.withOpacity(0.15)
                : const Color(0xFFECEEE9),
            width: !alert.read ? 1.5 : 1,
          ),
          boxShadow: alert.read
              ? null
              : [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 2))
                ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: cfg.bg, borderRadius: BorderRadius.circular(12)),
                    child: Icon(cfg.icon, size: 16, color: cfg.iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: cfg.badgeBg,
                                  borderRadius: BorderRadius.circular(50)),
                              child: Text(cfg.badge,
                                  style: AyuText.label(
                                      color: cfg.iconColor,
                                      size: 11.5,
                                      weight: FontWeight.w700)),
                            ),
                            if (!alert.read) ...[
                              const SizedBox(width: 8),
                              Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: AyuColors.danger,
                                      shape: BoxShape.circle)),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(alert.title,
                            style: AyuText.body(
                                size: 14.1,
                                weight: FontWeight.w700,
                                color: AyuColors.navy)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 10, color: AyuColors.textSubtle),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(alert.location,
                                  style: AyuText.label(
                                      color: AyuColors.textSubtle, size: 11.5)),
                            ),
                            const SizedBox(width: 6),
                            Text('•',
                                style: AyuText.label(
                                    color: AyuColors.textLight, size: 11.2)),
                            const SizedBox(width: 6),
                            const Icon(Icons.access_time_rounded,
                                size: 10, color: AyuColors.textSubtle),
                            const SizedBox(width: 3),
                            Text(alert.time,
                                style: AyuText.label(
                                    color: AyuColors.textSubtle, size: 11.5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Chevron + dismiss
                  Column(
                    children: [
                      AnimatedRotation(
                        turns: expanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.chevron_right,
                            size: 15, color: AyuColors.textLight),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: onDismiss,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                              color: AyuColors.sageBg, shape: BoxShape.circle),
                          child: const Icon(Icons.close,
                              size: 11, color: AyuColors.textSubtle),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Expanded content
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _buildExpanded(),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              height: 1, color: const Color(0xFFF0F1EC)),
          const SizedBox(height: 12),
          Text(alert.body,
              style: AyuText.body(
                  color: const Color(0xFF64748B), size: 13.1)),
          if (alert.quoted != null && alert.fair != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: AyuColors.dangerBg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text('QUOTED',
                            style: AyuText.label(
                                color: AyuColors.danger,
                                size: 10.4,
                                weight: FontWeight.w600)),
                        Text(alert.quoted!,
                            style: AyuText.body(
                                size: 16,
                                weight: FontWeight.w800,
                                color: AyuColors.danger)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                        color: AyuColors.successBg,
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text('FAIR',
                            style: AyuText.label(
                                color: AyuColors.success,
                                size: 10.4,
                                weight: FontWeight.w600)),
                        Text(alert.fair!,
                            style: AyuText.body(
                                size: 16,
                                weight: FontWeight.w800,
                                color: AyuColors.success)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ExpandedAction(
                  icon: Icons.check_circle_outline_rounded,
                  label: 'Resolved',
                  iconColor: AyuColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ExpandedAction(
                  icon: Icons.location_on,
                  label: 'View on Map',
                  iconColor: AyuColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpandedAction extends StatelessWidget {
  const _ExpandedAction({required this.icon, required this.label, required this.iconColor});
  final IconData icon;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
          color: AyuColors.sageBg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: iconColor),
          const SizedBox(width: 6),
          Text(label,
              style: AyuText.body(size: 12.5, weight: FontWeight.w700)),
        ],
      ),
    );
  }
}
