-- Matches the terminal's palette: ptyxis/one-warm.palette (Ptyxis "One (Warm)",
-- based on Atom One Dark). Overrides are the colors that palette diverges on
-- from onedark.nvim's stock "dark" style — see that file's comments for why.
return {
  {
    "navarasu/onedark.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "dark",
      colors = {
        bg0 = "#16191D", -- terminal Background
        fg = "#D6D2C4", -- terminal Foreground/Cursor
        black = "#000000", -- terminal Color0
        red = "#E06C75", -- terminal Color1
        yellow = "#D19A66", -- terminal Color3
        -- bg_blue/bg_yellow are onedark's own UI-accent shades (menu
        -- selection, search highlight) with no equivalent in the terminal
        -- palette — map them onto the closest real palette colors instead.
        bg_blue = "#61AFEF", -- terminal Color4 (blue)
        bg_yellow = "#D19A66", -- terminal Color3
      },
    },
    config = function(_, opts)
      require("onedark").setup(opts)
      require("onedark").load()
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "onedark",
    },
  },
}
