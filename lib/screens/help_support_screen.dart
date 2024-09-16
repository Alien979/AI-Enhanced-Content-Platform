import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: const Color(0xFFE6B17E),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('User Guide'),
            onTap: () {
              // Navigate to user guide screen or launch a web page
            },
          ),
          ListTile(
            leading: const Icon(Icons.question_answer),
            title: const Text('FAQs'),
            onTap: () {
              // Navigate to FAQs screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Contact Support'),
            onTap: () {
              _launchEmail();
            },
          ),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Report a Bug'),
            onTap: () {
              // Navigate to bug report screen
            },
          ),
        ],
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@example.com',
      queryParameters: {
        'subject': 'Support Request',
      },
    );
    if (await canLaunch(emailLaunchUri.toString())) {
      await launch(emailLaunchUri.toString());
    } else {
      throw 'Could not launch email client';
    }
  }
}