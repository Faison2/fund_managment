import 'dart:convert';
import 'package:flutter/foundation.dart';

final Set<String> _sensitiveKeys = {
  'password', 'Password', 'PASSWORD',
  'APIUsername', 'APIPassword',
  'token', 'Token', 'access_token', 'refresh_token',
  'email', 'Email', 'EMAIL',
  'phone', 'Phone', 'phoneNumber', 'Mobile', 'mobile',
  'nida', 'NIDA',
  'cdsNumber', 'CDSNumber', 'CDS_Number',
  'accountNumber', 'AccountNo', 'account_no',
  'bankAccountNo', 'bank_account_no',
  'id', 'ID', 'IdentificationNo',
  'dob', 'DOB', 'DateOfBirth',
  'secret', 'Secret', 'SECRET',
  'authorization', 'Authorization',
};

final List<RegExp> _sensitivePatterns = [
  RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b'), // email
  RegExp(r'\b(?:\+?\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\b'), // phone
  RegExp(r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'), // credit card
];

String _redact(String input) {
  String result = input;
  for (final pattern in _sensitivePatterns) {
    result = result.replaceAllMapped(pattern, (_) => '***REDACTED***');
  }
  return result;
}

Map _redactMap(dynamic item) {
  if (item is Map) {
    return item.map((key, value) {
      final isSensitive = _sensitiveKeys.any((k) => key.toString().contains(k));
      return MapEntry(key, isSensitive ? '***REDACTED***' : _redactValue(value));
    });
  }
  return item is Map ? item : {};
}

dynamic _redactValue(dynamic value) {
  if (value is Map) return _redactMap(value);
  if (value is List) return value.map(_redactValue).toList();
  if (value is String) return _redact(value);
  return value;
}

class AppLogger {
  AppLogger._();

  static void debug(String message, [dynamic payload]) {
    if (kReleaseMode) return;
    final safePayload = payload != null ? _redactValue(payload) : null;
    final safeMsg = _redact(message);
    if (safePayload != null) {
      debugPrint('🐛 $safeMsg — $safePayload');
    } else {
      debugPrint('🐛 $safeMsg');
    }
  }

  static void info(String message, [dynamic payload]) {
    if (kReleaseMode) return;
    final safePayload = payload != null ? _redactValue(payload) : null;
    final safeMsg = _redact(message);
    if (safePayload != null) {
      debugPrint('📘 $safeMsg — $safePayload');
    } else {
      debugPrint('📘 $safeMsg');
    }
  }

  static void warn(String message, [dynamic payload]) {
    if (kReleaseMode) return;
    final safePayload = payload != null ? _redactValue(payload) : null;
    final safeMsg = _redact(message);
    if (safePayload != null) {
      debugPrint('⚠️ $safeMsg — $safePayload');
    } else {
      debugPrint('⚠️ $safeMsg');
    }
  }

  static void error(String message, [dynamic payload]) {
    if (kReleaseMode) return;
    final safePayload = payload != null ? _redactValue(payload) : null;
    final safeMsg = _redact(message);
    if (safePayload != null) {
      debugPrint('❌ $safeMsg — $safePayload');
    } else {
      debugPrint('❌ $safeMsg');
    }
  }
}
