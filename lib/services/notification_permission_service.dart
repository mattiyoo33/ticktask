/// Notification Permission Service
/// 
/// This service handles notification permission requests and status checks
/// using the permission_handler package.
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class NotificationPermissionService {
  // Check if notification permission is granted
  Future<bool> isPermissionGranted() async {
    try {
      final status = await ph.Permission.notification.status;
      debugPrint('🔔 Permission status check: $status (granted: ${status.isGranted})');
      return status.isGranted || status.isLimited;
    } catch (e, stackTrace) {
      debugPrint('❌ Error checking notification permission: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // Check if notification permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied() async {
    try {
      final status = await ph.Permission.notification.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      debugPrint('Error checking if permission is permanently denied: $e');
      return false;
    }
  }

  // Request notification permission
  Future<bool> requestPermission() async {
    try {
      debugPrint('🔔 Requesting notification permission...');
      
      // Check current status first
      final currentStatus = await ph.Permission.notification.status;
      debugPrint('📊 Current permission status: $currentStatus');
      
      // If already granted, return true
      if (currentStatus.isGranted) {
        debugPrint('✅ Notification permission already granted');
        return true;
      }
      
      // Request permission
      final status = await ph.Permission.notification.request();
      debugPrint('📊 Permission request result: $status');
      
      if (status.isGranted) {
        debugPrint('✅ Notification permission granted');
        return true;
      } else if (status.isDenied) {
        debugPrint('❌ Notification permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        debugPrint('❌ Notification permission permanently denied');
        return false;
      } else if (status.isRestricted) {
        debugPrint('⚠️ Notification permission is restricted');
        return false;
      } else if (status.isLimited) {
        debugPrint('⚠️ Notification permission is limited');
        return true; // Limited is still usable
      } else {
        debugPrint('⚠️ Notification permission status: $status');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error requesting notification permission: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  // Open app settings (for when permission is permanently denied)
  Future<bool> openAppSettings() async {
    try {
      return await ph.openAppSettings();
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }

  // Get permission status description
  Future<String> getPermissionStatusDescription() async {
    try {
      final status = await ph.Permission.notification.status;
      
      if (status.isGranted) {
        return 'Notifications are enabled';
      } else if (status.isDenied) {
        return 'Notifications are disabled. Tap to enable.';
      } else if (status.isPermanentlyDenied) {
        return 'Notifications are permanently disabled. Please enable in Settings.';
      } else {
        return 'Notification permission status unknown';
      }
    } catch (e) {
      return 'Unable to check notification permission';
    }
  }
}

