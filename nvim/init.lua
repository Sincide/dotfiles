-- ============================================================================
-- Evil Space Neovim Configuration
-- AI-Enhanced Learning Environment for New Neovim Users
-- ============================================================================

-- Bootstrap lazy.nvim plugin manager
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ============================================================================
-- BASIC SETTINGS (Essential for learning)
-- ============================================================================

-- Leader key (space is easier for beginners)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic editor settings
vim.opt.number = true           -- Show line numbers
vim.opt.relativenumber = true   -- Show relative line numbers
vim.opt.mouse = "a"             -- Enable mouse support
vim.opt.clipboard = "unnamedplus" -- Use system clipboard
vim.opt.undofile = true         -- Enable persistent undo
vim.opt.ignorecase = true       -- Case insensitive searching
vim.opt.smartcase = true        -- Case sensitive if uppercase present
vim.opt.updatetime = 250        -- Faster completion
vim.opt.signcolumn = "yes"      -- Always show sign column
vim.opt.wrap = false            -- Don't wrap lines
vim.opt.tabstop = 4             -- Tab width
vim.opt.shiftwidth = 4          -- Indent width
vim.opt.expandtab = true        -- Use spaces instead of tabs
vim.opt.autoindent = true       -- Auto indent
vim.opt.smartindent = true      -- Smart indent
vim.opt.cursorline = true       -- Highlight current line
vim.opt.termguicolors = true    -- Enable 24-bit colors
vim.opt.showmode = false        -- Don't show mode (statusline will)
vim.opt.splitbelow = true       -- Horizontal splits go below
vim.opt.splitright = true       -- Vertical splits go right

-- ============================================================================
-- KEYMAPS (Beginner-friendly with AI assistance)
-- ============================================================================

-- Basic navigation helpers
vim.keymap.set("n", "<leader>h", ":help ", { desc = "Open help (type topic after)" })
vim.keymap.set("n", "<leader>?", ":WhichKey<CR>", { desc = "Show all keybindings" })

-- File operations
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<leader>wq", ":wq<CR>", { desc = "Save and quit" })

-- Window management
vim.keymap.set("n", "<leader>sv", ":vsplit<CR>", { desc = "Split vertically" })
vim.keymap.set("n", "<leader>sh", ":split<CR>", { desc = "Split horizontally" })
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "Move to bottom window" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "Move to top window" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

-- AI assistance keybindings (will be set up with plugins)
vim.keymap.set("n", "<leader>ai", "", { desc = "AI Assistant" })
vim.keymap.set("n", "<leader>ae", "", { desc = "AI Explain code" })
vim.keymap.set("n", "<leader>ac", "", { desc = "AI Chat" })
vim.keymap.set("n", "<leader>af", "", { desc = "AI Fix code" })
vim.keymap.set("n", "<leader>ag", "", { desc = "AI Generate code" })

-- ============================================================================
-- PLUGIN SETUP
-- ============================================================================

require("lazy").setup({
  -- Essential plugins for learning
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        plugins = {
          marks = true,
          registers = true,
          spelling = {
            enabled = true,
            suggestions = 20,
          },
        },
      })
    end,
  },

  -- Color scheme that matches your dotfiles
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true,
        styles = {
          sidebars = "transparent",
          floats = "transparent",
        },
      })
      vim.cmd.colorscheme("tokyonight")
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "tokyonight",
          globalstatus = true,
        },
        sections = {
          lualine_c = {
            { "filename", path = 1 },
          },
          lualine_x = {
            { "filetype" },
            { "encoding" },
            { "fileformat" },
          },
        },
      })
    end,
  },

  -- File tree
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = false,
        },
      })
      vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file explorer" })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({})
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Search in files" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Find help" })
    end,
  },

  -- Syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "query", "python", "javascript", "bash", "fish" },
        auto_install = true,
        highlight = {
          enable = true,
        },
        indent = {
          enable = true,
        },
      })
    end,
  },

  -- =========================================================================
  -- AI INTEGRATION PLUGINS
  -- =========================================================================

  -- Gen.nvim - Flexible local LLM integration
  {
    "David-Kunz/gen.nvim",
    config = function()
      require("gen").setup({
        model = "mistral:7b-instruct", -- Simpler model for reliability
        host = "localhost",
        port = "11434",
        display_mode = "float", -- Float window is easier
        show_prompt = true,
        show_model = true,
        no_auto_close = false,
        debug = true -- Enable debug to see what's happening
      })

      -- Custom prompts optimized for learning
      require("gen").prompts["Explain_Code"] = {
        prompt = "Explain this code in simple terms for someone learning programming. Break it down step by step:\n\n$text",
        replace = false,
      }
      
      require("gen").prompts["Fix_Code"] = {
        prompt = "Fix any issues in this code and explain what was wrong:\n\n$text",
        replace = true,
      }
      
      require("gen").prompts["Learn_Command"] = {
        prompt = "I'm learning Neovim. Can you explain how to do this: $input? Give me the exact commands and keystrokes.",
        replace = false,
      }
      
      require("gen").prompts["Neovim_Help"] = {
        prompt = "I'm new to Neovim and need help with: $input. Please explain in simple terms with examples.",
        replace = false,
      }

      -- Keybindings for AI assistance
      vim.keymap.set({"n", "v"}, "<leader>ae", ":Gen Explain_Code<CR>", { desc = "AI: Explain selected code" })
      vim.keymap.set({"n", "v"}, "<leader>af", ":Gen Fix_Code<CR>", { desc = "AI: Fix code issues" })
      vim.keymap.set("n", "<leader>ah", ":Gen Neovim_Help<CR>", { desc = "AI: Get Neovim help" })
      vim.keymap.set("n", "<leader>al", ":Gen Learn_Command<CR>", { desc = "AI: Learn Neovim command" })
      vim.keymap.set({"n", "v"}, "<leader>ag", ":Gen<CR>", { desc = "AI: Generate (all prompts)" })
    end,
  },

  -- ChatGPT alternative for local models (disabled until working)
  -- {
  --   "jackMort/ChatGPT.nvim",
  --   event = "VeryLazy",
  --   dependencies = {
  --     "MunifTanjim/nui.nvim",
  --     "nvim-lua/plenary.nvim",
  --     "folke/trouble.nvim",
  --     "nvim-telescope/telescope.nvim"
  --   },
  --   config = function()
  --     require("chatgpt").setup({
  --       api_host_cmd = "echo http://localhost:11434",
  --       api_key_cmd = "echo ollama", -- Dummy key for local
  --       openai_params = {
  --         model = "mistral:7b-instruct",
  --         frequency_penalty = 0,
  --         presence_penalty = 0,
  --         max_tokens = 3000,
  --         temperature = 0.2,
  --         top_p = 0.1,
  --         n = 1,
  --       },
  --       openai_edit_params = {
  --         model = "qwen2.5-coder:14b",
  --         frequency_penalty = 0,
  --         presence_penalty = 0,
  --         temperature = 0,
  --         top_p = 1,
  --         n = 1,
  --       },
  --       chat = {
  --         welcome_message = "Hi! I'm your local AI assistant. I can help you learn Neovim, explain code, and assist with programming tasks.",
  --         loading_text = "Loading your local AI...",
  --         question_sign = "",
  --         answer_sign = "🤖",
  --         max_line_length = 120,
  --         sessions_window = {
  --           active_sign = "  ",
  --           inactive_sign = "  ",
  --           current_line_sign = "",
  --         },
  --         keymaps = {
  --           close = "<C-c>",
  --           yank_last = "<C-y>",
  --           yank_last_code = "<C-k>",
  --           scroll_up = "<C-u>",
  --           scroll_down = "<C-d>",
  --         },
  --       },
  --       popup_layout = {
  --         default = "center",
  --         center = {
  --           width = "80%",
  --           height = "80%",
  --         },
  --       },
  --       popup_window = {
  --         border = {
  --           highlight = "FloatBorder",
  --           style = "rounded",
  --           text = {
  --             top = " ChatGPT ",
  --           },
  --         },
  --         win_options = {
  --           wrap = true,
  --           linebreak = true,
  --           foldcolumn = "1",
  --           winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
  --         },
  --         buf_options = {
  --           filetype = "markdown",
  --         },
  --       },
  --     })
  -- 
  --     -- Chat keybindings
  --     vim.keymap.set("n", "<leader>ac", ":ChatGPT<CR>", { desc = "AI: Open chat" })
  --     vim.keymap.set({"n", "v"}, "<leader>aa", ":ChatGPTActAs<CR>", { desc = "AI: Act as..." })
  --     vim.keymap.set({"n", "v"}, "<leader>ar", ":ChatGPTRun<CR>", { desc = "AI: Run action" })
  --   end,
  -- },

  -- Learning assistance (disabled for beginners)
  -- {
  --   "m4xshen/hardtime.nvim",
  --   dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
  --   opts = {
  --     disabled_filetypes = { "qf", "netrw", "NvimTree", "lazy", "mason", "oil" },
  --   },
  --   config = function(_, opts)
  --     require("hardtime").setup(opts)
  --   end,
  -- },

  -- Auto-completion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
        }),
      })
    end,
  },
})

-- ============================================================================
-- LEARNING TIPS SYSTEM
-- ============================================================================

-- Show helpful tips for new users
local function show_welcome_message()
  vim.notify([[
🌌 Welcome to Evil Space Neovim! 🌌

AI-Powered Learning Commands:
• <Space>ae - Explain selected code
• <Space>af - Fix code issues  
• <Space>ac - Open AI chat
• <Space>ah - Get Neovim help
• <Space>al - Learn commands

Quick Start:
• <Space>e - File explorer
• <Space>ff - Find files
• <Space>? - Show all keys
• <Space>h - Help system

Your AI models are ready:
• qwen2.5-coder:14b (coding)  
• mistral:7b-instruct (chat)
• codegemma:7b (backup)

Press <Space>? to see all shortcuts!
]], "Info", { title = "Evil Space Neovim" })
end

-- Show welcome message after a delay
vim.defer_fn(show_welcome_message, 1000)

-- ============================================================================
-- AUTOCOMMANDS (Helpful automation)
-- ============================================================================

-- Highlight yanked text
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Auto-save when leaving insert mode
vim.api.nvim_create_autocmd("InsertLeave", {
  desc = "Auto-save file when leaving insert mode",
  group = vim.api.nvim_create_augroup("auto-save", { clear = true }),
  callback = function()
    if vim.bo.modified and vim.bo.buftype == "" then
      vim.cmd("silent! write")
    end
  end,
})

-- Show cursor line only in active window
vim.api.nvim_create_autocmd({ "VimEnter", "WinEnter", "BufWinEnter" }, {
  desc = "Show cursor line in active window",
  group = vim.api.nvim_create_augroup("cursor-line", { clear = true }),
  callback = function()
    vim.opt_local.cursorline = true
  end,
})

vim.api.nvim_create_autocmd("WinLeave", {
  desc = "Hide cursor line in inactive window",
  group = vim.api.nvim_create_augroup("cursor-line", { clear = false }),
  callback = function()
    vim.opt_local.cursorline = false
  end,
})

-- ============================================================================
-- LEARNING MODE FUNCTIONS
-- ============================================================================

-- Function to show command explanations
function _G.explain_command(cmd)
  vim.cmd("Gen Neovim_Help " .. cmd)
end

-- Create learning commands
vim.api.nvim_create_user_command("Learn", function(opts)
  _G.explain_command(opts.args)
end, { nargs = 1, desc = "Learn about a Neovim command" })

vim.api.nvim_create_user_command("Tips", function()
  show_welcome_message()
end, { desc = "Show learning tips" })

-- ============================================================================
-- THEME INTEGRATION
-- ============================================================================

-- Match your dotfiles theme colors
vim.api.nvim_set_hl(0, "Normal", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NormalFloat", { bg = "NONE" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "NONE" })

-- Create command to switch between your AI models
vim.api.nvim_create_user_command("AiModel", function(opts)
  local model = opts.args
  if model == "" then
    print("Available models: qwen2.5-coder:14b, mistral:7b-instruct, codegemma:7b")
    return
  end
  
  require("gen").setup({ model = model })
  print("Switched AI model to: " .. model)
end, { nargs = "?", desc = "Switch AI model" })

-- Simple AI chat command
vim.api.nvim_create_user_command("AiChat", function(opts)
  local question = opts.args
  if question == "" then
    print("Usage: :AiChat your question here")
    return
  end
  
  -- Open a terminal and run ollama
  vim.cmd("split")
  vim.cmd("terminal ollama run mistral:7b-instruct '" .. question .. "'")
end, { nargs = "*", desc = "Ask AI a question" })

-- Add keybinding for simple AI chat
vim.keymap.set("n", "<leader>ac", ":AiChat ", { desc = "AI: Ask question (type after command)" })

print("🌌 Evil Space Neovim loaded! Press <Space>? for help or <Space>ac for AI chat") 