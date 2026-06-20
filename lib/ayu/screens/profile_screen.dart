import 'package:flutter/material.dart';
import '../theme/ayu_colors.dart';
import '../theme/ayu_text_styles.dart';
import '../widgets/editable_field.dart';
import '../widgets/section_label.dart';
import '../widgets/custom_toggle.dart';

const _nationalities = ['Australian', 'British', 'Canadian', 'Chinese', 'French', 'German', 'Indian', 'Japanese', 'American', 'Other'];
const _languages = ['English', 'French', 'German', 'Mandarin', 'Hindi', 'Japanese', 'Spanish'];
const _interests = ['Temples', 'Food', 'Nature', 'History', 'Beaches', 'Adventure', 'Culture', 'Shopping', 'Nightlife'];

/// Profile screen — dark hero header with avatar, editable form, interest chips, toggles.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.onBack});
  final VoidCallback onBack;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _editing = false;
  bool _saved = false;

  String _name = 'Alex Morgan';
  String _email = 'alex.morgan@email.com';
  String _phone = '+44 7911 123456';
  String _homeCity = 'London, UK';
  String _nationality = 'British';
  String _passport = 'GB1234567';
  String _language = 'English';
  String _emergencyName = 'James Morgan';
  String _emergencyPhone = '+44 7911 654321';

  final List<String> _selectedInterests = ['Temples', 'Food', 'Nature', 'Beaches'];
  bool _notifications = true;
  bool _scamAlerts = true;

  // Trust score animation driven by TweenAnimationBuilder in build()
  void _handleSave() {
    setState(() {
      _editing = false;
      _saved = true;
    });
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  void _toggleInterest(String tag) {
    setState(() {
      _selectedInterests.contains(tag)
          ? _selectedInterests.remove(tag)
          : _selectedInterests.add(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AyuColors.sageBg,
      child: Column(
        children: [
          _buildHeroHeader(),
          // Saved toast
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _saved
                ? Container(
                    key: const ValueKey('toast'),
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AyuColors.successBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AyuColors.sageAccent, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 15, color: AyuColors.success),
                        const SizedBox(width: 10),
                        Text('Profile saved successfully',
                            style: AyuText.body(
                                size: 13.6,
                                weight: FontWeight.w700,
                                color: AyuColors.success)),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 16, bottom: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal info
                  SectionLabel(icon: Icons.person_outline_rounded, label: 'Personal Information'),
                  _gap(),
                  EditableField(label: 'Full Name', value: _name, icon: Icons.person_outline_rounded, onChanged: (v) => setState(() => _name = v), editing: _editing),
                  const SizedBox(height: 10),
                  EditableField(label: 'Email', value: _email, icon: Icons.mail_outline_rounded, onChanged: (v) => setState(() => _email = v), editing: _editing),
                  const SizedBox(height: 10),
                  EditableField(label: 'Phone', value: _phone, icon: Icons.phone_outlined, onChanged: (v) => setState(() => _phone = v), editing: _editing),
                  const SizedBox(height: 10),
                  EditableField(label: 'Home City', value: _homeCity, icon: Icons.location_on_outlined, onChanged: (v) => setState(() => _homeCity = v), editing: _editing),
                  const SizedBox(height: 20),

                  // Travel documents
                  SectionLabel(icon: Icons.menu_book_outlined, label: 'Travel Documents'),
                  _gap(),
                  // Nationality selector
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: _editing ? AyuColors.white : AyuColors.sageBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: _editing ? AyuColors.lime : Colors.transparent,
                          width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                              color: AyuColors.sageLightBg,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.language_rounded, size: 14, color: AyuColors.sageDeep),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('NATIONALITY',
                                  style: AyuText.label(color: AyuColors.textSubtle, size: 10.9, weight: FontWeight.w600, letterSpacing: 0.04 * 11)),
                              const SizedBox(height: 2),
                              _editing
                                  ? DropdownButton<String>(
                                      value: _nationality,
                                      isDense: true,
                                      underline: const SizedBox(),
                                      onChanged: (v) => setState(() => _nationality = v!),
                                      items: _nationalities.map((n) => DropdownMenuItem(value: n, child: Text(n, style: AyuText.body(size: 14.4, weight: FontWeight.w600)))).toList(),
                                    )
                                  : Text(_nationality, style: AyuText.body(size: 14.4, weight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  EditableField(label: 'Passport Number', value: _passport, placeholder: 'e.g. GB1234567', icon: Icons.menu_book_outlined, onChanged: (v) => setState(() => _passport = v), editing: _editing),
                  const SizedBox(height: 20),

                  // Emergency contact
                  SectionLabel(icon: Icons.phone_outlined, label: 'Emergency Contact'),
                  _gap(),
                  EditableField(label: 'Contact Name', value: _emergencyName, icon: Icons.person_outline_rounded, onChanged: (v) => setState(() => _emergencyName = v), editing: _editing),
                  const SizedBox(height: 10),
                  EditableField(label: 'Contact Phone', value: _emergencyPhone, icon: Icons.phone_outlined, onChanged: (v) => setState(() => _emergencyPhone = v), editing: _editing),
                  const SizedBox(height: 20),

                  // Travel interests
                  SectionLabel(icon: Icons.favorite_border_rounded, label: 'Travel Interests'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _interests.map((tag) {
                      final selected = _selectedInterests.contains(tag);
                      return GestureDetector(
                        onTap: () => _editing ? _toggleInterest(tag) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? AyuColors.lime : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(50),
                            border: selected ? null : Border.all(color: AyuColors.borderLight, width: 1.5),
                          ),
                          child: Text(tag,
                              style: AyuText.chip(
                                  color: selected ? AyuColors.navy : AyuColors.textMuted,
                                  active: selected)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Language
                  SectionLabel(icon: Icons.language_rounded, label: 'Language'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _languages.map((lang) {
                      final sel = _language == lang;
                      return GestureDetector(
                        onTap: () => _editing ? setState(() => _language = lang) : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel ? AyuColors.navy : Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(50),
                            border: sel ? null : Border.all(color: AyuColors.borderLight, width: 1.5),
                          ),
                          child: Text(lang,
                              style: AyuText.chip(
                                  color: sel ? AyuColors.white : AyuColors.textMuted,
                                  active: sel)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Notifications
                  SectionLabel(icon: Icons.notifications_outlined, label: 'Notifications'),
                  _ToggleRow(
                    label: 'Push Notifications',
                    sub: 'Get alerts on your device',
                    value: _notifications,
                    onChanged: (v) => setState(() => _notifications = v),
                  ),
                  const SizedBox(height: 10),
                  _ToggleRow(
                    label: 'Scam Alerts',
                    sub: 'Real-time Guardian warnings',
                    value: _scamAlerts,
                    onChanged: (v) => setState(() => _scamAlerts = v),
                  ),
                  const SizedBox(height: 20),

                  // Guardian trust score
                  SectionLabel(icon: Icons.shield_outlined, label: 'Guardian Trust Score'),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AyuColors.navy, AyuColors.navyDeep],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('92 / 100',
                                    style: AyuText.body(
                                        size: 16,
                                        weight: FontWeight.w800,
                                        color: AyuColors.white)),
                                Text('Protected traveler',
                                    style: AyuText.label(
                                        color: Colors.white.withOpacity(0.6),
                                        size: 11.5)),
                              ],
                            ),
                            Row(
                              children: List.generate(
                                5,
                                (_) => const Icon(Icons.star_rounded,
                                    size: 14, color: AyuColors.lime),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            height: 8,
                            color: Colors.white.withOpacity(0.15),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: 0.92),
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeOut,
                              builder: (_, v, __) => FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: v,
                                child: Container(
                                    decoration: BoxDecoration(
                                        color: AyuColors.lime,
                                        borderRadius: BorderRadius.circular(50))),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action rows
                  _ActionRow(icon: Icons.shield_outlined, label: 'Privacy & Data Settings', color: AyuColors.info),
                  const SizedBox(height: 10),
                  _ActionRow(icon: Icons.menu_book_outlined, label: 'Download My Data', color: AyuColors.sageDeep),
                  const SizedBox(height: 16),

                  // Logout
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AyuColors.dangerBg,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: AyuColors.dangerLight, width: 1.5),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout_rounded, size: 16, color: AyuColors.danger),
                        const SizedBox(width: 10),
                        Text('Sign Out',
                            style: AyuText.body(
                                size: 14.4, weight: FontWeight.w700, color: AyuColors.danger)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 4);

  Widget _buildHeroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AyuColors.navy, AyuColors.navyDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 20).copyWith(top: 50, bottom: 24),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 4),
              // Avatar
              Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AyuColors.lime, width: 3),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          'https://images.unsplash.com/photo-1520466809213-7b9a56adcd45?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=200',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AyuColors.sageLightBg),
                        ),
                      ),
                    ),
                    if (_editing)
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                              color: AyuColors.lime, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded,
                              size: 12, color: AyuColors.navy),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(_name,
                  style: AyuText.h2(color: AyuColors.white)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 11, color: Color(0x99FFFFFF)),
                  const SizedBox(width: 4),
                  Text(_homeCity,
                      style: AyuText.label(
                          color: Colors.white.withOpacity(0.6),
                          size: 12.5,
                          weight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 16),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _HeroStat(label: 'Trips', value: '3'),
                  _HeroStat(label: 'Scams blocked', value: '3'),
                  _HeroStat(label: 'Saved', value: '₨11.8K'),
                ],
              ),
            ],
          ),
          // Back button
          Positioned(
            top: 0,
            left: 0,
            child: GestureDetector(
              onTap: widget.onBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 16, color: AyuColors.white),
              ),
            ),
          ),
          // Edit / Save
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: _editing ? _handleSave : () => setState(() => _editing = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _editing
                      ? AyuColors.lime
                      : Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: _editing
                      ? [
                          const Icon(Icons.check, size: 13, color: AyuColors.navy),
                          const SizedBox(width: 6),
                          Text('Save',
                              style: AyuText.label(
                                  color: AyuColors.navy,
                                  size: 12.8,
                                  weight: FontWeight.w700)),
                        ]
                      : [
                          const Icon(Icons.edit_outlined,
                              size: 13, color: AyuColors.white),
                          const SizedBox(width: 6),
                          Text('Edit',
                              style: AyuText.label(
                                  color: AyuColors.white,
                                  size: 12.8,
                                  weight: FontWeight.w600)),
                        ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(value,
              style: AyuText.body(
                  size: 17.6, weight: FontWeight.w800, color: AyuColors.white)),
          Text(label,
              style: AyuText.label(
                  color: Colors.white.withOpacity(0.5),
                  size: 10.4,
                  weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.sub,
    required this.value,
    required this.onChanged,
  });
  final String label, sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: AyuText.body(size: 14.1, weight: FontWeight.w700)),
                Text(sub,
                    style: AyuText.label(color: AyuColors.textSubtle, size: 11.5)),
              ],
            ),
          ),
          CustomToggle(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: AyuColors.sageBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: AyuText.body(size: 14.1, weight: FontWeight.w600)),
          ),
          const Icon(Icons.chevron_right, size: 15, color: AyuColors.textLight),
        ],
      ),
    );
  }
}
