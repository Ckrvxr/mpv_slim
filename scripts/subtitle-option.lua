-- subtitle-option.lua — Subtitle options menu for ModernZ

local input = require 'mp.input'

local function show_menu()
    input.select({
        items = {
            "Sub: Coming soon",
            "X Close",
        },
        keep_open = true,
        submit = function(id)
            if id == 1 then
                mp.osd_message("Subtitle Options: Coming soon", 2)
                input.terminate()
            elseif id == 2 then
                input.terminate()
            end
        end,
    })
end

mp.register_script_message("subtitle-option-show-menu", show_menu)
