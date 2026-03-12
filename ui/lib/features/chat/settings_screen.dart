import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';
import '../../main.dart';
import '../../services/api_service.dart';
import '../../core/services/auth_service.dart';
import '../../routes/app_routes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  final Map<String, String> _languages = {
    'English': 'en_IN',
    'हिंदी (Hindi)': 'hi_IN',
    'मराठी (Marathi)': 'mr_IN',
  };

  String _currentLangName = 'English';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _currentLangName = prefs.getString('selected_lang_name') ?? 'English';
    });
  }

  Future<void> _updateLanguage(String name, String code) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('selected_lang_name', name);
    await prefs.setString('selected_lang_code', code);

    setState(() {
      _currentLangName = name;
    });

    if (!mounted) return;

    if (code == 'mr_IN') {
      MyApp.setLocale(context, const Locale('mr'));
    }
    else if (code == 'hi_IN') {
      MyApp.setLocale(context, const Locale('hi'));
    }
    else {
      MyApp.setLocale(context, const Locale('en'));
    }
  }

  @override
  Widget build(BuildContext context) {

    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFE9F8EF),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),

        title: Text(
          loc.settings,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _userInfoSection(context),

            const SizedBox(height: 24),

            _settingsCard(
              icon: Icons.language,
              title: loc.language,
              subtitle: "${loc.currently}: $_currentLangName",
              onTap: () => _showLanguagePicker(context),
            ),

            const SizedBox(height: 12),

            _settingsCard(
              icon: Icons.record_voice_over,
              title: loc.voice,
              subtitle: loc.assistantVoicePreferences,
              onTap: () => _showComingSoon(context),
            ),

            const SizedBox(height: 12),

            _settingsCard(
              icon: Icons.info_outline,
              title: loc.about,
              subtitle: loc.appVersionInfo,
              onTap: () => _showAboutDialog(context),
            ),

            const SizedBox(height: 32),

            _logoutButton(context, loc),

          ],
        ),
      ),
    );
  }

  // ---------------- LANGUAGE PICKER ----------------

  void _showLanguagePicker(BuildContext context) {

    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,

      builder: (context) => AlertDialog(
        title: Text(loc.selectLanguage),

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),

        content: Column(
          mainAxisSize: MainAxisSize.min,

          children: _languages.entries.map((entry) {

            return RadioListTile<String>(
              title: Text(entry.key),
              value: entry.key,
              groupValue: _currentLangName,
              activeColor: const Color(0xFF0E3D3D),

              onChanged: (value) {
                if (value != null) {
                  _updateLanguage(value, entry.value);
                  Navigator.pop(context);
                }
              },
            );

          }).toList(),
        ),
      ),
    );
  }

  // ---------------- SETTINGS CARD ----------------

  Widget _settingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,

      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),

        child: Row(
          children: [

            Container(
              width: 42,
              height: 42,

              decoration: BoxDecoration(
                color: const Color(0xFF0E3D3D).withOpacity(0.12),
                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                color: const Color(0xFF0E3D3D),
                size: 22,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- USER INFO ----------------

  Widget _userInfoSection(BuildContext context) {

    final loc = AppLocalizations.of(context)!;

    return FutureBuilder(
      future: Future.wait([
        AuthService.getUserName(),
        AuthService.getPhoneNumber(),
        AuthService.getUserId(),
      ]),

      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userName = snapshot.data?[0] as String? ?? loc.user;
        final phoneNumber = snapshot.data?[1] as String? ?? loc.notAvailable;

        return Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),

          child: Row(
            children: [

              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0x1A0E3D3D),

                child: Icon(
                  Icons.person,
                  color: Color(0xFF0E3D3D),
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    phoneNumber,
                    style: const TextStyle(
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- LOGOUT ----------------

  Widget _logoutButton(BuildContext context, AppLocalizations loc) {

    return SizedBox(
      width: double.infinity,

      child: ElevatedButton(

        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.red,

          padding: const EdgeInsets.symmetric(vertical: 16),

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.red.withOpacity(0.3)),
          ),
        ),

        onPressed: () => _performLogout(context),

        child: Text(
          loc.logout,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _performLogout(BuildContext context) async {

    await AuthService.logout();

    ApiService.currentUserId = null;

    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.phone,
            (route) => false,
      );
    }
  }

  void _showComingSoon(BuildContext context) {

    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.comingSoon),
        content: Text(loc.featureNextUpdate),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.ok),
          )
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {

    final loc = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'AgriAssist',
        applicationVersion: '1.0.0',
        children: [
          Text(loc.aiCompanion),
        ],
      ),
    );
  }
}