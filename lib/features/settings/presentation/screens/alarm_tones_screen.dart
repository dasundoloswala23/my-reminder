import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/providers/alarm_tones_provider.dart';
import '../../../../core/services/alarm_tones_service.dart';

/// Selected default alarm tone storage key
const String _defaultToneKey = 'default_alarm_tone';

/// Default Alarm Tone Provider
final defaultAlarmToneProvider = StateProvider<String>((ref) {
  return 'default';
});

class AlarmTonesScreen extends ConsumerStatefulWidget {
  const AlarmTonesScreen({super.key});

  @override
  ConsumerState<AlarmTonesScreen> createState() => _AlarmTonesScreenState();
}

class _AlarmTonesScreenState extends ConsumerState<AlarmTonesScreen> {
  String _selectedToneId = 'default';
  bool _isPlaying = false;
  String? _playingToneId;

  @override
  void initState() {
    super.initState();
    _loadSelectedTone();
  }

  Future<void> _loadSelectedTone() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTone = prefs.getString(_defaultToneKey);
    if (savedTone != null && mounted) {
      setState(() {
        _selectedToneId = savedTone;
      });
    }
  }

  Future<void> _saveSelectedTone(String toneId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_defaultToneKey, toneId);
    ref.read(defaultAlarmToneProvider.notifier).state = toneId;
  }

  @override
  void dispose() {
    // Stop any playing preview
    ref.read(alarmTonesServiceProvider).stopPreview();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tonesAsync = ref.watch(availableTonesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarm Tones'),
        actions: [
          TextButton(
            onPressed: () {
              _saveSelectedTone(_selectedToneId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Default alarm tone saved')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
      body: tonesAsync.when(
        data: (tones) => _buildTonesList(tones),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading tones: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(availableTonesProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTonesList(List<AlarmTone> tones) {
    // Group tones by category
    final defaultTones = tones.where((t) => !t.isSystem).toList();
    final systemTones = tones.where((t) => t.isSystem).toList();

    return ListView(
      children: [
        // Default/Built-in Tones Section
        _buildSectionHeader('Built-in Tones'),
        ...defaultTones.map((tone) => _buildToneTile(tone)),

        if (systemTones.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSectionHeader('System Tones'),
          ...systemTones.map((tone) => _buildToneTile(tone)),
        ],

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildToneTile(AlarmTone tone) {
    final isSelected = _selectedToneId == tone.id;
    final isPlaying = _playingToneId == tone.id && _isPlaying;

    return ListTile(
      leading: Icon(
        isPlaying ? Icons.volume_up : Icons.music_note,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        tone.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      subtitle: tone.isSystem
          ? Text(
              'System tone',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Stop Preview Button
          IconButton(
            icon: Icon(
              isPlaying ? Icons.stop : Icons.play_arrow,
              color: isPlaying ? Colors.red : null,
            ),
            onPressed: () => _togglePreview(tone),
            tooltip: isPlaying ? 'Stop' : 'Preview',
          ),
          // Selection Check
          Icon(
            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
          ),
        ],
      ),
      onTap: () {
        setState(() {
          _selectedToneId = tone.id;
        });
      },
    );
  }

  Future<void> _togglePreview(AlarmTone tone) async {
    final service = ref.read(alarmTonesServiceProvider);

    if (_playingToneId == tone.id && _isPlaying) {
      // Stop playing
      await service.stopPreview();
      setState(() {
        _isPlaying = false;
        _playingToneId = null;
      });
    } else {
      // Stop any currently playing tone
      if (_isPlaying) {
        await service.stopPreview();
      }

      // Start playing this tone
      setState(() {
        _isPlaying = true;
        _playingToneId = tone.id;
      });

      await service.previewTone(tone);

      // Auto-stop after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _playingToneId == tone.id) {
          service.stopPreview();
          setState(() {
            _isPlaying = false;
            _playingToneId = null;
          });
        }
      });
    }
  }
}


