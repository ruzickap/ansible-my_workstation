return {
  {
    "zbirenbaum/copilot.lua",
    opts = {
      -- Show Copilot suggestions as inline ghost text.
      suggestion = {
        enabled = true,
        -- Suggest automatically while typing, without a manual trigger.
        auto_trigger = true,
        keymap = {
          -- Accept the whole suggestion.
          accept = "<Tab>",
          -- Cycle to the next / previous suggestion (Alt+] / Alt+[).
          next = "<M-]>",
          prev = "<M-[>",
        },
      },
    },
  },
}
