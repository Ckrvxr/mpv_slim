-- audio-option.lua — Audio options menu for ModernZ (state machine)

local input = require 'mp.input'

-- SOFA filter paths
local config_dir = mp.command_native({"expand-path", "~~/"})
config_dir = string.gsub(config_dir, "\\", "/")
config_dir = string.gsub(config_dir, "(:)", "\\%1")
local path_SADIEII_D1_48K_24bit_256tap_FIR_SOFA = config_dir .. "/models/SADIEII_D1_48K_24bit_256tap_FIR_SOFA.sofa"
local path_SADIEII_D1_48K_24bit_03s_FIR_SOFA  = config_dir .. "/models/SADIEII_D1_48K_24bit_0.3s_FIR_SOFA.sofa"
local path_SADIEII_D2_48K_24bit_256tap_FIR_SOFA = config_dir .. "/models/SADIEII_D2_48K_24bit_256tap_FIR_SOFA.sofa"
local path_SADIEII_D2_48K_24bit_03s_FIR_SOFA  = config_dir .. "/models/SADIEII_D2_48K_24bit_0.3s_FIR_SOFA.sofa"
local sofalizer_SADIEII_D1_48K_24bit_256tap_FIR_SOFA = "lavfi=[sofalizer=sofa='" .. path_SADIEII_D1_48K_24bit_256tap_FIR_SOFA .. "']"
local sofalizer_SADIEII_D1_48K_24bit_03s_FIR_SOFA  = "lavfi=[sofalizer=sofa='" .. path_SADIEII_D1_48K_24bit_03s_FIR_SOFA  .. "']"
local sofalizer_SADIEII_D2_48K_24bit_256tap_FIR_SOFA = "lavfi=[sofalizer=sofa='" .. path_SADIEII_D2_48K_24bit_256tap_FIR_SOFA .. "']"
local sofalizer_SADIEII_D2_48K_24bit_03s_FIR_SOFA  = "lavfi=[sofalizer=sofa='" .. path_SADIEII_D2_48K_24bit_03s_FIR_SOFA  .. "']"

mp.set_property("user-data/sofalizer-SADIEII_D1_48K_24bit_256tap_FIR_SOFA", sofalizer_SADIEII_D1_48K_24bit_256tap_FIR_SOFA)
mp.set_property("user-data/sofalizer-SADIEII_D1_48K_24bit_0.3s_FIR_SOFA", sofalizer_SADIEII_D1_48K_24bit_03s_FIR_SOFA)
mp.set_property("user-data/sofalizer-SADIEII_D2_48K_24bit_256tap_FIR_SOFA", sofalizer_SADIEII_D2_48K_24bit_256tap_FIR_SOFA)
mp.set_property("user-data/sofalizer-SADIEII_D2_48K_24bit_0.3s_FIR_SOFA", sofalizer_SADIEII_D2_48K_24bit_03s_FIR_SOFA)
mp.set_property("user-data/sofalizer-bypass", "")

local sofa_presets = {
    { id = "D1_256tap", label = "SADIEII_D1_48K_24bit_256tap_FIR_SOFA.sofa",    filter = sofalizer_SADIEII_D1_48K_24bit_256tap_FIR_SOFA },
    { id = "D1_0.3s",   label = "SADIEII_D1_48K_24bit_0.3s_FIR_SOFA.sofa",    filter = sofalizer_SADIEII_D1_48K_24bit_03s_FIR_SOFA },
    { id = "D2_256tap", label = "SADIEII_D2_48K_24bit_256tap_FIR_SOFA.sofa",    filter = sofalizer_SADIEII_D2_48K_24bit_256tap_FIR_SOFA },
    { id = "D2_0.3s",   label = "SADIEII_D2_48K_24bit_0.3s_FIR_SOFA.sofa",    filter = sofalizer_SADIEII_D2_48K_24bit_03s_FIR_SOFA },
}

local loudnorm_presets = {
    { id = "OFF", label = "OFF", filter = "" },
    { cat = "Broadcasting Standards" },
    { id = "EBU_R128",    label = "I=-24.0:TP=-1.0:LRA=7.0           EBU R128 (Europe)",  filter = "lavfi=[loudnorm=I=-24.0:TP=-1.0:LRA=7.0]" },
    { id = "ATSC_A85",    label = "I=-24.0:TP=-2.0:LRA=10.0        ATSC A/85 (North America)", filter = "lavfi=[loudnorm=I=-24.0:TP=-2.0:LRA=10.0]" },
    { id = "GY_T_282",    label = "I=-24.0:TP=-2.0:LRA=10.0        GY/T 282 (China)", filter = "lavfi=[loudnorm=I=-24.0:TP=-2.0:LRA=10.0]" },
    { id = "ARIB_TR_B32", label = "I=-24.0:TP=-1.0:LRA=7.0           ARIB TR-B32 (Japan)",  filter = "lavfi=[loudnorm=I=-24.0:TP=-1.0:LRA=7.0]" },
    { id = "FreeTV_OP59", label = "I=-24.0:TP=-2.0:LRA=10.0        FreeTV OP59 (Australia)", filter = "lavfi=[loudnorm=I=-24.0:TP=-2.0:LRA=10.0]" },
    { id = "KCC",         label = "I=-24.0:TP=-1.0:LRA=8.0           KCC Notice (South Korea)",  filter = "lavfi=[loudnorm=I=-24.0:TP=-1.0:LRA=8.0]" },
    { id = "NBR_15603",   label = "I=-24.0:TP=-1.0:LRA=7.0           NBR 15603 (Brazil)",  filter = "lavfi=[loudnorm=I=-24.0:TP=-1.0:LRA=7.0]" },
    { cat = "Video Streaming & OTT" },
    { id = "Netflix_Dialogue",    label = "I=-27.0:TP=-2.0:LRA=10.0        Netflix (Dialogue)", filter = "lavfi=[loudnorm=I=-27.0:TP=-2.0:LRA=10.0]" },
    { id = "Netflix_NonDialogue", label = "I=-24.0:TP=-2.0:LRA=14.0        Netflix (Non-Dialogue)", filter = "lavfi=[loudnorm=I=-24.0:TP=-2.0:LRA=14.0]" },
    { id = "Disney_Plus",         label = "I=-27.0:TP=-2.0:LRA=12.0        Disney+", filter = "lavfi=[loudnorm=I=-27.0:TP=-2.0:LRA=12.0]" },
    { id = "Apple_TV_Plus",       label = "I=-24.0:TP=-1.0:LRA=10.0        Apple TV+", filter = "lavfi=[loudnorm=I=-24.0:TP=-1.0:LRA=10.0]" },
    { id = "Amazon_Prime_Video",  label = "I=-24.0:TP=-2.0:LRA=12.0        Amazon Prime Video", filter = "lavfi=[loudnorm=I=-24.0:TP=-2.0:LRA=12.0]" },
    { id = "YouTube_Video",       label = "I=-14.0:TP=-1.0:LRA=11.0        YouTube", filter = "lavfi=[loudnorm=I=-14.0:TP=-1.0:LRA=11.0]" },
    { id = "Hulu",                label = "I=-24.0:TP=-2.0:LRA=10.0        Hulu", filter = "lavfi=[loudnorm=I=-24.0:TP=-2.0:LRA=10.0]" },
    { cat = "Music & Audio Streaming" },
    { id = "AES_TD1008",      label = "I=-16.0:TP=-1.0:LRA=12.0        AES TD1008 (OTT)", filter = "lavfi=[loudnorm=I=-16.0:TP=-1.0:LRA=12.0]" },
    { id = "Apple_Music",     label = "I=-16.0:TP=-1.0:LRA=12.0        Apple Music (Sound Check)", filter = "lavfi=[loudnorm=I=-16.0:TP=-1.0:LRA=12.0]" },
    { id = "Spotify_Normal",  label = "I=-14.0:TP=-1.0:LRA=11.0        Spotify (Normal)", filter = "lavfi=[loudnorm=I=-14.0:TP=-1.0:LRA=11.0]" },
    { id = "Spotify_Loud",    label = "I=-11.0:TP=-2.0:LRA=8.0           Spotify (Loud)",  filter = "lavfi=[loudnorm=I=-11.0:TP=-2.0:LRA=8.0]" },
    { id = "Spotify_Quiet",   label = "I=-19.0:TP=-1.0:LRA=14.0        Spotify (Quiet)", filter = "lavfi=[loudnorm=I=-19.0:TP=-1.0:LRA=14.0]" },
    { id = "Tidal_HiFi",      label = "I=-14.0:TP=-1.0:LRA=12.0        Tidal HiFi", filter = "lavfi=[loudnorm=I=-14.0:TP=-1.0:LRA=12.0]" },
    { id = "Amazon_Music",    label = "I=-14.0:TP=-1.0:LRA=11.0        Amazon Music", filter = "lavfi=[loudnorm=I=-14.0:TP=-1.0:LRA=11.0]" },
    { id = "Deezer",          label = "I=-14.0:TP=-1.0:LRA=11.0        Deezer", filter = "lavfi=[loudnorm=I=-14.0:TP=-1.0:LRA=11.0]" },
    { cat = "Cinema & Games" },
    { id = "Cinema_Indie",        label = "I=-18.0:TP=-2.0:LRA=18.0        Cinema / Indie Feature", filter = "lavfi=[loudnorm=I=-18.0:TP=-2.0:LRA=18.0]" },
    { id = "Sony_PS5",            label = "I=-24.0:TP=-2.0:LRA=15.0        Sony PlayStation 5 (ASWG)", filter = "lavfi=[loudnorm=I=-24.0:TP=-2.0:LRA=15.0]" },
    { id = "Xbox",                label = "I=-23.0:TP=-2.0:LRA=14.0        Xbox (Game Audio)", filter = "lavfi=[loudnorm=I=-23.0:TP=-2.0:LRA=14.0]" },
}

-- Filter chain state
local current_sofalizer = ""
local current_loudnorm = ""
local current_loudnorm_id = nil

local function update_chain()
    if current_sofalizer == "" and current_loudnorm == "" then
        mp.set_property("af", "")
    elseif current_sofalizer == "" then
        mp.set_property("af", current_loudnorm)
    elseif current_loudnorm == "" then
        mp.set_property("af", current_sofalizer)
    else
        mp.set_property("af", current_sofalizer .. "," .. current_loudnorm)
    end
end

-- Defaults persistence
local defaults_path = "~~/script-opts/audio-option-defaults.lua"

local function save_defaults()
    local path = mp.command_native({"expand-path", defaults_path})
    local f = io.open(path, "w")
    if not f then
        mp.msg.error("Save failed: cannot open " .. path)
        mp.osd_message("Save failed!", 2)
        return
    end
    f:write("return {\n")
    f:write(string.format("    sofalizer = %s,\n", current_sofalizer == "" and "''" or string.format("%q", current_sofalizer)))
    f:write(string.format("    loudnorm = %s,\n", current_loudnorm == "" and "''" or string.format("%q", current_loudnorm)))
    f:write(string.format("    loudnorm_id = %s,\n", current_loudnorm_id and string.format("%q", current_loudnorm_id) or "nil"))
    f:write("}\n")
    f:close()
    mp.osd_message("Defaults saved", 2)
end

local function load_defaults()
    local path = mp.command_native({"expand-path", defaults_path})
    local ok, defaults = pcall(dofile, path)
    if ok and defaults then
        if defaults.sofalizer then
            current_sofalizer = defaults.sofalizer
        end
        if defaults.loudnorm then
            current_loudnorm = defaults.loudnorm
            current_loudnorm_id = defaults.loudnorm_id
        end
        if defaults.sofalizer or defaults.loudnorm then
            update_chain()
        end
    end
end

local menu_state = "main"

local function show_menu()
    local items = {}
    local id_map = {}

    if menu_state == "main" then
        items = {
            "1. Audio Tracks",
            "2. SOFA Spatial Audio",
            "3. Loudness Normalization",
            "4. EQ Equalizer",
        }

    elseif menu_state == "sofa" then
        for i, p in ipairs(sofa_presets) do
            items[i] = (current_sofalizer == p.filter and "[x] " or "[  ] ") .. p.label
        end
        items[#sofa_presets + 1] = (current_sofalizer == "" and "[x] " or "[  ] ") .. "BYPASS"
        items[#sofa_presets + 2] = "───────────────────────────────────"
        items[#sofa_presets + 3] = "  +  Save Selected as Default"
        items[#sofa_presets + 4] = "  <  Back to Upper Menu"
        items[#sofa_presets + 5] = "  x  Close Menu"

    elseif menu_state == "loudnorm" then
        for i, p in ipairs(loudnorm_presets) do
            if p.cat then
                items[#items + 1] = "── " .. p.cat .. " ──"
            else
                items[#items + 1] = (p.id == current_loudnorm_id and "[x] " or "[  ] ") .. p.label
                id_map[#items] = i
            end
        end
        items[#items + 1] = "───────────────────────────────────"
        items[#items + 1] = "  +  Save Selected as Default"
        items[#items + 1] = "  <  Back to Upper Menu"
        items[#items + 1] = "  x  Close Menu"
    end

    local function reopen()
        input.terminate()
        mp.add_timeout(0.05, show_menu)
    end

    input.select({
        items = items,
        keep_open = true,
        submit = function(id)
            if menu_state == "main" then
                if id == 2 then
                    menu_state = "sofa"; reopen()
                elseif id == 3 then
                    menu_state = "loudnorm"; reopen()
                elseif id == 1 or id == 4 then
                    mp.osd_message("Coming soon", 2)
                end

            elseif menu_state == "sofa" then
                local n = #sofa_presets
                if id >= 1 and id <= n then
                    current_sofalizer = sofa_presets[id].filter
                    update_chain()
                    reopen()
                elseif id == n + 1 then
                    current_sofalizer = ""
                    update_chain()
                    reopen()
                elseif id == n + 3 then
                    save_defaults()
                elseif id == n + 4 then
                    menu_state = "main"; reopen()
                elseif id == n + 5 then
                    menu_state = "main"; input.terminate()
                end

            elseif menu_state == "loudnorm" then
                local preset_idx = id_map[id]
                if preset_idx then
                    local p = loudnorm_presets[preset_idx]
                    current_loudnorm = p.filter
                    current_loudnorm_id = p.id
                    update_chain()
                    reopen()
                elseif id == #items - 2 then
                    save_defaults()
                elseif id == #items - 1 then
                    menu_state = "main"; reopen()
                elseif id == #items then
                    menu_state = "main"; input.terminate()
                end
            end
        end,
    })
end

load_defaults()

mp.register_script_message("audio-option-show-menu", show_menu)
