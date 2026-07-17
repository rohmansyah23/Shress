import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final recentSelectedBusinessesProvider = StateNotifierProvider<RecentSelectedBusinessesNotifier, List<int>>((ref) {
  return RecentSelectedBusinessesNotifier();
});

class RecentSelectedBusinessesNotifier extends StateNotifier<List<int>> {
  RecentSelectedBusinessesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('recent_selected_businesses') ?? [];
      state = list.map(int.parse).toList();
    } catch (_) {
      // Fallback in case of error
    }
  }

  Future<void> addBusiness(int id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updated = List<int>.from(state)..remove(id)..insert(0, id);
      if (updated.length > 3) {
        updated.removeLast();
      }
      state = updated;
      await prefs.setStringList(
        'recent_selected_businesses',
        updated.map((i) => i.toString()).toList(),
      );
    } catch (_) {
      // Fallback
    }
  }
}
