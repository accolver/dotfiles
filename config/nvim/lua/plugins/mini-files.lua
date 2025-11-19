return {
  "nvim-mini/mini.files",
  opts = {
    options = {
      use_as_default_explorer = true,
    },
    windows = { preview = true },
  },
  config = function(_, opts)
    local MiniFiles = require("mini.files")
    MiniFiles.setup(opts)

    -- state variable to track visibility
    local show_all = false

    -- custom toggle function
    local function toggle_gitignore_filter()
      show_all = not show_all
      MiniFiles.refresh({
        content = {
          filter = show_all and nil or function(fs_entry)
            -- Default filter: hide .gitignored and dotfiles
            return not vim.startswith(fs_entry.name, ".")
          end,
        },
      })
      vim.notify("mini.files: showing " .. (show_all and "ALL files" or "filtered files"), vim.log.levels.INFO)
    end

    -- add toggle key (uppercase I by default)
    vim.api.nvim_create_autocmd("User", {
      pattern = "MiniFilesBufferCreate",
      callback = function(ev)
        vim.keymap.set("n", "I", toggle_gitignore_filter, {
          buffer = ev.data.buf_id,
          desc = "Toggle .gitignored visibility",
        })
      end,
    })
  end,
}
