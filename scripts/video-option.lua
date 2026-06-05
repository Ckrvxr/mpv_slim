-- video-option.lua — Video options menu for ModernZ

local input = require 'mp.input'

local function show_menu()
    input.select({
        items = {
            "Video: Coming soon",
            "X Close",
        },
        keep_open = true,
        submit = function(id)
            if id == 1 then
                mp.osd_message("Video Options: Coming soon", 2)
                input.terminate()
            elseif id == 2 then
                input.terminate()
            end
        end,
    })
end

mp.register_script_message("video-option-show-menu", show_menu)
