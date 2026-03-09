// lib/core/providers/user_name_provider.dart
//
// Stores the Mint user's chosen display name.
//
// FLOW:
//   • On first launch after name entry: setName() is called.
//     - Extracts the first word (first name only).
//     - Persists to SharedPreferences so it survives restarts.
//     - Fires-and-forgets a Firestore write to 'mint_users' (curiosity log).
//   • On every subsequent launch: build() loads the name from SharedPreferences.
//   • Dashboard reads the name via ref.watch(userNameProvider).
//   • Settings calls setName() again when the user edits their name.
//
// NOTE: Only used by the Mint flavor. Basboosa reads its name from AppStrings.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userNameProvider =
AsyncNotifierProvider<UserNameNotifier, String>(UserNameNotifier.new);

class UserNameNotifier extends AsyncNotifier<String> {
  static const _kName = 'mint_user_name';

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kName) ?? '';
  }

  /// Save a new name. Only the first word is stored/shown as the greeting name.
  /// The full input is logged to Firestore for curiosity.
  Future<void> setName(String rawInput) async {
    final trimmed   = rawInput.trim();
    final firstName = trimmed.split(RegExp(r'\s+')).first;

    // Persist locally first — never fails even without network.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kName, firstName);
    state = AsyncData(firstName);

    // Fire-and-forget Firestore log — we only want to know who's using it.
    _logToFirestore(trimmed, firstName);
  }

  Future<void> _logToFirestore(String fullName, String firstName) async {
    try {
      await FirebaseFirestore.instance.collection('mint_users').add({
        'full_name'  : fullName,
        'first_name' : firstName,
        'timestamp'  : FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[UserNameNotifier] Firestore log error: $e');
    }
  }
}