-- Reloader - CC:Tweaked factory reset utility
-- Repository: https://github.com/Frez7373/Reloader
-- WARNING: This permanently deletes all user files on the computer.
-- Mounted floppy/disk media is preserved.

term.clear()
term.setCursorPos(1, 1)

local function center(text, y)
    local w = term.getSize()
    local x = math.max(1, math.floor((w - #text) / 2) + 1)
    term.setCursorPos(x, y)
    term.write(text)
end

local w, h = term.getSize()

center("RELOADER", 2)
center("CC:Tweaked Factory Reset", 4)

term.setCursorPos(2, 6)
term.write("WARNING: ALL USER FILES WILL BE DELETED.")

term.setCursorPos(2, 8)
term.write("This includes programs, settings and startup files.")

term.setCursorPos(2, 10)
term.write("Mounted disk/floppy media will NOT be deleted.")

term.setCursorPos(2, 12)
term.write("Type RESET and press Enter to continue:")

term.setCursorPos(2, 13)
local answer = read()

if answer ~= "RESET" then
    term.clear()
    term.setCursorPos(1, 1)
    print("Factory reset cancelled.")
    return
end

term.clear()
term.setCursorPos(1, 1)
center("Resetting computer...", math.max(1, math.floor(h / 2)))

-- Reset the computer label.
pcall(function()
    os.setComputerLabel(nil)
end)

-- Delete all writable root-level user files/directories.
-- ROM is read-only system content and must remain.
-- disk is external mounted media and is intentionally preserved.
local protected = {
    rom = true,
    disk = true
}

local items = fs.list("/")
local failed = {}

for _, name in ipairs(items) do
    if not protected[name] then
        local ok = pcall(function()
            fs.delete("/" .. name)
        end)

        if not ok or fs.exists("/" .. name) then
            table.insert(failed, name)
        end
    end
end

-- Give the filesystem a moment to settle before rebooting.
sleep(0.2)

if #failed > 0 then
    term.clear()
    term.setCursorPos(1, 1)
    print("Factory reset completed with warnings.")
    print("")
    print("Could not remove:")
    for _, name in ipairs(failed) do
        print(" - " .. name)
    end
    print("")
    print("Press any key to reboot.")
    os.pullEvent("key")
else
    term.clear()
    term.setCursorPos(1, 1)
    center("FACTORY RESET COMPLETE", math.max(1, math.floor(h / 2)))
    sleep(1)
end

os.reboot()
