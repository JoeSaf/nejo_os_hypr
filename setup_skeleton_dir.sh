#!/bin/bash
# Script to set up the skeleton directory for Xfce with SDDM

set -e  # Exit on error

# Working directory - expected to be the archiso config directory
WORK_DIR="$(pwd)"
SKEL_DIR="$WORK_DIR/airootfs/etc/skel"

echo "Setting up skeleton directory at $SKEL_DIR..."

# Create necessary directories
mkdir -p "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml"
mkdir -p "$SKEL_DIR/.config/xfce4/panel"
mkdir -p "$SKEL_DIR/.config/autostart"
mkdir -p "$SKEL_DIR/Desktop"
mkdir -p "$SKEL_DIR/Documents"
mkdir -p "$SKEL_DIR/Downloads"
mkdir -p "$SKEL_DIR/Pictures"

# Configure Xfce desktop
cat > "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitor0" type="empty">
        <property name="image-path" type="string">/usr/share/backgrounds/xfce/xfce-blue.jpg</property>
        <property name="last-image" type="string">/usr/share/backgrounds/xfce/xfce-blue.jpg</property>
        <property name="last-single-image" type="string">/usr/share/backgrounds/xfce/xfce-blue.jpg</property>
        <property name="image-style" type="int" value="5"/>
      </property>
    </property>
  </property>
</channel>
EOF

# Configure Xfce panel
cat > "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=6;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="30"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
        <value type="int" value="7"/>
        <value type="int" value="8"/>
      </property>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu"/>
    <property name="plugin-2" type="string" value="tasklist"/>
    <property name="plugin-3" type="string" value="separator"/>
    <property name="plugin-4" type="string" value="pager"/>
    <property name="plugin-5" type="string" value="separator"/>
    <property name="plugin-6" type="string" value="systray"/>
    <property name="plugin-7" type="string" value="separator"/>
    <property name="plugin-8" type="string" value="clock"/>
  </property>
</channel>
EOF

# Configure Xfce session
cat > "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-session" version="1.0">
  <property name="general" type="empty">
    <property name="FailsafeSessionName" type="string" value="Failsafe"/>
    <property name="SessionName" type="string" value="Default"/>
    <property name="SaveOnExit" type="bool" value="true"/>
  </property>
  <property name="sessions" type="empty">
    <property name="Failsafe" type="empty">
      <property name="IsFailsafe" type="bool" value="true"/>
      <property name="Count" type="int" value="5"/>
      <property name="Client0_Command" type="array">
        <value type="string" value="xfwm4"/>
      </property>
      <property name="Client1_Command" type="array">
        <value type="string" value="xfsettingsd"/>
      </property>
      <property name="Client2_Command" type="array">
        <value type="string" value="xfce4-panel"/>
      </property>
      <property name="Client3_Command" type="array">
        <value type="string" value="Thunar"/>
        <value type="string" value="--daemon"/>
      </property>
      <property name="Client4_Command" type="array">
        <value type="string" value="xfdesktop"/>
      </property>
    </property>
  </property>
</channel>
EOF

# Configure terminal 
cat > "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-terminal.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-terminal" version="1.0">
  <property name="font-name" type="string" value="Monospace 11"/>
  <property name="misc-cursor-blinks" type="bool" value="true"/>
  <property name="misc-cursor-shape" type="string" value="TERMINAL_CURSOR_SHAPE_BLOCK"/>
  <property name="misc-always-show-tabs" type="bool" value="false"/>
  <property name="scrolling-lines" type="uint" value="10000"/>
  <property name="color-foreground" type="string" value="#f8f8f2"/>
  <property name="color-background" type="string" value="#272822"/>
  <property name="color-palette" type="string" value="#272822;#f92672;#a6e22e;#f4bf75;#66d9ef;#ae81ff;#a1efe4;#f8f8f2;#75715e;#f92672;#a6e22e;#f4bf75;#66d9ef;#ae81ff;#a1efe4;#f9f8f5"/>
  <property name="use-theme-colors" type="bool" value="false"/>
</channel>
EOF

# Configure window manager
cat > "$SKEL_DIR/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="activate_action" type="string" value="bring"/>
    <property name="borderless_maximize" type="bool" value="true"/>
    <property name="box_move" type="bool" value="false"/>
    <property name="box_resize" type="bool" value="false"/>
    <property name="button_layout" type="string" value="O|SHMC"/>
    <property name="button_offset" type="int" value="0"/>
    <property name="button_spacing" type="int" value="0"/>
    <property name="click_to_focus" type="bool" value="true"/>
    <property name="cycle_apps_only" type="bool" value="false"/>
    <property name="cycle_draw_frame" type="bool" value="true"/>
    <property name="cycle_hidden" type="bool" value="true"/>
    <property name="cycle_minimum" type="bool" value="true"/>
    <property name="cycle_preview" type="bool" value="true"/>
    <property name="cycle_tabwin_mode" type="int" value="0"/>
    <property name="cycle_workspaces" type="bool" value="false"/>
    <property name="focus_delay" type="int" value="250"/>
    <property name="focus_hint" type="bool" value="true"/>
    <property name="focus_new" type="bool" value="true"/>
    <property name="frame_opacity" type="int" value="100"/>
    <property name="full_width_title" type="bool" value="true"/>
    <property name="horiz_scroll_opacity" type="bool" value="false"/>
    <property name="inactive_opacity" type="int" value="100"/>
    <property name="maximized_offset" type="int" value="0"/>
    <property name="mousewheel_rollup" type="bool" value="true"/>
    <property name="move_opacity" type="int" value="100"/>
    <property name="preview_mode" type="int" value="0"/>
    <property name="raise_delay" type="int" value="250"/>
    <property name="raise_on_click" type="bool" value="true"/>
    <property name="raise_on_focus" type="bool" value="false"/>
    <property name="raise_with_any_button" type="bool" value="true"/>
    <property name="repeat_urgent_blink" type="bool" value="false"/>
    <property name="resize_opacity" type="int" value="100"/>
    <property name="scroll_workspaces" type="bool" value="true"/>
    <property name="shadow_delta_height" type="int" value="0"/>
    <property name="shadow_delta_width" type="int" value="0"/>
    <property name="shadow_delta_x" type="int" value="0"/>
    <property name="shadow_delta_y" type="int" value="-3"/>
    <property name="shadow_opacity" type="int" value="50"/>
    <property name="show_app_icon" type="bool" value="false"/>
    <property name="show_dock_shadow" type="bool" value="true"/>
    <property name="show_frame_shadow" type="bool" value="true"/>
    <property name="show_popup_shadow" type="bool" value="false"/>
    <property name="snap_resist" type="bool" value="false"/>
    <property name="snap_to_border" type="bool" value="true"/>
    <property name="snap_to_windows" type="bool" value="false"/>
    <property name="snap_width" type="int" value="10"/>
    <property name="theme" type="string" value="Default"/>
    <property name="tile_on_move" type="bool" value="true"/>
    <property name="title_alignment" type="string" value="center"/>
    <property name="title_font" type="string" value="Sans Bold 9"/>
    <property name="title_horizontal_offset" type="int" value="0"/>
    <property name="titleless_maximize" type="bool" value="false"/>
    <property name="title_shadow_active" type="string" value="false"/>
    <property name="title_shadow_inactive" type="string" value="false"/>
    <property name="title_vertical_offset_active" type="int" value="0"/>
    <property name="title_vertical_offset_inactive" type="int" value="0"/>
    <property name="toggle_workspaces" type="bool" value="false"/>
    <property name="unredirect_overlays" type="bool" value="true"/>
    <property name="urgent_blink" type="bool" value="false"/>
    <property name="use_compositing" type="bool" value="true"/>
    <property name="workspace_count" type="int" value="4"/>
    <property name="wrap_cycle" type="bool" value="true"/>
    <property name="wrap_layout" type="bool" value="true"/>
    <property name="wrap_resistance" type="int" value="10"/>
    <property name="wrap_windows" type="bool" value="true"/>
    <property name="wrap_workspaces" type="bool" value="false"/>
    <property name="zoom_desktop" type="bool" value="true"/>
  </property>
</channel>
EOF

# Create a bashrc with useful aliases
cat > "$SKEL_DIR/.bashrc" << 'EOF'
# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific aliases and functions
alias ls='ls --color=auto'
alias ll='ls -lah'
alias grep='grep --color=auto'
alias ip='ip -c'
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rs'
alias search='pacman -Ss'

# Set the PS1 prompt
PS1='\[\e[0;32m\]\u@\h\[\e[m\] \[\e[1;34m\]\w\[\e[m\] \[\e[1;32m\]\$\[\e[m\] '

# Add /usr/local/bin to PATH
export PATH=$PATH:/usr/local/bin
EOF

# Create a simple vimrc
cat > "$SKEL_DIR/.vimrc" << 'EOF'
" Basic vim configuration
syntax on
set number
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set smartindent
set hlsearch
set incsearch
set ignorecase
set smartcase
set showmatch
set backspace=indent,eol,start
set mouse=a
set clipboard=unnamedplus
EOF

# Create autostart for network manager applet
cat > "$SKEL_DIR/.config/autostart/nm-applet.desktop" << 'EOF'
[Desktop Entry]
Name=Network Manager Applet
Comment=Network management
Exec=nm-applet
Terminal=false
Type=Application
Icon=nm-device-wireless
StartupNotify=true
X-GNOME-Autostart-enabled=true
EOF

# Set permissions
chmod -R 755 "$SKEL_DIR"

echo "Skeleton directory setup complete!"
