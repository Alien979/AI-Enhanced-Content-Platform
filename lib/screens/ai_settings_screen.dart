// lib/screens/ai_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AISettingsScreen extends StatefulWidget {
  @override
  _AISettingsScreenState createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  double _temperature = 0.7;
  int _maxTokens = 150;
  String _writingStyle = 'Neutral';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _temperature = prefs.getDouble('ai_temperature') ?? 0.7;
      _maxTokens = prefs.getInt('ai_max_tokens') ?? 150;
      _writingStyle = prefs.getString('ai_writing_style') ?? 'Neutral';
    });
  }

  _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('ai_temperature', _temperature);
    await prefs.setInt('ai_max_tokens', _maxTokens);
    await prefs.setString('ai_writing_style', _writingStyle);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Assistant Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Creativity (Temperature)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Slider(
              value: _temperature,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: _temperature.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _temperature = value;
                });
              },
            ),
            SizedBox(height: 20),
            Text('Max Tokens', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Slider(
              value: _maxTokens.toDouble(),
              min: 50,
              max: 500,
              divisions: 45,
              label: _maxTokens.toString(),
              onChanged: (value) {
                setState(() {
                  _maxTokens = value.round();
                });
              },
            ),
            SizedBox(height: 20),
            Text('Writing Style', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _writingStyle,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _writingStyle = newValue;
                  });
                }
              },
              items: <String>['Neutral', 'Formal', 'Casual', 'Poetic', 'Technical']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            SizedBox(height: 40),
            Center(
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}