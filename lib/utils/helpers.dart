// lib/utils/helpers.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';

class Helpers {
  // Format timestamp to date string
  static String formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    final dt = (timestamp as Timestamp).toDate();
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  // Format timestamp to date and time string
  static String formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    final dt = (timestamp as Timestamp).toDate();
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // Format seconds to MM:SS
  static String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // Format time spent to readable string
  static String formatTimeSpent(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '$minutes phút $secs giây';
  }

  // Get color based on score percentage
  static Color getScoreColor(double percentage) {
    if (percentage >= AppConstants.excellentScoreThreshold) {
      return AppConstants.successColor;
    }
    if (percentage >= AppConstants.goodScoreThreshold) {
      return AppConstants.warningColor;
    }
    return AppConstants.errorColor;
  }

  // Get timer color based on remaining time percentage
  static Color getTimerColor(double remainingPercentage) {
    if (remainingPercentage > AppConstants.timerGreenThreshold) {
      return AppConstants.successColor;
    }
    if (remainingPercentage > AppConstants.timerOrangeThreshold) {
      return AppConstants.warningColor;
    }
    return AppConstants.errorColor;
  }

  // Get option label (A, B, C, D, ...)
  static String getOptionLabel(int index) {
    return String.fromCharCode(65 + index);
  }

  // Calculate percentage
  static String getPercentageString(int score, int total) {
    if (total == 0) return '0';
    return ((score / total) * 100).toStringAsFixed(0);
  }

  // Show snackbar
  static void showSnackBar(BuildContext context, String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  // Show error dialog
  static void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog
  static Future<bool?> showConfirmDialog(
      BuildContext context, {
        required String title,
        required String content,
        String confirmText = 'OK',
        String cancelText = 'Hủy',
      }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}