import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  _NotificationSettingsScreenState createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Email Notifications'),
            value: _emailNotifications,
            onChanged: (bool value) {
              setState(() {
                _emailNotifications = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Push Notifications'),
            value: _pushNotifications,
            onChanged: (bool value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
        ],
      ),
    );
  }
}