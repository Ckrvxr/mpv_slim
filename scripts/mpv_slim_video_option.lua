-- mpv_slim_video_option.lua — Video options menu for ModernZ (state machine)

local input = require 'mp.input'

local tone_map_methods = { "spline", "bt.2390", "bt.2446a", "hable", "mobius", "reinhard", "clip", "linear" }
local gamut_mappings  = { "auto", "absolute", "clp", "darken", "desaturate", "linear", "perceptual", "relative", "saturation", "warn" }

local current_brightness  = mp.get_property_number("brightness", 0)
local current_contrast    = mp.get_property_number("contrast", 0)
local current_saturation  = mp.get_property_number("saturation", 0)
local current_gamma       = mp.get_property_number("gamma", 0)
local current_tone_map    = mp.get_property("tone-mapping", "spline")
local current_gamut       = mp.get_property("gamut-mapping-mode", "perceptual")
local current_target_peak = mp.get_property("target-peak", "auto")
local current_peak_pct    = mp.get_property_number("hdr-peak-percentile", 99.995)
local current_peak_decay  = mp.get_property_number("hdr-peak-decay-rate", 20)
local current_compute_pk  = mp.get_property_bool("hdr-compute-peak", true)

local upscaler_options = {
    { file = "ravu-zoom-ar-r3-yuv.hook",    label = "RAVU_Zoom_AR_R3_YUV",   type = "shader" },
    { file = "SSimSuperRes.glsl",       label = "SSimSuperRes",              type = "shader" },
    { file = "ArtCNN_C4F32.glsl",       label = "ArtCNN_C4F32",              type = "shader" },
    { file = "ArtCNN_C4F32_DS.glsl",    label = "ArtCNN_C4F32_DS",           type = "shader" },
    { file = "ArtCNN_C4F32_DN.glsl",    label = "ArtCNN_C4F32_DN",           type = "shader" },
    { file = "ArtCNN_C4F16.glsl",       label = "ArtCNN_C4F16",              type = "shader" },
    { file = "ArtCNN_C4F16_DS.glsl",    label = "ArtCNN_C4F16_DS",           type = "shader" },
    { file = "ArtCNN_C4F16_DN.glsl",    label = "ArtCNN_C4F16_DN",           type = "shader" },
    -- Traditional built-in scalers
    { file = nil, label = "Nearest",    type = "builtin", scaler = "nearest" },
    { file = nil, label = "Bilinear",   type = "builtin", scaler = "bilinear" },
    { file = nil, label = "Hermite",    type = "builtin", scaler = "hermite" },
    { file = nil, label = "Mitchell",   type = "builtin", scaler = "mitchell" },
    { file = nil, label = "Catmull-Rom",type = "builtin", scaler = "catmull_rom" },
    { file = nil, label = "EWA Lanczos",type = "builtin", scaler = "ewa_lanczos4sharpest" },
}

local function detect_current_upscaler()
    local shaders = mp.get_property_native("glsl-shaders") or {}
    for _, s in ipairs(shaders) do
        for _, u in ipairs(upscaler_options) do
            if u.file and s:find(u.file) then return u end
        end
    end
    return upscaler_options[1]
end

local current_upscaler = detect_current_upscaler()

local function apply_upscaler(id)
    local selected = upscaler_options[id]
    if current_upscaler.file then
        mp.commandv("change-list", "glsl-shaders", "remove", "~~/models/shaders/" .. current_upscaler.file)
    end
    if selected.type == "builtin" then
        mp.set_property("scale", selected.scaler)
    else
        mp.set_property("scale", "catmull_rom")
        mp.commandv("change-list", "glsl-shaders", "append", "~~/models/shaders/" .. selected.file)
    end
    current_upscaler = selected
end

-- Non-Local Means Denoiser
local current_nlmeans_on = false

local function apply_nlmeans_off()
    local shaders = mp.get_property_native("glsl-shaders") or {}
    for _, s in ipairs(shaders) do
        if s:find("nlmeans") then
            mp.commandv("change-list", "glsl-shaders", "remove", s)
        end
    end
    current_nlmeans_on = false
end

local function detect_nlmeans_on()
    local shaders = mp.get_property_native("glsl-shaders") or {}
    for _, s in ipairs(shaders) do
        if s:find("nlmeans") then current_nlmeans_on = true; return end
    end
    current_nlmeans_on = false
end

detect_nlmeans_on()

local function apply_props()
    mp.set_property_number("brightness", current_brightness)
    mp.set_property_number("contrast", current_contrast)
    mp.set_property_number("saturation", current_saturation)
    mp.set_property_number("gamma", current_gamma)
    mp.set_property("tone-mapping", current_tone_map)
    mp.set_property("gamut-mapping-mode", current_gamut)
    mp.set_property("target-peak", current_target_peak)
    mp.set_property_number("hdr-peak-percentile", current_peak_pct)
    mp.set_property_number("hdr-peak-decay-rate", current_peak_decay)
    mp.set_property_bool("hdr-compute-peak", current_compute_pk)
end

local defaults_path = "~~/script-opts/mpv_slim_video_option-defaults.lua"

local function save_defaults()
    local path = mp.command_native({"expand-path", defaults_path})
    local f = io.open(path, "w")
    if not f then
        mp.msg.error("Save failed: cannot open " .. path)
        mp.osd_message("Save failed!", 2)
        return
    end
    local upscaler_id = nil
    for i, u in ipairs(upscaler_options) do
        if u == current_upscaler then upscaler_id = i; break end
    end
    f:write("return {\n")
    f:write(string.format("    brightness = %d,\n", current_brightness))
    f:write(string.format("    contrast = %d,\n", current_contrast))
    f:write(string.format("    saturation = %d,\n", current_saturation))
    f:write(string.format("    gamma = %d,\n", current_gamma))
    f:write(string.format("    tone_mapping = %q,\n", current_tone_map))
    f:write(string.format("    gamut_mapping = %q,\n", current_gamut))
    f:write(string.format("    target_peak = %q,\n", current_target_peak))
    f:write(string.format("    peak_percentile = %s,\n", string.format("%.3f", current_peak_pct)))
    f:write(string.format("    peak_decay_rate = %d,\n", current_peak_decay))
    f:write(string.format("    compute_peak = %s,\n", current_compute_pk and "true" or "false"))
    if upscaler_id then
        f:write(string.format("    upscaler_id = %d,\n", upscaler_id))
    end
    f:write("}\n")
    f:close()
    mp.osd_message("Defaults saved", 2)
end

local function load_defaults()
    local path = mp.command_native({"expand-path", defaults_path})
    local ok, defaults = pcall(dofile, path)
    if ok and defaults then
        local changed = false
        if defaults.brightness then current_brightness = defaults.brightness; changed = true end
        if defaults.contrast then current_contrast = defaults.contrast; changed = true end
        if defaults.saturation then current_saturation = defaults.saturation; changed = true end
        if defaults.gamma then current_gamma = defaults.gamma; changed = true end
        if defaults.tone_mapping then current_tone_map = defaults.tone_mapping; changed = true end
        if defaults.gamut_mapping then current_gamut = defaults.gamut_mapping; changed = true end
        if defaults.target_peak then current_target_peak = defaults.target_peak; changed = true end
        if defaults.peak_percentile then current_peak_pct = defaults.peak_percentile; changed = true end
        if defaults.peak_decay_rate then current_peak_decay = defaults.peak_decay_rate; changed = true end
        if defaults.compute_peak ~= nil then current_compute_pk = defaults.compute_peak; changed = true end
        if defaults.upscaler_id and defaults.upscaler_id >= 1 and defaults.upscaler_id <= #upscaler_options then
            apply_upscaler(defaults.upscaler_id)
        end
        if changed then apply_props() end
    end
end

local menu_state = "main"

local function show_menu()
    local items = {}
    local id_map = {}

    if menu_state == "main" then
        items = {
            "1. Video Tracks",
            "2. Style Tweaks",
            "3. Tone Mapping",
            "4. Upscaler [" .. current_upscaler.label .. "]",
            "5. Non-Local Means Denoiser " .. (current_nlmeans_on and "[ON]" or "[OFF]"),
        }

    elseif menu_state == "video_tracks" then
        local tracks = mp.get_property_native("track-list")
        local vid = mp.get_property_number("vid", 0)
        items[#items + 1] = (vid == 0 and "[x] " or "[  ] ") .. "No Video"
        id_map[#items] = 0
        for _, t in ipairs(tracks) do
            if t.type == "video" then
                local label = t.lang or "unknown"
                if t.title then label = label .. " - " .. t.title end
                if t.codec then label = label .. " [" .. t.codec .. "]" end
                if t.w and t.h then label = label .. " " .. t.w .. "x" .. t.h end
                items[#items + 1] = (t.id == vid and "[x] " or "[  ] ") .. t.id .. ". " .. label
                id_map[#items] = t.id
            end
        end
        items[#items + 1] = "───────────────────────────────────"
        items[#items + 1] = "  <  Back to Upper Menu"
        items[#items + 1] = "  x  Close Menu"

    elseif menu_state == "style_tweaks" then
        items[1] = "  1. Brightness: " .. tostring(current_brightness)
        items[2] = "  2. Contrast: " .. tostring(current_contrast)
        items[3] = "  3. Saturation: " .. tostring(current_saturation)
        items[4] = "  4. Gamma: " .. tostring(current_gamma)
        items[5] = "───────────────────────────────────"
        items[6] = "  +  Save as Default"
        items[7] = "  <  Back to Upper Menu"
        items[8] = "  x  Close Menu"

    elseif menu_state == "brightness" then
        items[1]  = "  Current Brightness: " .. tostring(current_brightness)
        items[2]  = "  + 100"
        items[3]  = "  + 10"
        items[4]  = "  + 1"
        items[5]  = "  = 0"
        items[6]  = "  - 1"
        items[7]  = "  - 10"
        items[8]  = "  - 100"
        items[9]  = "───────────────────────────────────"
        items[10] = "  <  Back to Upper Menu"
        items[11] = "  x  Close Menu"

    elseif menu_state == "contrast" then
        items[1]  = "  Current Contrast: " .. tostring(current_contrast)
        items[2]  = "  + 100"
        items[3]  = "  + 10"
        items[4]  = "  + 1"
        items[5]  = "  = 0"
        items[6]  = "  - 1"
        items[7]  = "  - 10"
        items[8]  = "  - 100"
        items[9]  = "───────────────────────────────────"
        items[10] = "  <  Back to Upper Menu"
        items[11] = "  x  Close Menu"

    elseif menu_state == "saturation" then
        items[1]  = "  Current Saturation: " .. tostring(current_saturation)
        items[2]  = "  + 100"
        items[3]  = "  + 10"
        items[4]  = "  + 1"
        items[5]  = "  = 0"
        items[6]  = "  - 1"
        items[7]  = "  - 10"
        items[8]  = "  - 100"
        items[9]  = "───────────────────────────────────"
        items[10] = "  <  Back to Upper Menu"
        items[11] = "  x  Close Menu"

    elseif menu_state == "gamma" then
        items[1]  = "  Current Gamma: " .. tostring(current_gamma)
        items[2]  = "  + 100"
        items[3]  = "  + 10"
        items[4]  = "  + 1"
        items[5]  = "  = 0"
        items[6]  = "  - 1"
        items[7]  = "  - 10"
        items[8]  = "  - 100"
        items[9]  = "───────────────────────────────────"
        items[10] = "  <  Back to Upper Menu"
        items[11] = "  x  Close Menu"

    elseif menu_state == "tone_mapping" then
        items[1]      = "  1. Tone Map Method: " .. current_tone_map
        items[2]      = "  2. Gamut Mapping: " .. current_gamut
        items[3]      = "  3. Target Peak: " .. current_target_peak
        items[4]      = "  4. Compute Peak: " .. (current_compute_pk and "yes" or "no")
        if current_compute_pk then
            items[5]  = "  5. Peak Percentile: " .. string.format("%.3f", current_peak_pct)
            items[6]  = "  6. Peak Decay Rate: " .. tostring(current_peak_decay)
            items[7]  = "───────────────────────────────────"
            items[8]  = "  +  Save as Default"
            items[9]  = "  <  Back to Upper Menu"
            items[10] = "  x  Close Menu"
        else
            items[5] = "───────────────────────────────────"
            items[6] = "  +  Save as Default"
            items[7] = "  <  Back to Upper Menu"
            items[8] = "  x  Close Menu"
        end

    elseif menu_state == "tone_map_method" then
        for i, v in ipairs(tone_map_methods) do
            local label = v
            if v == "spline" then label = v .. " (recommend)" end
            items[i] = (v == current_tone_map and "[x] " or "[  ] ") .. label
        end
        local n = #tone_map_methods
        items[n + 1] = "───────────────────────────────────"
        items[n + 2] = "  <  Back to Upper Menu"
        items[n + 3] = "  x  Close Menu"

    elseif menu_state == "gamut_mapping" then
        for i, v in ipairs(gamut_mappings) do
            local label = v
            if v == "perceptual" then label = v .. " (recommend)" end
            items[i] = (v == current_gamut and "[x] " or "[  ] ") .. label
        end
        local n = #gamut_mappings
        items[n + 1] = "───────────────────────────────────"
        items[n + 2] = "  <  Back to Upper Menu"
        items[n + 3] = "  x  Close Menu"

    elseif menu_state == "target_peak" then
        items[1]  = "  Current Target Peak: " .. current_target_peak
        items[2]  = "  = auto (recommend)"
        items[3]  = "  + 100"
        items[4]  = "  + 10"
        items[5]  = "  + 1"
        items[6]  = "  = 203 (recommend)"
        items[7]  = "  = 1000"
        items[8]  = "  - 1"
        items[9]  = "  - 10"
        items[10] = "  - 100"
        items[11] = "───────────────────────────────────"
        items[12] = "  <  Back to Upper Menu"
        items[13] = "  x  Close Menu"

    elseif menu_state == "peak_percentile" then
        items[1]  = "  Current Peak Percentile: " .. string.format("%.3f", current_peak_pct)
        items[2]  = "  + 0.100"
        items[3]  = "  + 0.010"
        items[4]  = "  + 0.001"
        items[5]  = "  - 0.001"
        items[6]  = "  - 0.010"
        items[7]  = "  - 0.100"
        items[8]  = "───────────────────────────────────"
        items[9]  = "  <  Back to Upper Menu"
        items[10] = "  x  Close Menu"

    elseif menu_state == "peak_decay_rate" then
        items[1]  = "  Current Peak Decay Rate: " .. tostring(current_peak_decay)
        items[2]  = "  + 100"
        items[3]  = "  + 10"
        items[4]  = "  + 1"
        items[5]  = "  = 0"
        items[6]  = "  - 1"
        items[7]  = "  - 10"
        items[8]  = "  - 100"
        items[9]  = "───────────────────────────────────"
        items[10] = "  <  Back to Upper Menu"
        items[11] = "  x  Close Menu"

    elseif menu_state == "compute_peak" then
        items[1] = (current_compute_pk and "[x] " or "[  ] ") .. "yes"
        items[2] = (not current_compute_pk and "[x] " or "[  ] ") .. "no"
        items[3] = "───────────────────────────────────"
        items[4] = "  <  Back to Upper Menu"
        items[5] = "  x  Close Menu"

    elseif menu_state == "upscaler" then
        local idx = 0
        for i, u in ipairs(upscaler_options) do
            if i > 1 and u.type == "builtin" and upscaler_options[i-1].type ~= "builtin" then
                idx = idx + 1
                items[idx] = "───────────────────────────────────"
            end
            idx = idx + 1
            items[idx] = (u.label == current_upscaler.label and "[x] " or "[  ] ") .. u.label
        end
        items[idx + 1] = "───────────────────────────────────"
        items[idx + 2] = "  +  Save as Default"
        items[idx + 3] = "  <  Back to Upper Menu"
        items[idx + 4] = "  x  Close Menu"
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
                if id == 1 then
                    menu_state = "video_tracks"; reopen()
                elseif id == 2 then
                    menu_state = "style_tweaks"; reopen()
                elseif id == 3 then
                    menu_state = "tone_mapping"; reopen()
                elseif id == 4 then
                    menu_state = "upscaler"; reopen()
                elseif id == 5 then
                    if current_nlmeans_on then
                        apply_nlmeans_off()
                    else
                        apply_nlmeans_off()
                        mp.commandv("change-list", "glsl-shaders", "append", "~~/models/shaders/nlmeans_sharpen_denoise.glsl")
                        current_nlmeans_on = true
                    end
                    reopen()
                end

            elseif menu_state == "video_tracks" then
                local track_id = id_map[id]
                if track_id ~= nil then
                    mp.set_property_number("vid", track_id)
                    reopen()
                elseif id == #items - 1 then
                    menu_state = "main"; reopen()
                elseif id == #items then
                    menu_state = "main"; input.terminate()
                end

            elseif menu_state == "style_tweaks" then
                if id == 1 then
                    menu_state = "brightness"; reopen()
                elseif id == 2 then
                    menu_state = "contrast"; reopen()
                elseif id == 3 then
                    menu_state = "saturation"; reopen()
                elseif id == 4 then
                    menu_state = "gamma"; reopen()
                elseif id == 6 then
                    save_defaults()
                elseif id == 7 then
                    menu_state = "main"; reopen()
                elseif id == 8 then
                    menu_state = "main"; input.terminate()
                end

            elseif menu_state == "brightness" then
                local function clamp(v) return math.max(-100, math.min(100, v)) end
                if id == 2 then current_brightness = clamp(current_brightness + 100); mp.set_property_number("brightness", current_brightness); reopen()
                elseif id == 3 then current_brightness = clamp(current_brightness + 10); mp.set_property_number("brightness", current_brightness); reopen()
                elseif id == 4 then current_brightness = clamp(current_brightness + 1); mp.set_property_number("brightness", current_brightness); reopen()
                elseif id == 5 then current_brightness = 0; mp.set_property_number("brightness", 0); reopen()
                elseif id == 6 then current_brightness = clamp(current_brightness - 1); mp.set_property_number("brightness", current_brightness); reopen()
                elseif id == 7 then current_brightness = clamp(current_brightness - 10); mp.set_property_number("brightness", current_brightness); reopen()
                elseif id == 8 then current_brightness = clamp(current_brightness - 100); mp.set_property_number("brightness", current_brightness); reopen()
                elseif id == 10 then menu_state = "style_tweaks"; reopen()
                elseif id == 11 then menu_state = "main"; input.terminate()
                else reopen()
                end

            elseif menu_state == "contrast" then
                local function clamp(v) return math.max(-100, math.min(100, v)) end
                if id == 2 then current_contrast = clamp(current_contrast + 100); mp.set_property_number("contrast", current_contrast); reopen()
                elseif id == 3 then current_contrast = clamp(current_contrast + 10); mp.set_property_number("contrast", current_contrast); reopen()
                elseif id == 4 then current_contrast = clamp(current_contrast + 1); mp.set_property_number("contrast", current_contrast); reopen()
                elseif id == 5 then current_contrast = 0; mp.set_property_number("contrast", 0); reopen()
                elseif id == 6 then current_contrast = clamp(current_contrast - 1); mp.set_property_number("contrast", current_contrast); reopen()
                elseif id == 7 then current_contrast = clamp(current_contrast - 10); mp.set_property_number("contrast", current_contrast); reopen()
                elseif id == 8 then current_contrast = clamp(current_contrast - 100); mp.set_property_number("contrast", current_contrast); reopen()
                elseif id == 10 then menu_state = "style_tweaks"; reopen()
                elseif id == 11 then menu_state = "main"; input.terminate()
                else reopen()
                end

            elseif menu_state == "saturation" then
                local function clamp(v) return math.max(-100, math.min(100, v)) end
                if id == 2 then current_saturation = clamp(current_saturation + 100); mp.set_property_number("saturation", current_saturation); reopen()
                elseif id == 3 then current_saturation = clamp(current_saturation + 10); mp.set_property_number("saturation", current_saturation); reopen()
                elseif id == 4 then current_saturation = clamp(current_saturation + 1); mp.set_property_number("saturation", current_saturation); reopen()
                elseif id == 5 then current_saturation = 0; mp.set_property_number("saturation", 0); reopen()
                elseif id == 6 then current_saturation = clamp(current_saturation - 1); mp.set_property_number("saturation", current_saturation); reopen()
                elseif id == 7 then current_saturation = clamp(current_saturation - 10); mp.set_property_number("saturation", current_saturation); reopen()
                elseif id == 8 then current_saturation = clamp(current_saturation - 100); mp.set_property_number("saturation", current_saturation); reopen()
                elseif id == 10 then menu_state = "style_tweaks"; reopen()
                elseif id == 11 then menu_state = "main"; input.terminate()
                else reopen()
                end

            elseif menu_state == "gamma" then
                local function clamp(v) return math.max(-100, math.min(100, v)) end
                if id == 2 then current_gamma = clamp(current_gamma + 100); mp.set_property_number("gamma", current_gamma); reopen()
                elseif id == 3 then current_gamma = clamp(current_gamma + 10); mp.set_property_number("gamma", current_gamma); reopen()
                elseif id == 4 then current_gamma = clamp(current_gamma + 1); mp.set_property_number("gamma", current_gamma); reopen()
                elseif id == 5 then current_gamma = 0; mp.set_property_number("gamma", 0); reopen()
                elseif id == 6 then current_gamma = clamp(current_gamma - 1); mp.set_property_number("gamma", current_gamma); reopen()
                elseif id == 7 then current_gamma = clamp(current_gamma - 10); mp.set_property_number("gamma", current_gamma); reopen()
                elseif id == 8 then current_gamma = clamp(current_gamma - 100); mp.set_property_number("gamma", current_gamma); reopen()
                elseif id == 10 then menu_state = "style_tweaks"; reopen()
                elseif id == 11 then menu_state = "main"; input.terminate()
                else reopen()
                end

            elseif menu_state == "tone_mapping" then
                if id == 1 then
                    menu_state = "tone_map_method"; reopen()
                elseif id == 2 then
                    menu_state = "gamut_mapping"; reopen()
                elseif id == 3 then
                    menu_state = "target_peak"; reopen()
                elseif id == 4 then
                    current_compute_pk = not current_compute_pk
                    mp.set_property_bool("hdr-compute-peak", current_compute_pk)
                    reopen()
                elseif current_compute_pk and id == 5 then
                    menu_state = "peak_percentile"; reopen()
                elseif current_compute_pk and id == 6 then
                    menu_state = "peak_decay_rate"; reopen()
                elseif id == (current_compute_pk and 8 or 6) then
                    save_defaults()
                elseif id == (current_compute_pk and 9 or 7) then
                    menu_state = "main"; reopen()
                elseif id == (current_compute_pk and 10 or 8) then
                    menu_state = "main"; input.terminate()
                else
                    reopen()
                end

            elseif menu_state == "tone_map_method" then
                local n = #tone_map_methods
                if id >= 1 and id <= n then
                    current_tone_map = tone_map_methods[id]
                    mp.set_property("tone-mapping", current_tone_map)
                    reopen()
                elseif id == n + 2 then
                    menu_state = "tone_mapping"; reopen()
                elseif id == n + 3 then
                    menu_state = "main"; input.terminate()
                else
                    reopen()
                end

            elseif menu_state == "gamut_mapping" then
                local n = #gamut_mappings
                if id >= 1 and id <= n then
                    current_gamut = gamut_mappings[id]
                    mp.set_property("gamut-mapping-mode", current_gamut)
                    reopen()
                elseif id == n + 2 then
                    menu_state = "tone_mapping"; reopen()
                elseif id == n + 3 then
                    menu_state = "main"; input.terminate()
                else
                    reopen()
                end

            elseif menu_state == "target_peak" then
                local function get_base()
                    local n = tonumber(current_target_peak)
                    return n and n or 203
                end
                local function set_peak(v)
                    v = math.max(1, math.min(2000, v))
                    current_target_peak = tostring(v)
                    mp.set_property("target-peak", current_target_peak)
                end
                if id == 2 then current_target_peak = "auto"; mp.set_property("target-peak", "auto"); reopen()
                elseif id == 3 then set_peak(get_base() + 100); reopen()
                elseif id == 4 then set_peak(get_base() + 10); reopen()
                elseif id == 5 then set_peak(get_base() + 1); reopen()
                elseif id == 6 then set_peak(203); reopen()
                elseif id == 7 then set_peak(1000); reopen()
                elseif id == 8 then set_peak(get_base() - 1); reopen()
                elseif id == 9 then set_peak(get_base() - 10); reopen()
                elseif id == 10 then set_peak(get_base() - 100); reopen()
                elseif id == 12 then menu_state = "tone_mapping"; reopen()
                elseif id == 13 then menu_state = "main"; input.terminate()
                else reopen()
                end

            elseif menu_state == "peak_percentile" then
                local function clamp_pct(v)
                    return math.max(99.000, math.min(100.000, v))
                end
                if id == 2 then current_peak_pct = clamp_pct(current_peak_pct + 0.100); mp.set_property_number("hdr-peak-percentile", current_peak_pct); reopen()
                elseif id == 3 then current_peak_pct = clamp_pct(current_peak_pct + 0.010); mp.set_property_number("hdr-peak-percentile", current_peak_pct); reopen()
                elseif id == 4 then current_peak_pct = clamp_pct(current_peak_pct + 0.001); mp.set_property_number("hdr-peak-percentile", current_peak_pct); reopen()
                elseif id == 5 then current_peak_pct = clamp_pct(current_peak_pct - 0.001); mp.set_property_number("hdr-peak-percentile", current_peak_pct); reopen()
                elseif id == 6 then current_peak_pct = clamp_pct(current_peak_pct - 0.010); mp.set_property_number("hdr-peak-percentile", current_peak_pct); reopen()
                elseif id == 7 then current_peak_pct = clamp_pct(current_peak_pct - 0.100); mp.set_property_number("hdr-peak-percentile", current_peak_pct); reopen()
                elseif id == 9 then menu_state = "tone_mapping"; reopen()
                elseif id == 10 then menu_state = "main"; input.terminate()
                else reopen()
                end

            elseif menu_state == "peak_decay_rate" then
                local function clamp_decay(v)
                    return math.max(1, math.min(100, v))
                end
                if id == 2 then current_peak_decay = clamp_decay(current_peak_decay + 100); mp.set_property_number("hdr-peak-decay-rate", current_peak_decay); reopen()
                elseif id == 3 then current_peak_decay = clamp_decay(current_peak_decay + 10); mp.set_property_number("hdr-peak-decay-rate", current_peak_decay); reopen()
                elseif id == 4 then current_peak_decay = clamp_decay(current_peak_decay + 1); mp.set_property_number("hdr-peak-decay-rate", current_peak_decay); reopen()
                elseif id == 5 then current_peak_decay = clamp_decay(current_peak_decay - 1); mp.set_property_number("hdr-peak-decay-rate", current_peak_decay); reopen()
                elseif id == 6 then current_peak_decay = clamp_decay(current_peak_decay - 10); mp.set_property_number("hdr-peak-decay-rate", current_peak_decay); reopen()
                elseif id == 7 then current_peak_decay = clamp_decay(current_peak_decay - 100); mp.set_property_number("hdr-peak-decay-rate", current_peak_decay); reopen()
                elseif id == 9 then menu_state = "tone_mapping"; reopen()
                elseif id == 10 then menu_state = "main"; input.terminate()
                else reopen()
                end

            elseif menu_state == "compute_peak" then
                if id == 1 then
                    current_compute_pk = true
                    mp.set_property_bool("hdr-compute-peak", true)
                    reopen()
                elseif id == 2 then
                    current_compute_pk = false
                    mp.set_property_bool("hdr-compute-peak", false)
                    reopen()
                elseif id == 4 then
                    menu_state = "tone_mapping"; reopen()
                elseif id == 5 then
                    menu_state = "main"; input.terminate()
                else
                    reopen()
                end

            elseif menu_state == "upscaler" then
                local n_shaders = 0
                for _, u in ipairs(upscaler_options) do
                    if u.type ~= "builtin" then n_shaders = n_shaders + 1 else break end
                end
                local n_builtins = #upscaler_options - n_shaders
                if id >= 1 and id <= n_shaders then
                    apply_upscaler(id)
                    reopen()
                elseif id >= n_shaders + 2 and id <= n_shaders + 1 + n_builtins then
                    apply_upscaler(id - 1)
                    reopen()
                elseif id == n_shaders + 3 + n_builtins then
                    save_defaults()
                    reopen()
                elseif id == n_shaders + 4 + n_builtins then
                    menu_state = "main"; reopen()
                elseif id == n_shaders + 5 + n_builtins then
                    menu_state = "main"; input.terminate()
                else
                    reopen()
                end
            end
        end,
    })
end

load_defaults()

mp.register_script_message("mpv_slim_video_option_show_menu", show_menu)
