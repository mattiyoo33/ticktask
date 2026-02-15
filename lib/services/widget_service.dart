import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Service to update home/lock screen widget data.
/// For test: displays "test-widgets" in the widget.
class WidgetService {
  static const String _widgetTextKey = 'widget_text';
  static const String _androidWidgetName = 'TicktaskWidgetProvider';
  static const String _iOSWidgetName = 'TicktaskWidget';

  /// Saves widget text and triggers widget update.
  /// Use [text] or default "test-widgets" for testing.
  static Future<void> updateWidget({String text = 'test-widgets'}) async {
    try {
      await HomeWidget.saveWidgetData<String>(_widgetTextKey, text);
      await HomeWidget.updateWidget(androidName: _androidWidgetName, iOSName: _iOSWidgetName);
      debugPrint('WidgetService: widget updated with "$text"');
    } catch (e) {
      debugPrint('WidgetService: failed to update widget $e');
    }
  }

  /// Call on app start so the widget shows current data (e.g. "test-widgets").
  static Future<void> initWidget() async {
    await updateWidget(text: 'test-widgets');
  }
}
