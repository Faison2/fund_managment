import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../provider/locale_provider.dart';
import '../../provider/theme_provider.dart';
import 'minor_dashboard.dart';

// ── TSL Brand colours ──────────────────────────────────────────────────────
class _TSL {
  static const Color blue  = Color(0xFF329AD6);
  static const Color teal  = Color(0xFF00A79D);
  static const Color grey  = Color(0xFF939598);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF231F20);
}

// Full-detail profile view for a single linked minor — every field the
// GetLinkedMinors API returns, laid out in labelled sections.
class MinorProfileScreen extends StatelessWidget {
  final LinkedMinorAccount minor;
  final String guardianName;

  const MinorProfileScreen({
    Key? key,
    required this.minor,
    required this.guardianName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().isDark;
    final sw   = context.watch<LocaleProvider>().isSwahili;

    final bg      = dark ? _TSL.black : const Color(0xFFEAF6F1);
    final cardBg  = dark ? const Color(0xFF1B2321) : _TSL.white;
    final txtPrim = dark ? _TSL.white : _TSL.black;
    final txtSec  = dark ? _TSL.white.withOpacity(0.6) : _TSL.grey;
    final divider = dark
        ? _TSL.white.withOpacity(0.08)
        : _TSL.grey.withOpacity(0.15);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            // ── Top bar ──────────────────────────────────────────────────
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.maybePop(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Icon(Icons.arrow_back_ios_new_rounded,
                        size: 20, color: txtPrim),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  sw ? 'Wasifu wa Mtoto' : 'Minor Profile',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: txtPrim,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Avatar + name + account-type badge ─────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_TSL.teal, _TSL.blue],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        minor.fullName.isNotEmpty
                            ? minor.fullName[0].toUpperCase()
                            : 'M',
                        style: const TextStyle(
                          color: _TSL.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    minor.fullName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: txtPrim,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _TSL.blue.withOpacity(dark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      minor.accountTypeLabel,
                      style: TextStyle(
                        color: _TSL.blue,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // ── Personal details ────────────────────────────────────────
            _sectionCard(
              cardBg: cardBg,
              divider: divider,
              title: sw ? 'Maelezo Binafsi' : 'Personal Details',
              icon: Icons.badge_outlined,
              txtSec: txtSec,
              rows: [
                _row(sw ? 'Jina Kamili' : 'Full Name', minor.fullName,
                    txtPrim, txtSec),
                _row(sw ? 'Cheo' : 'Title', minor.title, txtPrim, txtSec),
                _row(sw ? 'Jinsia' : 'Gender',
                    minor.gender == 'M'
                        ? (sw ? 'Mwanaume' : 'Male')
                        : minor.gender == 'F'
                        ? (sw ? 'Mwanamke' : 'Female')
                        : minor.gender,
                    txtPrim,
                    txtSec),
                _row(sw ? 'Tarehe ya Kuzaliwa' : 'Date of Birth',
                    minor.formattedDob, txtPrim, txtSec),
                _row(sw ? 'Utaifa' : 'Nationality', minor.nationality,
                    txtPrim, txtSec),
              ],
            ),
            const SizedBox(height: 16),

            // ── Identification ──────────────────────────────────────────
            _sectionCard(
              cardBg: cardBg,
              divider: divider,
              title: sw ? 'Utambulisho' : 'Identification',
              icon: Icons.fingerprint_rounded,
              txtSec: txtSec,
              rows: [
                _row('Account ${sw ? "Namba" : "Number"}', minor.cdsNumber,
                    txtPrim, txtSec),
                _row(sw ? 'Msimbo wa Wakala' : 'Broker Code',
                    minor.brokerCode, txtPrim, txtSec),
                _row(sw ? 'Namba ya Kitambulisho' : 'ID Number',
                    minor.idNoPP, txtPrim, txtSec),
                _row(sw ? 'Aina ya Kitambulisho' : 'ID Type',
                    minor.idType.isEmpty ? '—' : minor.idType, txtPrim,
                    txtSec),
              ],
            ),
            const SizedBox(height: 16),

            // ── Contact / address ───────────────────────────────────────
            _sectionCard(
              cardBg: cardBg,
              divider: divider,
              title: sw ? 'Anwani' : 'Address',
              icon: Icons.home_outlined,
              txtSec: txtSec,
              rows: [
                _row(sw ? 'Anwani' : 'Address', minor.address, txtPrim,
                    txtSec),
              ],
            ),
            const SizedBox(height: 16),

            // ── Guardian details ─────────────────────────────────────────
            _sectionCard(
              cardBg: cardBg,
              divider: divider,
              title: sw ? 'Msimamizi' : 'Guardian',
              icon: Icons.family_restroom_rounded,
              txtSec: txtSec,
              rows: [
                _row(sw ? 'Jina la Msimamizi' : 'Guardian Name',
                    guardianName, txtPrim, txtSec),
                _row(sw ? 'Cheo cha Msimamizi' : 'Guardian Title',
                    minor.gTitle.isEmpty ? '—' : minor.gTitle, txtPrim,
                    txtSec),
                _row(
                    sw ? 'Kitambulisho cha Msimamizi' : 'Guardian ID',
                    minor.guardianIdentification,
                    txtPrim,
                    txtSec),
                _row(sw ? 'Barua Pepe ya Msimamizi' : 'Guardian Email',
                    minor.gEmail.isEmpty ? '—' : minor.gEmail, txtPrim,
                    txtSec),
                _row(
                    sw ? 'Hali ya Ndoa ya Msimamizi' : 'Marital Status',
                    minor.gMaritalStatus.isEmpty
                        ? '—'
                        : minor.gMaritalStatus,
                    txtPrim,
                    txtSec),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required Color cardBg,
    required Color divider,
    required Color txtSec,
    required String title,
    required IconData icon,
    required List<Widget> rows,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _TSL.teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: _TSL.teal, size: 17),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: txtSec,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: divider),
          const SizedBox(height: 6),
          ...rows,
        ],
      ),
    );
  }

  Widget _row(
      String label, String value, Color txtPrim, Color txtSec) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: txtSec),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: txtPrim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}