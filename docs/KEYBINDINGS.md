# Keybindings Documentation

> **Status**: Draft / Work in Progress
>
> **Purpose**: Unify keybinding configurations across all tools to create a cohesive, muscle-memory-friendly development environment that can be managed entirely through Nix.

---

## Table of Contents

1. [Overview & Philosophy](#overview--philosophy)
2. [Current State Analysis](#current-state-analysis)
3. [Hyprland (Wayland Compositor)](#hyprland-wayland-compositor)
4. [Ghostty (Terminal Emulator)](#ghostty-terminal-emulator)
5. [Zellij (Terminal Multiplexer)](#zellij-terminal-multiplexer)
6. [Helix (Text Editor)](#helix-text-editor)
7. [Browser (Firefox/Chrome with Vimium)](#browser-firefoxchrome-with-vimium)
8. [Git Aliases](#git-aliases)
9. [Hardware-Specific Configurations](#hardware-specific-configurations)
   - [Ultimate Hacking Keyboard (UHK)](#ultimate-hacking-keyboard-uhk)
   - [Framework Laptop](#framework-laptop)
   - [Portable Programmable Keyboard (Future)](#portable-programmable-keyboard-future)
   - [MacBook](#macbook)
   - [Hardware Translation Table](#hardware-translation-table)
10. [Keybinding Consistency Matrix](#keybinding-consistency-matrix)
11. [Nix Implementation Guide](#nix-implementation-guide)
12. [Migration Path](#migration-path)
13. [Quick Reference Cards](#quick-reference-cards)

---

## Overview & Philosophy

### Core Philosophy: Mouse-Free Workflow

**The primary goal of this keybinding configuration is to eliminate mouse usage entirely.** Every operation should be accessible via keyboard, optimized for speed, ergonomics, and muscle memory.

**Mouse Avoidance Strategy**
- **Caps Lock Mouse Mode**: Caps Lock key activates mouse mode for rare situations requiring mouse interaction
  - `f` = left click
  - `s` = right click
  - Navigation via home row (details TBD)
- **Benefits**: Reduced hand movement, eliminated context switching, RSI prevention, increased speed

### Design Principles

**Modifier Key Strategy**
- `Super`: Hyprland window manager modifier (configured in Hyprland as `$mod = SUPER`)
  - **Physical key**: Alt key (swapped to Super via `altwin:swap_alt_win`)
  - On UHK: Fn2 + key sends Alt, which system interprets as Super due to swap
  - On Framework: Pressing Alt sends Super due to swap
  - On MacBook: Option key behavior (TBD)
- `Ctrl`: Application-level operations
- `Shift`: Modifications to base keybindings (e.g., reverse direction, new window vs current)

**Why the swap?**
- Alt key position is more ergonomic for frequent window management
- By swapping Alt↔Win, we get Super in an accessible position
- UHK Fn2 layer sends Alt codes, which become Super after swap

**Consistency Patterns**
- Navigation: `j k i l` (Vim-style, home row focused) across all tools
  - `j` = left, `k` = down, `i` = up, `l` = right
  - Stays on home row for maximum ergonomics
- Common actions: `q` = quit, `r` = reload, `w` = write/save
- Mnemonics: Actions should be memorable and consistent
- Modal interactions: Submaps/modes for complex operations (resize, layout, etc.)

**Ergonomic Principles**
1. **Home Row Optimization**: Minimize finger travel from home row position
2. **Thumb Utilization**: Use UHK Fn2 thumb key for frequent modifiers
3. **Symmetrical Usage**: Balance left/right hand workload
4. **Layer Coherence**: Related functions grouped on same layer
5. **Reduced Strain**: Avoid awkward Ctrl+Shift+Alt combinations

**Goals**
1. **Zero mouse usage** for all development workflows
2. Minimize cognitive load when switching between tools
3. Reduce RSI through ergonomic key placement and programmable keyboard customization
4. Enable declarative configuration through Nix for reproducibility
5. **Maximize portability**: OS-level configuration allows any programmable keyboard to work identically

**Portability-First Strategy**

This configuration prioritizes **OS-level keybindings** over hardware-specific configurations to ensure seamless portability across different programmable keyboards:

- **Current**: UHK (desktop/workstation)
- **Current**: Framework laptop built-in keyboard (travel/portable)
- **Future**: Portable programmable keyboard (40-60% layout for travel)
  - Examples: Corne, Planck, Preonic, or other QMK/ZMK firmware keyboards

**Why OS-level configuration?**
1. **Hardware Independence**: Any programmable keyboard can be configured to send the same keycodes (Alt+JKIL)
2. **Single Source of Truth**: OS handles the Alt→Super swap via `altwin:swap_alt_win`
3. **No Hyprland Changes**: Hyprland config stays identical regardless of keyboard
4. **Easy Migration**: New keyboard? Just configure it to send Alt codes, everything else works
5. **Nix Management**: OS-level settings are declaratively managed in your NixOS config

---

## Current State Analysis

### What's Currently Configured

**Hyprland**
- Location: `/home/ncrmro/nixos-config/archive/home.nix:109-116`
- Status: ⚠️ Partial - Mouse bindings only
- Configured modifier: `$mod = SUPER`
- Physical key: Alt (swapped to Super via `altwin:swap_alt_win`)
- Known keybindings:
  - `Super+J` (physical Alt+J) = focus left pane
  - `Super+K` (physical Alt+K) = focus down pane
  - `Super+I` (physical Alt+I) = focus up pane
  - `Super+L` (physical Alt+L) = focus right pane
- Current config (legacy):
  ```nix
  "$mod" = "SUPER";
  bindm = [
    "$mod, mouse:272, movewindow"
    "$mod, mouse:273, resizewindow"
    "$mod ALT, mouse:272, resizewindow"
  ];
  ```

**Helix**
- Location: `/home/ncrmro/nixos-config/home-manager/common/features/cli/helix.nix:43`
- Status: ⚠️ Minimal
- Current config:
  ```nix
  keys.normal = { ret = ":write"; };
  ```

**Git Aliases**
- Location: `/home/ncrmro/nixos-config/home-manager/common/features/cli/git.nix`
- Status: ✅ Complete
- Aliases: `b`, `p`, `co`, `c`, `ci`, `a`, `st`

**Input Configuration**
- Location: `/home/ncrmro/nixos-config/home-manager/common/features/desktop/default.nix:22-30`
- Status: ✅ Complete
- Config: Caps→Ctrl, Alt↔Win swap, mouse sensitivity

### What's Using Defaults

- **Zellij**: Using default keybindings (Ctrl+G leader key)
- **Ghostty**: No custom keybindings configured
- **Browser**: No Vimium configuration managed in Nix

### What's Missing

- Complete Hyprland keyboard bindings
- Ghostty terminal keybindings
- Zellij customization for workflow
- Enhanced Helix keybindings
- Browser extension configuration
- UHK layer programming
- Hardware-specific optimizations

### Reference Materials

- **Hyprland App Groups**: Spike at `/home/ncrmro/nixos-config/spikes/1757895719_hyprland_app_groups/`
  - Contains workspace layout suggestions
  - App group launch patterns
  - Suggested keybindings for group management

---

## Hyprland (Wayland Compositor)

### Current Configuration
<!-- Reference: archive/home.nix, spikes/1757895719_hyprland_app_groups/ -->

### Proposed Keybindings

#### Window Management
<!-- Navigation, focus, move, resize, float, fullscreen, close -->

#### Workspace Navigation
<!-- 1-10, special workspaces, move windows between workspaces -->

#### Application Launching
<!-- Terminal, browser, app groups -->

#### Submaps/Modes
<!-- Resize mode, layout mode, move mode -->

#### Integration with App Groups
<!-- Launch development, communication, media, notes, monitoring groups -->

---

## Ghostty (Terminal Emulator)

### Documentation Reference
- Official docs: https://ghostty.org/docs/config/keybind
- Action reference: https://ghostty.org/docs/config/keybind/reference

### Current Configuration
<!-- None - using defaults -->

### Proposed Keybindings

#### Tab/Pane Management
<!-- Create, close, navigate tabs/splits -->

#### Font Size Controls
<!-- Increase, decrease, reset -->

#### Quick Terminal Toggle
<!-- Global keybinding for dropdown terminal -->

#### Clipboard Operations
<!-- Copy, paste, selection modes -->

#### Configuration Syntax
```nix
# Example:
# keybind = trigger=action
# keybind = global:cmd+backquote=toggle_quick_terminal
# keybind = ctrl+shift+t=new_tab
```

---

## Zellij (Terminal Multiplexer)

### Documentation Reference
- Official docs: https://zellij.dev/documentation/keybindings.html
- Binding guide: https://zellij.dev/documentation/keybindings-binding.html

### Current Configuration
- Location: `/home/ncrmro/nixos-config/home-manager/common/features/cli/default.nix:107-114`
- Using defaults with Tokyo Night theme

### Proposed Keybindings

#### Session Management
<!-- Attach, detach, sessions -->

#### Pane Navigation
<!-- Create, close, navigate, resize -->

#### Layout Management
<!-- Switch layouts, custom layouts -->

#### Mode Switching
<!-- Normal, locked, pane, tab, resize, search modes -->

#### Integration with Ghostty
<!-- How Zellij runs inside Ghostty -->

---

## Helix (Text Editor)

### Current Configuration
- Location: `/home/ncrmro/nixos-config/home-manager/common/features/cli/helix.nix:43`
- Current: `Return` → `:write`

### Proposed Keybindings

#### Normal Mode Enhancements
<!-- Custom normal mode bindings -->

#### LSP Operations
<!-- Go-to-definition, hover, rename, code actions -->

#### File Navigation
<!-- File picker, buffer switcher, symbol search -->

#### Multi-Cursor Workflows
<!-- Selection expansion, multiple cursors -->

#### Integration Workflows
<!-- Terminal spawning, git operations -->

---

## Browser (Firefox/Chrome with Vimium)

### Extension Reference
- Vimium: https://github.com/philc/vimium
- Vimium C: https://github.com/gdh1995/vimium-c

### Current Configuration
<!-- None - manual installation only -->

### Proposed Keybindings

#### Navigation
<!-- j/k scroll, gg/G top/bottom, f/F link hints -->

#### Tab Management
<!-- t create, x close, J/K navigate tabs -->

#### History Navigation
<!-- H/L back/forward -->

#### Search
<!-- / search, n/N next/prev -->

#### Custom Mappings
<!-- Consistency with other tools -->

### Nix Configuration Strategy
<!-- Export Vimium config, version control, apply across machines -->

---

## Git Aliases

### Current Configuration
- Location: `/home/ncrmro/nixos-config/home-manager/common/features/cli/git.nix`

```nix
alias = {
  b = "branch";
  p = "pull";
  co = "checkout";
  c = "commit";
  ci = "commit -a";
  a = "add";
  st = "status -sb";
};
```

### Proposed Additions
<!-- Additional workflow aliases, integration patterns -->

---

## Hardware-Specific Configurations

### Ultimate Hacking Keyboard (UHK)

#### Current Status
- Enabled in: `/home/ncrmro/nixos-config/hosts/ncrmro-laptop/default.nix:71`
- Enabled in: `/home/ncrmro/nixos-config/hosts/workstation/default.nix:54`
- Config: `hardware.keyboard.uhk.enable = true;`

#### Layer Architecture

The UHK uses a layer system where each layer binds actions to keys. Layers are activated via dedicated keys, with Fn2 positioned under the right thumb for ergonomic access.

**Current Layer Configuration:**

##### Fn2 Layer (Hyprland Navigation)
**Position**: Right thumb key
**Purpose**: Ergonomic access to Hyprland window management

**Current Fn2 Mappings** (selectively configured, not blanket Alt modifier):
- `Fn2 + J` → sends `Alt+J` → system interprets as `Super+J` (due to `altwin:swap_alt_win`) → Hyprland: focus left pane
- `Fn2 + K` → sends `Alt+K` → system interprets as `Super+K` → Hyprland: focus down pane
- `Fn2 + I` → sends `Alt+I` → system interprets as `Super+I` → Hyprland: focus up pane
- `Fn2 + L` → sends `Alt+L` → system interprets as `Super+L` → Hyprland: focus right pane

**Note**: These are manually configured key mappings in UHK Agent, not a global "Fn2 = Alt modifier" setting.

**Why send Alt if Hyprland uses Super?**
- The `kb_options = "altwin:swap_alt_win"` setting swaps Alt and Super at the X11/Wayland input level
- UHK sends Alt codes → system swaps them to Super → Hyprland receives Super
- This allows using the ergonomically positioned Alt key for window management

##### Mod Layer (Arrow Keys)
**Purpose**: Vim-style arrow key navigation

**Expected Mappings**:
- `Mod + J` → Left Arrow
- `Mod + K` → Down Arrow
- `Mod + I` → Up Arrow
- `Mod + L` → Right Arrow

This creates consistency between Fn2 (Hyprland navigation) and Mod (arrow keys), both using the same home row keys (JKIL).

##### Base Layer
- Standard QWERTY layout
- Possible home row mods (TBD)

##### Fn Layer
- Function keys (F1-F12)
- System controls

##### Fn3-Fn5 Layers
- Reserved for future expansion
- Potential uses:
  - Fn3: Development tools (IDE shortcuts, terminal operations)
  - Fn4: Media controls and system operations
  - Fn5: Application-specific bindings

#### Ergonomic Design Benefits

1. **Thumb Access**: Fn2 under right thumb eliminates pinky strain from holding Alt
2. **Home Row Navigation**: J, K, I, L keeps fingers on home row
3. **Consistent Patterns**: Same keys (JKIL) across Mod and Fn2 layers
4. **Reduced Movement**: All navigation reachable without leaving home position

#### UHK Agent Configuration

Configuration is managed through UHK Agent software (https://ultimatehackingkeyboard.github.io/agent/).

**Mapping Process**:
1. Open UHK Agent
2. Select Fn2 layer
3. Click key to configure (J, K, I, or L)
4. Set secondary role to: "Keystroke" → Select modifiers (Alt) → Select key
5. Save to keyboard

#### NixOS Integration

NixOS enables UHK support through hardware module:

```nix
hardware.keyboard.uhk.enable = true;
```

This ensures proper USB permissions and udev rules for UHK Agent access. Keymaps are stored in UHK hardware memory and persist across systems.

---

### Framework Laptop

#### Current Configuration
- Host: `/home/ncrmro/nixos-config/hosts/ncrmro-laptop/default.nix`
- Monitor: BOE 0x0BCA (built-in display)
- Keyboard: UHK support enabled (for when external UHK is connected)
- Fingerprint reader: Enabled

#### Input Configuration
```nix
kb_options = "compose:caps,ctrl:nocaps,altwin:swap_alt_win";
```
- Caps Lock → Ctrl
- Caps Lock disabled (important for Caps Lock mouse mode)
- Alt ↔ Win swapped

#### Portable Keybinding Strategy

Since the Framework laptop lacks the UHK's ergonomic Fn2 thumb key, the same Hyprland operations are accessed via direct Alt key usage (which is swapped to Super):

**Hyprland Navigation** (matches UHK Fn2 layer exactly):
- Physical `Alt + J` → sends `Super+J` (due to swap) → Hyprland: focus left pane
- Physical `Alt + K` → sends `Super+K` → Hyprland: focus down pane
- Physical `Alt + I` → sends `Super+I` → Hyprland: focus up pane
- Physical `Alt + L` → sends `Super+L` → Hyprland: focus right pane

**Key Insight**: The muscle memory is identical between UHK and Framework:
- UHK: Thumb presses Fn2, fingers press JKIL → sends Alt+JKIL → swapped to Super+JKIL
- Framework: Thumb presses Alt, fingers press JKIL → sends Alt+JKIL → swapped to Super+JKIL
- **Same physical keys, same hand positions, same cognitive pattern**

#### Laptop-Specific Considerations

**Layout Differences**:
- No dedicated navigation cluster (Home/End/PgUp/PgDn)
- Function keys require Fn modifier (F1-F12)
- No numpad
- Trackpad available (but avoid for mouse-free workflow)

**Optimization Strategies**:
1. **Alt Key Accessibility**:
   - Alt is positioned for thumb access (similar ergonomics to UHK Fn2)
   - With `altwin:swap_alt_win`, this is optimized for the layout

2. **Caps Lock as Ctrl**:
   - Frees up Caps Lock for mouse mode activation
   - Makes Ctrl more accessible for app-level operations

3. **Function Row**:
   - Media controls: Fn+F1-F12
   - Brightness: Fn+F7/F8
   - Volume: Fn+F9/F10/F11

#### Power/Brightness Keys
```
Fn + F7 = Brightness down
Fn + F8 = Brightness up
Fn + F9 = Mute
Fn + F10 = Volume down
Fn + F11 = Volume up
Fn + F12 = Keyboard backlight toggle
```

#### Migration from UHK

When switching from UHK to built-in Framework keyboard:
1. All Hyprland navigation works identically (Alt+JKIL)
2. Arrow key navigation requires standard arrow keys (no Mod layer)
3. Function keys require Fn modifier
4. All other keybindings remain consistent

**Recommendation**: Keep UHK connected when at desk for optimal ergonomics; use Framework keyboard for portable scenarios with identical Hyprland muscle memory.

---

### Portable Programmable Keyboard (Future)

#### Overview

For travel scenarios with the Framework laptop (or other portable setup), a compact programmable keyboard provides:
- Ergonomic benefits of custom layout
- Portability (40-60% size)
- Same muscle memory as UHK
- QMK/ZMK firmware for deep customization

#### Recommended Keyboards

**Popular Options**:
- **Corne (40-42 keys)**: Split, ergonomic, highly portable
- **Planck (47-48 keys)**: Ortholinear, compact, classic
- **Preonic (60 keys)**: Planck with number row
- **Lily58**: Split, more keys than Corne
- **Kyria**: Split, ergonomic, thumb clusters

**Selection Criteria**:
1. QMK/ZMK firmware support (for custom key mappings)
2. Thumb cluster or thumb keys (for layer access)
3. Travel-friendly size (fits in laptop bag)
4. Split or compact ergonomic layout

#### Configuration Strategy

**Firmware Setup** (QMK/ZMK):
```c
// Example QMK layer configuration
// Layer 0 (Base): Standard QWERTY
// Layer 1 (Lower): Navigation layer accessed via thumb key

// Configure thumb key to act as layer toggle
// Configure Layer 1:
// - J → Alt+J (Hyprland focus left)
// - K → Alt+K (Hyprland focus down)
// - I → Alt+I (Hyprland focus up)
// - L → Alt+L (Hyprland focus right)
```

**Key Principle**:
- Keyboard firmware sends `Alt+JKIL` codes
- OS-level `altwin:swap_alt_win` swaps to `Super+JKIL`
- Hyprland receives `Super+JKIL` for navigation
- **Identical to UHK and Framework behavior**

#### Portability Benefits

1. **Same OS Configuration**: No Nix config changes needed
2. **Same Muscle Memory**: Thumb + JKIL pattern identical to UHK
3. **Compact Travel**: Fits in laptop bag alongside Framework
4. **Universal**: Works with any laptop (Framework, MacBook, etc.)
5. **Firmware Persistence**: Keyboard config stored in firmware, not OS

#### Migration Checklist

When configuring a new portable keyboard:
- [ ] Flash QMK/ZMK firmware
- [ ] Configure base layer (QWERTY or preferred)
- [ ] Configure lower/raise layer with thumb key access
- [ ] Map navigation layer: J/K/I/L → Alt+J/K/I/L
- [ ] Test with Hyprland (should work immediately due to OS swap)
- [ ] Configure additional layers (function keys, media controls)
- [ ] Save firmware configuration to version control

---

### MacBook

#### Current Configuration
- Home Manager: `/home/ncrmro/nixos-config/home-manager/ncrmro/ncrmro-macbook.nix`
- Home Manager: `/home/ncrmro/nixos-config/home-manager/ncrmro/unsup-macbook.nix`
- Status: Minimal user setup, no custom keybindings
- **Operating System**: macOS (not NixOS/Hyprland)

#### macOS-Specific Considerations

**Important**: MacBook runs **macOS**, not Hyprland. Therefore, Hyprland-specific keybindings don't apply.

**Window Management on macOS:**
- macOS uses native window management (Mission Control, Spaces)
- Alternative tiling window managers:
  - **Aerospace**: Tiling window manager inspired by i3
  - **Rectangle**: Window snapping tool
  - **Amethyst**: Tiling window manager
  - **yabai**: Advanced tiling window manager

**Keyboard Layout Differences:**
- **Command** key instead of Super/Win (primary modifier on macOS)
- **Option** key instead of Alt
- Touch Bar on some models (context-sensitive function keys)

#### Portable Keyboard with macOS

If using a programmable keyboard (QMK/ZMK) with MacBook:

**Option 1: macOS Window Manager**
- Configure window manager (Aerospace/yabai) to use Cmd+JKIL
- Program keyboard to send Cmd+JKIL (Command instead of Alt)
- Different firmware from Linux setup

**Option 2: System-Level Key Swap**
- Use Karabiner-Elements to swap Option↔Command
- Program keyboard to send Alt+JKIL (same as Linux)
- Alt codes get swapped to Command codes
- Similar to Linux `altwin:swap_alt_win` approach

**Recommendation**: Use Option 2 for consistency with Linux setups. This allows the same keyboard firmware to work across Linux and macOS.

#### Tools Applicable to macOS

These keybinding configurations work on macOS:
- **Ghostty**: Cross-platform terminal (same config)
- **Zellij**: Cross-platform multiplexer (same config)
- **Helix**: Cross-platform editor (same config)
- **Browser/Vimium**: Cross-platform (same config)
- **Git aliases**: Cross-platform (same config)

**Not Applicable**:
- Hyprland keybindings (Linux-only Wayland compositor)

#### Home Manager macOS Module

**Important**: Home Manager should be used on macOS to manage keybindings for maximum consistency across platforms.

**Home Manager can manage on macOS:**
- **Ghostty terminal**: Keybindings configured in `programs.ghostty` module
- **Zellij**: Keybindings configured in `programs.zellij.settings`
- **Helix editor**: Keybindings configured in `programs.helix.settings.keys`
- **Git**: Aliases and configuration
- **Shell**: Zsh/Bash configuration
- **Browser**: Vimium config can be exported and tracked

**Benefits of Home Manager on macOS:**
1. **Single source of truth**: Same Nix config for NixOS and macOS
2. **Version controlled**: All keybindings tracked in git
3. **Declarative**: Reproducible across machines
4. **Cross-platform**: Keybindings for Ghostty/Zellij/Helix identical on both systems

**macOS-Specific (Outside Home Manager):**
- Window management (Aerospace, yabai, Rectangle)
  - Configure separately to use Cmd+JKIL or Option+JKIL
  - Karabiner-Elements for key swapping (if desired)

**Strategy**: Use Home Manager for all tool-specific keybindings; use native macOS/third-party tools only for window management.

---

### Hardware Translation Table

This table shows how the same window management operations are performed across different hardware configurations:

| Action | UHK (NixOS) | Framework Built-in (NixOS) | Portable QMK/ZMK (NixOS) | MacBook (macOS) |
|--------|-------------|----------------------------|--------------------------|-----------------|
| **WM Focus Left** | Fn2 (thumb) + J → Alt+J → Super+J* | Alt + J → Super+J* | Lower (thumb) + J → Alt+J → Super+J* | Cmd + J† or Option+J via Karabiner |
| **WM Focus Down** | Fn2 (thumb) + K → Alt+K → Super+K* | Alt + K → Super+K* | Lower (thumb) + K → Alt+K → Super+K* | Cmd + K† or Option+K via Karabiner |
| **WM Focus Up** | Fn2 (thumb) + I → Alt+I → Super+I* | Alt + I → Super+I* | Lower (thumb) + I → Alt+I → Super+I* | Cmd + I† or Option+I via Karabiner |
| **WM Focus Right** | Fn2 (thumb) + L → Alt+L → Super+L* | Alt + L → Super+L* | Lower (thumb) + L → Alt+L → Super+L* | Cmd + L† or Option+L via Karabiner |
| **Arrow Keys** | Mod + JKIL → ←↓↑→ | Standard arrows | Firmware layer → ←↓↑→ | Standard arrows |
| **Caps Lock Mouse Mode** | Remapped to Ctrl | Remapped to Ctrl | Remapped to Ctrl | TBD |
| **Configuration Method** | UHK Agent (GUI) | N/A (built-in) | QMK/ZMK firmware | N/A (built-in) |
| **OS** | NixOS + Hyprland | NixOS + Hyprland | NixOS + Hyprland | macOS + Aerospace/yabai |
| **Portability** | Desktop use | Always available | Travel with laptop | macOS only |

\* **NixOS/Linux**: All keyboards send Alt codes → `altwin:swap_alt_win` swaps to Super → Hyprland receives Super
† **macOS**: Requires macOS window manager (Aerospace, yabai, etc.) configured for Cmd+JKIL navigation

**Key Insights:**
1. **OS-Level Swap is Universal**: The `altwin:swap_alt_win` setting makes ALL keyboards work identically
2. **Firmware Strategy**: Configure any programmable keyboard to send Alt+JKIL
3. **Thumb Ergonomics**: UHK Fn2 and QMK/ZMK lower layer both provide thumb access
4. **No OS Changes Needed**: Adding a new keyboard requires zero Nix/Hyprland configuration changes
5. **Muscle Memory**: Physical pattern is identical across all keyboards (thumb + JKIL)

**Adding a New Programmable Keyboard:**
1. Flash firmware (UHK Agent, QMK, or ZMK)
2. Configure layer with Alt+JKIL mappings
3. Plug in keyboard
4. Everything works immediately (OS swap setting already configured)

---

## Keybinding Consistency Matrix

### Common Operations Across Tools

| Action | Hyprland | Ghostty | Zellij | Helix | Browser (Vimium) |
|--------|----------|---------|--------|-------|------------------|
| **Navigation** |
| Focus/Move Left | `Super+J`* | TBD | `Ctrl+G h` | `h` | TBD |
| Focus/Move Down | `Super+K`* | TBD | `Ctrl+G j` | `j` | `j` (scroll) |
| Focus/Move Up | `Super+I`* | TBD | `Ctrl+G k` | `k` | `k` (scroll) |
| Focus/Move Right | `Super+L`* | TBD | `Ctrl+G l` | `l` | TBD |
| **Window/Tab/Pane Management** |
| New Window/Tab | `Super+Return`* | TBD | TBD | TBD | `t` |
| Close | `Super+Q`* | TBD | `Ctrl+G x` | `:q` | `x` |
| Next | `Super+Tab`* | TBD | TBD | TBD | `J` |
| Previous | `Super+Shift+Tab`* | TBD | TBD | TBD | `K` |
| **Common Actions** |
| Reload/Refresh | `Super+R`* | TBD | TBD | `:reload` | `r` |
| Search | TBD | TBD | TBD | `/` | `/` |
| Quit | `Super+Shift+Q`* | TBD | TBD | `:q` | TBD |
| Save | N/A | N/A | N/A | `Return` | N/A |
| **Special Functions** |
| Fullscreen | `Super+F`* | TBD | TBD | TBD | TBD |
| Floating Toggle | `Super+V`* | N/A | N/A | N/A | N/A |
| Workspace 1-10 | `Super+1-0`* | N/A | N/A | N/A | N/A |

\* **Physical key**: Press Alt (swapped to Super via `altwin:swap_alt_win`)
- On UHK: Fn2 (thumb) + key sends Alt, swapped to Super
- On Framework: Alt + key sends Alt, swapped to Super
- Both produce identical Super keycodes to Hyprland

*TBD = To Be Defined in implementation*

---

## Nix Implementation Guide

### Module Structure

All keybindings should be managed declaratively through Nix/Home Manager. This structure works on both **NixOS** and **macOS** (via Home Manager).

```
home-manager/common/features/
├── desktop/                    # NixOS only
│   └── hyprland/
│       └── keybindings.nix     # Hyprland window manager bindings
├── cli/                        # Cross-platform (NixOS + macOS)
│   ├── ghostty/
│   │   └── keybindings.nix     # Terminal keybindings
│   ├── zellij/
│   │   └── keybindings.nix     # Multiplexer keybindings
│   └── helix/
│       └── keybindings.nix     # Editor keybindings
└── browser/                    # Cross-platform (NixOS + macOS)
    └── vimium/
        └── config.nix          # Browser extension config
```

**Cross-Platform Strategy:**
- **CLI tools** (Ghostty, Zellij, Helix): Same configuration on NixOS and macOS
- **Desktop** (Hyprland): NixOS only; macOS uses separate window manager
- **Browser** (Vimium): Identical configuration on both platforms

### Configuration Examples

#### Hyprland Keybindings Module
```nix
# home-manager/common/features/desktop/hyprland/keybindings.nix
{ config, lib, pkgs, ... }:
{
  # Example structure - to be implemented
}
```

#### Ghostty Keybindings Module
```nix
# home-manager/common/features/cli/ghostty/keybindings.nix
{ config, lib, pkgs, ... }:
{
  programs.ghostty = {
    # Example structure - to be implemented
  };
}
```

### Host-Specific Customizations
<!-- How to override defaults per-host -->

### Hardware-Specific Modules
<!-- Framework vs MacBook specific keybinding adjustments -->

---

## Migration Path

### Implementation Phases

**Phase 1: Documentation & Planning** ✅
- [x] Document current state
- [x] Research tool capabilities
- [x] Design unified keybinding scheme
- [ ] Create consistency matrix

**Phase 2: Hyprland Foundation**
- [ ] Implement complete Hyprland keybindings
- [ ] Setup window management bindings
- [ ] Configure workspace navigation
- [ ] Add app launcher bindings
- [ ] Integrate app groups from spike

**Phase 3: Terminal Stack**
- [ ] Configure Ghostty custom keybindings
- [ ] Customize Zellij for workflow
- [ ] Test Ghostty + Zellij integration

**Phase 4: Editor Enhancement**
- [ ] Enhance Helix keybindings
- [ ] Add LSP operation bindings
- [ ] Configure multi-cursor workflows

**Phase 5: Browser Integration**
- [ ] Setup Vimium configuration
- [ ] Export and version control config
- [ ] Test consistency with other tools

**Phase 6: Hardware Optimization**
- [ ] Program UHK layers
- [ ] Test on Framework laptop
- [ ] Test on MacBook (if applicable)
- [ ] Document ergonomic improvements

**Phase 7: Testing & Iteration**
- [ ] Daily usage testing (mouse-free workflows)
- [ ] Test Caps Lock mouse mode for edge cases
- [ ] Verify muscle memory portability (UHK ↔ Framework)
- [ ] Identify conflicts and issues
- [ ] Refine based on real-world usage
- [ ] Measure productivity improvements
- [ ] Document lessons learned

---

## Quick Reference Cards

### Hyprland Cheatsheet
<!-- Top 30 keybindings -->

### Terminal Stack Cheatsheet
<!-- Ghostty + Zellij common operations -->

### Helix Cheatsheet
<!-- Most-used editor commands -->

### Browser (Vimium) Cheatsheet
<!-- Essential navigation commands -->

### UHK Layer Diagram
<!-- Visual representation of layer layouts -->

---

## Additional Resources

### Documentation Links
- [Hyprland Wiki - Binds](https://wiki.hypr.land/Configuring/Binds/)
- [Ghostty Keybindings Docs](https://ghostty.org/docs/config/keybind)
- [Zellij Keybindings Guide](https://zellij.dev/documentation/keybindings.html)
- [Helix Documentation](https://docs.helix-editor.com/)
- [Vimium GitHub](https://github.com/philc/vimium)
- [UHK Agent](https://ultimatehackingkeyboard.github.io/agent/)

### Related Configuration Files
- Hyprland: `archive/home.nix:109-116`
- App Groups: `spikes/1757895719_hyprland_app_groups/`
- Helix: `home-manager/common/features/cli/helix.nix:43`
- Git: `home-manager/common/features/cli/git.nix`
- Input: `home-manager/common/features/desktop/default.nix:22-30`

---

## Contributing

This is a living document. As keybindings are implemented and tested, this documentation should be updated to reflect:
- Actual configurations that work well
- Conflicts discovered during usage
- Ergonomic improvements
- New tools added to the workflow

## Changelog

- 2025-10-25: Initial outline created
  - Added comprehensive structure for all tools (Hyprland, Ghostty, Zellij, Helix, Browser/Vimium)
  - Documented mouse-free workflow philosophy
  - Clarified modifier key strategy: Hyprland uses Super, accessed via Alt (swapped via `altwin:swap_alt_win`)
  - Documented current UHK Fn2 layer configuration (manually configured Alt+JKIL mappings)
  - Added Framework laptop portability strategy (direct Alt+JKIL usage)
  - **Added portable programmable keyboard section (QMK/ZMK)**
    - OS-level configuration strategy for maximum portability
    - Hardware-independent approach (any programmable keyboard sends Alt codes)
    - Recommended keyboards: Corne, Planck, Preonic, Lily58, Kyria
    - Migration checklist for new keyboards
  - Created hardware translation table for UHK ↔ Framework ↔ Portable Keyboard ↔ MacBook
  - Documented ergonomic principles and Caps Lock mouse mode
  - Added keybinding consistency matrix across all tools
  - Outlined 7-phase migration path
  - **Emphasized portability-first strategy**: Single OS configuration works with any programmable keyboard
