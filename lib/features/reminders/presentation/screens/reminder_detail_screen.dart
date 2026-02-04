import 'package:flutter/material.dart';

class ReminderDetailScreen extends StatefulWidget {
  final String reminderId;

  const ReminderDetailScreen({super.key, required this.reminderId});

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminder();
  }

  Future<void> _loadReminder() async {
    // TODO: Load reminder from Firestore
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              // TODO: Show delete confirmation
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            Text(
              'Sample Reminder Title',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),

            // Date & Time
            Row(
              children: [
                const Icon(Icons.schedule, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Today, 6:00 PM',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description
            if (true) // TODO: Check if description exists
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This is a sample description for the reminder.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                ],
              ),

            // Subtasks
            Text(
              'Subtasks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: [
                  CheckboxListTile(
                    value: false,
                    onChanged: (value) {
                      // TODO: Toggle subtask
                    },
                    title: const Text('Sample subtask 1'),
                  ),
                  CheckboxListTile(
                    value: true,
                    onChanged: (value) {
                      // TODO: Toggle subtask
                    },
                    title: const Text('Sample subtask 2'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Images
            Text(
              'Images',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('No images attached'),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            ElevatedButton(
              onPressed: () {
                // TODO: Mark as complete
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text('Mark as Complete'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
