-- One Dark colorscheme — matches the terminal (Ptyxis `one-sysaccent` palette
-- and the oh-my-posh prompt colors: coral #E06C75, gold #E5C07B, green #98C379).
return {
  {
    "navarasu/onedark.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "dark", -- classic One Dark; alternatives: darker, cool, deep, warm, warmer
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "onedark",
    },
  },
}
