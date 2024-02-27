-- TODO disable overlay when on the message line
-- TODO next up should, of course, be a telescope to display all known email mentions

local pickers = require'telescope.pickers'
local finders = require'telescope.finders'
local conf = require'telescope.config'.values
local actions = require'telescope.actions'
local action_state = require'telescope.actions.state'
local entry_display = require'telescope.pickers.entry_display'

local M = {}

M._keys = {}

function M.setup(config)
  -- setup each key to be a search pattern
  for _, entry in ipairs(config.keys) do
    local key = entry[1]
    local opts = { virt_text_pos = 'overlay',
                   search = '%s*%<([^%>]+)%>',
                   query = 'id:\'%s\'',
                   notmuch = 'id:\'%s\'',
                 }
    if entry[2] then for k,v in pairs(entry[2]) do
      opts[k] = v
    end end
    M._keys[key] = opts
  end
  M.ns = vim.api.nvim_create_namespace('notmuch')
  -- TODO toggle state
  vim.api.nvim_set_hl(M.ns, 'EmailDate'   , { fg = '#ffffff', bg = '#000077' })
  vim.api.nvim_set_hl(M.ns, 'EmailSubject', { fg = '#ffffff', bg = '#0000FF' })
  vim.api.nvim_set_hl(M.ns, 'EmailAuthors', { fg = '#ffffff', bg = '#000077' })
  vim.api.nvim_set_hl_ns(M.ns)

  local auid = vim.api.nvim_create_augroup('NotmuchGroup', { clear = true, })
  vim.api.nvim_create_autocmd({"InsertLeave", },
    { pattern = "",
      callback = function() M.replaceMessageId() end,
      desc = "notmuch.nvim, InsertLeave",
      group = auid,
    })
  vim.api.nvim_create_autocmd({"InsertEnter", },
    { pattern = "",
      callback = function() M.clear() end,
      desc = "notmuch.nvim, InsertLeave",
      group = auid,
    })
end

-- Lists all mail lines in the telescope picker

function M.pickMail(opts)
  opts = opts or {}
  local selection = nil
  local results = {}
  for _, idl in pairs(M._findMessageIDs()) do
    table.insert(results, idl)
  end
  local displayer = entry_display.create {
    separator = ' ',
    items = {
      { width = 10 },
      { width = 99 },
      { width = 59 },
    },
  }
  local make_display = function(entry)
    local e = entry.value
    local m = e.msg[1]
    return displayer {
      { m.date_relative, 'EmailDate' },
      { m.subject, 'EmailSubject' },
      { m.authors, 'EmailAuthors' },
    }
  end
  pickers.new(opts, {
    prompt_title = "Linked Emails",
    finder = finders.new_table {
        results = results,
        entry_maker = function(entry)
          local ln = entry.msg[1].date_relative..'  '..entry.msg[1].subject..'  '..entry.msg[1].authors
          return {
            value = entry,
            ordinal = ln,
            display = make_display,
            lnum = entry.line,
          }
        end,
    },
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        selection = action_state.get_selected_entry()
        M._openNeomutt(selection.value.line)
      end)
      return true
    end
  }):find()
  --M._openNeomutt(selection)
  --print("hello",selection)
end

function M.queryById(_, v, idstr)
  local command = 'notmuch search --format=json --output=summary --limit=1 '..string.format(v.query, idstr)
  local handle = io.popen(command)
  local result = {}
  if handle
    then
      result = vim.json.decode(handle:read('*a'))
      handle:close()
    end
  return result
end

-- | The actual "open neomutt" function.

function M._openNeomutt(line)
  for k,v in pairs(M._keys) do
    local idstr = line:match(k..v.search)
    if idstr then
      vim.api.nvim_command('terminal neomutt -f \'notmuch://?query=thread:{id:'..idstr..'}\'')
    end
  end
end

-- | Will open neomutt with the query.

function M.openNeomutt()
  local line = vim.api.nvim_get_current_line()
  M._openNeomutt(line)
end

-- This function provides a list of all lines with message IDs.

function M._findMessageIDs()
  local idlines = {}
  local lines = vim.api.nvim_buf_get_lines(0,0,-1,false)
  for row, line in pairs(lines) do
    for key, val in pairs (M._keys) do
      local from, idstr, to = line:match('()'..key..val.search..'()')
      local msg = nil
      if idstr then
        msg = M.queryById(key, val, idstr)
      end
      if (msg and msg[1]) then
        table.insert(idlines, { row=row, line=line, from=from, idstr=idstr, to=to, msg=msg })
      end
    end
  end
  return idlines
end

-- | Replaces message id's with the actual Email subject

function M.replaceMessageId()
  local idlines = M._findMessageIDs()
  for _, idl in pairs (idlines) do
    local len = math.max(0, idl.to-idl.from+1)
    local fillStr = string.format('%'..len..'s', '')
    local opts = {
      virt_text = { { idl.msg[1].date_relative..'  ', 'EmailDate' },
                    { idl.msg[1].subject, 'EmailSubject' },
                    { '  '..idl.msg[1].authors, 'EmailAuthors' },
                    { fillStr, 'String' },
                  },
      virt_text_pos = 'overlay',
      virt_text_hide = true,  -- original text will show up when, say, using visual mode
    }
    -- https://jdhao.github.io/2021/09/09/nvim_use_virtual_text/
    --
    -- TODO store extmark, to allow to toggle them on or off! (Or just delete all of them in the
    -- namespace and recreate if necessary.
    vim.api.nvim_buf_set_extmark(0, M.ns, idl.row-1, idl.from-1, opts)
  end
end

function M.clear()
  vim.api.nvim_buf_clear_namespace(0, M.ns, 0, -1)
end

return M



-- TODO this is the full date format, when using "notmuch show"
--local date = vim.fn.strptime('%a, %d %b %Y %T %z', mail1.headers.Date)
--local strdate = vim.fn.strftime('%F %T', date)
--msgline = string.format('%s  %s  %s', mail1.date_relative, mail1.subject, mail1.authors)
