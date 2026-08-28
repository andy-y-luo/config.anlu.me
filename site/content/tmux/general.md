+++
title = "Tmux"
author = ["Andy Luo"]
keywords = ["dotfiles", "emacs", "configuration"]
draft = false
+++

I'm using Tmux to run multiple terminal sessions inside a single window. The session persistence feature is nice, and I can juggle multiple workstreams at once through it.


## General / Base Settings {#general-base-settings}


### Terminal / mouse behavior {#terminal-mouse-behavior}

I want to be able to scroll, resize, switch panes/wins with the mouse.

```cfg
set -g mouse on
```

Set correct $TERM for colors &amp; keybindings.

```cfg
set -g default-terminal "tmux-256color"
```


### Prefix key {#prefix-key}

Remap prefix from `C-b` to `C-a` for easier reach.

```cfg
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix
```


### Reload {#reload}

Reload the config on the fly so changes don't require restarting tmux.

```cfg
bind r source-file ~/.config/tmux/tmux.conf \; display-message "tmux.conf reloaded"
```


### Pane behavior {#pane-behavior}

Intuitive split commands using `|` and `-`.

```cfg
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %
```

Switching panes happens frequently, I don't want to trigger the prefix key all the time. I'll use `M-<direction>` to go where I want.

```cfg
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D
```

Start pane numbering at `1`.

```cfg
set-option -g pane-base-index 1
```


### Window behaviour {#window-behaviour}

Don't rename windows automatically; start window numbering at `1`.

```cfg
set-option -g allow-rename off
set-option -g base-index 1
```

`allow-rename off` stops tmux from renaming on its own; `set-titles off`
stops tmux from forwarding shell OSC sequences (zsh, fish, etc.) to the
outer terminal.

```cfg
set -g set-titles off
```


### Status line {#status-line}

The bottom-of-screen status bar. Refresh every 5s so the clock stays
current, and left-align the window list.

```cfg
set -g status-interval 5
set -g status-justify left
```

`status-left` shows the session name; `status-right` shows a custom
red "Z" when the active pane is zoomed (via the `window_zoomed_flag`
format), followed by the current key mode from the `tmux-mode-indicator`
plugin. Both have a leading/trailing space for edge padding. Colors
come from the [everforest hard oldlight](https://github.com/theorytoe/everforest-emacs) emacs theme, bar `bg/fg`
match the active modeline (`#edf0cd` / `#9da9a0`); the session name
uses the green accent (`#8da101`); the zoom "Z" uses the theme red
(`#f85552`).

```cfg
set -g status-left-length 32
set -g status-left  ' #[fg=#8da101,bold]#S '
set -g status-right ' #{?window_zoomed_flag,#[fg=#f85552]Z ,}#{tmux_mode_indicator} '
set -g status-style 'bg=#edf0cd,fg=#9da9a0'
```

In the window list, the current window is wrapped in brackets; all
windows use the default style.

```cfg
setw -g window-status-format         ' #I:#W#F '
setw -g window-status-current-format ' [#I:#W#F]'
```


### Plugin manager (TPM) {#plugin-manager--tpm}

TPM is installed once per machine, outside this config:

```sh
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

Declare plugins to load. Press `prefix + I` to install, `prefix + U` to
update, `prefix + M-u` to remove.

```cfg
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'MunifTanjim/tmux-mode-indicator'
```

Mode indicator styles — each mode maps to an everforest primary, with
the theme bg cream as fg on cool colors and the theme fg dark grey on
yellow for legibility.

```cfg
set -g @mode_indicator_prefix_mode_style 'bg=#3a94c5,fg=#fff9e8'
set -g @mode_indicator_copy_mode_style   'bg=#dfa000,fg=#5c6a72'
set -g @mode_indicator_sync_mode_style   'bg=#f85552,fg=#fff9e8'
set -g @mode_indicator_empty_mode_style  'bg=#35a77c,fg=#fff9e8'
```

Initialize TPM — this must be the last line of the config so bindings
from installed plugins are picked up.

```cfg
run '~/.config/tmux/plugins/tpm/tpm'
```
