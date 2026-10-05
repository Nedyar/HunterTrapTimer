-- Hunter Trap Timer: shows how long the hunter's trap stays armed.
-- Core.lua holds the settings, the shared helpers, the startup and the slash
-- commands.
local ADDON_NAME, ns = ...
local L = ns.L

-- WoW Forever runs the Midnight addon API, where some results are "secret":
-- using one in a condition, or even comparing it with nil, raises an error.
-- Anything that might be secret goes through Plain() before it is looked at.
local issecretvalue = issecretvalue or function() return false end
ns.IsSecret = issecretvalue

function ns.Plain(value)
    if issecretvalue(value) then
        return nil
    end
    return value
end

function ns.Print(message, ...)
    if select("#", ...) > 0 then
        message = message:format(...)
    end
    print("|cffabd473Hunter Trap Timer|r: " .. message)
end

-- What the addon notices, for the /htt probe log. Probe.lua replaces it while
-- recording; otherwise it does nothing.
function ns.Log() end

-- RegisterEvent raises for an event this client does not have, which would
-- abort the rest of the file, so every registration is wrapped.
function ns.RegisterEvents(frame, ...)
    for i = 1, select("#", ...) do
        pcall(frame.RegisterEvent, frame, (select(i, ...)))
    end
end

function ns.RegisterUnitEvents(frame, units, ...)
    for i = 1, select("#", ...) do
        pcall(frame.RegisterUnitEvent, frame, (select(i, ...)), unpack(units))
    end
end

-- Settings -----------------------------------------------------------------

-- By default the icon looks and sits like a shaman's totem (see Display.lua).
ns.DEFAULTS = {
    version = 2,
    position = "player", -- "player": under the player frame, where totems show; "free": at x, y
    x = 0,               -- when free, where the icon's center is, from the center of the screen
    y = -150,
    locked = true,       -- unlocked, the icon shows and can be dragged (which frees it)
    shape = "round",     -- "round", like a totem, or "square"
    seconds = "below",   -- the seconds left "below" the icon, like a totem's, or on its "center"
    iconSize = 37,       -- a totem button's size
    warnSeconds = 10,    -- the warning starts with this many seconds left (0: no warning)
    warnFlash = true,    -- the icon flashes during the warning
    warnSound = true,    -- a sound when the warning starts
}

-- Minimum, maximum and step of the numeric settings.
ns.LIMITS = {
    iconSize = { 20, 96, 1 },
    warnSeconds = { 0, 30, 1 },
}

-- The values the other settings can take.
local CHOICES = {
    position = { player = true, free = true },
    shape = { round = true, square = true },
    seconds = { below = true, center = true },
}

-- Version 1 had a square icon of 48 pixels, free on the screen.
local V1_ICON_SIZE = 48

-- How far from the center of the screen the icon may be saved.
local MAX_OFFSET = 4000

local function Clamp(value, low, high)
    return math.min(math.max(value, low), high)
end

-- Rounds value to the nearest step inside [low, high].
function ns.Snap(value, low, high, step)
    value = low + math.floor((value - low) / step + 0.5) * step
    return Clamp(math.floor(value * 100 + 0.5) / 100, low, high)
end

local function IsNumber(value)
    -- NaN is the one number not equal to itself.
    return type(value) == "number" and value == value
end

-- Replaces missing or invalid values with the defaults. Runs on the saved
-- settings.
function ns.Sanitize(db)
    local version = IsNumber(db.version) and db.version or 1
    for key, default in pairs(ns.DEFAULTS) do
        local value, limits = db[key], ns.LIMITS[key]
        if limits then
            db[key] = IsNumber(value) and ns.Snap(value, limits[1], limits[2], limits[3]) or default
        elseif CHOICES[key] then
            if not CHOICES[key][value] then
                db[key] = default
            end
        elseif type(default) == "number" then
            db[key] = IsNumber(value) and Clamp(value, -MAX_OFFSET, MAX_OFFSET) or default
        elseif type(default) == "boolean" and type(value) ~= "boolean" then
            db[key] = default
        end
    end
    -- The effect's countdown, and its setting, are gone.
    db.showEffect = nil
    -- From version 1 the icon moves to the totem's look and place, unless it
    -- was given another size or moved by hand: then it keeps them.
    if version < 2 then
        if db.iconSize == V1_ICON_SIZE then
            db.iconSize = ns.DEFAULTS.iconSize
        end
        if db.x ~= ns.DEFAULTS.x or db.y ~= ns.DEFAULTS.y then
            db.position = "free"
        end
    end
    db.version = ns.DEFAULTS.version
end

-- Every settings change ends here.
function ns.SettingsChanged()
    ns.Display.ApplySettings()
end

function ns.ResetSettings()
    wipe(ns.db)
    for key, value in pairs(ns.DEFAULTS) do
        ns.db[key] = value
    end
    ns.SettingsChanged()
    ns.Options.Refresh()
end

-- Startup ------------------------------------------------------------------

local events = CreateFrame("Frame")
ns.RegisterEvents(events, "ADDON_LOADED", "PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == ADDON_NAME then
        self:UnregisterEvent("ADDON_LOADED")
        if type(HunterTrapTimerDB) ~= "table" then
            HunterTrapTimerDB = {}
        end
        ns.Sanitize(HunterTrapTimerDB)
        ns.db = HunterTrapTimerDB
    elseif event == "PLAYER_LOGIN" then
        ns.isHunter = select(2, UnitClass("player")) == "HUNTER"
        -- Each part starts on its own, so a failure in one (reported as a normal
        -- Lua error) does not stop the others.
        for _, init in ipairs({ ns.Traps.Init, ns.Display.Init, ns.Options.Init }) do
            xpcall(init, geterrorhandler())
        end
    end
end)

-- Slash commands -------------------------------------------------------------

local function SetLocked(locked)
    ns.db.locked = locked
    ns.SettingsChanged()
    ns.Options.Refresh()
end

SLASH_HUNTERTRAPTIMER1 = "/htt"
SLASH_HUNTERTRAPTIMER2 = "/huntertraptimer"
SlashCmdList.HUNTERTRAPTIMER = function(message)
    local command, rest = strtrim(message or ""):match("^(%S*)%s*(.-)$")
    command = command:lower()
    if command == "" or command == "options" then
        ns.Options.Open()
    elseif command == "unlock" then
        SetLocked(false)
        ns.Print(L["icon unlocked: drag it where you want it, then /htt lock."])
    elseif command == "lock" then
        SetLocked(true)
        ns.Print(L["icon locked."])
    elseif command == "test" then
        ns.Traps.Test()
    elseif command == "clear" then
        if ns.Traps.Clear() then
            ns.Print(L["countdown cleared."])
        else
            ns.Print(L["there is no countdown to clear."])
        end
    elseif command == "probe" then
        -- A diagnostic for what WoW Forever lets the addon see; see Probe.lua.
        ns.Probe.Command(rest:lower())
    elseif command == "reset" then
        ns.ResetSettings()
        ns.Print(L["settings reset to the defaults."])
    else
        ns.Print(L["/htt - open the options"])
        ns.Print(L["/htt unlock, /htt lock - move the icon"])
        ns.Print(L["/htt test - show a test trap"])
        ns.Print(L["/htt clear - clear the countdown, should it go wrong"])
        ns.Print(L["/htt reset - restore the default settings"])
    end
end
