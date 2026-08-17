-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set('n', '<C-S-h>', '<cmd>bprevious<cr>', { desc = 'Previous Buffer' })
vim.keymap.set('n', '<C-S-l>', '<cmd>bnext<cr>', { desc = 'Next Buffer' })

local function current_git_root()
  local name = vim.api.nvim_buf_get_name(0)
  local dir = name ~= '' and vim.fn.fnamemodify(name, ':p:h') or vim.uv.cwd()
  local result = vim.system({ 'git', '-C', dir, 'rev-parse', '--show-toplevel' }, { text = true }):wait()

  if result.code == 0 and result.stdout and result.stdout ~= '' then
    return vim.trim(result.stdout)
  end

  local ok, lazyvim = pcall(require, 'lazyvim.util')
  if ok and type(lazyvim.root) == 'table' and lazyvim.root.get then
    return lazyvim.root.get()
  end
  if ok and type(lazyvim.root) == 'function' then
    return lazyvim.root()
  end

  return vim.uv.cwd()
end

vim.keymap.set({ 'n', 't' }, '<leader>ap', function()
  Snacks.terminal.toggle({ 'pi' }, {
    cwd = current_git_root(),
    auto_close = false,
    win = {
      style = 'terminal',
      position = 'right',
      width = 0.42,
    },
  })
end, { desc = 'Toggle Pi sidecar (repo root)' })
