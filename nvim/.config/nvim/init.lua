-- =====================
-- Leader & basic opts
-- =====================
vim.g.mapleader = " "
vim.g.maplocalleader = ","

local o, wo, bo = vim.o, vim.wo, vim.bo

-- UI
wo.number = true
wo.relativenumber = true
o.undofile = true
o.termguicolors = true
wo.signcolumn = "yes"
o.cursorline = true

-- Editing
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.smartindent = true
o.wrap = false

-- Search
o.ignorecase = true
o.smartcase = true

-- Misc
o.mouse = "a"
o.splitright = true
o.splitbelow = true

-- Requires nvim > 0.10
vim.g.clipboard = {
  name = "osc52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
    ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
  },
}


-- Create missing directories before saving
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("MKDIR_ON_SAVE", { clear = true }),
  callback = function(args)
    local path = vim.fn.fnamemodify(args.match, ":p:h")
    if path ~= nil and path ~= "" and not vim.loop.fs_stat(path) then
      vim.fn.mkdir(path, "p")
    end
  end,
})

-- =====================
-- Bootstrap lazy.nvim
-- =====================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- =====================
-- Plugins
-- =====================
require("lazy").setup({

  { "nvim-lua/plenary.nvim" },
  { "nvim-tree/nvim-web-devicons" },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = {
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      integrations = {
        treesitter = true,
        telescope = true,
        gitsigns = true,
        which_key = true,
        native_lsp = { enabled = true },
        cmp = true,
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Statusline & buffer line
  { "nvim-lualine/lualine.nvim", config = function()
      require("lualine").setup({ options = { globalstatus = true, theme = "catppuccin" } })
    end },

  -- Persistence
  {
    "folke/persistence.nvim",
    event = "BufReadPre", -- load before reading buffers
    opts = {},
  },

  -- Gitsigns
  { "lewis6991/gitsigns.nvim", opts = {} },

  -- Which-key
  { "folke/which-key.nvim", event = "VeryLazy", opts = { preset = "modern" } },

  -- Comments, pairs, surround
  { "numToStr/Comment.nvim", opts = {} },
  { "windwp/nvim-autopairs", event = "InsertEnter", config = function()
      require("nvim-autopairs").setup({})
    end },
  { "kylechui/nvim-surround", version = "*", opts = {} },


  -- Telescope + native fzf
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },
  { "nvim-telescope/telescope-fzf-native.nvim",
    build = function()
      local ok = pcall(vim.cmd, "!cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build")
      if not ok then
        -- fallback: try make if cmake not present
        pcall(vim.cmd, "!make")
      end
    end,
    cond = function()
      return vim.fn.executable("make") == 1 or vim.fn.executable("cmake") == 1
    end,
    config = function()
      pcall(function() require("telescope").load_extension("fzf") end)
    end,
  },

  -- Treesitter
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate", config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = { "lua", "vim", "vimdoc", "bash", "json", "yaml", "markdown", "markdown_inline", "python", "go", "javascript", "typescript", "html", "css" },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end },
})

-- =====================
-- Plugin configurations
-- =====================

-- Telescope defaults & keymaps
local telescope = require("telescope")
telescope.setup({
  defaults = {
    mappings = {
      i = { ["<C-j>"] = require("telescope.actions").move_selection_next,
            ["<C-k>"] = require("telescope.actions").move_selection_previous },
    },
  },
})

local map = vim.keymap.set
local builtin = require("telescope.builtin")
map("n", "<leader>ff", builtin.find_files, { desc = "Find files"})
map("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
map("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
map("n", "<leader>fh", builtin.help_tags, { desc = "Help" })
map("n", "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<cr>", { desc = "Find all" })

local persistence = require("persistence")

map("n", "<leader>qs", function() persistence.load() end, { desc = "Restore last session" })
map("n", "<leader>ql", function() persistence.load({ last = true }) end, { desc = "Restore last session (alternate)" })
map("n", "<leader>qd", function() persistence.stop() end, { desc = "Stop session saving" })


-- =====================
-- Quality-of-life keymaps
-- =====================

map({"n","v"}, "<leader>y", [["+y]], { desc = "Yank to system clipboard" })
map({"n","v"}, "<leader>p", [["+p]], { desc = "Paste from system clipboard" })
map({"n","v"}, "<C-c>", ":%y+<CR>", { desc = "Yank file to system clipboard" })
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete buffer" })
map("n", "<leader>qq", ":qa!<CR>", { desc = "Quit all!" })
map("n", "<Esc>", ":noh<CR>", { desc = "Clear search hl" })

-- Final niceties
vim.api.nvim_create_user_command("ReloadConfig", function()
  for name,_ in pairs(package.loaded) do
    if name:match('^user') or name:match('^plugins') then package.loaded[name] = nil end
  end
  dofile(vim.env.MYVIMRC)
  print("Config reloaded!")
end, {})

