local wezterm = require 'wezterm'
local config = wezterm.config_builder()
config.colors = {
  cursor_bg = '#96eaf9',
  cursor_fg = '#313131',
  cursor_border = '#96eaf9',
  compose_cursor = 'orange',
  foreground = "#ededed",
  background = "#000000",
  ansi = {
    '#000000',
    '#cb150a',
    '#0ca948',
    '#ff9e00',
    '#2c77ea',
    '#ad2bd0',
    '#10cec6',
    '#758989',
  },
  brights = {
    '#838383',
    '#f24c32',
    '#2cf083',
    '#ffd361',
    '#a5b7f4',
    '#bf89e0',
    '#96eaf9',
    '#ffffff',
  },
  visual_bell = '#202020',
}
config.default_cursor_style = "BlinkingUnderline"
config.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 150,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 150,
}

return config
