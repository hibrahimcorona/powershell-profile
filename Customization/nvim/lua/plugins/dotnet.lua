return {
  -- 1. Treesitter support for C#
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "c_sharp", "html" } },
  },

  -- 2. Mason tool installations with BOTH official and community registries
  {
    "mason-org/mason.nvim",
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
      ensure_installed = {
        "netcoredbg",
        "csharpier",
      },
    },
  },

  -- 3. Roslyn LSP Integration (seblyng/roslyn.nvim)
  {
    "seblyng/roslyn.nvim",
    ft = { "cs", "razor", "csproj", "sln" },
    opts = {
      config = {
        handlers = {},
        filewatching = "roslyn",
      },
    },
  },

  -- 4. DAP (Debug Adapter Protocol) & UI Setup
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {},
      },
    },
    config = function()
      -- CRITICAL for Windows: Prevent path separator mismatches that crash netcoredbg
      if vim.fn.has("win32") == 1 then
        vim.opt.shellslash = false
      end

      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()

      -- Automatically open/close DAP UI
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      -- Point directly to the netcoredbg executable on Windows
      local mason_path = vim.fn.stdpath("data") .. "/mason/packages/netcoredbg/"
      local netcoredbg_path = mason_path
        .. (vim.fn.has("win32") == 1 and "netcoredbg/netcoredbg.exe" or "netcoredbg/netcoredbg")

      dap.adapters.coreclr = {
        type = "executable",
        command = netcoredbg_path,
        args = { "--interpreter=vscode" },
      }

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "Launch .NET Core App",
          request = "launch",
          preLaunchTask = function()
            local handle = io.popen("dotnet build")
            if handle then
              handle:close()
            end
          end,
          program = function()
            -- Automatically target standard .NET output paths (e.g., bin/Debug/net10.0/)
            local cwd = vim.fn.getcwd()
            local handle = io.popen('dir /b /ad "' .. cwd .. '\\bin\\Debug"')
            local target_framework = ""
            if handle then
              for line in handle:lines() do
                if line:match("^net") then
                  target_framework = line
                  break
                end
              end
              handle:close()
            end

            local default_path = cwd .. "\\bin\\Debug\\" .. (target_framework ~= "" and target_framework .. "\\" or "")
            local path = vim.fn.input("Path to dll: ", default_path, "file")
            return (vim.fn.has("win32") == 1) and path:gsub("/", "\\") or path
          end,
          cwd = function()
            return vim.fn.getcwd()
          end,
          -- Ensure source mapping handles Windows drive letters properly
          sourceFileMap = function()
            local cwd = vim.fn.getcwd()
            return {
              [cwd] = cwd,
            }
          end,
        },
      }
    end,
  },
}
