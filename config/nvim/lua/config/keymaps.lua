-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Window navigation with <leader>h,j,k,l
vim.keymap.set("n", "<leader>h", "<C-w>h", { desc = "Move to left window" })
vim.keymap.set("n", "<leader>j", "<C-w>j", { desc = "Move to window below" })
vim.keymap.set("n", "<leader>k", "<C-w>k", { desc = "Move to window above" })
vim.keymap.set("n", "<leader>l", "<C-w>l", { desc = "Move to right window" })

-- Move Lazy to <leader>L (capital L)
vim.keymap.set("n", "<leader>L", "<cmd>Lazy<cr>", { desc = "Lazy" })

-- Use the built-in file browser instead of snacks explorer.
vim.keymap.set("n", "<leader>e", "<cmd>Ex<cr>", { desc = "Explorer" })
vim.keymap.set("n", "<leader>E", "<cmd>Ex<cr>", { desc = "Explorer" })
vim.keymap.set("n", "<leader>fe", "<cmd>Ex<cr>", { desc = "Explorer" })
vim.keymap.set("n", "<leader>fE", "<cmd>Ex<cr>", { desc = "Explorer" })
