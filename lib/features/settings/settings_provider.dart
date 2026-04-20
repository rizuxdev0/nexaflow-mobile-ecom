import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/auth_storage.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final bool notificationsEnabled;
  SettingsState({required this.notificationsEnabled});

  SettingsState copyWith({bool? notificationsEnabled}) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState(notificationsEnabled: true)) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await AuthStorage.getNotificationSettings();
    state = state.copyWith(notificationsEnabled: enabled);
  }

  Future<void> toggleNotifications(bool enabled) async {
    await AuthStorage.saveNotificationSettings(enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }
}
