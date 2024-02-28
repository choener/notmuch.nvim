# A simple notmuch plugin for neovim

- This plugin overlays "Message-ID" strings from emails in your text with the "date", "subject", and
"from" information from your emails.
- In addition, this information is used to run notmuch searches and display the results in neomutt.
- This makes it possible to annotate notes with email information and jump into email threads right from your notes.

## Requirements

- `notmuch`: <https://notmuchmail.org/>
- your emails to be indexed using `notmuch` itself
- neomutt for jumping to email threads

## Howto use

- Place a string starting with `Message-ID: <prefix@suffix>` in your text
- Whenever not in insert mode, the line starting with `Message-ID: ...` until the end of the line
will have an overlay with the string: `YYYY-MM-DD HH:MM Subject From| To...To`
- If the Message-ID is unknown, there will be no overlay

- `lua require('notmuch').openNeomutt` jumps to the email chain starting with the Message-ID
- `lua require('notmuch').pickMail` open a telescope picker with all starting emails based on Message-ID

Example:

`Message-ID: <prefix@suffix>` becomes  
`2024-02-29 22:00 Initial Release me@abc.def| you@abc.def`

## Configuration

Configure searches and colors for the overlays:
```
local nme = require'notmuch'
nme.setup({
  keys = {
    { 'NOTMUCH', },
    { 'Message%-ID:', { search = '%s*%<([^%>]+)%>',
                       query = 'id:\'%s\'',
                       notmuch = 'id:\'%s\'',
                     },
    },
  },
})

vim.api.nvim_set_hl(nme.ns, 'EmailDate'   , { fg = '#ffffff', bg = '#000099' })
vim.api.nvim_set_hl(nme.ns, 'EmailSubject', { fg = '#ffffff', bg = '#000077' })
vim.api.nvim_set_hl(nme.ns, 'EmailAuthors', { fg = '#ffffff', bg = '#000099' })
vim.api.nvim_set_hl_ns(nme.ns)
```

Configure shortcuts for direct jumps to neomutt or the mail picker (here in an after plugin):
```
local wk = require('which-key')
local ne = require('notmuch')
ne.replaceMessageId()
wk.register({
  ['<leader>'] = {
    t = { name = '+neorg',
      e = { ne.openNeomutt, 'open neomutt with Message-ID query' },
      E = { ne.pickMail, 'Open picker for all Mails' },
    },
  },
}, { noremap = true, silent = true, })

```



# Devoloper notes

- neovim can decode json to lua objects
    - <https://neovim.io/doc/user/lua.html#vim.json>
    - notmuch can produce json output
