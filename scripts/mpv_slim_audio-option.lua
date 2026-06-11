-- mpv_slim_audio-option.lua — Audio options menu for ModernZ (state machine)

local input = require 'mp.input'
local utils = require 'mp.utils'

-- Don't touch this function any more, it's working fine
local function resolve_filter_path(raw_path)
    local path = mp.command_native({"expand-path", raw_path})
    path = path:gsub("\\", "/")
    path = path:gsub(":", "\\:")
    path = path:gsub(",", "\\,")
    path = path:gsub("'", "\\'")
    return path
end

-- SOFA presets scanned from models/sofas/*.sofa
local sofa_presets = {}
do
    local sofa_dir = mp.command_native({"expand-path", "~~/models/sofas"})
    local files = utils.readdir(sofa_dir, "files")

    if files then
        for _, filename in ipairs(files) do
            if filename:match("%.sofa$") then
                local id = filename:gsub("%.sofa$", "")
                local path = utils.join_path(sofa_dir, filename)
                table.insert(sofa_presets, {
                    id = id,
                    label = filename,
                    path = path
                })
            end
        end
    else
        mp.msg.warn("SOFA directory not found or empty: " .. tostring(sofa_dir))
    end
end

-- EQ presets scanned from models/equalizers/*.txt
local eq_presets = {}
do
    local models_dir = mp.command_native({"expand-path", "~~/models/equalizers"})
    local files = utils.readdir(models_dir, "files")

    if files then
        for _, filename in ipairs(files) do
            if filename:match("%.txt$") then
                local path = utils.join_path(models_dir, filename)

                local f = io.open(path, "r")
                if f then
                    local content = f:read("*all")
                    f:close()

                    content = content:gsub("^\xEF\xBB\xBF", "")
                    content = content:gsub("^%s*GraphicEQ:%s*", "")
                    content = content:gsub("^%s*", ""):gsub("%s*$", "")

                    local entries = {}
                    for hz, db in content:gmatch("([%d%.]+)%s+([%-%d%.]+)") do
                        table.insert(entries, string.format("entry(%s,%s)", hz, db))
                    end
                    local curves = table.concat(entries, ";")

                    if curves ~= "" then
                        local filter = "lavfi=[firequalizer=gain_entry='" .. curves .. "']"
                        local id = filename:gsub("%.txt$", "")
                        table.insert(eq_presets, { id = id, label = filename, filter = filter })
                    end
                end
            end
        end
    else
        mp.msg.warn("EQ directory not found or empty: " .. tostring(models_dir))
    end
end

local loudnorm_presets = {
    { id = "BYPASS", label = "BYPASS", filter = "" },
    { id = "EBU_R128",    label = "I=-24.0:TP=-1.0:LRA=7.0           EBU R128 (Europe)",  filter = "lavfi=[loudnorm=I=-24.0:TP=-1.0:LRA=7.0]" },
    { id = "ATSC_A85",    label = "I=-24.0:TP=-2.0:LRA=10.0        ATSC A/85 (North America)", filter = "lavfi=[loudnorm=I=-24.0:TP=-2.0:LRA=10.0]" },
    { id = "Netflix_Dialogue",    label = "I=-27.0:TP=-2.0:LRA=10.0        Netflix (Dialogue)", filter = "lavfi=[loudnorm=I=-27.0:TP=-2.0:LRA=10.0]" },
    { id = "Netflix_NonDialogue", label = "I=-24.0:TP=-2.0:LRA=14.0        Netflix (Non-Dialogue)", filter = "lavfi=[loudnorm=I=-24.0:TP=-2.0:LRA=14.0]" },
    { id = "Disney_Plus",         label = "I=-27.0:TP=-2.0:LRA=12.0        Disney+", filter = "lavfi=[loudnorm=I=-27.0:TP=-2.0:LRA=12.0]" },
    { id = "Apple_TV_Plus",       label = "I=-24.0:TP=-1.0:LRA=10.0        Apple TV+", filter = "lavfi=[loudnorm=I=-24.0:TP=-1.0:LRA=10.0]" },
    { id = "Amazon_Prime_Video",  label = "I=-24.0:TP=-2.0:LRA=12.0        Amazon Prime Video", filter = "lavfi=[loudnorm=I=-24.0:TP=-2.0:LRA=12.0]" },
    { id = "YouTube_Video",       label = "I=-14.0:TP=-1.0:LRA=11.0        YouTube", filter = "lavfi=[loudnorm=I=-14.0:TP=-1.0:LRA=11.0]" },
    { id = "Hulu",                label = "I=-24.0:TP=-2.0:LRA=10.0        Hulu", filter = "lavfi=[loudnorm=I=-24.0:TP=-2.0:LRA=10.0]" },
    { id = "Apple_Music",     label = "I=-16.0:TP=-1.0:LRA=12.0        Apple Music (Sound Check)", filter = "lavfi=[loudnorm=I=-16.0:TP=-1.0:LRA=12.0]" },
    { id = "Spotify_Normal",  label = "I=-14.0:TP=-1.0:LRA=11.0        Spotify (Normal)", filter = "lavfi=[loudnorm=I=-14.0:TP=-1.0:LRA=11.0]" },
    { id = "Spotify_Loud",    label = "I=-11.0:TP=-2.0:LRA=8.0           Spotify (Loud)",  filter = "lavfi=[loudnorm=I=-11.0:TP=-2.0:LRA=8.0]" },
    { id = "Spotify_Quiet",   label = "I=-19.0:TP=-1.0:LRA=14.0        Spotify (Quiet)", filter = "lavfi=[loudnorm=I=-19.0:TP=-1.0:LRA=14.0]" },
    { id = "Tidal_HiFi",      label = "I=-14.0:TP=-1.0:LRA=12.0        Tidal HiFi", filter = "lavfi=[loudnorm=I=-14.0:TP=-1.0:LRA=12.0]" },
    { id = "Cinema_Indie",        label = "I=-18.0:TP=-2.0:LRA=18.0        Cinema / Indie Feature", filter = "lavfi=[loudnorm=I=-18.0:TP=-2.0:LRA=18.0]" },
}

-- Filter chain state
local current_sofa_preset = nil
local current_sofa_radius = 1.0
local current_sofa_gain = 12
local current_sofalizer = ""
local current_loudnorm = ""
local current_loudnorm_id = nil
local current_eq = ""
local current_eq_file = nil

local function build_sofa_filter()
    if not current_sofa_preset then return "" end
    for _, p in ipairs(sofa_presets) do
        if p.id == current_sofa_preset then
            local safe_path = resolve_filter_path(p.path)
            return "lavfi=[sofalizer=sofa='" .. safe_path .. "':radius=" .. string.format("%.2f", current_sofa_radius) .. ":gain=" .. tostring(current_sofa_gain) .. "]"
        end
    end
    return ""
end

local function refresh_sofalizer()
    current_sofalizer = build_sofa_filter()
end

local function update_chain()
    local parts = {}
    if current_sofalizer ~= "" then parts[#parts+1] = current_sofalizer end
    if current_loudnorm ~= "" then parts[#parts+1] = current_loudnorm end
    if current_eq ~= "" then parts[#parts+1] = current_eq end
    mp.set_property("af", table.concat(parts, ","))
end

-- Defaults persistence
local defaults_path = "~~/script-opts/mpv_slim_audio-option-defaults.lua"

local function save_defaults()
    local path = mp.command_native({"expand-path", defaults_path})
    local f = io.open(path, "w")
    if not f then
        mp.msg.error("Save failed: cannot open " .. path)
        mp.osd_message("Save failed!", 2)
        return
    end
    f:write("return {\n")
    f:write(string.format("    sofa_preset = %s,\n", current_sofa_preset and string.format("%q", current_sofa_preset) or "nil"))
    f:write(string.format("    sofa_radius = %s,\n", string.format("%.2f", current_sofa_radius)))
    f:write(string.format("    sofa_gain = %s,\n", tostring(current_sofa_gain)))
    local saved_sofalizer = current_sofalizer
    if saved_sofalizer ~= "" then
        local cfg = mp.command_native({"expand-path", "~~/"})
        cfg = cfg:gsub("\\", "/")
        saved_sofalizer = saved_sofalizer:gsub(cfg:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1"), "~~/")
    end
    f:write(string.format("    sofalizer = %s,\n", saved_sofalizer == "" and "''" or string.format("%q", saved_sofalizer)))
    f:write(string.format("    loudnorm = %s,\n", current_loudnorm == "" and "''" or string.format("%q", current_loudnorm)))
    f:write(string.format("    loudnorm_id = %s,\n", current_loudnorm_id and string.format("%q", current_loudnorm_id) or "nil"))
    f:write(string.format("    eq = %s,\n", current_eq == "" and "''" or string.format("%q", current_eq)))
    f:write(string.format("    eq_file = %s,\n", current_eq_file and string.format("%q", current_eq_file) or "nil"))
    f:write("}\n")
    f:close()
    mp.osd_message("Defaults saved", 2)
end

local function load_defaults()
    local path = mp.command_native({"expand-path", defaults_path})
    local ok, defaults = pcall(dofile, path)
    if ok and defaults then
        if defaults.sofa_preset then
            for _, p in ipairs(sofa_presets) do
                if p.id == defaults.sofa_preset then
                    current_sofa_preset = defaults.sofa_preset
                    break
                end
            end
        end
        if defaults.sofa_radius then
            current_sofa_radius = defaults.sofa_radius
        end
        if defaults.sofa_gain then
            current_sofa_gain = defaults.sofa_gain
        end
        refresh_sofalizer()
        if defaults.sofalizer then
            local saved = defaults.sofalizer
            if saved ~= "" then
                saved = saved:gsub("sofa='([^']+)'", function(p)
                    return "sofa='" .. resolve_filter_path(p) .. "'"
                end)
            end
            current_sofalizer = saved
        end
        if defaults.loudnorm then
            current_loudnorm = defaults.loudnorm
            current_loudnorm_id = defaults.loudnorm_id
        end
        if defaults.eq and defaults.eq_file then
            for _, p in ipairs(eq_presets) do
                if p.id == defaults.eq_file then
                    current_eq = defaults.eq
                    current_eq_file = defaults.eq_file
                    break
                end
            end
        end
        if current_sofalizer ~= "" or current_loudnorm ~= "" or current_eq ~= "" then
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
        local n = #sofa_presets
        items[1] = (current_sofa_preset == nil and "[x] " or "[  ] ") .. "BYPASS"
        items[2] = "────────────── SOFA Parameters ─────────────"
        items[3] = "       Sound Distance: " .. string.format("%.2f", current_sofa_radius)
        items[4] = "       Gain: " .. tostring(current_sofa_gain) .. " dB"
        for i, p in ipairs(sofa_presets) do
            items[i + 4] = (current_sofa_preset == p.id and "[x] " or "[  ] ") .. p.label
        end
        items[n + 5] = "───────────────────────────────────"
        items[n + 6] = "  +  Save as Default"
        items[n + 7] = "  <  Back to Upper Menu"
        items[n + 8] = "  x  Close Menu"

    elseif menu_state == "sofa_radius" then
        for i = 0, 50 do
            local v = i * 0.1
            local is_selected = math.abs(v - current_sofa_radius) < 0.001
            items[i + 1] = (is_selected and "[x] " or "[  ] ") .. string.format("%.2f", v)
        end
        items[52] = "───────────────────────────────────"
        items[53] = "  <  Back to Upper Menu"
        items[54] = "  x  Close Menu"

    elseif menu_state == "sofa_gain" then
        for i = 0, 36 do
            local is_selected = (i == current_sofa_gain)
            items[i + 1] = (is_selected and "[x] " or "[  ] ") .. tostring(i) .. " dB"
        end
        items[38] = "───────────────────────────────────"
        items[39] = "  <  Back to Upper Menu"
        items[40] = "  x  Close Menu"

    elseif menu_state == "loudnorm" then
        for i, p in ipairs(loudnorm_presets) do
            items[#items + 1] = (p.id == current_loudnorm_id and "[x] " or "[  ] ") .. p.label
            id_map[#items] = i
        end
        items[#items + 1] = "───────────────────────────────────"
        items[#items + 1] = "  +  Save Selected as Default"
        items[#items + 1] = "  <  Back to Upper Menu"
        items[#items + 1] = "  x  Close Menu"

    elseif menu_state == "audio_tracks" then
        local tracks = mp.get_property_native("track-list")
        local aid = mp.get_property_number("aid", 0)
        items[#items + 1] = (aid == 0 and "[x] " or "[  ] ") .. "No Audio"
        id_map[#items] = 0
        for _, t in ipairs(tracks) do
            if t.type == "audio" then
                local label = t.lang or "unknown"
                if t.title then label = label .. " - " .. t.title end
                if t.codec then label = label .. " [" .. t.codec .. "]" end
                items[#items + 1] = (t.id == aid and "[x] " or "[  ] ") .. t.id .. ". " .. label
                id_map[#items] = t.id
            end
        end
        items[#items + 1] = "───────────────────────────────────"
        items[#items + 1] = "  <  Back to Upper Menu"
        items[#items + 1] = "  x  Close Menu"

    elseif menu_state == "eq" then
        items[1] = (current_eq == "" and "[x] " or "[  ] ") .. "BYPASS"
        for i, p in ipairs(eq_presets) do
            items[i + 1] = (current_eq == p.filter and "[x] " or "[  ] ") .. p.label
        end
        local n = #eq_presets
        items[n + 2] = "───────────────────────────────────"
        items[n + 3] = "  +  Save Selected as Default"
        items[n + 4] = "  <  Back to Upper Menu"
        items[n + 5] = "  x  Close Menu"
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
                elseif id == 1 then
                    menu_state = "audio_tracks"; reopen()
                elseif id == 4 then
                    menu_state = "eq"; reopen()
                end

            elseif menu_state == "sofa" then
                local n = #sofa_presets
                if id == 1 then
                    current_sofa_preset = nil
                    refresh_sofalizer()
                    update_chain()
                    reopen()
                elseif id == 3 then
                    menu_state = "sofa_radius"; reopen()
                elseif id == 4 then
                    menu_state = "sofa_gain"; reopen()
                elseif id >= 5 and id <= n + 4 then
                    current_sofa_preset = sofa_presets[id - 4].id
                    refresh_sofalizer()
                    update_chain()
                    reopen()
                elseif id == n + 6 then
                    save_defaults()
                elseif id == n + 7 then
                    menu_state = "main"; reopen()
                elseif id == n + 8 then
                    menu_state = "main"; input.terminate()
                end

            elseif menu_state == "sofa_radius" then
                if id >= 1 and id <= 51 then
                    current_sofa_radius = (id - 1) * 0.1
                    refresh_sofalizer()
                    update_chain()
                    reopen()
                elseif id == 53 then
                    menu_state = "sofa"; reopen()
                elseif id == 54 then
                    menu_state = "main"; input.terminate()
                else
                    reopen()
                end

            elseif menu_state == "sofa_gain" then
                if id >= 1 and id <= 37 then
                    current_sofa_gain = id - 1
                    refresh_sofalizer()
                    update_chain()
                    reopen()
                elseif id == 39 then
                    menu_state = "sofa"; reopen()
                elseif id == 40 then
                    menu_state = "main"; input.terminate()
                else
                    reopen()
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
                else
                    reopen()
                end

            elseif menu_state == "audio_tracks" then
                local track_id = id_map[id]
                if track_id ~= nil then
                    mp.set_property_number("aid", track_id)
                    reopen()
                elseif id == #items - 1 then
                    menu_state = "main"; reopen()
                elseif id == #items then
                    menu_state = "main"; input.terminate()
                end

            elseif menu_state == "eq" then
                local n = #eq_presets
                if id == 1 then
                    current_eq = ""
                    current_eq_file = nil
                    update_chain()
                    reopen()
                elseif id >= 2 and id <= n + 1 then
                    current_eq = eq_presets[id - 1].filter
                    current_eq_file = eq_presets[id - 1].id
                    update_chain()
                    reopen()
                elseif id == n + 3 then
                    save_defaults()
                elseif id == n + 4 then
                    menu_state = "main"; reopen()
                elseif id == n + 5 then
                    menu_state = "main"; input.terminate()
                end
            end
        end,
    })
end

load_defaults()

mp.register_script_message("mpv_slim_audio-option-show-menu", show_menu)