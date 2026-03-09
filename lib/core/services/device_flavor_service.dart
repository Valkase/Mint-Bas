// lib/core/services/device_flavor_service.dart
//
// Determines whether this device is Basboosa's phone.
//
// FLOW (runs once per install, then cached permanently):
//   1. Read AndroidID from device_info_plus
//   2. Query Firestore 'basboosa_devices' for android_id match
//      → Found: it's Basboosa (direct method, most reliable)
//   3. If not found → fetch this device's public IP
//   4. Query Firestore 'web_visits' for a matching IP
//      → Found: it's Basboosa (IP method, gift website triggered this)
//        Mark that web_visit doc as 'claimed' so it's never reused
//   5. If nothing matches → it's Mint, log to 'mint_installs'
//   6. On any error → default to mint, do NOT cache (retry next launch)
//
// FIREBASE SETUP:
//   The 'web_visits' collection is written by the gift website.
//   Each document has:  ip (string), timestamp, user_agent
//   This service adds:  claimed (bool), claimed_at (timestamp)

import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../flavor/app_flavor.dart';

class DeviceFlavorService {
  DeviceFlavorService._();
  static final DeviceFlavorService instance = DeviceFlavorService._();

  static const _kFlavor     = 'app_flavor';
  static const _kConfirmed  = 'flavor_confirmed';
  static const _kOnboarding = 'onboarding_complete';

  // IP provider — returns JSON: { "ip": "x.x.x.x" }
  static const _ipProviderUrl = 'https://api.ipify.org?format=json';

  // ── Public API ─────────────────────────────────────────────────────────────

  Future<AppFlavor> detectFlavor() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Already confirmed on a previous install — use the cache.
      if (prefs.getBool(_kConfirmed) == true) {
        final cached = prefs.getString(_kFlavor);
        return cached == 'basboosa'
            ? AppFlavor.basboosa
            : AppFlavor.mint;
      }

      // ── Method 1: Android ID ───────────────────────────────────────────────
      final deviceId = await _getAndroidId();
      debugPrint('[DeviceFlavorService] Android ID: $deviceId');

      final byId = await _queryByAndroidId(deviceId);
      if (byId != null) {
        await _persist(prefs, byId);
        return byId;
      }

      // ── Method 2: IP address (gift website) ────────────────────────────────
      final ip = await _getPublicIp();
      if (ip != null) {
        debugPrint('[DeviceFlavorService] Public IP: $ip');
        final byIp = await _queryByIp(ip);
        if (byIp != null) {
          await _persist(prefs, byIp);
          return byIp;
        }
      }

      // ── Nothing matched → Mint ─────────────────────────────────────────────
      await _logMintInstall(deviceId);
      await _persist(prefs, AppFlavor.mint);
      return AppFlavor.mint;

    } catch (e) {
      // Network / Firestore error — default to mint but don't cache.
      debugPrint('[DeviceFlavorService] detectFlavor error: $e');
      return AppFlavor.mint;
    }
  }

  Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboarding) == true;
  }

  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboarding, true);
  }

  // ── Method 1: Android ID ───────────────────────────────────────────────────

  Future<String> _getAndroidId() async {
    if (!Platform.isAndroid) return 'non-android';
    final info = await DeviceInfoPlugin().androidInfo;
    return info.id;
  }

  Future<AppFlavor?> _queryByAndroidId(String androidId) async {
    final snap = await FirebaseFirestore.instance
        .collection('basboosa_devices')
        .where('android_id', isEqualTo: androidId)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      debugPrint('[DeviceFlavorService] → Basboosa via Android ID 🎉');
      return AppFlavor.basboosa;
    }
    return null;
  }

  // ── Method 2: Public IP ────────────────────────────────────────────────────

  Future<String?> _getPublicIp() async {
    try {
      final response = await http
          .get(Uri.parse(_ipProviderUrl))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['ip'] as String?;
      }
    } catch (e) {
      debugPrint('[DeviceFlavorService] IP fetch error: $e');
    }
    return null;
  }

  Future<AppFlavor?> _queryByIp(String ip) async {
    final db = FirebaseFirestore.instance;

    final snap = await db
        .collection('web_visits')
        .where('ip', isEqualTo: ip)
        .where('claimed', isEqualTo: false)
        .limit(1)
        .get();                          // ← orderBy('timestamp') removed

    if (snap.docs.isNotEmpty) {
      debugPrint('[DeviceFlavorService] → Basboosa via IP match 🎉');
      await snap.docs.first.reference.update({
        'claimed'    : true,
        'claimed_at' : FieldValue.serverTimestamp(),
      });
      return AppFlavor.basboosa;
    }
    return null;
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _logMintInstall(String androidId) async {
    try {
      await FirebaseFirestore.instance.collection('mint_installs').add({
        'android_id' : androidId,
        'first_seen' : FieldValue.serverTimestamp(),
      });
      debugPrint('[DeviceFlavorService] → Mint flavor');
    } catch (e) {
      debugPrint('[DeviceFlavorService] mint log error: $e');
    }
  }

  Future<void> _persist(SharedPreferences prefs, AppFlavor flavor) async {
    await prefs.setString(
      _kFlavor,
      flavor == AppFlavor.basboosa ? 'basboosa' : 'mint',
    );
    await prefs.setBool(_kConfirmed, true);
  }
}