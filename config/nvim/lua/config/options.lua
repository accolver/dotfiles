-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Prioritize .git over LSP for root detection
vim.g.root_spec = { { ".git", "lua" }, "lsp", "cwd" }

-- Prefer project Prettier configs over generic formatting.
-- If no Prettier config exists for a project, LazyVim will not use Prettier there.
vim.g.lazyvim_prettier_needs_config = true
