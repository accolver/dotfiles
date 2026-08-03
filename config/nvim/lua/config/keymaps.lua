-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set('n', '<C-S-h>', '<cmd>bprevious<cr>', { desc = 'Previous Buffer' })
vim.keymap.set('n', '<C-S-l>', '<cmd>bnext<cr>', { desc = 'Next Buffer' })
