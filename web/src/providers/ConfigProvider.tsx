import { Context, createContext, useContext, useEffect, useState } from 'react';
import { MantineColor } from '@mantine/core';
import { fetchNui } from '../utils/fetchNui';
import { useNuiEvent } from '../hooks/useNuiEvent';
import type { ThemeCustomConfig, PresetName, AnimationStyle, AnimationSpeed, ProgressBarPosition, TextUiOverridePosition } from '../theme/themeTypes';
import { PRESETS } from '../theme/presets';

export interface Config {
  // Mantine base
  primaryColor: MantineColor;
  primaryShade: 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9;
  darkMode: boolean;
  disableAnimations?: boolean;
  // Extended theme
  theme: ThemeCustomConfig;
}

interface ConfigCtxValue {
  config: Config;
  setConfig: (config: Config) => void;
  isLoading: boolean;
}

const DEFAULT_THEME: ThemeCustomConfig = { ...PRESETS.glass };

const DEFAULT_CONFIG: Config = {
  primaryColor: 'custom',
  primaryShade: 6,
  darkMode: false,
  disableAnimations: false,
  theme: DEFAULT_THEME,
};

const ConfigCtx = createContext<ConfigCtxValue | null>(null);

// Merge a partial raw object (from NUI) into a full ThemeCustomConfig safely
function mergeTheme(raw: Partial<ThemeCustomConfig> | undefined): ThemeCustomConfig {
  if (!raw) return { ...DEFAULT_THEME };
  const preset = raw.activePreset ? PRESETS[raw.activePreset as PresetName] : DEFAULT_THEME;
  return {
    ...preset,
    ...raw,
  };
}

const ConfigProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [config, setConfig] = useState<Config>(DEFAULT_CONFIG);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    const timeoutId = setTimeout(() => {
      if (isLoading) {
        console.warn('[ox_lib] Config loading timeout, using defaults');
        setIsLoading(false);
      }
    }, 5000);

    fetchNui<any>('getConfig')
      .then((data) => {
        clearTimeout(timeoutId);
        setConfig({
          primaryColor: data.primaryColor ?? 'red',
          primaryShade: data.primaryShade ?? 8,
          darkMode: data.darkMode ?? false,
          disableAnimations: data.disableAnimations ?? false,
          theme: mergeTheme(data.theme),
        });
        setIsLoading(false);
      })
      .catch((error) => {
        clearTimeout(timeoutId);
        console.warn('[ox_lib] Failed to load config, using defaults:', error);
        setIsLoading(false);
      });
  }, []);

  useNuiEvent<any>('refreshConfig', (data) => {
    setConfig({
      primaryColor: data.primaryColor ?? 'red',
      primaryShade: data.primaryShade ?? 8,
      darkMode: data.darkMode ?? false,
      disableAnimations: data.disableAnimations ?? false,
      theme: mergeTheme(data.theme),
    });
  });

  return (
    <ConfigCtx.Provider value={{ config, setConfig, isLoading }}>
      {children}
    </ConfigCtx.Provider>
  );
};

export default ConfigProvider;
export const useConfig = () => useContext<ConfigCtxValue>(ConfigCtx as Context<ConfigCtxValue>);

// Re-export types for convenience
export type { ThemeCustomConfig, PresetName, AnimationStyle, AnimationSpeed, ProgressBarPosition, TextUiOverridePosition };
