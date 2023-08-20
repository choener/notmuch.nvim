-- TODO disable overlay when on the message line
-- TODO next up should, of course, be a telescope to display all known email mentions

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
  vim.api.nvim_set_hl(0, 'EmailDate'   , { fg = '#ffffff', bg = '#000077' })
  vim.api.nvim_set_hl(0, 'EmailSubject', { fg = '#ffffff', bg = '#0000FF' })
  vim.api.nvim_set_hl(0, 'EmailAuthors', { fg = '#ffffff', bg = '#000077' })
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

function M.openNeomutt()
  local line = vim.api.nvim_get_current_line()
  for k,v in pairs(M._keys) do
    local idstr = line:match(k..v.search)
    if idstr then
      local h = io.popen('notmuch-mutt search -o ~/.cache/notmuch/mutt/extmark/ thread:{id:\''..idstr..'\'}')
      if h then
        h:close()
      end
      vim.api.nvim_command('terminal neomutt -f ~/.cache/notmuch/mutt/extmark/')
      break
    end
  end
end

function M.replaceMessageId()
  local lines = vim.api.nvim_buf_get_lines(0,0,-1, false)
  for row, line in pairs(lines)
    do
      -- Uses lua patterns, careful these are not regexes
      -- https://neovim.io/doc/user/luaref.html#lua-pattern
      -- https://www.lua.org/pil/20.2.html
      local key, val = nil, nil
      local from, idstr, to = nil, nil, nil
      for k,v in pairs(M._keys) do
        from, idstr, to = line:match('()'..k..v.search..'()')
        if idstr then
          key = k
          val = v
          break
        end
      end
      local msg = nil
      if idstr then
        msg = M.queryById(key, val, idstr)
      end
      if (msg and msg[1]) then
        local len = math.max(0, to-from+1)
        local fillStr = string.format('%'..len..'s', '')
        local opts = {
          virt_text = { { msg[1].date_relative..'  ', 'EmailDate' },
                        { msg[1].subject, 'EmailSubject' },
                        { '  '..msg[1].authors, 'EmailAuthors' },
                        { fillStr, 'String' },
                      },
          virt_text_pos = 'overlay',
          virt_text_hide = true,  -- original text will show up when, say, using visual mode
        }
        -- https://jdhao.github.io/2021/09/09/nvim_use_virtual_text/
        --
        -- TODO store extmark, to allow to toggle them on or off! (Or just delete all of them in the
        -- namespace and recreate if necessary.
        vim.api.nvim_buf_set_extmark(0, M.ns, row-1, from-1, opts)
      end
    end
end

return M



-- TODO this is the full date format, when using "notmuch show"
--local date = vim.fn.strptime('%a, %d %b %Y %T %z', mail1.headers.Date)
--local strdate = vim.fn.strftime('%F %T', date)
--msgline = string.format('%s  %s  %s', mail1.date_relative, mail1.subject, mail1.authors)
