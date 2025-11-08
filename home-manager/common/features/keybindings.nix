{
  config,
  lib,
  pkgs,
  ...
}: {
  # Centralized Keybinding Configuration
  # ONLY keybinding settings - enable/theme/other configs stay in respective modules
  #
  # Tab Navigation Strategy:
  # - Browser-standard shortcuts (Ctrl+PgUp/PgDn, Ctrl+Tab) work in Chrome, Firefox, Zellij, most apps
  # - UHK Mod layer: W/E/R/C → Ctrl+PgUp/T/PgDn/W for ergonomic home row access
  # - Framework laptop: Fn+Ctrl+Arrow (PgUp/PgDn) or Ctrl+Tab (no Fn needed)
  # - Both methods supported for flexibility across hardware

  # Zellij - Terminal Multiplexer Tab and Pane Navigation
  programs.zellij.settings.keybinds = {
    normal = {
      # ===== TAB NAVIGATION =====
      # Previous tab: Ctrl+PgUp
      # - UHK: Mod+W → Ctrl+PgUp
      # - Framework: Fn+Ctrl+Arrow Up → Ctrl+PgUp
      # - Works in: Zellij, Chrome, Firefox, many apps
      "bind \"Ctrl PageUp\"" = {GoToPreviousTab = {};};

      # Next tab: Ctrl+PgDn
      # - UHK: Mod+R → Ctrl+PgDn
      # - Framework: Fn+Ctrl+Arrow Down → Ctrl+PgDn
      # - Works in: Zellij, Chrome, Firefox, many apps
      "bind \"Ctrl PageDown\"" = {GoToNextTab = {};};

      # Previous tab (alternative): Ctrl+Shift+Tab
      # - All keyboards: Ctrl+Shift+Tab (no Fn needed)
      # - Browser-standard, works everywhere
      "bind \"Ctrl Shift Tab\"" = {GoToPreviousTab = {};};

      # Next tab (alternative): Ctrl+Tab
      # - All keyboards: Ctrl+Tab (no Fn needed)
      # - Browser-standard, works everywhere
      "bind \"Ctrl Tab\"" = {GoToNextTab = {};};

      # New tab: Ctrl+T
      # - UHK: Mod+E → Ctrl+T
      # - Framework: Ctrl+T
      # - Universal browser/app standard
      "bind \"Ctrl t\"" = {NewTab = {};};

      # Close tab: Ctrl+W
      # - UHK: Mod+C → Ctrl+W
      # - Framework: Ctrl+W
      # - Universal browser/app standard
      "bind \"Ctrl w\"" = {CloseTab = {};};

      # ===== PANE NAVIGATION =====
      # Direct pane navigation using Alt+J/K/I/L
      # - Matches Hyprland's ergonomic JKIL pattern (Super+JKIL for windows)
      # - No mode switching required (faster than Ctrl+P → hjkl)
      # - Works over SSH identically to local navigation
      # - No conflict with Hyprland (Hyprland uses Super, apps receive Alt)

      # Navigate to pane on the left: Alt+J
      "bind \"Alt j\"" = {MoveFocus = "Left";};

      # Navigate to pane below: Alt+K
      "bind \"Alt k\"" = {MoveFocus = "Down";};

      # Navigate to pane above: Alt+I
      "bind \"Alt i\"" = {MoveFocus = "Up";};

      # Navigate to pane on the right: Alt+L
      "bind \"Alt l\"" = {MoveFocus = "Right";};

      # ===== MODE SWITCHING =====
      # Unbind default Ctrl+G (which normally enters locked mode)
      # Conflict avoided: Ctrl+G is used by Claude Code for "open prompt in editor"
      "unbind \"Ctrl g\"" = [];

      # Lock mode: Ctrl+Shift+G (custom binding, replaces default Ctrl+G)
      "bind \"Ctrl Shift g\"" = {SwitchToMode = "locked";};

      # Unbind default Ctrl+O (which normally enters session mode)
      # Conflicts avoided: Ctrl+O is used by Claude Code for "view thinking" and lazygit for "copy"
      "unbind \"Ctrl o\"" = [];

      # Session mode: Ctrl+Shift+O (custom binding, replaces default Ctrl+O)
      "bind \"Ctrl Shift o\"" = {SwitchToMode = "session";};

      # Unbind default Ctrl+P (pane mode) navigation from normal mode
      # We're using direct Alt+JKIL navigation instead
      # Keep Ctrl+P for entering pane mode (for split creation, etc.)
      # but navigation is now direct via Alt+JKIL
    };
  };

  # Ghostty - Tab Navigation with Shift Modifier
  # Strategy: Ghostty tabs use Ctrl+Shift+W/E/R/C to avoid conflict with Zellij
  # Zellij uses Ctrl+PgUp/PgDn/Tab/T/W (no shift)
  # This allows both to coexist if needed, with Zellij as primary
  programs.ghostty.settings.keybind = [
    # Previous tab: Ctrl+Shift+W (original W + shift)
    "ctrl+shift+w=previous_tab"

    # New tab: Ctrl+Shift+E (original E + shift)
    "ctrl+shift+e=new_tab"

    # Next tab: Ctrl+Shift+R (original R + shift)
    "ctrl+shift+r=next_tab"

    # Close tab: Ctrl+Shift+C (original C + shift)
    "ctrl+shift+c=close_surface"

    # Unbind conflicting shortcuts to ensure Zellij receives them
    "ctrl+page_up=unbind"
    "ctrl+page_down=unbind"
    "ctrl+tab=unbind"
  ];

  # Future keybinding configurations:
  # - Helix: programs.helix.settings.keys = { ... };
  # - Browser/Vimium: Export and track configuration
}
