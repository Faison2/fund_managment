import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../trade/trade_shared.dart';


class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;

  bool _notificationsOn = true;
  bool _biometricsOn = false;
  bool _priceAlertsOn = true;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TradeColors.bg,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: TradeColors.bg,
              pinned: true,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: TradeColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: TradeColors.border),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: TradeColors.txtPrim),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Profile',
                  style: TextStyle(
                      color: TradeColors.txtPrim,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: TradeColors.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: TradeColors.border),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        size: 16, color: TradeColors.teal),
                  ),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildAvatarCard(),
                  const SizedBox(height: 20),
                  _buildStatsRow(),
                  const SizedBox(height: 20),
                  const TradeSectionHeader(
                      title: 'Account Details',
                      icon: Icons.account_circle_outlined),
                  _buildAccountCard(),
                  const SizedBox(height: 20),
                  const TradeSectionHeader(
                      title: 'Preferences',
                      icon: Icons.tune_rounded),
                  _buildPreferencesCard(),
                  const SizedBox(height: 20),
                  const TradeSectionHeader(
                      title: 'Support',
                      icon: Icons.help_outline_rounded),
                  _buildSupportCard(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Avatar / identity card ─────────────────────────────────────────────────
  Widget _buildAvatarCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D3D5C), Color(0xFF061820)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: TradeColors.teal.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
                color: TradeColors.teal.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [TradeColors.teal, Color(0xFF0080FF)],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: TradeColors.teal.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Center(
                    child: Text('TI',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900)),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: TradeColors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF0D3D5C), width: 2),
                    ),
                    child: const Icon(Icons.check,
                        size: 10, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TSL Investor',
                      style: TextStyle(
                          color: TradeColors.txtPrim,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('investor@tsl.co.tz',
                      style: TextStyle(
                          color: TradeColors.txtSec, fontSize: 12)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: TradeColors.teal.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color:
                          TradeColors.teal.withOpacity(0.3)),
                    ),
                    child: const Text('Trade Account Active',
                        style: TextStyle(
                            color: TradeColors.teal,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    final stats = [
      {'label': 'Total Trades', 'value': '142', 'color': TradeColors.teal},
      {'label': 'Win Rate',     'value': '68%', 'color': TradeColors.green},
      {'label': 'Avg Return',   'value': '+12.4%', 'color': TradeColors.gold},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: stats.asMap().entries.map((e) {
          final item = e.value;
          final color = item['color'] as Color;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: e.key < 2 ? 10 : 0),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border:
                Border.all(color: color.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Text(item['value'] as String,
                      style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(item['label'] as String,
                      style: const TextStyle(
                          color: TradeColors.txtSec,
                          fontSize: 10),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Account details card ───────────────────────────────────────────────────
  Widget _buildAccountCard() {
    final details = [
      {'icon': Icons.badge_outlined,         'label': 'CDS Number',      'value': 'CDS-00123456'},
      {'icon': Icons.account_balance_outlined,'label': 'Account Type',   'value': 'Individual Retail'},
      {'icon': Icons.verified_outlined,       'label': 'KYC Status',     'value': 'Verified ✓'},
      {'icon': Icons.calendar_today_outlined, 'label': 'Member Since',   'value': 'January 2022'},
      {'icon': Icons.phone_outlined,          'label': 'Phone',          'value': '+255 7XX XXX XXX'},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: TradeColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TradeColors.border),
        ),
        child: Column(
          children: details.asMap().entries.map((e) {
            final item = e.value;
            final last = e.key == details.length - 1;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(item['icon'] as IconData,
                          size: 18, color: TradeColors.teal),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(item['label'] as String,
                            style: const TextStyle(
                                color: TradeColors.txtSec,
                                fontSize: 13)),
                      ),
                      Text(item['value'] as String,
                          style: const TextStyle(
                              color: TradeColors.txtPrim,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                if (!last)
                  Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.05),
                      indent: 16,
                      endIndent: 16),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Preferences card ───────────────────────────────────────────────────────
  Widget _buildPreferencesCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: TradeColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TradeColors.border),
        ),
        child: Column(
          children: [
            _prefToggle(
              Icons.notifications_outlined,
              'Push Notifications',
              _notificationsOn,
                  (v) {
                HapticFeedback.selectionClick();
                setState(() => _notificationsOn = v);
              },
            ),
            Divider(height: 1, color: Colors.white.withOpacity(0.05),
                indent: 16, endIndent: 16),
            _prefToggle(
              Icons.fingerprint_rounded,
              'Biometric Login',
              _biometricsOn,
                  (v) {
                HapticFeedback.selectionClick();
                setState(() => _biometricsOn = v);
              },
            ),
            Divider(height: 1, color: Colors.white.withOpacity(0.05),
                indent: 16, endIndent: 16),
            _prefToggle(
              Icons.price_change_outlined,
              'Price Alerts',
              _priceAlertsOn,
                  (v) {
                HapticFeedback.selectionClick();
                setState(() => _priceAlertsOn = v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _prefToggle(
      IconData icon, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: TradeColors.teal),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: TradeColors.txtPrim, fontSize: 13)),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: TradeColors.teal,
            activeTrackColor: TradeColors.teal.withOpacity(0.25),
            inactiveThumbColor: TradeColors.txtSec,
            inactiveTrackColor:
            TradeColors.txtSec.withOpacity(0.15),
          ),
        ],
      ),
    );
  }

  // ── Support card ───────────────────────────────────────────────────────────
  Widget _buildSupportCard() {
    final items = [
      {'icon': Icons.help_outline_rounded,       'label': 'Help & FAQ'},
      {'icon': Icons.chat_bubble_outline_rounded, 'label': 'Live Chat Support'},
      {'icon': Icons.policy_outlined,             'label': 'Terms & Privacy'},
      {'icon': Icons.info_outline_rounded,        'label': 'About TSL Trade v1.0.0'},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: TradeColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TradeColors.border),
        ),
        child: Column(
          children: items.asMap().entries.map((e) {
            final item = e.value;
            final last = e.key == items.length - 1;
            return Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(last ? 18 : 0),
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(item['icon'] as IconData,
                            size: 18, color: TradeColors.txtSec),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(item['label'] as String,
                              style: const TextStyle(
                                  color: TradeColors.txtPrim,
                                  fontSize: 13)),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            size: 16, color: TradeColors.txtSec),
                      ],
                    ),
                  ),
                ),
                if (!last)
                  Divider(
                      height: 1,
                      color: Colors.white.withOpacity(0.05),
                      indent: 16,
                      endIndent: 16),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}