import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Service to update home/lock screen widget data.
/// For test: displays "test-widgets" in the widget.
/// NOTE: iOS widgets are disabled (commented out) - Android only for now.
class WidgetService {
  static const String _widgetTextKey = 'widget_text';
  static const String _androidWidgetName = 'TicktaskWidgetProvider';
  // iOS widgets disabled - requires iOS 14.0+ deployment target
  // static const String _iOSWidgetName = 'TicktaskWidget';

  /// Saves widget text and triggers widget update.
  /// Use [text] or default "test-widgets" for testing.
  /// Currently Android-only (iOS widgets commented out).
  static Future<void> updateWidget({String text = 'test-widgets'}) async {
    // Skip iOS for now - requires iOS 14.0+ deployment target
    if (Platform.isIOS) {
      debugPrint('WidgetService: iOS widgets disabled (requires iOS 14.0+)');
      return;
    }

    try {
      await HomeWidget.saveWidgetData<String>(_widgetTextKey, text);
      // Android only - iOS commented out
      await HomeWidget.updateWidget(androidName: _androidWidgetName);
      // await HomeWidget.updateWidget(androidName: _androidWidgetName, iOSName: _iOSWidgetName);
      debugPrint('WidgetService: widget updated with "$text"');
    } catch (e) {
      debugPrint('WidgetService: failed to update widget $e');
    }
  }

  /// Call on app start so the widget shows current data (e.g. "test-widgets").
  /// Android-only (iOS widgets disabled).
  static Future<void> initWidget() async {
    await updateWidget(text: 'test-widgets');
  }
}
