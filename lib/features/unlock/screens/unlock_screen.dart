// lib/features/unlock/screens/unlock_screen.dart
//
// Shown once on first launch of the Basboosa APK.
//
// FLOW:
//   1. Fetches the device's public IP (api.ipify.org)
//   2. Queries Firestore 'web_visits' for a matching unclaimed document
//      where is_gift_recipient == true  ← CRITICAL: prevents foreign-IP
//      docs (written by the site for analytics) from being claimed here.
//   3. Match found  → marks it claimed, saves unlocked=true to
//                     SharedPreferences, navigates forward. Never shown again.
//   4. No match     → shows a plain "not for you" wall. No way past it.
//   5. Network/timeout error → shows a retry button.
//
// BUG FIXES (vs previous version):
//   • Added `.where('is_gift_recipient', isEqualTo: true)` to the Firestore
//     query — without this, any web_visits doc (including analytics docs
//     written for foreign IPs) could be matched and incorrectly claimed.
//   • Added `.timeout(const Duration(seconds: 10))` to the Firestore call —
//     without this the app freezes indefinitely on slow / cold-start networks.
//   • Added `if (!mounted) return;` guards after every await so no setState
//     is called on a disposed widget.

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

const _kUnlocked     = 'app_unlocked';
const _ipProviderUrl = 'https://api.ipify.org?format=json';

/// Call once in main() before runApp to check cached unlock state.
Future<bool> isAppUnlocked() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kUnlocked) ?? false;
}

// ── State machine ─────────────────────────────────────────────

enum _UnlockState { checking, notAuthorised, error }

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {

  _UnlockState _state = _UnlockState.checking;

  @override
  void initState() {
    super.initState();
    _check();
  }

  // ── Core logic ────────────────────────────────────────────────────────────

  Future<void> _check() async {
    if (!mounted) return;
    setState(() => _state = _UnlockState.checking);

    try {
      // 1 — Get public IP
      final ip = await _getPublicIp();
      if (!mounted) return;

      if (ip == null) {
        setState(() => _state = _UnlockState.error);
        return;
      }

      // 2 — Query Firestore.
      //
      // FIX 1: filter by is_gift_recipient == true.
      //   The HTML gift page writes a web_visits document for EVERY visitor,
      //   including foreign IPs, with is_gift_recipient: false.  Without this
      //   filter any of those docs could match a future app install on the
      //   same IP and wrongly grant access — which is exactly the bug we saw.
      //
      // FIX 2: .timeout(10s) on the Firestore call.
      //   Without a timeout the app freezes on the loading screen when the
      //   network is slow or the Firestore socket hasn't warmed up yet.
      final db   = FirebaseFirestore.instance;
      final snap = await db
          .collection('web_visits')
          .where('ip',               isEqualTo: ip)
          .where('claimed',          isEqualTo: false)
          .where('is_gift_recipient', isEqualTo: true)   // ← FIX 1
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));          // ← FIX 2

      if (!mounted) return;                               // ← FIX 3

      if (snap.docs.isNotEmpty) {
        // 3 — Match: mark claimed so no other device can reuse this visit
        await snap.docs.first.reference.update({
          'claimed'    : true,
          'claimed_at' : FieldValue.serverTimestamp(),
        });

        if (!mounted) return;                             // ← FIX 3

        // 4 — Persist so this check never runs again
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kUnlocked, true);
        appUnlocked = true;

        if (!mounted) return;                             // ← FIX 3

        // Go to onboarding if not done, otherwise straight to app
        if (!appOnboardingComplete) {
          context.go('/onboarding');
        } else {
          context.go('/');
        }
      } else {
        // No matching IP with is_gift_recipient=true — not authorised
        setState(() => _state = _UnlockState.notAuthorised);
      }

    } on TimeoutException {
      // Firestore took too long — show retry instead of freezing
      if (!mounted) return;
      setState(() => _state = _UnlockState.error);
    } catch (e) {
      // Network / Firestore error — show retry
      if (!mounted) return;
      setState(() => _state = _UnlockState.error);
    }
  }

  Future<String?> _getPublicIp() async {
    try {
      final res = await http
          .get(Uri.parse(_ipProviderUrl))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['ip'] as String?;
      }
    } catch (_) {}
    return null;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: switch (_state) {
              _UnlockState.checking       => _CheckingView(),
              _UnlockState.notAuthorised  => _NotAuthorisedView(),
              _UnlockState.error          => _ErrorView(onRetry: _check),
            },
          ),
        ),
      ),
    );
  }
}

// ── Checking (spinner) ────────────────────────────────────────

class _CheckingView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 2),
        const SizedBox(height: 24),
        Text(
          'Checking your device…',
          style: AppTheme.caption,
        ),
      ],
    );
  }
}

// ── Not authorised (wall — no way through) ────────────────────

class _NotAuthorisedView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width : 80,
          height: 80,
          decoration: BoxDecoration(
            color : AppTheme.error.withAlpha(25),
            shape : BoxShape.circle,
            border: Border.all(
                color: AppTheme.error.withAlpha(76), width: 1.5),
          ),
          child: Icon(
            Icons.lock_outline_rounded,
            color: AppTheme.error,
            size : 36,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'This app is personal.',
          style: AppTheme.heading,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'It was made for someone specific.\nThis device is not authorised.',
          style    : AppTheme.caption.copyWith(height: 1.7),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Error (retry) ─────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width : 80,
          height: 80,
          decoration: BoxDecoration(
            color : AppTheme.primary.withAlpha(25),
            shape : BoxShape.circle,
          ),
          child: Icon(
            Icons.wifi_off_rounded,
            color: AppTheme.primary,
            size : 36,
          ),
        ),
        const SizedBox(height: 32),
        Text('No connection', style: AppTheme.heading),
        const SizedBox(height: 12),
        Text(
          'An internet connection is needed\nthe first time you open this app.',
          style    : AppTheme.caption.copyWith(height: 1.7),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primary,
              padding        : const EdgeInsets.symmetric(vertical: 16),
              shape          : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Try again',
              style: TextStyle(
                color     : Colors.white,
                fontSize  : 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}