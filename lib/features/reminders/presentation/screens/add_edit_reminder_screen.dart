import 'package:flutter/material.dart';

class AddEditReminderScreen extends StatefulWidget {
  final String? reminderId; // null for add, id for edit

  const AddEditReminderScreen({super.key, this.reminderId});

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _alarmSound = 'default';
  int? _earlyReminderMinutes;
  List<String> _images = [];
  List<Map<String, dynamic>> _subtasks = [];

  bool get _isEditMode => widget.reminderId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadReminder();
    }
  }

  Future<void> _loadReminder() async {
    // TODO: Load reminder from Firestore
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Save to Firestore and schedule notifications

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Reminder' : 'Add Reminder'),
        actions: [
          TextButton(
            onPressed: _saveReminder,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Enter reminder title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Add details (optional)',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Date & Time Selection
              _buildDateTimeSection(),
              const SizedBox(height: 24),

              // Alarm Sound Selection
              _buildAlarmSoundSection(),
              const SizedBox(height: 24),

              // Early Reminder
              _buildEarlyReminderSection(),
              const SizedBox(height: 24),

              // Subtasks Section
              _buildSubtasksSection(),
              const SizedBox(height: 24),

              // Images Section
              _buildImagesSection(),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveReminder,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child:
                      Text(_isEditMode ? 'Update Reminder' : 'Create Reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _selectedDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _selectedTime,
                      );
                      if (time != null) {
                        setState(() => _selectedTime = time);
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(_selectedTime.format(context)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmSoundSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Alarm Sound',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _alarmSound,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'default', child: Text('Default')),
                DropdownMenuItem(value: 'bell', child: Text('Bell')),
                DropdownMenuItem(value: 'chime', child: Text('Chime')),
                DropdownMenuItem(value: 'radar', child: Text('Radar')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _alarmSound = value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarlyReminderSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Early Reminder',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButton<int?>(
              value: _earlyReminderMinutes,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                DropdownMenuItem(value: 60, child: Text('1 hour before')),
              ],
              onChanged: (value) {
                setState(() => _earlyReminderMinutes = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtasksSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtasks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    // TODO: Add subtask
                  },
                ),
              ],
            ),
            if (_subtasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No subtasks added'),
                ),
              )
            else
              ..._subtasks.map((task) => ListTile(
                    leading: const Icon(Icons.check_box_outline_blank),
                    title: Text(task['text'] ?? ''),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        // TODO: Remove subtask
                      },
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Images',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate),
                  onPressed: () {
                    // TODO: Pick images
                  },
                ),
              ],
            ),
            if (_images.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No images attached'),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _images
                    .map((url) => Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[300],
                          ),
                          // TODO: Show actual images
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
