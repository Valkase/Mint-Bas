// lib/core/services/device_flavor_service.dart
//
// Determines whether this device is Basboosa's phone.
//
// FLOW (runs once per install, then cached permanently):
//   1. Read AndroidID from device_info_plus
//   2. Query Firestore 'basboosa_devices' collection for a doc with
//      field android_id == <this device's id>
//   3. If found  → cache AppFlavor.basboosa in SharedPreferences
//      If not found → cache AppFlavor.mint AND write to 'mint_installs'
//      On any error → default to mint, do NOT cache (retry next launch)
//
// FIREBASE SETUP (do this once manually in the Firebase console):
//   Collection: basboosa_devices
//   Document:   (auto-id)
//   Fields:     android_id  (string)  ← set this to her Android ID
//
//   You can find her Android ID by running the app on her phone once
//   and looking at the debug console — it will be printed there.

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../flavor/app_flavor.dart';

class DeviceFlavorService {
  DeviceFlavorService._();
  static final DeviceFlavorService instance = DeviceFlavorService._();

  static const _kFlavor    = 'app_flavor';
  static const _kConfirmed = 'flavor_confirmed';
  static const _kOnboarding = 'onboarding_complete';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Returns the flavor for this device.
  /// Uses cached value if already confirmed, otherwise hits Firestore.
  Future<AppFlavor> detectFlavor() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // If we've already confirmed the flavor, use the cache.
      if (prefs.getBool(_kConfirmed) == true) {
        final cached = prefs.getString(_kFlavor);
        return cached == 'basboosa'
            ? AppFlavor.basboosa
            : AppFlavor.mint;
      }

      // Get the Android ID.
      final deviceId = await _getAndroidId();
      debugPrint('[DeviceFlavorService] Android ID: $deviceId');

      // Query Firestore.
      final flavor = await _queryFirestore(deviceId);

      // Persist the result so we never hit Firestore again.
      await prefs.setString(_kFlavor, flavor == AppFlavor.basboosa ? 'basboosa' : 'mint');
      await prefs.setBool(_kConfirmed, true);

      return flavor;
    } catch (e) {
      // Network/Firestore error — default to mint but don't cache,
      // so we retry on the next launch.
      debugPrint('[DeviceFlavorService] detectFlavor error: $e');
      return AppFlavor.mint;
    }
  }

  /// Whether the user has already completed onboarding.
  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboarding) == true;
  }

  /// Call this when the user finishes onboarding.
  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboarding, true);
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<String> _getAndroidId() async {
    if (!Platform.isAndroid) return 'non-android';
    final info = await DeviceInfoPlugin().androidInfo;
    return info.id; // unique per device + signing key
  }

  Future<AppFlavor> _queryFirestore(String androidId) async {
    final db = FirebaseFirestore.instance;

    // Check if this device is Basboosa's.
    final snap = await db
        .collection('basboosa_devices')
        .where('android_id', isEqualTo: androidId)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      debugPrint('[DeviceFlavorService] → Basboosa flavor 🎉');
      return AppFlavor.basboosa;
    }

    // Not Basboosa — record the install for analytics.
    await db.collection('mint_installs').add({
      'android_id' : androidId,
      'first_seen' : FieldValue.serverTimestamp(),
    });

    debugPrint('[DeviceFlavorService] → Mint flavor');
    return AppFlavor.mint;
  }
}