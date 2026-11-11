/// Keeps developer-only Guard routes out of normal beta builds.
///
/// The opt-in can only take effect in a debug build. Release and profile builds
/// ignore the define even if it is supplied explicitly.
bool developerGuardToolsEnabled({
  required bool isDebugMode,
  required bool optedIn,
}) => isDebugMode && optedIn;

const bool developerGuardToolsOptedIn = bool.fromEnvironment(
  'NEW_MAN_ENABLE_GUARD_DEVELOPER_TOOLS',
  defaultValue: false,
);
