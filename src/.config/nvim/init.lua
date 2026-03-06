-- Minimal Neovim setup with lazy.nvim + Neo-tree
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

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.g.mapleader = " "

require("lazy").setup({
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = { "Neotree" },
    opts = {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle filesystem left<cr>", desc = "Explorer" },
    },
  },
})

local terminal_height = 12

local function find_terminal_window()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "terminal" then
      return win
    end
  end
  return nil
end

local function open_or_focus_terminal()
  local term_win = find_terminal_window()
  if term_win then
    vim.api.nvim_set_current_win(term_win)
    vim.api.nvim_win_set_height(term_win, terminal_height)
    vim.cmd("startinsert")
    return
  end

  vim.cmd("botright " .. terminal_height .. "split")
  vim.cmd("terminal")
  vim.cmd("startinsert")
end

local function jump_between_code_and_terminal()
  if vim.bo.buftype == "terminal" then
    vim.cmd("wincmd p")
    if vim.bo.buftype == "terminal" then
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype ~= "terminal" then
          vim.api.nvim_set_current_win(win)
          break
        end
      end
    end
    return
  end

  open_or_focus_terminal()
end

vim.keymap.set("n", "<leader>t", open_or_focus_terminal, { desc = "Terminal: open bottom (12 lines)" })
vim.keymap.set("n", "<leader>j", jump_between_code_and_terminal, { desc = "Jump code <-> terminal" })
vim.keymap.set("t", "<leader>j", function()
  vim.cmd("stopinsert")
  jump_between_code_and_terminal()
end, { desc = "Jump code <-> terminal" })

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(data)
    if vim.fn.argc() ~= 1 then
      return
    end
    if vim.fn.isdirectory(data.file) ~= 1 then
      return
    end

    require("lazy").load({ plugins = { "neo-tree.nvim" } })
    vim.cmd("cd " .. vim.fn.fnameescape(data.file))
    vim.cmd("Neotree filesystem reveal left")
  end,
})
