-- audio-option.lua — Audio options menu for ModernZ

local input = require 'mp.input'

-- SOFA filter paths
local config_dir = mp.command_native({"expand-path", "~~/"})
config_dir = string.gsub(config_dir, "\\", "/")
config_dir = string.gsub(config_dir, "(:)", "\\%1")
local path_256tap = config_dir .. "/models/SADIEII_D1_48K_24bit_256tap_FIR_SOFA.sofa"
local path_03s    = config_dir .. "/models/SADIEII_D1_48K_24bit_0.3s_FIR_SOFA.sofa"
local filter_256tap = "lavfi=[sofalizer=sofa='" .. path_256tap .. "'],lavfi=[loudnorm=I=-20:TP=-1.5:LRA=14]"
local filter_03s    = "lavfi=[sofalizer=sofa='" .. path_03s    .. "'],lavfi=[loudnorm=I=-20:TP=-1.5:LRA=14]"

mp.set_property("user-data/sofa-filter-256tap", filter_256tap)
mp.set_property("user-data/sofa-filter-03s", filter_03s)
mp.set_property("user-data/sofa-filter-bypass", "")

local function apply_filter(filter_str, msg)
    mp.set_property("af", filter_str)
    mp.osd_message(msg, 2)
end

-- SOFA submenu
local function show_sofa_menu()
    local caf = mp.get_property("af", "")
    input.select({
        items = {
            (caf:find("256tap") and "[x] " or "[  ] ") .. "SADIEII_D1_48K_24bit_256tap_FIR_SOFA.sofa",
            (caf:find("0%.3s") and "[x] " or "[  ] ") .. "SADIEII_D1_48K_24bit_0.3s_FIR_SOFA.sofa",
            (caf == "" and "[x] " or "[  ] ") .. "BYPASS",
            "───────────────────────────────────",
            "  <  Back to Upper Menu",
            "  x  Close Menu",
        },
        submit = function(id)
            if id == 1 then
                apply_filter(filter_256tap, "SOFA: 256tap (anechoic)")
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 2 then
                apply_filter(filter_03s, "SOFA: 0.3s (BBC reverb)")
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 3 then
                apply_filter("", "SOFA: off (native stereo)")
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 4 then
                input.terminate()
                mp.add_timeout(0.05, show_main_menu)
            elseif id == 5 then
                input.terminate()
            end
        end,
    })
end

-- Main menu
local function show_main_menu()
    input.select({
        items = {
            "1. Audio Tracks",
            "2. SOFA Spatial Audio",
            "3. EQ Equalizer",
        },
        submit = function(id)
            if id == 1 then
                mp.osd_message("Audio Tracks: Coming soon", 2)
                input.terminate()
            elseif id == 2 then
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 3 then
                mp.osd_message("EQ Equalizer: Coming soon", 2)
                input.terminate()
            end
        end,
    })
end

mp.register_script_message("audio-option-show-menu", show_main_menu)

-- M key cycles 256tap -> 0.3s -> bypass
local state = 0
local function cycle_sofa()
    if state == 0 then
        apply_filter(filter_256tap, "SOFA: 256tap (anechoic)")
        state = 1
    elseif state == 1 then
        apply_filter(filter_03s, "SOFA: 0.3s (BBC reverb)")
        state = 2
    else
        apply_filter("", "SOFA: off (native stereo)")
        state = 0
    end
end
mp.add_key_binding("M", "toggle_sofa_filter", cycle_sofa)
