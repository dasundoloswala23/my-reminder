import 'dart:io';
import 'package:flutter/services.dart';

/// Alarm Tone model
class AlarmTone {
  final String id;
  final String name;
  final String? uri;
  final bool isSystem;
  final bool isDefault;

  const AlarmTone({
    required this.id,
    required this.name,
    this.uri,
    this.isSystem = false,
    this.isDefault = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmTone && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Alarm Tones Service - fetches system and custom alarm tones
class AlarmTonesService {
  static const MethodChannel _channel = MethodChannel('com.myre.myreminder/alarm_tones');

  // Default built-in tones (available on all platforms)
  static const List<AlarmTone> defaultTones = [
    AlarmTone(
      id: 'default',
      name: 'Default',
      isDefault: true,
    ),
    AlarmTone(
      id: 'gentle',
      name: 'Gentle Wake',
    ),
    AlarmTone(
      id: 'classic',
      name: 'Classic Alarm',
    ),
    AlarmTone(
      id: 'digital',
      name: 'Digital Beep',
    ),
    AlarmTone(
      id: 'melody',
      name: 'Morning Melody',
    ),
    AlarmTone(
      id: 'nature',
      name: 'Nature Sounds',
    ),
    AlarmTone(
      id: 'urgent',
      name: 'Urgent Alert',
    ),
    AlarmTone(
      id: 'chime',
      name: 'Soft Chime',
    ),
  ];

  /// Get all available alarm tones (system + default)
  Future<List<AlarmTone>> getAvailableTones() async {
    final List<AlarmTone> tones = List.from(defaultTones);

    // Try to fetch system tones on Android
    if (Platform.isAndroid) {
      try {
        final systemTones = await _getAndroidSystemTones();
        tones.addAll(systemTones);
      } catch (e) {
        // Platform channel not implemented, use default tones only
        debugPrint('Could not fetch system tones: $e');
      }
    }

    // On iOS, system tones are accessed differently
    if (Platform.isIOS) {
      tones.addAll(_getiOSSystemTones());
    }

    return tones;
  }

  /// Get Android system alarm/ringtones
  Future<List<AlarmTone>> _getAndroidSystemTones() async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('getAlarmTones');
      if (result == null) return [];

      return result.map((item) {
        final map = Map<String, dynamic>.from(item);
        return AlarmTone(
          id: map['id'] as String,
          name: map['name'] as String,
          uri: map['uri'] as String?,
          isSystem: true,
        );
      }).toList();
    } catch (e) {
      return _getDefaultAndroidTones();
    }
  }

  /// Fallback Android tones when platform channel is unavailable
  List<AlarmTone> _getDefaultAndroidTones() {
    return const [
      AlarmTone(id: 'android_alarm', name: 'Android Alarm', isSystem: true),
      AlarmTone(id: 'android_ringtone', name: 'Android Ringtone', isSystem: true),
      AlarmTone(id: 'android_notification', name: 'Android Notification', isSystem: true),
    ];
  }

  /// Get iOS system tones
  List<AlarmTone> _getiOSSystemTones() {
    // iOS uses UNNotificationSound with system sound names
    return const [
      AlarmTone(id: 'ios_default', name: 'Default (iOS)', isSystem: true),
      AlarmTone(id: 'ios_tri-tone', name: 'Tri-tone', isSystem: true),
      AlarmTone(id: 'ios_chime', name: 'Chime', isSystem: true),
      AlarmTone(id: 'ios_glass', name: 'Glass', isSystem: true),
      AlarmTone(id: 'ios_horn', name: 'Horn', isSystem: true),
      AlarmTone(id: 'ios_bell', name: 'Bell', isSystem: true),
      AlarmTone(id: 'ios_electronic', name: 'Electronic', isSystem: true),
      AlarmTone(id: 'ios_anticipate', name: 'Anticipate', isSystem: true),
      AlarmTone(id: 'ios_bloom', name: 'Bloom', isSystem: true),
      AlarmTone(id: 'ios_calypso', name: 'Calypso', isSystem: true),
      AlarmTone(id: 'ios_chord', name: 'Chord', isSystem: true),
      AlarmTone(id: 'ios_circles', name: 'Circles', isSystem: true),
      AlarmTone(id: 'ios_complete', name: 'Complete', isSystem: true),
      AlarmTone(id: 'ios_hello', name: 'Hello', isSystem: true),
      AlarmTone(id: 'ios_input', name: 'Input', isSystem: true),
      AlarmTone(id: 'ios_keys', name: 'Keys', isSystem: true),
      AlarmTone(id: 'ios_note', name: 'Note', isSystem: true),
      AlarmTone(id: 'ios_popcorn', name: 'Popcorn', isSystem: true),
      AlarmTone(id: 'ios_pulse', name: 'Pulse', isSystem: true),
      AlarmTone(id: 'ios_synth', name: 'Synth', isSystem: true),
      AlarmTone(id: 'ios_alert', name: 'Alert', isSystem: true),
      AlarmTone(id: 'ios_ascending', name: 'Ascending', isSystem: true),
      AlarmTone(id: 'ios_bark', name: 'Bark', isSystem: true),
      AlarmTone(id: 'ios_beacon', name: 'Beacon', isSystem: true),
      AlarmTone(id: 'ios_bulletin', name: 'Bulletin', isSystem: true),
      AlarmTone(id: 'ios_illumination', name: 'Illumination', isSystem: true),
      AlarmTone(id: 'ios_presto', name: 'Presto', isSystem: true),
      AlarmTone(id: 'ios_radar', name: 'Radar', isSystem: true),
      AlarmTone(id: 'ios_radiate', name: 'Radiate', isSystem: true),
      AlarmTone(id: 'ios_ripples', name: 'Ripples', isSystem: true),
      AlarmTone(id: 'ios_sencha', name: 'Sencha', isSystem: true),
      AlarmTone(id: 'ios_signal', name: 'Signal', isSystem: true),
      AlarmTone(id: 'ios_silk', name: 'Silk', isSystem: true),
      AlarmTone(id: 'ios_slow_rise', name: 'Slow Rise', isSystem: true),
      AlarmTone(id: 'ios_stargaze', name: 'Stargaze', isSystem: true),
      AlarmTone(id: 'ios_summit', name: 'Summit', isSystem: true),
      AlarmTone(id: 'ios_twinkle', name: 'Twinkle', isSystem: true),
      AlarmTone(id: 'ios_uplift', name: 'Uplift', isSystem: true),
      AlarmTone(id: 'ios_waves', name: 'Waves', isSystem: true),
    ];
  }

  /// Play a preview of the selected tone
  Future<void> previewTone(AlarmTone tone) async {
    try {
      await _channel.invokeMethod('previewTone', {'id': tone.id, 'uri': tone.uri});
    } catch (e) {
      debugPrint('Could not preview tone: $e');
    }
  }

  /// Stop the preview
  Future<void> stopPreview() async {
    try {
      await _channel.invokeMethod('stopPreview');
    } catch (e) {
      debugPrint('Could not stop preview: $e');
    }
  }
}

void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}

