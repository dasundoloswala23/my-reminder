import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/alarm_tones_service.dart';

/// Alarm Tones Service Provider
final alarmTonesServiceProvider = Provider<AlarmTonesService>((ref) {
  return AlarmTonesService();
});

/// Available Alarm Tones Provider
final availableTonesProvider = FutureProvider<List<AlarmTone>>((ref) async {
  final service = ref.watch(alarmTonesServiceProvider);
  return service.getAvailableTones();
});

/// Selected Tone Provider (for preview purposes)
final selectedToneProvider = StateProvider<AlarmTone?>((ref) => null);

