import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../provider/locale_provider.dart';
import '../../provider/theme_provider.dart';

class ContactUsPage extends StatefulWidget {
  const ContactUsPage({Key? key}) : super(key: key);

  @override
  State<ContactUsPage> createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage>
    with TickerProviderStateMixin {
  late AnimationController _pageAnim;
  late AnimationController _pulseAnim;
  late Animation<double> _fade;
  late Animation<double> _pulse;

  // ── Office details ─────────────────────────────────────────────────────────
  static const double _lat = -6.7819676;
  static const double _lng = 39.2744252;
  static const String _phone = '+255 753011994';
  static const String _email = 'tanzaniasecuritieslimited@gmail.com';

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650))
      ..forward();
    _pulseAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _fade = CurvedAnimation(parent: _pageAnim, curve: Curves.easeOut);
    _pulse = CurvedAnimation(parent: _pulseAnim, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pageAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  // ── Theme helpers ──────────────────────────────────────────────────────────
  bool get _dark => context.watch<ThemeProvider>().isDark;
  bool get _sw => context.watch<LocaleProvider>().isSwahili;

  Color get _bg => _dark ? const Color(0xFF0A1628) : const Color(0xFFF4F7FB);
  Color get _card => _dark ? const Color(0xFF0F1F35) : Colors.white;
  Color get _teal => const Color(0xFF2E7D99);
  Color get _green => const Color(0xFF4CAF50);
  Color get _txtP => _dark ? Colors.white : const Color(0xFF1A1A2E);
  Color get _txtS => _dark ? Colors.white54 : Colors.grey.shade500;
  Color get _div => _dark ? Colors.white10 : Colors.grey.shade100;

  // ── URL actions ────────────────────────────────────────────────────────────
  Future<void> _directions() async {
    HapticFeedback.mediumImpact();
    final geo = Uri.parse('geo:$_lat,$_lng?q=$_lat,$_lng(TSL+Investment)');
    final web = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$_lat,$_lng&travelmode=driving');
    if (await canLaunchUrl(geo)) {
      await launchUrl(geo);
    } else {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMap() async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$_lat,$_lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _call() async {
    HapticFeedback.selectionClick();
    final uri = Uri.parse('tel:$_phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _mail() async {
    HapticFeedback.selectionClick();
    final uri =
    Uri.parse('mailto:$_email?subject=Inquiry%20%E2%80%93%20TSL%20Investment');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    HapticFeedback.selectionClick();
    final number = _phone.replaceAll('+', '').replaceAll(' ', '');
    final uri = Uri.parse('https://wa.me/$number');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _copy(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: _green,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    context.watch<LocaleProvider>();

    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _appBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 20),
                _mapCard(),
                const SizedBox(height: 14),
                _directionsButton(),
                const SizedBox(height: 20),
                _addressCard(),
                const SizedBox(height: 14),
                _quickActions(),
                const SizedBox(height: 14),
                _hoursCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sliver App Bar ─────────────────────────────────────────────────────────
  Widget _appBar() {
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      backgroundColor: _dark ? const Color(0xFF0F2744) : _teal,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(

        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D99), Color(0xFF1A5F77), Color(0xFF2E7D32)],
            ),
          ),
          child: FadeTransition(
            opacity: _fade,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                          child: const Icon(Icons.location_on_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _sw ? 'Wasiliana Nasi' : 'Contact Us',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              _sw
                                  ? 'Tuko Dar es Salaam, Tanzania'
                                  : 'Dar es Salaam, Tanzania',
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Map preview card ───────────────────────────────────────────────────────
  Widget _mapCard() {
    return _anim(
      delay: 0,
      child: GestureDetector(
        onTap: _openMap,
        child: Container(
          height: 210,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _teal.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // ── Map background (animated pin fallback) ────────────────────
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  width: double.infinity,
                  height: 210,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _dark
                          ? [const Color(0xFF0D2137), const Color(0xFF1A3A5C)]
                          : [const Color(0xFFD4EAF5), const Color(0xFFB8D8EA)],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Grid lines (faux-map roads)
                      CustomPaint(
                        size: const Size(double.infinity, 210),
                        painter: _GridPainter(
                          lineColor: _dark
                              ? Colors.white.withValues(alpha: 0.045)
                              : Colors.grey.withValues(alpha: 0.14),
                          roadColor: _dark
                              ? Colors.white.withValues(alpha: 0.09)
                              : Colors.grey.withValues(alpha: 0.28),
                        ),
                      ),
                      // Pulsing rings + pin
                      Center(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer pulse
                            Container(
                              width: 85 + 22 * _pulse.value,
                              height: 85 + 22 * _pulse.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _teal.withOpacity(
                                    0.07 * (1 - _pulse.value)),
                              ),
                            ),
                            // Middle ring
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _teal.withOpacity(0.12),
                                border: Border.all(
                                    color: _teal.withOpacity(0.3), width: 1.5),
                              ),
                            ),
                            // Pin
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF2E7D99),
                                    Color(0xFF4CAF50)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _teal.withOpacity(0.5),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.location_on_rounded,
                                  color: Colors.white, size: 22),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Office label chip ─────────────────────────────────────────
              Positioned(
                bottom: 12,
                left: 12,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _dark
                        ? Colors.black.withOpacity(0.6)
                        : Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _teal.withOpacity(0.25)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.business_rounded, size: 13, color: _teal),
                      const SizedBox(width: 5),
                      Text(
                        'TSL Investment – Alfa Plaza',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _txtP),
                      ),
                    ],
                  ),
                ),
              ),
              // ── Open in Maps chip ─────────────────────────────────────────
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.open_in_new_rounded, size: 12, color: _teal),
                      const SizedBox(width: 4),
                      Text(
                        _sw ? 'Fungua Ramani' : 'Open Maps',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _teal),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Get Directions button ──────────────────────────────────────────────────
  Widget _directionsButton() {
    return _anim(
      delay: 60,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2E7D99), Color(0xFF4CAF50)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _teal.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _directions,
              borderRadius: BorderRadius.circular(16),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_rounded,
                        color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      _sw
                          ? 'Pata Maelekezo ya Kuelekea Ofisi'
                          : 'Get Directions to Our Office',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Address card ───────────────────────────────────────────────────────────
  Widget _addressCard() {
    return _anim(
      delay: 120,
      child: _buildCard(
        title: _sw ? 'Anwani ya Ofisi' : 'Office Address',
        icon: Icons.location_on_rounded,
        accent: _teal,
        children: [
          _row(
            icon: Icons.business_rounded,
            sub: _sw ? 'Jengo' : 'Building',
            value: 'Alfa Plaza Complex',
            onTap: () => _copy('Alfa Plaza Complex', 'Address'),
          ),
          _line(),
          _row(
            icon: Icons.place_outlined,
            sub: _sw ? 'Mtaa' : 'Street',
            value: 'Chabruma Street',
            onTap: () => _copy('Chabruma Street', 'Street'),
          ),
          _line(),
          _row(
            icon: Icons.location_city_rounded,
            sub: _sw ? 'Mji' : 'City',
            value: 'Dar es Salaam, Tanzania',
            onTap: () => _copy('Dar es Salaam, Tanzania', 'City'),
          ),
          _line(),
          _row(
            icon: Icons.my_location_rounded,
            sub: _sw ? 'Kuratibu' : 'Coordinates',
            value: '${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}',
            onTap: () => _copy('$_lat, $_lng', 'Coordinates'),
          ),
        ],
      ),
    );
  }

  // ── Quick-action buttons: Call / Email / WhatsApp ─────────────────────────
  Widget _quickActions() {
    return _anim(
      delay: 180,
      child: Row(
        children: [
          Expanded(
            child: _actionBtn(
              icon: Icons.phone_rounded,
              label: _sw ? 'Piga Simu' : 'Call',
              color: _green,
              onTap: _call,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionBtn(
              icon: Icons.email_outlined,
              label: _sw ? 'Barua Pepe' : 'Email',
              color: _teal,
              onTap: _mail,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _actionBtn(
              icon: Icons.chat_rounded,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              onTap: _whatsapp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _div),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_dark ? 0.2 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(_dark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _txtP,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Opening hours card ─────────────────────────────────────────────────────
  Widget _hoursCard() {
    final weekday = DateTime.now().weekday; // 1=Mon … 7=Sun
    final hour = DateTime.now().hour;
    final isOpen = weekday <= 5
        ? (hour >= 9 && hour < 17)
        : weekday == 6
        ? (hour >= 9 && hour < 13)
        : false;

    return _anim(
      delay: 240,
      child: _buildCard(
        title: _sw ? 'Masaa ya Kufanya Kazi' : 'Opening Hours',
        icon: Icons.access_time_rounded,
        accent: const Color(0xFFE67E22),
        trailing: _statusBadge(isOpen),
        children: [
          _hoursRow(
            day: _sw ? 'Jumatatu – Ijumaa' : 'Mon – Fri',
            hours: '8:00 AM – 5:00 PM',
            isToday: weekday >= 1 && weekday <= 5,
            closed: false,
          ),
          _line(),
          _hoursRow(
            day: _sw ? 'Jumamosi' : 'Saturday',
            hours: _sw ? 'Imefungwa' : 'Closed',
            isToday: weekday == 7,
            closed: true,
          ),
          _line(),
          _hoursRow(
            day: _sw ? 'Jumapili' : 'Sunday',
            hours: _sw ? 'Imefungwa' : 'Closed',
            isToday: weekday == 7,
            closed: true,
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(bool open) {
    final color = open ? _green : const Color(0xFFEF4444);
    final label = open
        ? (_sw ? 'Wazi Sasa' : 'Open Now')
        : (_sw ? 'Imefungwa' : 'Closed');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 6,
              height: 6,
              decoration:
              BoxDecoration(shape: BoxShape.circle, color: color)),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  // ── Reusable card shell ────────────────────────────────────────────────────
  Widget _buildCard({
    required String title,
    required IconData icon,
    required Color accent,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _div),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_dark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(_dark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _txtP)),
                const Spacer(),
                if (trailing != null) trailing,
              ],
            ),
          ),
          Divider(height: 1, color: _div),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String sub,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 17, color: _txtS),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sub,
                      style: TextStyle(fontSize: 10.5, color: _txtS)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _txtP)),
                ],
              ),
            ),
            Icon(Icons.copy_rounded, size: 14, color: _txtS),
          ],
        ),
      ),
    );
  }

  Widget _hoursRow({
    required String day,
    required String hours,
    required bool isToday,
    required bool closed,
  }) {
    final dotColor = closed ? const Color(0xFFEF4444) : _green;
    return Container(
      decoration: isToday
          ? BoxDecoration(
        color: _teal.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            if (isToday)
              Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 8),
                  decoration:
                  BoxDecoration(shape: BoxShape.circle, color: dotColor))
            else
              const SizedBox(width: 14),
            Expanded(
              child: Text(day,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                      isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday ? _txtP : _txtS)),
            ),
            Text(hours,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                    isToday ? FontWeight.w700 : FontWeight.w500,
                    color: closed
                        ? const Color(0xFFEF4444)
                        : (isToday ? _green : _txtS))),
          ],
        ),
      ),
    );
  }

  Widget _line() => Divider(height: 1, indent: 40, color: _div);

  // ── Entry animation wrapper ────────────────────────────────────────────────
  Widget _anim({required Widget child, required int delay}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + delay),
      curve: Curves.easeOutCubic,
      builder: (_, v, ch) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 18 * (1 - v)), child: ch),
      ),
      child: child,
    );
  }
}

// ── Faux-map grid painter ──────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final Color lineColor;
  final Color roadColor;
  _GridPainter({required this.lineColor, required this.roadColor});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final roadPaint = Paint()
      ..color = roadColor
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    // Grid
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    // Roads
    canvas.drawLine(
        Offset(0, size.height * 0.52),
        Offset(size.width, size.height * 0.44),
        roadPaint);
    canvas.drawLine(
        Offset(size.width * 0.38, 0),
        Offset(size.width * 0.44, size.height),
        roadPaint);
  }

  @override
  bool shouldRepaint(_GridPainter o) =>
      o.lineColor != lineColor || o.roadColor != roadColor;
}