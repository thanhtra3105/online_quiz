// lib/services/location_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;

class UserLocationResult {
  final bool success;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final String status; // 'allowed', 'denied', 'timeout', 'unsupported'
  final String? errorMessage;

  UserLocationResult({
    required this.success,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.status,
    this.errorMessage,
  });
}

class LocationService {
  /// Lấy vị trí GPS hiện tại từ trình duyệt
  static Future<UserLocationResult> getCurrentLocation({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!kIsWeb) {
      return UserLocationResult(
        success: false,
        status: 'unsupported',
        errorMessage: 'Chỉ hỗ trợ trên nền tảng Web.',
      );
    }

    try {
      final geolocation = html.window.navigator.geolocation;

      final completer = Completer<UserLocationResult>();

      geolocation.getCurrentPosition(
        enableHighAccuracy: true,
        timeout: timeout,
        maximumAge: const Duration(seconds: 30),
      ).then((pos) {
        final coords = pos.coords;
        if (coords != null && coords.latitude != null && coords.longitude != null) {
          completer.complete(
            UserLocationResult(
              success: true,
              latitude: coords.latitude!.toDouble(),
              longitude: coords.longitude!.toDouble(),
              accuracy: coords.accuracy?.toDouble(),
              status: 'allowed',
            ),
          );
        } else {
          completer.complete(
            UserLocationResult(
              success: false,
              status: 'error',
              errorMessage: 'Không nhận được tọa độ từ thiết bị.',
            ),
          );
        }
      }).catchError((err) {
        String status = 'denied';
        String msg = 'Bạn chưa cấp quyền vị trí hoặc thiết bị chưa bật định vị GPS.';
        final errStr = err.toString().toLowerCase();
        if (errStr.contains('timeout')) {
          status = 'timeout';
          msg = 'Hết thời gian chờ lấy vị trí GPS.';
        }
        completer.complete(
          UserLocationResult(
            success: false,
            status: status,
            errorMessage: msg,
          ),
        );
      });

      return await completer.future.timeout(
        timeout + const Duration(seconds: 2),
        onTimeout: () => UserLocationResult(
          success: false,
          status: 'timeout',
          errorMessage: 'Quá thời gian lấy vị trí GPS (Timeout).',
        ),
      );
    } catch (e) {
      return UserLocationResult(
        success: false,
        status: 'error',
        errorMessage: 'Lỗi khi yêu cầu vị trí: $e',
      );
    }
  }
}
