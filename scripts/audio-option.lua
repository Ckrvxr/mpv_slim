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
local sofalizer_SADIEII_D1_48K_24bit_256tap_FIR_SOFA = "lavfi=[sofalizer=sofa='" .. path_SADIEII_D1_48K_24bit_256tap_FIR_SOFA .. "']"
local sofalizer_SADIEII_D1_48K_24bit_03s_FIR_SOFA  = "lavfi=[sofalizer=sofa='" .. path_SADIEII_D1_48K_24bit_03s_FIR_SOFA  .. "']"
local sofalizer_SADIEII_D2_48K_24bit_256tap_FIR_SOFA = "lavfi=[sofalizer=sofa='" .. path_SADIEII_D2_48K_24bit_256tap_FIR_SOFA .. "']"
local sofalizer_SADIEII_D2_48K_24bit_03s_FIR_SOFA  = "lavfi=[sofalizer=sofa='" .. path_SADIEII_D2_48K_24bit_03s_FIR_SOFA  .. "']"

mp.set_property("user-data/sofalizer-SADIEII_D1_48K_24bit_256tap_FIR_SOFA", sofalizer_SADIEII_D1_48K_24bit_256tap_FIR_SOFA)
mp.set_property("user-data/sofalizer-SADIEII_D1_48K_24bit_0.3s_FIR_SOFA", sofalizer_SADIEII_D1_48K_24bit_03s_FIR_SOFA)
mp.set_property("user-data/sofalizer-SADIEII_D2_48K_24bit_256tap_FIR_SOFA", sofalizer_SADIEII_D2_48K_24bit_256tap_FIR_SOFA)
mp.set_property("user-data/sofalizer-SADIEII_D2_48K_24bit_0.3s_FIR_SOFA", sofalizer_SADIEII_D2_48K_24bit_03s_FIR_SOFA)
mp.set_property("user-data/sofalizer-bypass", "")

-- Loudnorm presets (label includes hardcoded params for manual alignment)
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
local current_sofalizer = ""     -- active sofalizer filter ("" = bypass)
local current_loudnorm = ""      -- active loudnorm filter string ("" = off)
local current_loudnorm_id = nil  -- active preset id for checkmark

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

local function apply_sofalizer(sofalizer_str, msg)
    current_sofalizer = sofalizer_str
    update_chain()
    mp.osd_message(msg, 2)
end

-- SOFA submenu
local function show_sofa_menu()
    input.select({
        items = {
            (current_sofalizer:find("D1_48K_24bit_256tap") and "[x] " or "[  ] ") .. "SADIEII_D1_48K_24bit_256tap_FIR_SOFA.sofa",
            (current_sofalizer:find("D1_48K_24bit_0%.3s") and "[x] " or "[  ] ") .. "SADIEII_D1_48K_24bit_0.3s_FIR_SOFA.sofa",
            (current_sofalizer:find("D2_48K_24bit_256tap") and "[x] " or "[  ] ") .. "SADIEII_D2_48K_24bit_256tap_FIR_SOFA.sofa",
            (current_sofalizer:find("D2_48K_24bit_0%.3s") and "[x] " or "[  ] ") .. "SADIEII_D2_48K_24bit_0.3s_FIR_SOFA.sofa",
            (current_sofalizer == "" and "[x] " or "[  ] ") .. "BYPASS",
            "───────────────────────────────────",
            "  <  Back to Upper Menu",
            "  x  Close Menu",
        },
        submit = function(id)
            if id == 1 then
                apply_sofalizer(sofalizer_SADIEII_D1_48K_24bit_256tap_FIR_SOFA, "SOFA: D1 256tap (anechoic)")
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 2 then
                apply_sofalizer(sofalizer_SADIEII_D1_48K_24bit_03s_FIR_SOFA, "SOFA: D1 0.3s (BBC reverb)")
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 3 then
                apply_sofalizer(sofalizer_SADIEII_D2_48K_24bit_256tap_FIR_SOFA, "SOFA: D2 256tap (anechoic)")
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 4 then
                apply_sofalizer(sofalizer_SADIEII_D2_48K_24bit_03s_FIR_SOFA, "SOFA: D2 0.3s (BBC reverb)")
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 5 then
                current_sofalizer = ""
                update_chain()
                mp.osd_message("SOFA: off (native stereo)", 2)
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

-- Loudness Normalization submenu
local function show_loudnorm_menu()
    local items = {}
    local id_map = {}  -- menu index -> preset table index

    for i, p in ipairs(loudnorm_presets) do
        if p.cat then
            table.insert(items, "── " .. p.cat .. " ──")
        else
            local checked = (p.id == current_loudnorm_id) and "[x] " or "[  ] "
            table.insert(items, checked .. p.label)
            id_map[#items] = i
        end
    end

    table.insert(items, "───────────────────────────────────")
    table.insert(items, "  <  Back to Upper Menu")
    table.insert(items, "  x  Close Menu")

    local n_selectable = #items - 3  -- exclude separator, back, close

    input.select({
        items = items,
        submit = function(id)
            local preset_idx = id_map[id]
            if preset_idx then
                local p = loudnorm_presets[preset_idx]
                current_loudnorm = p.filter
                current_loudnorm_id = p.id
                update_chain()
                mp.osd_message("Loudness: " .. p.label, 2)
                input.terminate()
                mp.add_timeout(0.05, show_loudnorm_menu)
            elseif id == n_selectable + 2 then  -- Back (skip separator)
                input.terminate()
                mp.add_timeout(0.05, show_main_menu)
            elseif id == n_selectable + 3 then  -- Close
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
            "3. Loudness Normalization",
            "4. EQ Equalizer",
        },
        submit = function(id)
            if id == 1 then
                mp.osd_message("Audio Tracks: Coming soon", 2)
                input.terminate()
            elseif id == 2 then
                input.terminate()
                mp.add_timeout(0.05, show_sofa_menu)
            elseif id == 3 then
                input.terminate()
                mp.add_timeout(0.05, show_loudnorm_menu)
            elseif id == 4 then
                mp.osd_message("EQ Equalizer: Coming soon", 2)
                input.terminate()
            end
        end,
    })
end

mp.register_script_message("audio-option-show-menu", show_main_menu)
