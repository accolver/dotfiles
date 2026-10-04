-- Run from the repo root with installed LazyVim plugins:
-- nvim --headless -u config/nvim/init.lua '+lua dofile("tests/nvim_markdown_test.lua")'
local ok, err = pcall(function()
  require("lazyvim.config").load("autocmds")
  require("lazy").load({ plugins = { "nvim-lint", "conform.nvim", "render-markdown.nvim" } })

  local lint = require("lint")
  local conform = require("conform")
  for _, ft in ipairs({ "markdown", "markdown.mdx" }) do
    assert(not vim.tbl_contains(lint._resolve_linter_by_ft(ft), "markdownlint-cli2"), ft .. " still runs markdownlint")
    assert(
      not vim.tbl_contains(conform.formatters_by_ft[ft], "markdownlint-cli2"),
      ft .. " still applies markdownlint fixes"
    )
    assert(vim.tbl_contains(conform.formatters_by_ft[ft], "prettier"), ft .. " lost Prettier")
    assert(vim.tbl_contains(conform.formatters_by_ft[ft], "markdown-toc"), ft .. " lost TOC formatting")
    vim.cmd.enew()
    vim.bo.filetype = ft
    assert(not vim.wo.spell, ft .. " still enables spellcheck")
    assert(vim.wo.wrap, ft .. " lost soft wrapping")
  end

  assert(vim.tbl_contains(lint._resolve_linter_by_ft("fish"), "fish"), "fish linting changed")
  vim.cmd.enew()
  vim.bo.filetype = "gitcommit"
  assert(vim.wo.spell, "gitcommit spellcheck changed")
  assert(require("render-markdown").get(), "Markdown rendering is disabled")
end)
if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
else
  print("PASS: quiet Markdown, preserved formatters/rendering and other filetype defaults")
  vim.cmd("qa!")
end
