return {
  {
    "neovim/nvim-lspconfig",
    opts = function()
      -- VS-style Debugging Keymaps via nvim-dap
      vim.keymap.set("n", "<F5>", function()
        require("dap").continue()
      end, { desc = "DAP: Continue / Start (VS F5)" })
      vim.keymap.set("n", "<F9>", function()
        require("dap").toggle_breakpoint()
      end, { desc = "DAP: Toggle Breakpoint (VS F9)" })
      vim.keymap.set("n", "<F10>", function()
        require("dap").step_over()
      end, { desc = "DAP: Step Over (VS F10)" })
      vim.keymap.set("n", "<F11>", function()
        require("dap").step_into()
      end, { desc = "DAP: Step Into (VS F11)" })
      vim.keymap.set("n", "<S-F11>", function()
        require("dap").step_out()
      end, { desc = "DAP: Step Out (VS Shift+F11)" })
    end,
  },
}
