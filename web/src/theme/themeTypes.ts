export type AnimationStyle = 'slide' | 'fade' | 'scale' | 'bounce' | 'none';
export type AnimationSpeed = 'fast' | 'normal' | 'slow';
export type PresetName = 'glass' | 'solid' | 'neon' | 'compact';
export type ProgressBarPosition = 'bottom' | 'top' | 'center';
export type CircleProgressPosition = 'middle' | 'bottom';
export type TextUiOverridePosition = 'right-center' | 'left-center' | 'top-center' | 'bottom-center' | 'center' | 'auto';

export interface ThemeCustomConfig {
  activePreset: PresetName;

  // Accent / button color (hex, e.g. '#ec4899')
  primaryColor: string;

  // Menu & dialog backgrounds
  bgPrimary: string;      // rgba
  bgSecondary: string;    // rgba
  bgInput: string;        // rgba
  borderColor: string;    // rgba
  borderRadius: number;
  shadowEnabled: boolean;

  // Menu text & item colors
  textPrimary: string;
  textSecondary: string;
  itemBg: string;         // menu item normal background
  itemBgHover: string;    // menu item hover background

  // Notification-specific overrides ('' = inherit from menu values)
  notifBg: string;
  notifBorder: string;
  notifTextTitle: string;
  notifTextBody: string;

  // Component accent colors
  progressColor: string;         // '' = use primaryColor
  circleProgressColor: string;   // '' = use primaryColor
  skillCheckColor: string;

  // Animation (used by ScaleFade, not exposed in settings UI)
  animationStyle: AnimationStyle;
  animationSpeed: AnimationSpeed;

  // Position overrides
  notificationPosition: string;
  progressPosition: ProgressBarPosition;
  circleProgressPosition: CircleProgressPosition;
  textUiPosition: TextUiOverridePosition;
}
