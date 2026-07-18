-- mpv_slim_volume_memory.lua — Global volume & mute memory across files and sessions
-- modified by mpv_slim: volume_memory start

local mp = require("mp")
local msg = mp.msg
local state_file = mp.command_native({"expand-path", "~~/script-opts/mpv_slim_volume_state-defaults.lua"})

local function save_state()
    local vol = mp.get_property_number("volume")
    local mute = mp.get_property_bool("mute")
    if vol then
        local f = io.open(state_file, "w")
        if f then
            f:write(string.format(
                "return {\n    volume = %d,\n    mute = %s,\n}\n",
                math.floor(vol + 0.5), mute and "true" or "false"
            ))
            f:close()
        else
            msg.warn("[volume_memory] failed to write state file: " .. state_file)
        end
    end
end

local function restore_state()
    -- State file is a Lua table (same format as other mpv_slim_*-defaults.lua
    -- files), so we can just loadfile it.
    local chunk, err = loadfile(state_file)
    if not chunk then return end
    local ok, state = pcall(chunk)
    if not ok or type(state) ~= "table" then return end
    if type(state.volume) == "number" then
        mp.set_property_number("volume", state.volume)
    end
    if type(state.mute) == "boolean" then
        mp.set_property_bool("mute", state.mute)
    end
end

mp.add_timeout(0, function()
    -- Restore the saved volume before attaching observers. If observers are
    -- attached first, their initial callback fires with mpv's default volume
    -- (100) and immediately overwrites the saved state on disk.
    restore_state()
    mp.observe_property("volume", "number", save_state)
    mp.observe_property("mute", "bool", save_state)
end)
mp.register_event("shutdown", save_state)

-- modified by mpv_slim: volume_memory end
