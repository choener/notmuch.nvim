--nm = require'notmuch/init.lua'

-- TODO disable overlay when on the message line

local M = {}

function M.setup(config)
  M.ns = vim.api.nvim_create_namespace('notmuch')
  -- TODO toggle state
  vim.api.nvim_set_hl(0, 'EmailOneLine', { fg = '#ffffff', bg = '#0000FF' })
end

-- https://stackoverflow.com/questions/4105012/convert-a-string-date-to-a-timestamp
function M.fromTimeString(s)
end

function M.queryById(msgid)
  local command = 'notmuch show --format=json --entire-thread=false id:'..msgid
  local handle = io.popen(command)
  local result = {}
  if handle ~= nil
    then
      result = vim.json.decode(handle:read('*a'))
      handle:close()
    end
  return result
end

function M.findMessageIds()
  local lines = vim.api.nvim_buf_get_lines(0,0,-1, false)
  for row, line in pairs(lines)
    do
      -- Uses lua patterns, careful these are not regexes
      -- https://neovim.io/doc/user/luaref.html#lua-pattern
      -- https://www.lua.org/pil/20.2.html
      local from, id1, id2, to = line:match('()%`%`Message%-ID%:%s?%<(%w+)%@(%w+)%>%s*%`%`()')
      if from
      then
        local msg = M.queryById(id1..'@'..id2)
        local msgline = ''
        local mail1 = msg[1][1][1]
        local len = 0
        if mail1 ~= nil
          then
            len = math.max(0, to-from+1)
            msgline = string.format('%s   %s', mail1.headers.Date, mail1.headers.Subject)
          end
        -- TODO call to notmuch to get the actual message
        --print(row,from,to,id1,'@',id2)
        --print(vim.inspect(msg[1][1][1].headers))
        -- TODO use own highlight group ...
        local opts = {
          virt_text={{string.format('%-'..len..'.'..len..'s',msgline), 'EmailOneLine'}}, -- 'String' is the highlight group
          virt_text_pos='overlay'
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

