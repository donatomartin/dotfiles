-- Define the command to edit init.lua
vim.api.nvim_create_user_command('EditInit', function()
  local init_path = vim.fn.stdpath('config') .. '/init.lua'  -- This will get the path to your init.lua
  vim.cmd('edit ' .. init_path)  -- Open init.lua for editing
end, {})

-- Ensure Packer is installed
local ensure_packer = function()
    local fn = vim.fn
    local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
    if fn.empty(fn.glob(install_path)) > 0 then
        fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
        vim.cmd('packadd packer.nvim')
        return true
    end
    return false
end

local packer_bootstrap = ensure_packer()

-- Auto-recompile when saving init.lua
vim.cmd([[autocmd BufWritePost init.lua source <afile> | PackerSync]])

-- Basic Settings
vim.o.number = true              -- Show line numbers
vim.o.relativenumber = true      -- Show relative numbers
vim.o.tabstop = 4                -- Tab width
vim.o.shiftwidth = 4             -- Indent width
vim.o.expandtab = true           -- Convert tabs to spaces
vim.o.clipboard = 'unnamedplus'  -- Use system clipboard
vim.o.mouse = 'a'                -- Enable mouse support
vim.o.termguicolors = true       -- Enable true color support
vim.o.wrap = false               -- Disable line wrapping

-- Leader Key
vim.g.mapleader = " " -- Space as the leader key

-- Packer Plugins
require('packer').startup(function(use)
    use 'wbthomason/packer.nvim'         -- Packer itself
    use 'dracula/vim'                    -- Dracula theme
    use 'nvim-lualine/lualine.nvim'      -- Status line
    use 'nvim-tree/nvim-tree.lua'        -- File explorer
    use 'neovim/nvim-lspconfig'          -- LSP support
    use 'hrsh7th/nvim-cmp'               -- Autocompletion
    use 'hrsh7th/cmp-nvim-lsp'           -- LSP source for nvim-cmp
    use 'L3MON4D3/LuaSnip'               -- Snippet engine
    use 'onsails/lspkind.nvim'           -- Icons for autocompletion
    use 'williamboman/mason.nvim'        -- Mason
    use 'williamboman/mason-lspconfig.nvim' -- Mason LSP integration
    if packer_bootstrap then
        require('packer').sync()
    end
end)

-- Dracula Theme
vim.cmd([[colorscheme dracula]])

-- Lualine (Status Line)
require('lualine').setup {
    options = {
        theme = 'dracula',
        section_separators = '',
        component_separators = '|',
    },
}

-- Nvim-Tree (File Explorer)
require('nvim-tree').setup()

-- Mason Setup and LSP Server Configuration
require('mason').setup()  -- Initialize Mason
require('mason-lspconfig').setup({
    ensure_installed = { "lua_ls", "pylsp", "clangd" },  -- Ensure the LSPs are installed
    automatic_installation = true,             -- Automatically install LSP servers
})

-- LSP (Language Server Protocol) Configuration
local lspconfig = require('lspconfig')

-- Lua LSP (lua_ls) setup
lspconfig.lua_ls.setup({
    on_attach = function(client, bufnr)
        -- You can add custom keymaps or configuration here
    end,
    settings = {
        Lua = {
            runtime = {
                version = 'LuaJIT',  -- Specify LuaJIT or Lua version
                path = vim.split(package.path, ';'),
            },
            diagnostics = {
                globals = {'vim'},  -- Add vim to globals to avoid "undefined global vim" error
            },
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
                enable = false,  -- Disable telemetry
            },
        },
    },
})

-- Python LSP (pylsp) setup
lspconfig.pylsp.setup({
    on_attach = function(client, bufnr)
        -- You can add custom keymaps or configuration here
    end,
})

-- C/C++ LSP (clangd) setup with proper GCC paths
lspconfig.clangd.setup({
    on_attach = function(client, bufnr)
        -- You can add custom keymaps or configuration here
    end,
    cmd = {
        "clangd",
        "--background-index",  -- Enable background indexing
        "--clang-tidy",  -- Enable clang-tidy
        "--header-insertion=never",  -- Disable automatic header insertion
        "--compile-commands-dir", "build",  -- Specify directory with compile_commands.json (optional)
    },
    settings = {
        clangd = {
            -- Additional arguments for clangd to help with GCC header detection
            extraArgs = {
                "--gcc-toolchain=C:/Users/Donato/scoop/apps/gcc/current",  -- Point to the GCC toolchain directory
                "--include-directory=C:/Users/Donato/scoop/apps/gcc/current/include",  -- GCC include path
                "--include-directory=C:/Users/Donato/scoop/apps/gcc/current/lib/gcc/x86_64-w64-mingw32/12.2.0/include",  -- GCC std include path (adjust based on your version)
            },
        },
    },
    env = {
        -- Set environment variables to help clangd find GCC headers
        PATH = "C:/Users/Donato/scoop/apps/gcc/current/bin;" .. os.getenv("PATH"),
    },
})
-- Autocompletion Setup (nvim-cmp)
local cmp = require('cmp')
local lspkind = require('lspkind')

cmp.setup({
    formatting = {
        format = lspkind.cmp_format({ with_text = true, maxwidth = 50 }),
    },
    snippet = {
        expand = function(args)
            require('luasnip').lsp_expand(args.body)
        end,
    },
    mapping = {
        ['<C-b>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<CR>'] = cmp.mapping.confirm({ select = true }),
    },
    sources = {
        { name = 'nvim_lsp' },
        { name = 'luasnip' },
    },
})

