import 'package:flutter/material.dart';

class AIAssistantPanel extends StatefulWidget {
  const AIAssistantPanel({super.key});

  @override
  _AIAssistantPanelState createState() => _AIAssistantPanelState();
}

class _AIAssistantPanelState extends State<AIAssistantPanel> {
  final TextEditingController _promptController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('AI Writing Assistant'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _promptController,
            decoration: const InputDecoration(
              hintText: 'Enter your prompt here...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          const Text('Suggested prompts:'),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Continue the story'),
                selected: false,
                onSelected: (_) => _promptController.text = 'Continue the story',
              ),
              ChoiceChip(
                label: const Text('Describe the setting'),
                selected: false,
                onSelected: (_) => _promptController.text = 'Describe the current setting in detail',
              ),
              ChoiceChip(
                label: const Text('Character dialogue'),
                selected: false,
                onSelected: (_) => _promptController.text = 'Write a dialogue between the main characters',
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          child: const Text('Get Assistance'),
          onPressed: () => Navigator.of(context).pop(_promptController.text),
        ),
      ],
    );
  }
}