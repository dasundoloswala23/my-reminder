import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/reminder_entity.dart';
import '../providers/reminder_provider.dart';
import '../../../../core/providers/alarm_tones_provider.dart';
import '../../../../core/services/alarm_tones_service.dart';

class AddEditReminderScreen extends ConsumerStatefulWidget {
  final String? reminderId;

  const AddEditReminderScreen({super.key, this.reminderId});

  @override
  ConsumerState<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends ConsumerState<AddEditReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subtaskController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _alarmSound = 'default';
  int? _earlyReminderMinutes;
  bool _isUrgent = false;
  bool _earlyReminderUrgent = false;
  List<String> _images = [];
  List<Subtask> _subtasks = [];
  bool _isLoading = false;
  ReminderEntity? _existingReminder;

  bool get _isEditMode => widget.reminderId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      _loadReminder();
    }
  }

  Future<void> _loadReminder() async {
    setState(() => _isLoading = true);
    final reminder = await ref.read(reminderByIdProvider(widget.reminderId!).future);
    if (reminder != null && mounted) {
      setState(() {
        _existingReminder = reminder;
        _titleController.text = reminder.title;
        _descriptionController.text = reminder.description ?? '';
        _selectedDate = reminder.scheduledAt;
        _selectedTime = TimeOfDay.fromDateTime(reminder.scheduledAt);
        _alarmSound = reminder.alarmSound;
        _earlyReminderMinutes = reminder.earlyReminderMinutes;
        _isUrgent = reminder.isUrgent;
        _images = List.from(reminder.images);
        _subtasks = List.from(reminder.subtasks);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final scheduledAt = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      if (_isEditMode && _existingReminder != null) {
        final updatedReminder = _existingReminder!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          scheduledAt: scheduledAt,
          earlyReminderMinutes: _earlyReminderMinutes,
          alarmSound: _alarmSound,
          isUrgent: _isUrgent,
          subtasks: _subtasks,
          images: _images,
          updatedAt: DateTime.now(),
        );
        await ref.read(reminderNotifierProvider.notifier).updateReminder(updatedReminder);
      } else {
        await ref.read(reminderNotifierProvider.notifier).createReminder(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          scheduledAt: scheduledAt,
          earlyReminderMinutes: _earlyReminderMinutes,
          alarmSound: _alarmSound,
          isUrgent: _isUrgent,
          subtasks: _subtasks,
        );
      }

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving reminder: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _subtasks.add(Subtask(
        id: const Uuid().v4(),
        text: text,
        isDone: false,
      ));
      _subtaskController.clear();
    });
  }

  void _removeSubtask(String id) {
    setState(() {
      _subtasks.removeWhere((s) => s.id == id);
    });
  }

  void _toggleSubtask(String id) {
    setState(() {
      _subtasks = _subtasks.map((s) {
        if (s.id == id) {
          return s.copyWith(isDone: !s.isDone);
        }
        return s;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Reminder' : 'Add Reminder'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveReminder,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _isLoading && _isEditMode && _existingReminder == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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

                    // Urgent Toggle
                    _buildUrgentToggle(),
                    const SizedBox(height: 24),

                    // Early Reminder
                    _buildEarlyReminderSection(),
                    const SizedBox(height: 24),

                    // Alarm Sound Selection
                    _buildAlarmSoundSection(),
                    const SizedBox(height: 24),

                    // Subtasks Section
                    _buildSubtasksSection(),
                    const SizedBox(height: 24),

                    // Images Section
                    _buildImagesSection(),
                    const SizedBox(height: 32),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveReminder,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(_isEditMode ? 'Update Reminder' : 'Create Reminder'),
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

  Widget _buildUrgentToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Urgent',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isUrgent
                          ? 'Will show as alarm with sound'
                          : 'Will show as notification',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
                Switch(
                  value: _isUrgent,
                  onChanged: (value) {
                    setState(() => _isUrgent = value);
                  },
                  activeTrackColor: Colors.red.withValues(alpha: 0.5),
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.red;
                    }
                    return null;
                  }),
                ),
              ],
            ),
            if (_isUrgent)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.alarm, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This reminder will trigger a full-screen alarm with sound',
                        style: TextStyle(color: Colors.red[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlarmSoundSection() {
    final tonesAsync = ref.watch(availableTonesProvider);

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
                  'Alarm Sound',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () => _previewSelectedTone(),
                  tooltip: 'Preview',
                ),
              ],
            ),
            const SizedBox(height: 8),
            tonesAsync.when(
              data: (tones) => _buildTonesDropdown(tones),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => _buildDefaultTonesDropdown(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTonesDropdown(List<AlarmTone> tones) {
    // Find current tone or use default
    final currentTone = tones.firstWhere(
      (t) => t.id == _alarmSound,
      orElse: () => tones.first,
    );

    return DropdownButton<String>(
      value: currentTone.id,
      isExpanded: true,
      items: tones.map((tone) {
        return DropdownMenuItem(
          value: tone.id,
          child: Row(
            children: [
              Icon(
                tone.isSystem ? Icons.phone_android : Icons.music_note,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tone.name),
                    if (tone.isSystem)
                      Text(
                        'System tone',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() => _alarmSound = value);
        }
      },
    );
  }

  Widget _buildDefaultTonesDropdown() {
    return DropdownButton<String>(
      value: _alarmSound,
      isExpanded: true,
      items: const [
        DropdownMenuItem(value: 'default', child: Text('Default')),
        DropdownMenuItem(value: 'gentle', child: Text('Gentle Wake')),
        DropdownMenuItem(value: 'classic', child: Text('Classic Alarm')),
        DropdownMenuItem(value: 'digital', child: Text('Digital Beep')),
        DropdownMenuItem(value: 'melody', child: Text('Morning Melody')),
        DropdownMenuItem(value: 'nature', child: Text('Nature Sounds')),
        DropdownMenuItem(value: 'urgent', child: Text('Urgent Alert')),
        DropdownMenuItem(value: 'chime', child: Text('Soft Chime')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() => _alarmSound = value);
        }
      },
    );
  }

  Future<void> _previewSelectedTone() async {
    final service = ref.read(alarmTonesServiceProvider);
    final tonesAsync = ref.read(availableTonesProvider);

    tonesAsync.whenData((tones) {
      final tone = tones.firstWhere(
        (t) => t.id == _alarmSound,
        orElse: () => tones.first,
      );
      service.previewTone(tone);

      // Stop after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        service.stopPreview();
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Playing preview...'),
        duration: Duration(seconds: 2),
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
            const SizedBox(height: 4),
            Text(
              'Get notified before the scheduled time',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButton<int?>(
              value: _earlyReminderMinutes,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: null, child: Text('None')),
                DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                DropdownMenuItem(value: 60, child: Text('1 hour before')),
                DropdownMenuItem(value: 120, child: Text('2 hours before')),
                DropdownMenuItem(value: 1440, child: Text('1 day before')),
              ],
              onChanged: (value) {
                setState(() => _earlyReminderMinutes = value);
              },
            ),
            if (_earlyReminderMinutes != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Urgent early reminder',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Switch(
                    value: _earlyReminderUrgent,
                    onChanged: (value) {
                      setState(() => _earlyReminderUrgent = value);
                    },
                    activeTrackColor: Colors.red.withValues(alpha: 0.5),
                    thumbColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.red;
                      }
                      return null;
                    }),
                  ),
                ],
              ),
            ],
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
            Text(
              'Subtasks',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subtaskController,
                    decoration: const InputDecoration(
                      hintText: 'Add a subtask',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addSubtask,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (_subtasks.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No subtasks added',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _subtasks.length,
                itemBuilder: (context, index) {
                  final subtask = _subtasks[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: IconButton(
                      icon: Icon(
                        subtask.isDone
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        color: subtask.isDone ? Colors.green : null,
                      ),
                      onPressed: () => _toggleSubtask(subtask.id),
                    ),
                    title: Text(
                      subtask.text,
                      style: TextStyle(
                        decoration: subtask.isDone ? TextDecoration.lineThrough : null,
                        color: subtask.isDone ? Colors.grey : null,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeSubtask(subtask.id),
                    ),
                  );
                },
              ),
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
                    // TODO: Pick images using image_picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Image picker coming soon')),
                    );
                  },
                ),
              ],
            ),
            if (_images.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No images attached',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _images
                    .map((url) => Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(url),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _images.remove(url);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
