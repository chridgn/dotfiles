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

require("lazy").setup({
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      filesystem = {
        filtered_items = {
          hide_dotfiles = false,
        },
      },
    },
  },
})

-- Window ID references set during IDE layout init
local bottom_terminal_win = nil
local claude_win = nil

-- Focus helpers
local function focus_editor()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "" then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
end

local function focus_terminal()
  if bottom_terminal_win and vim.api.nvim_win_is_valid(bottom_terminal_win) then
    vim.api.nvim_set_current_win(bottom_terminal_win)
    vim.cmd("startinsert")
  end
end

local function focus_claude()
  if claude_win and vim.api.nvim_win_is_valid(claude_win) then
    vim.api.nvim_set_current_win(claude_win)
    vim.cmd("startinsert")
  end
end

local function cycle_panes()
  local neo_tree_win, editor_win

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ft = vim.bo[buf].filetype
    local bt = vim.bo[buf].buftype
    if ft == "neo-tree" then
      neo_tree_win = win
    elseif bt == "" then
      editor_win = win
    end
  end

  local cur_buf = vim.api.nvim_get_current_buf()
  local cur_ft = vim.bo[cur_buf].filetype
  local cur_bt = vim.bo[cur_buf].buftype
  local cur_win = vim.api.nvim_get_current_win()

  if cur_ft == "neo-tree" then
    if editor_win then vim.api.nvim_set_current_win(editor_win) end
  elseif cur_bt == "" then
    focus_claude()
  elseif cur_win == claude_win then
    focus_terminal()
  elseif cur_win == bottom_terminal_win then
    if neo_tree_win then vim.api.nvim_set_current_win(neo_tree_win) end
  end
end

-- Keymaps
local function focus_neotree()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "neo-tree" then
      vim.api.nvim_set_current_win(win)
      return
    end
  end
end

vim.keymap.set("n", "<leader>i", focus_neotree, { desc = "Focus Neo-tree" })
vim.keymap.set("t", "<leader>i", function()
  vim.cmd("stopinsert")
  vim.defer_fn(focus_neotree, 10)
end, { desc = "Focus Neo-tree" })

vim.keymap.set("n", "<leader>e", focus_editor, { desc = "Focus editor" })
vim.keymap.set("t", "<leader>e", function()
  vim.cmd("stopinsert")
  vim.defer_fn(focus_editor, 10)
end, { desc = "Focus editor" })

vim.keymap.set("n", "<leader>t", focus_terminal, { desc = "Focus terminal" })
vim.keymap.set("t", "<leader>t", function()
  vim.cmd("stopinsert")
  vim.defer_fn(focus_terminal, 10)
end, { desc = "Focus terminal" })

vim.keymap.set("n", "<leader>c", focus_claude, { desc = "Focus Claude" })
vim.keymap.set("t", "<leader>c", function()
  vim.cmd("stopinsert")
  vim.defer_fn(focus_claude, 10)
end, { desc = "Focus Claude" })

vim.keymap.set("t", "<Esc><Esc>", "<C-\\><C-n>", { noremap = true, desc = "Exit terminal mode" })

vim.keymap.set("n", "<leader>q", function()
  if os.getenv("TMUX") then
    local session = vim.fn.system("tmux display-message -p '#S'"):gsub("%s+$", "")
    vim.fn.jobstart("tmux kill-session -t " .. session)
  else
    vim.cmd("qa!")
  end
end, { desc = "Quit all" })

vim.keymap.set("n", "<leader>j", cycle_panes, { desc = "Cycle panes" })
vim.keymap.set("t", "<leader>j", function()
  vim.cmd("stopinsert")
  vim.defer_fn(cycle_panes, 10)
end, { desc = "Cycle panes" })

-- Open IDE layout when nvim is invoked with a directory
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function(data)
    if vim.fn.isdirectory(data.file) ~= 1 then
      return
    end

    vim.cmd("cd " .. vim.fn.fnameescape(data.file))

    -- Bottom terminal (full width, 25% height)
    local height = math.floor(vim.o.lines * 0.25)
    vim.cmd("botright " .. height .. "split")
    vim.cmd("terminal")
    bottom_terminal_win = vim.api.nvim_get_current_win()

    -- Return to top, open Neo-tree on the left
    vim.cmd("wincmd k")
    vim.cmd("Neotree filesystem reveal left")

    -- Move to editor (right of Neo-tree), then split right for Claude
    vim.cmd("wincmd l")
    vim.cmd("rightbelow vsplit")
    vim.cmd("terminal claude")
    claude_win = vim.api.nvim_get_current_win()

    -- Land on the editor
    vim.cmd("wincmd h")
  end,
})
