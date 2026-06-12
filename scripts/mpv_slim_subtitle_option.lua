-- mpv_slim_subtitle_option.lua — Subtitle options menu for ModernZ (state machine)

local input = require 'mp.input'

local sub_ass_modes = { "force", "yes", "no", "strip" }

local current_sub_scale = mp.get_property_number("sub-scale", 1.0)
local current_sub_pos   = mp.get_property_number("sub-pos", 90)
local current_sub_delay = mp.get_property_number("sub-delay", 0.0)
local current_sub_vis   = mp.get_property_bool("sub-visibility", true)
local current_sub_ass   = mp.get_property("sub-ass-override", "force")

local defaults_path = "~~/script-opts/mpv_slim_subtitle_option-defaults.lua"

local function save_defaults()
    local path = mp.command_native({"expand-path", defaults_path})
    local f = io.open(path, "w")
    if not f then
        mp.msg.error("Save failed: cannot open " .. path)
        mp.osd_message("Save failed!", 2)
        return
    end
    f:write("return {\n")
    f:write(string.format("    sub_scale = %s,\n", string.format("%.1f", current_sub_scale)))
    f:write(string.format("    sub_pos = %d,\n", current_sub_pos))
    f:write(string.format("    sub_delay = %s,\n", string.format("%.1f", current_sub_delay)))
    f:write(string.format("    sub_visibility = %s,\n", current_sub_vis and "true" or "false"))
    f:write(string.format("    sub_ass_override = %q,\n", current_sub_ass))
    f:write("}\n")
    f:close()
    mp.osd_message("Defaults saved", 2)
end

local function load_defaults()
    local path = mp.command_native({"expand-path", defaults_path})
    local ok, defaults = pcall(dofile, path)
    if ok and defaults then
        if defaults.sub_scale then current_sub_scale = defaults.sub_scale; mp.set_property_number("sub-scale", current_sub_scale) end
        if defaults.sub_pos then current_sub_pos = defaults.sub_pos; mp.set_property_number("sub-pos", current_sub_pos) end
        if defaults.sub_delay then current_sub_delay = defaults.sub_delay; mp.set_property_number("sub-delay", current_sub_delay) end
        if defaults.sub_visibility ~= nil then current_sub_vis = defaults.sub_visibility; mp.set_property_bool("sub-visibility", current_sub_vis) end
        if defaults.sub_ass_override then current_sub_ass = defaults.sub_ass_override; mp.set_property("sub-ass-override", current_sub_ass) end
    end
end

local menu_state = "main"

local function show_menu()
    local items = {}
    local id_map = {}

    if menu_state == "main" then
        local sid = mp.get_property_number("sid", 0)
        local current_label = "none"
        if sid ~= 0 then
            local tracks = mp.get_property_native("track-list")
            for _, t in ipairs(tracks) do
                if t.type == "sub" and t.id == sid then
                    current_label = t.lang or t.title or t.codec or tostring(sid)
                    break
                end
            end
        end
        items = {
            "1. Subtitle Tracks: " .. current_label,
            "2. Subtitles Scale: " .. string.format("%.1f", current_sub_scale),
            "3. Subtitles Position: " .. tostring(current_sub_pos),
            "4. Subtitles Delay: " .. string.format("%.1f", current_sub_delay) .. "s",
            "5. ASS Override: " .. current_sub_ass,
            "6. Auto Sync Subtitles to Audio",
        }

    elseif menu_state == "subtitle_tracks" then
        local tracks = mp.get_property_native("track-list")
        local sid = mp.get_property_number("sid", 0)
        items[1] = (sid == 0 and "[x] " or "[  ] ") .. "No Subtitles"
        id_map[1] = 0
        for _, t in ipairs(tracks) do
            if t.type == "sub" then
                local label = t.lang or "unknown"
                if t.title then label = label .. " - " .. t.title end
                if t.codec then label = label .. " [" .. t.codec .. "]" end
                items[#items + 1] = (t.id == sid and "[x] " or "[  ] ") .. t.id .. ". " .. label
                id_map[#items] = t.id
            end
        end
        items[#items + 1] = "───────────────────────────────────"
        items[#items + 1] = "  <  Back to Upper Menu"
        items[#items + 1] = "  x  Close Menu"

    elseif menu_state == "sub_scale" then
        items[1] = "  Current Subtitles Scale: " .. string.format("%.1f", current_sub_scale)
        items[2] = "  + 0.1"
        items[3] = "  - 0.1"
        items[4] = "───────────────────────────────────"
        items[5] = "  <  Back to Upper Menu"
        items[6] = "  x  Close Menu"

    elseif menu_state == "sub_pos" then
        items[1] = "  Current Subtitles Position: " .. tostring(current_sub_pos)
        items[2] = "  + 10"
        items[3] = "  + 1"
        items[4] = "  = 90"
        items[5] = "  - 1"
        items[6] = "  - 10"
        items[7] = "───────────────────────────────────"
        items[8] = "  <  Back to Upper Menu"
        items[9] = "  x  Close Menu"

    elseif menu_state == "sub_delay" then
        items[1] = "  Current Subtitles Delay: " .. string.format("%.1f", current_sub_delay) .. "s"
        items[2] = "  + 0.1"
        items[3] = "  = 0.0"
        items[4] = "  - 0.1"
        items[5] = "───────────────────────────────────"
        items[6] = "  <  Back to Upper Menu"
        items[7] = "  x  Close Menu"

    elseif menu_state == "sub_vis" then
        items[1] = (current_sub_vis and "[x] " or "[  ] ") .. "on"
        items[2] = (not current_sub_vis and "[x] " or "[  ] ") .. "off"
        items[3] = "───────────────────────────────────"
        items[4] = "  +  Save as Default"
        items[5] = "  <  Back to Upper Menu"
        items[6] = "  x  Close Menu"

    elseif menu_state == "sub_ass" then
        for i, v in ipairs(sub_ass_modes) do
            items[i] = (v == current_sub_ass and "[x] " or "[  ] ") .. v
        end
        local n = #sub_ass_modes
        items[n + 1] = "───────────────────────────────────"
        items[n + 2] = "  +  Save as Default"
        items[n + 3] = "  <  Back to Upper Menu"
        items[n + 4] = "  x  Close Menu"
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
                    menu_state = "subtitle_tracks"; reopen()
                elseif id == 2 then
                    menu_state = "sub_scale"; reopen()
                elseif id == 3 then
                    menu_state = "sub_pos"; reopen()
                elseif id == 4 then
                    menu_state = "sub_delay"; reopen()
                elseif id == 5 then
                    menu_state = "sub_ass"; reopen()
                elseif id == 6 then
                    input.terminate()
                    mp.add_timeout(0.1, function()
                        mp.commandv("script_message", "sync-to-audio")
                    end)
                end

            elseif menu_state == "subtitle_tracks" then
                local track_id = id_map[id]
                if track_id ~= nil then
                    mp.set_property_number("sid", track_id)
                    mp.set_property_bool("sub-visibility", track_id ~= 0)
                    current_sub_vis = (track_id ~= 0)
                    reopen()
                elseif id == #items - 1 then
                    menu_state = "main"; reopen()
                elseif id == #items then
                    menu_state = "main"; input.terminate()
                end

            elseif menu_state == "sub_scale" then
                if id == 2 then
                    current_sub_scale = math.min(3.0, current_sub_scale + 0.1)
                    mp.set_property_number("sub-scale", current_sub_scale)
                    reopen()
                elseif id == 3 then
                    current_sub_scale = math.max(0.1, current_sub_scale - 0.1)
                    mp.set_property_number("sub-scale", current_sub_scale)
                    reopen()
                elseif id == 5 then
                    menu_state = "main"; reopen()
                elseif id == 6 then
                    menu_state = "main"; input.terminate()
                else
                    reopen()
                end

            elseif menu_state == "sub_pos" then
                if id == 2 then
                    current_sub_pos = math.min(200, current_sub_pos + 10)
                    mp.set_property_number("sub-pos", current_sub_pos)
                    reopen()
                elseif id == 3 then
                    current_sub_pos = math.min(200, current_sub_pos + 1)
                    mp.set_property_number("sub-pos", current_sub_pos)
                    reopen()
                elseif id == 4 then
                    current_sub_pos = 90
                    mp.set_property_number("sub-pos", 90)
                    reopen()
                elseif id == 5 then
                    current_sub_pos = math.max(0, current_sub_pos - 1)
                    mp.set_property_number("sub-pos", current_sub_pos)
                    reopen()
                elseif id == 6 then
                    current_sub_pos = math.max(0, current_sub_pos - 10)
                    mp.set_property_number("sub-pos", current_sub_pos)
                    reopen()
                elseif id == 8 then
                    menu_state = "main"; reopen()
                elseif id == 9 then
                    menu_state = "main"; input.terminate()
                else
                    reopen()
                end

            elseif menu_state == "sub_delay" then
                if id == 2 then
                    current_sub_delay = math.min(10.0, current_sub_delay + 0.1)
                    mp.set_property_number("sub-delay", current_sub_delay)
                    reopen()
                elseif id == 3 then
                    current_sub_delay = 0.0
                    mp.set_property_number("sub-delay", 0.0)
                    reopen()
                elseif id == 4 then
                    current_sub_delay = math.max(-10.0, current_sub_delay - 0.1)
                    mp.set_property_number("sub-delay", current_sub_delay)
                    reopen()
                elseif id == 6 then
                    menu_state = "main"; reopen()
                elseif id == 7 then
                    menu_state = "main"; input.terminate()
                else
                    reopen()
                end

            elseif menu_state == "sub_vis" then
                if id == 1 then
                    current_sub_vis = true
                    mp.set_property_bool("sub-visibility", true)
                    reopen()
                elseif id == 2 then
                    current_sub_vis = false
                    mp.set_property_bool("sub-visibility", false)
                    reopen()
                elseif id == 4 then
                    save_defaults()
                    menu_state = "main"; reopen()
                elseif id == 5 then
                    menu_state = "main"; reopen()
                elseif id == 6 then
                    menu_state = "main"; input.terminate()
                else
                    reopen()
                end

            elseif menu_state == "sub_ass" then
                local n = #sub_ass_modes
                if id >= 1 and id <= n then
                    current_sub_ass = sub_ass_modes[id]
                    mp.set_property("sub-ass-override", current_sub_ass)
                    reopen()
                elseif id == n + 2 then
                    save_defaults()
                    menu_state = "main"; reopen()
                elseif id == n + 3 then
                    menu_state = "main"; reopen()
                elseif id == n + 4 then
                    menu_state = "main"; input.terminate()
                else
                    reopen()
                end
            end
        end,
    })
end

load_defaults()

mp.register_script_message("mpv_slim_subtitle_option-show-menu", show_menu)
