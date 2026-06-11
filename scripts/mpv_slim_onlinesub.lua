local mp = require("mp")
local utils = require("mp.utils")
local mpopt = require("mp.options")

local config = {
    api_key = "",
    languages = "zh,yue,en",
}
mpopt.read_options(config, "mpv_slim_onlinesub")

local function notify(msg, sec)
    sec = sec or 3
    mp.osd_message(msg, sec)
    mp.msg.info(msg)
end

local function subprocess(args)
    return mp.command_native({
        name = "subprocess",
        playback_only = false,
        capture_stdout = true,
        capture_stderr = true,
        args = args,
    })
end

local function search_subs(query, lang)
    local url = string.format(
        "https://api.opensubtitles.com/api/v1/subtitles?query=%s&languages=%s&type=movie&order_by=download_count&order_direction=desc&limit=20",
        query, lang
    )
    local result = subprocess({
        "curl", "-sL", "--max-time", "15",
        "-H", "Api-Key: " .. config.api_key,
        "-H", "Content-Type: application/json",
        "-H", "User-Agent: mpv_slim v1.0",
        url,
    })
    if result.status ~= 0 then
        notify("API request failed", 5)
        return nil
    end
    return utils.parse_json(result.stdout)
end

local function download_sub(file_id)
    local result = subprocess({
        "curl", "-sL", "--max-time", "15",
        "-X", "POST",
        "-H", "Api-Key: " .. config.api_key,
        "-H", "Content-Type: application/json",
        "-H", "User-Agent: mpv_slim v1.0",
        "-d", '{"file_id": ' .. file_id .. '}',
        "https://api.opensubtitles.com/api/v1/download",
    })
    if result.status ~= 0 then
        notify("Download request failed", 5)
        return nil
    end
    local data = utils.parse_json(result.stdout)
    if not data or not data.link then
        notify("No download link returned", 5)
        return nil
    end
    local tmp = os.tmpname() or os.getenv("TEMP") .. "/mpv_sub.srt"
    local dl = subprocess({ "curl", "-sL", "--max-time", "30", "-o", tmp, data.link })
    if dl.status ~= 0 then
        notify("Download failed", 5)
        return nil
    end
    return tmp
end

local function on_language_selected(lang_code, lang_label)
    notify("Searching subtitles...", 30)
    local filepath = mp.get_property("path")
    local filename
    if filepath then
        local splitted = utils.split_path(filepath)
        filename = splitted[2] or filepath
    else
        filename = "unknown"
    end
    local data = search_subs(filename, lang_code)
    if not data or not data.data or #data.data == 0 then
        notify("No subtitles found for " .. lang_label, 5)
        return
    end

    local items = {}
    local id_map = {}
    for i, entry in ipairs(data.data) do
        local attr = entry.attributes
        local release = attr.release or "unknown"
        local score = attr.votes or 0
        local lang = attr.language or ""
        items[i] = string.format("%s [%d] %s", release, score, lang)
        id_map[i] = entry.attributes.files[1].file_id
    end
    items[#items + 1] = "───────────────────────────────────"
    items[#items + 1] = "Cancel"

    input.select({
        items = items,
        submit = function(id)
            local file_id = id_map[id]
            if file_id then
                notify("Downloading...", 30)
                local path = download_sub(file_id)
                if path then
                    if mp.commandv("sub_add", path) then
                        notify("Subtitle loaded", 2)
                    else
                        notify("Failed to load subtitle", 3)
                    end
                end
            end
        end,
    })
end

-- script_message handlers: called from subtitle-option.lua
mp.register_script_message("onlinesub-zh-simp", function() on_language_selected("zh", "Simplified Chinese") end)
mp.register_script_message("onlinesub-zh-trad", function() on_language_selected("zh", "Traditional Chinese") end)
mp.register_script_message("onlinesub-yue", function() on_language_selected("yue", "Cantonese") end)
mp.register_script_message("onlinesub-en", function() on_language_selected("en", "English") end)
