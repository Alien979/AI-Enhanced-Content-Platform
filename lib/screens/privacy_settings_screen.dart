import 'package:flutter/material.dart';
import '../services/user_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  _PrivacySettingsScreenState createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final UserService _userService = UserService();
  bool _profilePublic = true;
  bool _showReadingActivity = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    final settings = await _userService.getPrivacySettings();
    setState(() {
      _profilePublic = settings['profilePublic'] ?? true;
      _showReadingActivity = settings['showReadingActivity'] ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: const Color(0xFFE6B17E),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Public Profile'),
            subtitle: const Text('Allow others to view your profile'),
            value: _profilePublic,
            onChanged: (bool value) {
              setState(() {
                _profilePublic = value;
              });
              _userService.updatePrivacySetting('profilePublic', value);
            },
          ),
          SwitchListTile(
            title: const Text('Show Reading Activity'),
            subtitle: const Text('Share your reading progress and activity'),
            value: _showReadingActivity,
            onChanged: (bool value) {
              setState(() {
                _showReadingActivity = value;
              });
              _userService.updatePrivacySetting('showReadingActivity', value);
            },
          ),
        ],
      ),
    );
  }
}