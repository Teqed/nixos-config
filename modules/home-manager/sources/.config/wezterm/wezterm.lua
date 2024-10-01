local wezterm = require 'wezterm' -- Pull in the wezterm API
local config = wezterm.config_builder() -- This will hold the configuration.
-- config.font = wezterm.font '...'
-- config.color_scheme = 'Matrix (terminal.sexy)'
-- config.cursor_blink_rate = 800
config.colors = {
  -- Overrides the cell background color when the current cell is occupied by the
  -- cursor and the cursor style is set to Block
  cursor_bg = '#96eaf9', -- color14
  -- Overrides the text color when the current cell is occupied by the cursor
  cursor_fg = '#313131', -- color0
  -- Specifies the border color of the cursor when the cursor style is set to Block,
  -- or the color of the vertical or horizontal bar when the cursor style is set to
  -- Bar or Underline.
  cursor_border = '#96eaf9', -- color14
  -- Since: 20220319-142410-0fcdea07
  -- When the IME, a dead key or a leader key are being processed and are effectively
  -- holding input pending the result of input composition, change the cursor
  -- to this color to give a visual cue about the compose state.
  compose_cursor = 'orange',
  foreground = "#ededed",
  background = "#000000", -- old 141619
  ansi = {
    '#000000', -- 'black', color0 -- old 313131
    '#cb150a', -- 'maroon', color1
    '#0ca948', -- 'green', color2
    '#ff9e00', -- 'olive', color3
    '#2c77ea', -- 'navy', color4
    '#ad2bd0', -- 'purple', color5
    '#10cec6', -- 'teal', color6
    '#758989', -- 'silver', color7
  },
  brights = {
    '#838383', -- 'grey', color8
    '#f24c32', -- 'red', color9
    '#2cf083', -- 'lime', color10
    '#ffd361', -- 'yellow', color11
    '#a5b7f4', -- 'blue', color12
    '#bf89e0', -- 'fuchsia', color13
    '#96eaf9', -- 'aqua', color14
    '#ffffff', -- 'white', color15 -- old c4dfdf
  },
  visual_bell = '#202020',
}
config.default_cursor_style = "BlinkingUnderline" -- Set the cursor style to SteadyBar
config.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 150,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 150,
}

return config -- and finally, return the configuration to wezterm
