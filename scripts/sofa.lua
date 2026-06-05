-- =====================================================================
-- 🎧 SOFA Spatial Audio Toggler via Native Lua Path Concatenation (Fixed)
-- =====================================================================

-- 1. Dynamically retrieve the absolute path of mpv configuration root (resolving ~~/ )
local config_dir = mp.command_native({"expand-path", "~~/"})

-- 2. Sanitize path string: convert Windows backslashes "\" to forward slashes "/"
config_dir = string.gsub(config_dir, "\\", "/")

-- ✨ CRITICAL FIX: Escape the Windows drive letter colon (e.g., "C:" -> "C\:") to bypass FFmpeg's filtergraph parser restriction
config_dir = string.gsub(config_dir, "(:)", "\\%1")

-- 3. Construct seamless absolute paths for the targeted SOFA models
local path_256tap = config_dir .. "/models/SADIEII_D1_48K_24bit_256tap_FIR_SOFA.sofa"
local path_03s    = config_dir .. "/models/SADIEII_D1_48K_24bit_0.3s_FIR_SOFA.sofa"

-- 4. Assemble the raw FFmpeg lavfi filterchain graphs with loudness normalization (loudnorm)
local filter_256tap = "lavfi=[sofalizer=sofa='" .. path_256tap .. "'],lavfi=[loudnorm=I=-20:TP=-1.5:LRA=14]"
local filter_03s    = "lavfi=[sofalizer=sofa='" .. path_03s    .. "'],lavfi=[loudnorm=I=-20:TP=-1.5:LRA=14]"

-- 5. Finite State Machine (FSM) configuration for cycle toggle
local state = 0

local function toggle_sofa_filter()
    if state == 0 then
        mp.set_property("af", filter_256tap)
        mp.osd_message("🎧 SOFA 空间音频: 256tap (纯净消音室)", 2)
        state = 1
    elseif state == 1 then
        mp.set_property("af", filter_03s)
        mp.osd_message("🏠 SOFA 空间音频: 0.3s (BBC 影院残响)", 2)
        state = 2
    else
        mp.set_property("af", "")
        mp.osd_message("❌ SOFA 空间音频: 已关闭 (原生双声道)", 2)
        state = 0
    end
end

-- 6. Bind the internal function to global mpv keybinding engine
mp.add_key_binding("M", "toggle_sofa_filter", toggle_sofa_filter)