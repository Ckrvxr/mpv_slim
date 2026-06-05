-- audio-option.lua — Audio options menu for ModernZ

local input = require 'mp.input'

-- SOFA filter paths
local config_dir = mp.command_native({"expand-path", "~~/"})
config_dir = string.gsub(config_dir, "\\", "/")
config_dir = string.gsub(config_dir, "(:)", "\\%1")
local path_SADIEII_D1_48K_24bit_256tap_FIR_SOFA = config_dir .. "/models/SADIEII_D1_48K_24bit_256tap_FIR_SOFA.sofa"
local path_SADIEII_D1_48K_24bit_03s_FIR_SOFA  = config_dir .. "/models/SADIEII_D1_48K_24bit_0.3s_FIR_SOFA.sofa"
local path_SADIEII_D2_48K_24bit_256tap_FIR_SOFA = config_dir .. "/models/SADIEII_D2_48K_24bit_256tap_FIR_SOFA.sofa"
local path_SADIEII_D2_48K_24bit_03s_FIR_SOFA  = config_dir .. "/models/SADIEII_D2_48K_24bit_0.3s_FIR_SOFA.sofa"
local filter_SADIEII_D1_48K_24bit_256tap_FIR_SOFA = "lavfi=[sofalizer=sofa='" .. path_SADIEII_D1_48K_24bit_256tap_FIR_SOFA .. "'],lavfi=[loudnorm=I=-20:TP=-1.5:LRA=14]"
local filter_SADIEII_D1_48K_24bit_03s_FIR_SOFA  = "lavfi=[sofalizer=sofa='" .. path_SADIEII_D1_48K_24bit_03s_FIR_SOFA  .. "'],lavfi=[loudnorm=I=-20:TP=-1.5:LRA=14]"
local filter_SADIEII_D2_48K_24bit_256tap_FIR_SOFA = "lavfi=[sofalizer=sofa='" .. path_SADIEII_D2_48K_24bit_256tap_FIR_SOFA .. "'],lavfi=[loudnorm=I=-20:TP=-1.5:LRA=14]"
local filter_SADIEII_D2_48K_24bit_03s_FIR_SOFA  = "lavfi=[sofalizer=sofa='" .. path_SADIEII_D2_48K_24bit_03s_FIR_SOFA  .. "'],lavfi=[loudnorm=I=-20:TP=-1.5:LRA=14]"

mp.set_property("user-data/sofa-filter-SADIEII_D1_48K_24bit_256tap_FIR_SOFA", filter_SADIEII_D1_48K_24bit_256tap_FIR_SOFA)
mp.set_property("user-data/sofa-filter-SADIEII_D1_48K_24bit_0.3s_FIR_SOFA", filter_SADIEII_D1_48K_24bit_03s_FIR_SOFA)
mp.set_property("user-data/sofa-filter-SADIEII_D2_48K_24bit_256tap_FIR_SOFA", filter_SADIEII_D2_48K_24bit_256tap_FIR_SOFA)
mp.set_property("user-data/sofa-filter-SADIEII_D2_48K_24bit_0.3s_FIR_SOFA", filter_SADIEII_D2_48K_24bit_03s_FIR_SOFA)
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
            (caf:find("D1_48K_24bit_256tap") and "[x] " or "[  ] ") .. "SADIEII_D1_48K_24bit_256tap_FIR_SOFA.sofa",
            (caf:find("D1_48K_24bit_0%.3s") and "[x] " or "[  ] ") .. "SADIEII_D1_48K_24bit_0.3s_FIR_SOFA.sofa",
            (caf:find("D2_48K_24bit_256tap") and "[x] " or "[  ] ") .. "SADIEII_D2_48K_24bit_256tap_FIR_SOFA.sofa",
            (caf:find("D2_48K_24bit_0%.3s") and "[x] " or "[  ] ") .. "SADIEII_D2_48K_24bit_0.3s_FIR_SOFA.sofa",
            (caf == "" and "[x] " or "[  ] ") .. "BYPASS",
            "───────────────────────────────────",
            "  <  Back to Upper Menu",
            "  x  Close Menu",
        },
        submit = function(id)
            if id == 1 then
                apply_filter(filter_SADIEII_D1_48K_24bit_256tap_FIR_SOFA, "SOFA: D1 256tap (anechoic)")
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 2 then
                apply_filter(filter_SADIEII_D1_48K_24bit_03s_FIR_SOFA, "SOFA: D1 0.3s (BBC reverb)")
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 3 then
                apply_filter(filter_SADIEII_D2_48K_24bit_256tap_FIR_SOFA, "SOFA: D2 256tap (anechoic)")
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 4 then
                apply_filter(filter_SADIEII_D2_48K_24bit_03s_FIR_SOFA, "SOFA: D2 0.3s (BBC reverb)")
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 5 then
                apply_filter("", "SOFA: off (native stereo)")
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 7 then  -- Back (skip separator at 6)
                input.terminate()
                mp.add_timeout(0.05, show_main_menu)
            elseif id == 8 then  -- Close
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
