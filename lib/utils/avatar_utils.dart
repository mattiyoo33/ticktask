import '../presentation/profile_screen/widgets/avatar_selection_modal_widget.dart';

/// Avatar Utilities
/// 
/// Helper functions for working with user avatars.
/// Avatars are stored as IDs (e.g., "avatar_1", "avatar_2") and mapped to icons.
class AvatarUtils {
  /// Get the icon name for an avatar ID
  /// Returns the default avatar icon if the ID is invalid or null
  static String getAvatarIcon(String? avatarId) {
    return AvatarSelectionModalWidget.getIconName(avatarId);
  }

  /// Check if an avatar ID is valid
  static bool isValidAvatar(String? avatarId) {
    return AvatarSelectionModalWidget.isValidAvatarId(avatarId);
  }

  /// Get default avatar icon (used when no avatar is selected)
  static String getDefaultAvatarIcon() {
    return 'account_circle';
  }
}

