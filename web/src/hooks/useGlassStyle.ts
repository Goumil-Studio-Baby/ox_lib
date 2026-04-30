import { useConfig } from '../providers/ConfigProvider';

export type GlassStyle = {
  mainBackground: string;
  lightBackground: string;
  border: string;
  shadow: string;
  textPrimary: string;
  textSecondary: string;
  borderRadius: string;
  isDarkMode: boolean;
};

export const useGlassStyle = (): GlassStyle => {
  const { config } = useConfig();
  const t = config.theme;

  const shadow = t.shadowEnabled
    ? '0 12px 40px rgba(0,0,0,0.6), 0 6px 20px rgba(0,0,0,0.4), inset 0 1px 0 rgba(255,255,255,0.08)'
    : 'none';

  return {
    mainBackground: t.bgPrimary,
    lightBackground: t.bgSecondary,
    border: t.borderColor,
    shadow,
    textPrimary: t.textPrimary,
    textSecondary: t.textSecondary,
    borderRadius: `${t.borderRadius}px`,
    isDarkMode: config.darkMode,
  };
};
