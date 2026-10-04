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
  local state = require("render-markdown.state")
  assert(#state.validate() == 0, "Invalid renderer configuration")
  local config = state.get(vim.api.nvim_get_current_buf())
  assert(#config.heading.icons > 0, "Heading icons are missing")
  assert(config.checkbox.enabled, "Checkbox rendering is disabled")
  assert(config.code.border == "thin", "Code blocks lack thin borders")

  -- Exercise the renderer on real Markdown, not just its option values.
  vim.cmd.enew()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, {
    "# Render check",
    "",
    "## Tasks",
    "",
    "- [ ] Pending",
    "- [x] Finished",
    "",
    "```lua",
    "print('hello')",
    "```",
    "",
    "| Name | Status |",
    "| --- | --- |",
    "| Sample | Ready |",
    "",
    "[Example](https://example.com)",
    "",
    "Cursor stays here.",
  })
  vim.bo.filetype = "markdown"
  vim.api.nvim_win_set_cursor(0, { 18, 0 })
  require("render-markdown").render({ buf = vim.api.nvim_get_current_buf() })
  local ns = vim.api.nvim_get_namespaces()["render-markdown.nvim"]
  assert(
    vim.wait(3000, function()
      return #vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, {}) > 0
    end, 50),
    "Renderer produced no decorations"
  )
  local groups = {}
  for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(0, ns, 0, -1, { details = true })) do
    local details = mark[4]
    if details.hl_group then
      groups[details.hl_group] = true
    end
    for _, chunk in ipairs(details.virt_text or {}) do
      for _, group in ipairs(type(chunk[2]) == "table" and chunk[2] or { chunk[2] }) do
        groups[group] = true
      end
    end
  end
  for _, group in ipairs({
    "RenderMarkdownH1",
    "RenderMarkdownChecked",
    "RenderMarkdownUnchecked",
    "RenderMarkdownCode",
    "RenderMarkdownCodeBorder",
    "RenderMarkdownTableRow",
    "RenderMarkdownLink",
  }) do
    assert(groups[group], "Missing rendered decoration: " .. group)
  end
end)
if not ok then
  vim.api.nvim_err_writeln(tostring(err))
  vim.cmd("cquit 1")
else
  print("PASS: quiet Markdown, richer rendering, and preserved other filetype defaults")
  vim.cmd("qa!")
end
