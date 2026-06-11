local mp = require("mp")
local utils = require("mp.utils")

-- modified by mpv_slim: package_path_fix start
local src = debug.getinfo(1, "S").source
local script_dir = src:match("@?(.*[/\\]).*$")
if script_dir and not script_dir:match("^[/\\]") and not script_dir:match("^%a:") then
    script_dir = utils.join_path(mp.command_native({"expand-path", "~~/"}), script_dir)
end
if script_dir then
    script_dir = script_dir:gsub("[/\\]$", "") .. "/"
    package.path = script_dir .. "?.lua;" .. package.path
end
-- modified by mpv_slim: package_path_fix end

require("autosubsync")