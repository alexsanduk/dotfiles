-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Expand %% in command-line mode to the current file's directory
vim.cmd("cnoremap <expr> %% getcmdtype() == ':' ? expand('%:h').'/' : '%%'")

-- Close current buffer
vim.keymap.set("n", "Q", "<cmd>bdelete<CR>", { silent = true, noremap = true })
