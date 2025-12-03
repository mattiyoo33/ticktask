import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CustomAppBarVariant {
  standard,
  centered,
  minimal,
  search,
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final CustomAppBarVariant variant;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final Widget? flexibleSpace;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final TextStyle? titleTextStyle;
  final IconThemeData? iconTheme;
  final SystemUiOverlayStyle? systemOverlayStyle;

  const CustomAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.variant = CustomAppBarVariant.standard,
    this.showBackButton = false,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.flexibleSpace,
    this.bottom,
    this.centerTitle = false,
    this.titleTextStyle,
    this.iconTheme,
    this.systemOverlayStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Provide haptic feedback for interactions
    void handleBackPress() {
      HapticFeedback.lightImpact();
      if (onBackPressed != null) {
        onBackPressed!();
      } else {
        Navigator.of(context).pop();
      }
    }

    Widget? buildLeading() {
      if (leading != null) return leading;

      if (showBackButton ||
          (automaticallyImplyLeading && Navigator.of(context).canPop())) {
        return IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
          ),
          onPressed: handleBackPress,
          tooltip: 'Back',
        );
      }

      return null;
    }

    List<Widget>? buildActions() {
      if (actions == null) return null;

      return actions!.map((action) {
        if (action is IconButton) {
          return Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: action,
          );
        }
        return action;
      }).toList();
    }

    Widget? buildTitle() {
      if (title == null) return null;

      switch (variant) {
        case CustomAppBarVariant.standard:
        case CustomAppBarVariant.search:
          return Text(
            title!,
            style: titleTextStyle ?? theme.appBarTheme.titleTextStyle,
            overflow: TextOverflow.ellipsis,
          );
        case CustomAppBarVariant.centered:
          return Text(
            title!,
            style: titleTextStyle ??
                theme.appBarTheme.titleTextStyle?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          );
        case CustomAppBarVariant.minimal:
          return Text(
            title!,
            style: titleTextStyle ??
                theme.appBarTheme.titleTextStyle?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
            overflow: TextOverflow.ellipsis,
          );
      }
    }

    bool shouldCenterTitle() {
      switch (variant) {
        case CustomAppBarVariant.centered:
          return true;
        case CustomAppBarVariant.standard:
        case CustomAppBarVariant.minimal:
        case CustomAppBarVariant.search:
          return centerTitle;
      }
    }

    double getElevation() {
      switch (variant) {
        case CustomAppBarVariant.minimal:
          return 0;
        case CustomAppBarVariant.standard:
        case CustomAppBarVariant.centered:
        case CustomAppBarVariant.search:
          return elevation ?? theme.appBarTheme.elevation ?? 0;
      }
    }

    return AppBar(
      title: buildTitle(),
      leading: buildLeading(),
      actions: buildActions(),
      automaticallyImplyLeading: false,
      backgroundColor: backgroundColor ?? theme.appBarTheme.backgroundColor,
      foregroundColor: foregroundColor ?? theme.appBarTheme.foregroundColor,
      elevation: getElevation(),
      scrolledUnderElevation: variant == CustomAppBarVariant.minimal ? 0 : 2,
      centerTitle: shouldCenterTitle(),
      flexibleSpace: flexibleSpace,
      bottom: bottom,
      iconTheme: iconTheme ?? theme.appBarTheme.iconTheme,
      systemOverlayStyle: systemOverlayStyle ??
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: theme.brightness == Brightness.light
                ? Brightness.dark
                : Brightness.light,
            statusBarBrightness: theme.brightness,
          ),
      surfaceTintColor: Colors.transparent,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );
}
