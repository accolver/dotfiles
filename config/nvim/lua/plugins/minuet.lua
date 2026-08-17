local ignored_filetypes = {
  'Avante',
  'NvimTree',
  'TelescopePrompt',
  'alpha',
  'bigfile',
  'checkhealth',
  'dap-repl',
  'dotenv',
  'gitcommit',
  'gitrebase',
  'help',
  'lazy',
  'mason',
  'noice',
  'notify',
  'prompt',
  'snacks_picker_input',
  'snacks_terminal',
  'terminal',
  'text',
  'toggleterm',
  'trouble',
}

local function is_secret_buffer()
  local name = vim.api.nvim_buf_get_name(0):lower()
  local basename = vim.fs.basename(name)

  if basename == '' then
    return false
  end

  return basename:match('^%.env') ~= nil
    or basename:match('%.env$') ~= nil
    or basename:match('%.env%.') ~= nil
    or basename:match('secret') ~= nil
    or basename:match('credential') ~= nil
    or basename:match('password') ~= nil
    or basename:match('token') ~= nil
    or basename:match('id_rsa') ~= nil
    or basename:match('id_ed25519') ~= nil
    or basename:match('%.pem$') ~= nil
    or basename:match('%.key$') ~= nil
    or basename:match('%.p12$') ~= nil
    or basename:match('%.pfx$') ~= nil
    or basename:match('%.kdbx$') ~= nil
end

local function refresh_suggestion()
  local vt = require('minuet.virtualtext')
  vt.action.dismiss()
  vim.schedule(function()
    vt.action.next()
  end)
end

return {
  {
    'milanglacier/minuet-ai.nvim',
    event = 'InsertEnter',
    keys = {
      {
        '<leader>as',
        function()
          require('minuet.virtualtext').action.accept()
        end,
        mode = 'n',
        desc = 'AI accept suggestion (insert: Ctrl-g a)',
      },
      {
        '<leader>al',
        function()
          require('minuet.virtualtext').action.accept_line()
        end,
        mode = 'n',
        desc = 'AI accept line (insert: Ctrl-g l)',
      },
      {
        '<leader>aj',
        function()
          require('minuet.virtualtext').action.next()
        end,
        mode = 'n',
        desc = 'AI next suggestion (insert: Ctrl-g n)',
      },
      {
        '<leader>ak',
        function()
          require('minuet.virtualtext').action.prev()
        end,
        mode = 'n',
        desc = 'AI previous suggestion (insert: Ctrl-g p)',
      },
      {
        '<leader>ax',
        function()
          require('minuet.virtualtext').action.dismiss()
        end,
        mode = 'n',
        desc = 'AI dismiss suggestion (insert: Ctrl-g d)',
      },
      {
        '<leader>ag',
        function()
          vim.cmd('startinsert')
          vim.schedule(refresh_suggestion)
        end,
        mode = 'n',
        desc = 'AI fetch suggestion (insert: Ctrl-g g)',
      },
      {
        '<C-g>g',
        refresh_suggestion,
        mode = 'i',
        desc = 'AI fetch suggestion',
      },
    },
    config = function()
      local mc = require('minuet.config')

      require('minuet').setup({
        provider = 'openai_compatible',
        context_window = 32768, -- Minuet counts characters; roughly 8K tokens.
        context_ratio = 0.8,
        throttle = 250,
        debounce = 250,
        request_timeout = 6,
        n_completions = 2,
        notify = 'warn',
        virtualtext = {
          auto_trigger_ft = { '*' },
          auto_trigger_ignore_ft = ignored_filetypes,
          keymap = {
            accept = '<C-g>a',
            accept_line = '<C-g>l',
            next = '<C-g>n',
            prev = '<C-g>p',
            dismiss = '<C-g>d',
          },
          show_on_completion_menu = false,
        },
        enable_predicates = {
          function()
            return vim.bo.buftype == ''
              and vim.bo.modifiable
              and not vim.bo.readonly
              and not is_secret_buffer()
          end,
        },
        provider_options = {
          openai_compatible = {
            name = 'Fireworks',
            api_key = 'FIREWORKS_API_KEY',
            end_point = 'https://api.fireworks.ai/inference/v1/chat/completions',
            model = 'accounts/fireworks/models/deepseek-v4-flash-0731',
            stream = true,
            system = mc.default_system_prefix_first,
            few_shots = mc.default_few_shots_prefix_first,
            chat_input = mc.default_chat_input_prefix_first,
            optional = {
              max_tokens = 320,
              reasoning_effort = 'none',
            },
          },
        },
      })
    end,
  },
}
