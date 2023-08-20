# A simple notmuch plugin for neovim

# Devoloper notes

- neovim can decode json to lua objects
    - <https://neovim.io/doc/user/lua.html#vim.json>
    - notmuch can produce json output

- Overlay any
    ``Message-ID: <prcywohpuwgemcl6zr2wo7pt2andoohezun5baeqoecc744yzb@blfbxuckqonx>``
    with the sender, receiver, date, and title information
    - here we want to restrict to the string length between the apo's.
- Do the same for everything between
    ```notmuch
    Message-ID: <prcywohpuwgemcl6zr2wo7pt2andoohezun5baeqoecc744yzb@blfbxuckqonx>
    ```
- If the cursor is above such a line, provide a float that can be entered.
- On button press, open neomutt with the correct notmuch search being populated
