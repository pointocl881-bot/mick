local CONFIG = {
    ScriptUrl = "https://raw.githubusercontent.com/pointocl881-bot/mick/main/main.lua",
    VersionUrl = "https://raw.githubusercontent.com/pointocl881-bot/mick/main/version.txt",
    CacheFile = "tg_mick_cache.lua",
    VersionFile = "tg_mick_version.txt",
    NotifyOnUpdate = true,
}

local function safeHttpGet(url)
    local ok, res = pcall(function() return game:HttpGet(url, true) end)
    if ok and res and #res > 0 then return res end
    return nil
end

local function readCache(path)
    if not isfile or not isfile(path) then return nil end
    local ok, data = pcall(readfile, path)
    if ok then return data end
    return nil
end

local function writeCache(path, data)
    if not writefile then return false end
    return pcall(writefile, path, data)
end

local function notify(title, text, duration)
    if not CONFIG.NotifyOnUpdate then return end
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title, Text = text, Duration = duration or 4,
        })
    end)
end

local function main()
    local remoteVersion = safeHttpGet(CONFIG.VersionUrl)
    if remoteVersion then remoteVersion = remoteVersion:gsub("%s+", "") end

    local cachedVersion = readCache(CONFIG.VersionFile)
    if cachedVersion then cachedVersion = cachedVersion:gsub("%s+", "") end

    local needDownload = true

    if remoteVersion and cachedVersion and remoteVersion == cachedVersion then
        local cachedScript = readCache(CONFIG.CacheFile)
        if cachedScript and #cachedScript > 100 then
            needDownload = false
            local fn = loadstring(cachedScript)
            if fn then pcall(fn) return end
            needDownload = true
        end
    end

    if needDownload then
        local scriptBody = safeHttpGet(CONFIG.ScriptUrl)
        if not scriptBody then
            local fallback = readCache(CONFIG.CacheFile)
            if fallback then
                notify("โหลดไม่สำเร็จ", "ใช้เวอร์ชันแคชเก่าแทน", 4)
                local fn = loadstring(fallback)
                if fn then pcall(fn) end
                return
            end
            notify("โหลดไม่สำเร็จ", "ตรวจสอบการเชื่อมต่ออินเทอร์เน็ต", 5)
            return
        end

        writeCache(CONFIG.CacheFile, scriptBody)
        if remoteVersion then writeCache(CONFIG.VersionFile, remoteVersion) end

        if remoteVersion and cachedVersion and remoteVersion ~= cachedVersion then
            notify("อัปเดตแล้ว", "เวอร์ชัน " .. remoteVersion, 4)
        end

        local fn, err = loadstring(scriptBody)
        if fn then
            local ok, runErr = pcall(fn)
            if not ok then warn("[TG Loader] Runtime: " .. tostring(runErr)) end
        else
            warn("[TG Loader] Syntax: " .. tostring(err))
        end
    end
end

main()