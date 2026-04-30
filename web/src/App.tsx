import Notifications from './features/notifications/NotificationWrapper';
import CircleProgressbar from './features/progress/CircleProgressbar';
import Progressbar from './features/progress/Progressbar';
import TextUI from './features/textui/TextUI';
import InputDialog from './features/dialog/InputDialog';
import ContextMenu from './features/menu/context/ContextMenu';
import { useNuiEvent } from './hooks/useNuiEvent';
import { setClipboard } from './utils/setClipboard';
import { fetchNui } from './utils/fetchNui';
import AlertDialog from './features/dialog/AlertDialog';
import ListMenu from './features/menu/list';
import Dev from './features/dev';
import { isEnvBrowser } from './utils/misc';
import SkillCheck from './features/skillcheck';
import RadialMenu from './features/menu/radial';
import { theme } from './theme';
import { MantineProvider, MantineThemeOverride } from '@mantine/core';
import { useConfig } from './providers/ConfigProvider';
import { GameRender } from './components/GameRender';
import { useMemo, useEffect } from 'react';
import { generateColorPalette } from './utils/colorUtils';

// When dark mode is OFF, lighten bg colors so toggling dark mode has a visible effect
function adaptToDarkMode(rgba: string, isDark: boolean): string {
  if (isDark) return rgba;
  const match = rgba.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/);
  if (!match) return rgba;
  const r = Math.min(255, parseInt(match[1]) + 28);
  const g = Math.min(255, parseInt(match[2]) + 28);
  const b = Math.min(255, parseInt(match[3]) + 28);
  const a = match[4] ? Math.max(0.30, parseFloat(match[4]) - 0.16) : 0.82;
  return `rgba(${r}, ${g}, ${b}, ${a.toFixed(2)})`;
}

function useThemeCssVariables() {
  const { config } = useConfig();
  const t = config.theme;
  const isDark = config.darkMode;

  useEffect(() => {
    const root = document.documentElement;
    const animDurations: Record<string, string> = { fast: '120ms', normal: '220ms', slow: '380ms' };
    const dur = animDurations[t.animationSpeed] ?? '220ms';

    root.style.setProperty('--ox-bg-primary',    adaptToDarkMode(t.bgPrimary, isDark));
    root.style.setProperty('--ox-bg-secondary',  adaptToDarkMode(t.bgSecondary, isDark));
    root.style.setProperty('--ox-bg-input',      adaptToDarkMode(t.bgInput, isDark));
    root.style.setProperty('--ox-border',        adaptToDarkMode(t.borderColor, isDark));
    root.style.setProperty('--ox-radius',        `${t.borderRadius}px`);
    root.style.setProperty('--ox-text-primary',  t.textPrimary);
    root.style.setProperty('--ox-text-secondary',t.textSecondary);
    root.style.setProperty('--ox-item-bg',       adaptToDarkMode(t.itemBg    || 'rgba(0,0,0,0.32)', isDark));
    root.style.setProperty('--ox-item-hover',    adaptToDarkMode(t.itemBgHover || 'rgba(255,255,255,0.10)', isDark));
    root.style.setProperty('--ox-primary',       t.primaryColor || '#ec4899');
    root.style.setProperty('--ox-notif-bg',      t.notifBg       || 'var(--ox-bg-primary)');
    root.style.setProperty('--ox-notif-border',  t.notifBorder   || 'var(--ox-border)');
    root.style.setProperty('--ox-notif-title',   t.notifTextTitle || 'var(--ox-text-primary)');
    root.style.setProperty('--ox-notif-body',    t.notifTextBody  || 'var(--ox-text-secondary)');
    root.style.setProperty('--ox-progress-color',t.progressColor || '');
    root.style.setProperty('--ox-skillcheck-color', t.skillCheckColor || '#ffffff');
    root.style.setProperty('--ox-anim-speed',    dur);
    root.style.setProperty('--ox-anim-style',    t.animationStyle);

    // Legacy aliases
    root.style.setProperty('--glass-bg',         adaptToDarkMode(t.bgPrimary, isDark));
    root.style.setProperty('--glass-bg-light',   adaptToDarkMode(t.bgSecondary, isDark));
    root.style.setProperty('--glass-border',     adaptToDarkMode(t.borderColor, isDark));
    root.style.setProperty('--glass-radius',     `${t.borderRadius}px`);
    root.style.setProperty('--anim-normal',      dur);
  }, [t, isDark]);
}

const AppInner: React.FC = () => {
  useThemeCssVariables();

  const { config, isLoading } = useConfig();

  useNuiEvent('setClipboard', (data: string) => {
    setClipboard(data);
  });

  fetchNui('init');

  const customPalette = useMemo(
    () => generateColorPalette(config.theme?.primaryColor || '#ec4899'),
    [config.theme?.primaryColor]
  );

  const mergedTheme = useMemo((): MantineThemeOverride => ({
    ...theme,
    colors: {
      ...theme.colors,
      custom: customPalette,
    },
    primaryColor: 'custom',
    primaryShade: 6,
    colorScheme: config.darkMode ? 'dark' : 'light',
  }), [customPalette, config.darkMode]);

  if (isLoading) {
    return (
      <MantineProvider withNormalizeCSS withGlobalStyles theme={mergedTheme}>
        <GameRender />
        {isEnvBrowser() && <Dev />}
      </MantineProvider>
    );
  }

  return (
    <MantineProvider withNormalizeCSS withGlobalStyles theme={mergedTheme}>
      <GameRender />
      <Progressbar />
      <CircleProgressbar />
      <Notifications />
      <TextUI />
      <InputDialog />
      <AlertDialog />
      <ContextMenu />
      <ListMenu />
      <RadialMenu />
      <SkillCheck />
      {isEnvBrowser() && <Dev />}
    </MantineProvider>
  );
};

const App: React.FC = () => <AppInner />;

export default App;
