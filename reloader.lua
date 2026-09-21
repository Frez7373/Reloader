-- Reloader v2 - CC:Tweaked factory reset utility
-- https://github.com/Frez7373/Reloader
--
-- Deletes the complete writable computer filesystem while preserving
-- read-only/system mounts and external mounted disks.
--
-- WARNING: This is destructive. All programs, OS files, startup files,
-- user data and saved settings on the computer are removed.

local function clearScreen()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function center(text, y)
    local w = select(1, term.getSize())
    local x = math.max(1, math.floor((w - #text) / 2) + 1)
    term.setCursorPos(x, y)
    term.write(text)
end

local function safeDelete(path)
    if not fs.exists(path) then
        return true
    end

    if fs.isReadOnly(path) then
        return false, "read-only"
    end

    local ok, err = pcall(fs.delete, path)
    if not ok then
        return false, tostring(err)
    end

    if fs.exists(path) then
        return false, "still exists"
    end

    return true
end

clearScreen()

local w, h = term.getSize()
center("RELOADER", 2)
center("CC:Tweaked Factory Reset", 4)

term.setCursorPos(2, 6)
term.write("THIS WILL ERASE THE COMPUTER'S INTERNAL FILES.")

term.setCursorPos(2, 8)
term.write("Programs, startup files, settings and user data will be deleted.")

term.setCursorPos(2, 10)
term.write("External mounted disks such as /disk and /disk1 are preserved.")

term.setCursorPos(2, 12)
term.write("Type RESET to continue:")

term.setCursorPos(2, 13)
local answer = read()

if answer ~= "RESET" then
    clearScreen()
    print("Factory reset cancelled.")
    return
end

clearScreen()
center("FACTORY RESET", 2)
term.setCursorPos(1, 4)
print("Preparing...")

-- Reset CraftOS settings before removing their file.
pcall(function()
    settings.clear()
    settings.save()
end)

-- Reset the computer label.
pcall(function()
    os.setComputerLabel(nil)
end)

local failed = {}
local removed = 0
local skipped = {}

local function processRoot()
    local items = fs.list("/")
    for _, name in ipairs(items) do
        local path = "/" .. name

        -- ROM is a read-only system mount.
        -- Preserve all external mounts (/disk, /disk1, etc.) and any other
        -- mounted root which is not the computer's internal HDD.
        local drive = nil
        pcall(function()
            drive = fs.getDrive(path)
        end)

        if name == "rom" or drive ~= "hdd" then
            table.insert(skipped, name)
        else
            local ok, err = safeDelete(path)

            if ok then
                removed = removed + 1
            else
                table.insert(failed, name .. " (" .. tostring(err) .. ")")
            end
        end
    end
end

processRoot()

-- A second pass catches anything which appeared during the first pass.
-- This also handles files created by a running program.
local remaining = fs.list("/")
for _, name in ipairs(remaining) do
    local path = "/" .. name

    local drive = nil
    pcall(function()
        drive = fs.getDrive(path)
    end)

    if name ~= "rom" and drive == "hdd" then
        local ok, err = safeDelete(path)
        if ok then
            removed = removed + 1
        else
            local alreadyFailed = false
            for _, value in ipairs(failed) do
                if value:match("^" .. name:gsub("(%W)", "%%%1") .. " ") then
                    alreadyFailed = true
                    break
                end
            end
            if not alreadyFailed then
                table.insert(failed, name .. " (" .. tostring(err) .. ")")
            end
        end
    end
end

-- Make sure the settings file is gone even if settings.save() recreated it.
pcall(function()
    if fs.exists("/.settings") then
        fs.delete("/.settings")
    end
end)

clearScreen()

if #failed > 0 then
    center("RESET FINISHED WITH ERRORS", 3)
    term.setCursorPos(1, 5)
    print("Removed internal entries: " .. tostring(removed))
    print("")
    print("Could not remove:")
    for _, value in ipairs(failed) do
        print("  " .. value)
    end
    print("")
    print("Press any key to reboot.")
    os.pullEvent("key")
else
    center("FACTORY RESET COMPLETE", math.max(1, math.floor(h / 2)))
    sleep(1)
end

os.reboot()
