local mp = require("mp")
local utils = require("mp.utils")
local mpopt = require("mp.options")

local config = {
    api_key = "",
    llm_api_key = "",
    llm_model = "deepseek-chat",
    llm_base_url = "https://api.deepseek.com/v1",
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

local function clean_filename(name)
    name = name:gsub("^%[.-%]%s*", "")
    name = name:gsub("%.[%w]+$", "")
    name = name:gsub("%d+[kpi]", "")
    name = name:gsub("[Ss]%d+[Ee]%d+", "")
    name = name:gsub("[Ee][Pp]%d+", "")
    name = name:gsub("[Ee]pisode%s*%d+", "")
    name = name:gsub("Season%s*%d+", "")
    name = name:gsub("Series%s*%d+", "")
    name = name:gsub("[%(%[]%d+[% %-%–]+%d+[%)%]]", "")
    name = name:gsub("[%(%[]%d+[%)%]]", "")
    name = name:gsub("%f[%w]20[012]%d%f[%D]", "")
    name = name:gsub("%f[%w]19[789]%d%f[%D]", "")
    name = name:gsub("WEB%-DL", "", {plain=true})
    name = name:gsub("WEB[Rr]ip", "")
    name = name:gsub("Blu[Rr]ay", "")
    name = name:gsub("BR[Rr]ip", "")
    name = name:gsub("HDTV", "")
    name = name:gsub("HD[Rr]ip", "")
    name = name:gsub("DVDRip", "")
    name = name:gsub("DVD", "")
    name = name:gsub("PPV", "")
    name = name:gsub("HEVC", "")
    name = name:gsub("AVC", "", {plain=true})
    name = name:gsub("h265", "")
    name = name:gsub("h264", "")
    name = name:gsub("x265", "", {plain=true})
    name = name:gsub("x264", "", {plain=true})
    name = name:gsub("%d+bit", "")
    name = name:gsub("Hi10P", "")
    name = name:gsub("DDP[%d%.]*", "")
    name = name:gsub("DD[%d%.]*", "")
    name = name:gsub("DTS%-HD", "")
    name = name:gsub("HD%-MA", "")
    name = name:gsub("AC3", "")
    name = name:gsub("AAC", "")
    name = name:gsub("DTS", "")
    name = name:gsub("TrueHD", "")
    name = name:gsub("Atmos", "")
    name = name:gsub("FLAC", "")
    name = name:gsub("OPUS", "")
    name = name:gsub("[%d%.]+ch", "")
    name = name:gsub("%f[%d][%d%.]+%f[%D]", "")
    name = name:gsub("HDR10", "")
    name = name:gsub("HDR", "")
    name = name:gsub("DV", "", {plain=true})
    name = name:gsub("SDR", "")
    name = name:gsub("HLG", "")
    name = name:gsub("PQ", "", {plain=true})
    name = name:gsub("DoVi", "")
    name = name:gsub("DolbyVision", "")
    name = name:gsub("Dual%-Audio", "")
    name = name:gsub("PROPER", "")
    name = name:gsub("REPACK", "")
    name = name:gsub("RERIP", "")
    name = name:gsub("READNFO", "")
    name = name:gsub("EXTENDED", "")
    name = name:gsub("iNTERNAL", "")
    name = name:gsub("AMZN", "")
    name = name:gsub("NF", "", {plain=true})
    name = name:gsub("IMAX", "")
    name = name:gsub("REMUX", "")
    name = name:gsub("COMPLETE", "")
    name = name:gsub("%.[%w]+%-[%w%.]+", "")
    name = name:gsub("%-[%w]+$", "")
    name = name:gsub("%s%-%s", " ")
    name = name:gsub("[%._%-]", " ")
    name = name:gsub("%s+", " ")
    name = name:match("^%s*(.-)%s*$") or name
    return name
end

local title_cache = {}

local function llm_clean_filename(name)
    if title_cache[name] then return title_cache[name] end
    if not config.llm_api_key or config.llm_api_key == "" then
        mp.msg.warn("No LLM API key, falling back to regex cleaning")
        return clean_filename(name)
    end

    local prompt = ("Extract the movie or TV show title from this filename. " ..
        "Return ONLY the title, nothing else. No explanation. " ..
        "Filename: %s"):format(name)
    local escaped = prompt:gsub('"', '\\"'):gsub("\n", "\\n")
    local body = ('{"model":"%s","messages":[{"role":"user","content":"%s"}],"stream":false,"max_tokens":64}'):format(
        config.llm_model, escaped)

    local result = subprocess({
        "curl", "-sL", "--max-time", "10",
        "-H", "Authorization: Bearer " .. config.llm_api_key,
        "-H", "Content-Type: application/json",
        "-d", body,
        config.llm_base_url .. "/chat/completions",
    })

    if result.status == 0 and result.stdout then
        local ok, data = pcall(utils.parse_json, result.stdout)
        if ok and data and data.choices and data.choices[1] then
            local title = data.choices[1].message.content
            if title then
                title = title:match("^%s*(.-)%s*$") or title
                if #title > 0 then
                    title_cache[name] = title
                    mp.msg.warn("LLM cleaned: " .. name .. " → " .. title)
                    return title
                end
            end
        end
    end

    local fallback = clean_filename(name)
    title_cache[name] = fallback
    return fallback
end

local function urlencode(s)
    return s:gsub("([^%w%.%- ])", function(c) return string.format("%%%02X", c:byte()) end)
           :gsub(" ", "+")
end

local function search_subs(query, lang)
    local cleaned = llm_clean_filename(query)
    mp.msg.warn("Searching: " .. cleaned)
    local url = string.format(
        "https://api.opensubtitles.com/api/v1/subtitles?query=%s&languages=%s&order_by=download_count&order_direction=desc&limit=20",
        urlencode(cleaned), lang
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
