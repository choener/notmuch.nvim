-- TODO disable overlay when on the message line

local M = {}

M._searchString = '()%`%`(%a*)%s*Message%-ID%:%s*%<([^%>]+)%>%s*%`%`()'

function M.setup(config)
  M.ns = vim.api.nvim_create_namespace('notmuch')
  -- TODO toggle state
  vim.api.nvim_set_hl(0, 'EmailDate'   , { fg = '#ffffff', bg = '#000077' })
  vim.api.nvim_set_hl(0, 'EmailSubject', { fg = '#ffffff', bg = '#0000FF' })
  vim.api.nvim_set_hl(0, 'EmailAuthors', { fg = '#ffffff', bg = '#000077' })
end

-- https://stackoverflow.com/questions/4105012/convert-a-string-date-to-a-timestamp
function M.fromTimeString(s)
end

function M.queryById(msgid)
  local command = 'notmuch search --format=json --output=summary --limit=1 id:'..msgid
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
  local from, how, idstr, to = line:match(M._searchString)
  if idstr then
    local h = io.popen('notmuch-mutt search -o ~/.cache/notmuch/mutt/extmark/ id:\''..idstr..'\'')
    if h then
      h:close()
    end
    vim.api.nvim_command('terminal neomutt -f ~/.cache/notmuch/mutt/extmark/')
  end
  -- 1. Be over a Message-ID line
  -- 2. Execute: notmuch-mutt search id:'the-id'
  -- 3. Execute: neomutt -f ~/.cache/notmuch/mutt/results/
  -- 4. Profit ;-)
end

function M.replaceMessageId()
  local lines = vim.api.nvim_buf_get_lines(0,0,-1, false)
  for row, line in pairs(lines)
    do
      -- Uses lua patterns, careful these are not regexes
      -- https://neovim.io/doc/user/luaref.html#lua-pattern
      -- https://www.lua.org/pil/20.2.html
      local from, how, idstr, to = line:match(M._searchString)
      if from
      then
        local msg = M.queryById('\''..idstr..'\'')
        local msgline = ''
        local mail1 = nil
        local len = 0
        if (msg and msg[1])
          then
            mail1 = msg[1]
            len = math.max(0, to-from+1)
            -- TODO this is the full date format, when using "notmuch show"
            --local date = vim.fn.strptime('%a, %d %b %Y %T %z', mail1.headers.Date)
            --local strdate = vim.fn.strftime('%F %T', date)
            --msgline = string.format('%s  %s  %s', mail1.date_relative, mail1.subject, mail1.authors)
            fillStr = string.format('%'..len..'s', '')
          end
        --local opts = {
        --  virt_text = {{string.format('%-'..len..'.'..len..'s',msgline), 'EmailOneLine'}},
        --  virt_text_pos = 'overlay'
        --}
        local opts = {
          virt_text = { { mail1.date_relative..'  ', 'EmailDate' },
                        { mail1.subject, 'EmailSubject' },
                        { '  '..mail1.authors, 'EmailAuthors' },
                        { fillStr, 'String' },
                      },
                      --{string.format('%-'..len..'s', msgline), 'EmailOneLine'} },
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

