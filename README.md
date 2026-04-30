# ox_lib — Goumil Studio Fork

A fork of [overextended/ox_lib](https://github.com/overextended/ox_lib) with a custom theme system, UI redesign, and Lua extensions for FiveM servers.

> **License:** This project is distributed under [GPL V3](./LICENSE) as required by the original project.
> All original code and copyright belong to [Overextended](https://github.com/overextended) and contributors.
> See [NOTICE.md](./NOTICE.md) for additional legal notices.

---

## What's different from the original

This fork adds a fully configurable theme system controllable in-game, without touching server config files.

### Web UI (`web/src/`)

| File | Change |
|---|---|
| `theme/themeTypes.ts` | **New** — TypeScript types for the full theme config |
| `theme/presets.ts` | **New** — 4 built-in presets (Glass, Solid, Neon, Compact) |
| `hooks/useGlassStyle.ts` | **New** — CSS variable-based style hook |
| `utils/colorUtils.ts` | **New** — Dynamic color palette generator from hex |
| `providers/ConfigProvider.tsx` | Extended with `config.theme` object |
| `App.tsx` | Injects `--ox-*` CSS variables at runtime, dark mode adaptive coloring |
| `components/Glass.tsx` | Uses CSS variables instead of hardcoded styles |
| `features/notifications/NotificationWrapper.tsx` | Position & color overrides from config |
| `features/textui/TextUI.tsx` | Position override from config |
| `features/progress/Progressbar.tsx` | Position & color override from config |
| `features/progress/CircleProgressbar.tsx` | Position & color override from config |
| `features/skillcheck/index.tsx` | Color override from config |
| `features/menu/context/ContextMenu.tsx` | CSS variables for background/border |
| `features/menu/context/components/ContextButton.tsx` | CSS variables for item colors |
| `features/menu/list/ListItem.tsx` | CSS variables for text/hover colors |
| `features/dialog/AlertDialog.tsx` | CSS variables |
| `features/dialog/InputDialog.tsx` | CSS variables |

### Lua

| File | Change |
|---|---|
| `resource/client.lua` | Reads theme from KVP, exposes `customPrimaryHex` & `primaryShade` |
| `resource/settings.lua` | `/ox_lib` command opens a 7-section context menu for live theme editing |
| `imports/selector/shared.lua` | **New** — `OxSelector` class with weighted random selection |
| `locales/fr.json` | French translations updated |

---

## Theme presets

| Preset | Accent | Style |
|---|---|---|
| Glass | Violet `#7c3aed` | Semi-transparent dark |
| Solid | Blue `#3b82f6` | Opaque dark with colored border |
| Neon | Purple `#a855f7` | Near-black with neon border |
| Compact | Sky `#0ea5e9` | Steel dark, flat no-blur |

---

## How to rebuild the UI

The full TypeScript/React source is included in `web/src/` as required by GPL V3.

```bash
cd web
npm install
npm run build
```

Then restart the resource in-game:
```
restart ox_lib
```

---

## In-game configuration

Use `/ox_lib` in-game to open the settings menu:
- Switch theme preset
- Pick a custom primary color (hex)
- Toggle dark/light mode
- Adjust background opacity
- Set notification/progress/textui position
- Per-component color overrides
- Reset to defaults

---

## Original project

- Repository: https://github.com/overextended/ox_lib
- Documentation: https://coxdocs.dev/ox_lib
- npm package: https://www.npmjs.com/package/@communityox/ox_lib

## Lua Language Server

- Install [Lua Language Server](https://marketplace.visualstudio.com/items?itemName=sumneko.lua)
- Install [CfxLua IntelliSense](https://marketplace.visualstudio.com/items?itemName=communityox.cfxlua-vscode-cox)
