-- Drop the statusline clock (lualine_z) - the system menu bar already shows it
return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    opts.sections.lualine_z = {}
  end,
}
