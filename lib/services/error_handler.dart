import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Centralized error handling service
class ErrorHandler {
  /// Format Firebase Auth errors to user-friendly messages
  static String getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'The user account does not exist';
      case 'wrong-password':
        return 'The password is incorrect';
      case 'invalid-email':
        return 'The email address is invalid';
      case 'user-disabled':
        return 'This user account has been disabled';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later';
      case 'network-request-failed':
        return 'Network connection failed. Please check your internet connection';
      case 'email-already-in-use':
        return 'This email address is already in use';
      case 'weak-password':
        return 'The password is too weak. Please use a stronger password';
      case 'invalid-credential':
        return 'Invalid credentials provided';
      default:
        if (error.message?.contains('reCAPTCHA') == true ||
            error.message?.contains('www.googleapis.com') == true) {
          return 'Security verification failed. Please try again later or use a different network';
        }
        return 'An authentication error occurred: ${error.message}';
    }
  }

  /// Format general exceptions to user-friendly messages
  static String getGeneralErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getAuthErrorMessage(error);
    }

    final errorString = error.toString();

    if (errorString.contains('SocketException')) {
      return 'No internet connection. Please check your network';
    } else if (errorString.contains('TimeoutException')) {
      return 'Request timeout. The server is taking too long to respond';
    } else if (errorString.contains('FormatException')) {
      return 'Invalid data format received from server';
    }

    return 'An unexpected error occurred: ${error.toString()}';
  }

  /// Show error snackbar
  static void showErrorSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: duration,
      ),
    );
  }

  /// Show success snackbar
  static void showSuccessSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: duration,
      ),
    );
  }

  /// Show info snackbar
  static void showInfoSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: duration,
      ),
    );
  }

  /// Log error for debugging
  static void logError(String tag, dynamic error, {StackTrace? stackTrace}) {
    // Logging disabled - use debugPrint if needed during development
  }
}
