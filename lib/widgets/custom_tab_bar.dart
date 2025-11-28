import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CustomTabBarVariant {
  standard,
  pills,
  underline,
  segmented,
}

class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<CustomTab> tabs;
  final TabController? controller;
  final ValueChanged<int>? onTap;
  final CustomTabBarVariant variant;
  final Color? backgroundColor;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? indicatorColor;
  final EdgeInsets? padding;
  final bool isScrollable;
  final TabAlignment? tabAlignment;

  const CustomTabBar({
    super.key,
    required this.tabs,
    this.controller,
    this.onTap,
    this.variant = CustomTabBarVariant.standard,
    this.backgroundColor,
    this.selectedColor,
    this.unselectedColor,
    this.indicatorColor,
    this.padding,
    this.isScrollable = false,
    this.tabAlignment,
  });

  void _handleTap(int index) {
    HapticFeedback.lightImpact();
    if (onTap != null) {
      onTap!(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    switch (variant) {
      case CustomTabBarVariant.pills:
        return _buildPillsTabBar(context, theme, colorScheme);
      case CustomTabBarVariant.underline:
        return _buildUnderlineTabBar(context, theme, colorScheme);
      case CustomTabBarVariant.segmented:
        return _buildSegmentedTabBar(context, theme, colorScheme);
      case CustomTabBarVariant.standard:
      default:
        return _buildStandardTabBar(context, theme, colorScheme);
    }
  }

  Widget _buildStandardTabBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      color: backgroundColor ??
          theme.tabBarTheme.labelColor?.withValues(alpha: 0.05),
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0),
      child: TabBar(
        controller: controller,
        onTap: _handleTap,
        tabs: tabs
            .map((tab) => Tab(
                  text: tab.text,
                  icon: tab.icon != null ? Icon(tab.icon) : null,
                  iconMargin: tab.icon != null
                      ? const EdgeInsets.only(bottom: 4.0)
                      : EdgeInsets.zero,
                ))
            .toList(),
        isScrollable: isScrollable,
        tabAlignment: tabAlignment,
        labelColor: selectedColor ?? colorScheme.primary,
        unselectedLabelColor: unselectedColor ?? colorScheme.onSurfaceVariant,
        indicatorColor: indicatorColor ?? colorScheme.primary,
        indicatorWeight: 2.0,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: theme.tabBarTheme.labelStyle,
        unselectedLabelStyle: theme.tabBarTheme.unselectedLabelStyle,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  Widget _buildPillsTabBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      color: backgroundColor,
      padding: padding ?? const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isSelected = controller?.index == index;

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: GestureDetector(
                onTap: () {
                  _handleTap(index);
                  controller?.animateTo(index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (selectedColor ?? colorScheme.primary)
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: isSelected
                          ? (selectedColor ?? colorScheme.primary)
                          : colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tab.icon != null) ...[
                        Icon(
                          tab.icon,
                          size: 18,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : (unselectedColor ??
                                  colorScheme.onSurfaceVariant),
                        ),
                        if (tab.text != null) const SizedBox(width: 8.0),
                      ],
                      if (tab.text != null)
                        Text(
                          tab.text!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.w400,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : (unselectedColor ??
                                    colorScheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUnderlineTabBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      color: backgroundColor,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0),
      child: TabBar(
        controller: controller,
        onTap: _handleTap,
        tabs: tabs
            .map((tab) => Tab(
                  text: tab.text,
                  icon: tab.icon != null ? Icon(tab.icon) : null,
                  iconMargin: tab.icon != null
                      ? const EdgeInsets.only(bottom: 4.0)
                      : EdgeInsets.zero,
                ))
            .toList(),
        isScrollable: isScrollable,
        tabAlignment: tabAlignment,
        labelColor: selectedColor ?? colorScheme.primary,
        unselectedLabelColor: unselectedColor ?? colorScheme.onSurfaceVariant,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(
            color: indicatorColor ?? colorScheme.primary,
            width: 3.0,
          ),
          insets: const EdgeInsets.symmetric(horizontal: 16.0),
        ),
        labelStyle: theme.tabBarTheme.labelStyle?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.tabBarTheme.unselectedLabelStyle,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  Widget _buildSegmentedTabBar(
      BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Container(
      color: backgroundColor,
      padding: padding ?? const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: tabs.asMap().entries.map((entry) {
            final index = entry.key;
            final tab = entry.value;
            final isSelected = controller?.index == index;
            final isFirst = index == 0;
            final isLast = index == tabs.length - 1;

            return Expanded(
              child: GestureDetector(
                onTap: () {
                  _handleTap(index);
                  controller?.animateTo(index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (selectedColor ?? colorScheme.primary)
                        : Colors.transparent,
                    borderRadius: BorderRadius.horizontal(
                      left: isFirst ? const Radius.circular(11.0) : Radius.zero,
                      right: isLast ? const Radius.circular(11.0) : Radius.zero,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (tab.icon != null) ...[
                        Icon(
                          tab.icon,
                          size: 18,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : (unselectedColor ??
                                  colorScheme.onSurfaceVariant),
                        ),
                        if (tab.text != null) const SizedBox(width: 8.0),
                      ],
                      if (tab.text != null)
                        Text(
                          tab.text!,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w500 : FontWeight.w400,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : (unselectedColor ??
                                    colorScheme.onSurfaceVariant),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomTab {
  final String? text;
  final IconData? icon;

  const CustomTab({
    this.text,
    this.icon,
  }) : assert(text != null || icon != null,
            'Either text or icon must be provided');
}