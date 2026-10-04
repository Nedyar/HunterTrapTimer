-- Behavioral tests for Hunter Trap Timer. run.lua runs them in Lua 5.1, the
-- game's Lua, against mock.lua, a strict stand-in for the WoW Forever API.
--
-- Each session starts a fresh game (NewSession: the mock and the addon's
-- files, loaded in the order of its TOC), logs in and plays a scenario: traps
-- put down, running out, springing on enemies whose auras can or cannot be
-- read, settings changed through the options page, and the probe.
local failures, passes = 0, 0
local ns
local function check(cond, message)
    if cond then
        passes = passes + 1
    else
        failures = failures + 1
        print_real("FAIL: " .. message)
    end
end
local function eq(actual, expected, message)
    check(actual == expected, message .. " (expected " .. tostring(expected) .. ", got " .. tostring(actual) .. ")")
end

-- The addon's files run with this environment: they read the globals as
-- usual, and any global they set other than ADDON_GLOBALS is a leak.
local ADDON_GLOBALS = { HunterTrapTimerDB = true, SLASH_HUNTERTRAPTIMER1 = true, SLASH_HUNTERTRAPTIMER2 = true }
local leaks, leaked = {}, {}
local ADDON_ENV = setmetatable({}, {
    __index = _G,
    __newindex = function(_, key, value)
        if not ADDON_GLOBALS[key] and not leaked[key] then
            leaked[key] = true
            leaks[#leaks + 1] = tostring(key)
        end
        _G[key] = value
    end,
})

-- opts: saved (the saved settings the client loads), class, known (spell IDs).
local function NewSession(opts)
    opts = opts or {}
    assert(loadstring(SOURCES["mock.lua"], "@mock.lua"))()
    HunterTrapTimerDB = opts.saved
    M.class = opts.class or "HUNTER"
    M.locale = opts.locale
    -- GetTime() goes on through a /reload.
    M.time = opts.time or M.time
    for _, spellID in ipairs(opts.known or { 1499, 14311, 13795, 13809, 13813 }) do
        M.known[spellID] = true
    end
    local ns = {}
    for _, file in ipairs(FILES) do
        local chunk = assert(loadstring(SOURCES[file], "@" .. file))
        setfenv(chunk, ADDON_ENV)
        chunk("HunterTrapTimer", ns)
    end
    M.Fire("ADDON_LOADED", "HunterTrapTimer")
    M.Fire("PLAYER_LOGIN")
    return ns
end

local function Slash(text)
    SlashCmdList.HUNTERTRAPTIMER(text)
end

-- The trap icons, in the order they were made.
local function Icons()
    local list = {}
    for _, f in ipairs(M.allFrames) do
        if f.parent == HunterTrapTimerFrame and f.cooldown then
            list[#list + 1] = f
        end
    end
    return list
end
-- The seconds shown on icon index now, or nil when it is not on screen. The
-- icons are redrawn first: between ticks they lag by up to one tick.
local function IconText(index)
    ns.Display.Refresh()
    local icon = Icons()[index]
    return icon and M.Visible(icon) and icon.text.textValue or nil
end
local function IconColor(index)
    local color = Icons()[index].text.color
    return ("%g,%g,%g"):format(color[1], color[2], color[3])
end
local WHITE, RED = "1,1,1", "1,0.25,0.25"

local function Frames(kind)
    local list = {}
    for _, f in ipairs(M.allFrames) do
        if f.kind == kind then
            list[#list + 1] = f
        end
    end
    return list
end
local function Button(text)
    for _, f in ipairs(Frames("Button")) do
        if f.textValue == text then
            return f
        end
    end
end

local function ProbeText()
    Slash("probe")
    return HunterTrapTimerProbe.Edit.textValue
end
local function Has(text, part)
    return text:find(part, 1, true) ~= nil
end

local function NoErrors(when)
    eq(#M.errors, 0, "no errors " .. when .. ": " .. table.concat(M.errors, " | "))
end

---------------------------------------------------------------------------
-- Session 1: a trap put down and left to run out.
---------------------------------------------------------------------------
ns = NewSession()
NoErrors("during login")
eq(ns.db.iconSize, 48, "defaults loaded")
check(M.mainCategory and M.mainCategory.name == "Hunter Trap Timer", "settings category registered")
check(M.addonCategory == M.mainCategory, "registered as addon category")
eq(SLASH_HUNTERTRAPTIMER1, "/htt", "slash command")
eq(M.forbidden, nil, "the combat log is never registered")
check(not M.Visible(HunterTrapTimerFrame), "nothing shows before a trap is down")

M.Cast(1499)
eq(ns.Traps.armed and ns.Traps.armed.trap.key, "freezing", "Freezing Trap is armed")
eq(IconText(1), 60, "the icon counts from 60")
local icon = Icons()[1]
eq(icon.texture.path, "icon:1499", "the trap's icon")
eq(icon.cooldown.start, M.time, "the sweep starts now")
eq(icon.cooldown.duration, 60, "the sweep lasts 60 seconds")
check(icon.cooldown.reverse, "the lit part is the time left")
eq(IconColor(1), WHITE, "white while plenty of time is left")

M.Advance(20)
eq(IconText(1), 40, "40 seconds left after 20")
M.Advance(29.875)
eq(#M.sounds, 0, "no warning with more than 10 seconds left")
check(not icon.flash:IsPlaying(), "no flash yet")
M.Advance(0.25)
eq(#M.sounds, 1, "the warning sound plays with 10 seconds left")
eq(IconColor(1), RED, "the seconds turn red")
check(icon.flash:IsPlaying(), "the icon flashes")
M.Advance(5)
eq(#M.sounds, 1, "the sound plays once")
M.Advance(5)
eq(ns.Traps.armed, nil, "the trap ran out after 60 seconds")
check(not M.Visible(HunterTrapTimerFrame), "the icon is gone")
check(not icon.flash:IsPlaying(), "the flash stopped")

-- A new trap replaces the old one, whatever its kind.
M.Cast(1499)
M.Advance(10)
M.Cast(13795)
eq(ns.Traps.armed.trap.key, "immolation", "Immolation Trap replaces Freezing Trap")
eq(IconText(1), 60, "and counts from 60 again")
eq(Icons()[1].texture.path, "icon:13795", "with its own icon")
eq(IconText(2), nil, "one icon only")

-- Casts that are not traps, or cannot be read, change nothing.
M.Cast(75)
eq(ns.Traps.armed.trap.key, "immolation", "another spell changes nothing")
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", SECRET)
eq(ns.Traps.armed.trap.key, "immolation", "a secret spell ID changes nothing")
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "pet", "Cast-3", 1499)
eq(ns.Traps.armed.trap.key, "immolation", "the pet's casts are not listened to")
NoErrors("with unreadable casts")

-- A rank the list lacks is still known by its name.
M.Cast(99001)
eq(ns.Traps.armed.trap.key, "freezing", "an unknown rank of Freezing Trap is found by name")
M.Advance(61)

-- /htt clear drops a countdown that went wrong.
M.Cast(1499)
local sounds = #M.sounds
Slash("clear")
eq(ns.Traps.armed, nil, "/htt clear drops the countdown")
check(not M.Visible(HunterTrapTimerFrame), "and its icon")
eq(M.printed[#M.printed], "|cffabd473Hunter Trap Timer|r: countdown cleared.", "and says so")
M.Advance(61)
eq(#M.sounds, sounds, "a cleared trap gives no warning")
Slash("clear")
eq(M.printed[#M.printed], "|cffabd473Hunter Trap Timer|r: there is no countdown to clear.",
    "with no trap down, it says there is nothing to clear")
Slash("test")
Slash("clear")
eq(ns.Traps.armed, nil, "it clears a test trap too")
NoErrors("clearing")

---------------------------------------------------------------------------
-- The trap springs, so it is gone: its icon goes.
---------------------------------------------------------------------------
M.AddUnit("nameplate1", { name = "Kobold" })
M.AddUnit("nameplate2", { name = "Gnoll" })
M.AddUnit("party1", { name = "Friend", friendly = true })

local function Sprang(message)
    eq(ns.Traps.armed, nil, message)
    check(not M.Visible(HunterTrapTimerFrame), message .. ": the icon is gone")
end

-- Its effect's aura, when it can be read.
M.Cast(1499)
M.Advance(5)
local before = #M.sounds
M.AddAura("nameplate1", 3355, 10)
Sprang("the freeze's aura: the trap sprang")
M.Advance(60)
eq(#M.sounds, before, "no warning for a trap that sprang")
M.RemoveAura("nameplate1", 3355)

-- Auras that are not this trap's.
M.Cast(1499)
M.AddAura("nameplate1", 3355, 20, { appliedAt = M.time - 5 })
check(ns.Traps.armed ~= nil, "an aura from before the trap went down is not its effect")
M.RemoveAura("nameplate1", 3355)
M.AddAura("nameplate2", 3355, 10, { source = "nameplate3" })
check(ns.Traps.armed ~= nil, "another hunter's freeze is not ours")
M.RemoveAura("nameplate2", 3355)
M.AddAura("nameplate2", 3355, 10, { source = "party1", fromPlayer = true })
check(ns.Traps.armed ~= nil, "nor a group member's, though it is a player's")
M.RemoveAura("nameplate2", 3355)
M.AddAura("party1", 3355, 10)
check(ns.Traps.armed ~= nil, "only enemies' auras are looked at")
M.RemoveAura("party1", 3355)
M.AddAura("nameplate1", 13797, 15)
check(ns.Traps.armed ~= nil, "another trap's effect is not this trap's")
M.RemoveAura("nameplate1", 13797)

-- Auras that cannot be read, listed as readable.
M.aurasSecret = true
M.AddAura("nameplate1", 3355, 10)
check(ns.Traps.armed ~= nil, "an aura the lookup cannot find is not noticed")
M.RemoveAura("nameplate1", 3355)
M.aurasSecret = false
M.Fire("UNIT_AURA", SECRET, SECRET)
M.Fire("UNIT_AURA", "nameplate1", SECRET)
check(ns.Traps.armed ~= nil, "an update that cannot be read at all says nothing")
NoErrors("with secret auras")
M.Advance(61)

---------------------------------------------------------------------------
-- In combat the effect cannot be read: an aura that turns up on an enemy,
-- with nothing else to explain it, is taken for the trap's.
---------------------------------------------------------------------------
M.combat, M.aurasSecret = true, true
M.Cast(1499)
M.HiddenAura("nameplate1")
Sprang("an unexplained aura on an enemy: the trap sprang")

-- Auras that something else explains.
M.Cast(1499)
M.Cast(13550)
M.HiddenAura("nameplate1")
check(ns.Traps.armed ~= nil, "an aura right after the hunter's Serpent Sting is the sting's")
M.Advance(1.5)
M.HiddenAura("nameplate1")
check(ns.Traps.armed ~= nil, "still 1.5 seconds after it")
M.Advance(0.125)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "pet", "Cast-4", 26177)
M.HiddenAura("nameplate1")
check(ns.Traps.armed ~= nil, "an aura right after the pet's Charge is the pet's")
M.Advance(2)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "nameplate1", "Cast-5", SECRET)
M.HiddenAura("nameplate1")
check(ns.Traps.armed ~= nil, "an aura right after the enemy's own cast is its own")
M.Fire("UNIT_AURA", "nameplate1", { isFullUpdate = false, removedAuraInstanceIDs = SECRET })
check(ns.Traps.armed ~= nil, "an aura that goes is not the trap's")
M.AddUnit("nameplate3", { name = "Guard", friendly = true })
M.HiddenAura("nameplate3")
check(ns.Traps.armed ~= nil, "a friendly unit's aura is not the trap's")
M.HiddenAura("party1")
check(ns.Traps.armed ~= nil, "nor a group member's")
M.Advance(1.125)
M.HiddenAura("nameplate2")
Sprang("an aura nothing explains")

-- In a group, the group's casts explain auras too.
M.inGroup = true
M.Cast(1499)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "party1", "Cast-7", SECRET)
M.HiddenAura("nameplate2")
check(ns.Traps.armed ~= nil, "an aura right after a group member's cast is theirs")
M.Advance(1.625)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "partypet1", "Cast-8", SECRET)
M.HiddenAura("nameplate2")
check(ns.Traps.armed ~= nil, "and so is one right after their pet's")
M.Advance(1.625)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "party1", "Cast-9", 75)
-- In a raid the hunter is a raid unit as well: their own casts are not the group's.
M.AddUnit("raid3", { name = "Tester", isPlayer = true, friendly = true })
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "raid3", "Cast-10", 1499)
M.HiddenAura("nameplate2")
Sprang("in a group, an aura nothing explains")
M.inGroup = false

-- Attacks that put no aura explain nothing, whatever their rank.
for _, attack in ipairs({ { 75, "Auto Shot" }, { 14261, "Raptor Strike" }, { 3044, "Arcane Shot" },
    { 14282, "Arcane Shot (higher rank)" } }) do
    M.Cast(1499)
    M.Cast(attack[1])
    M.HiddenAura("nameplate2")
    Sprang(attack[2] .. " explains nothing")
end
M.Cast(1499)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "pet", "Cast-12", 17253)
M.HiddenAura("nameplate2")
Sprang("nor the pet's Bite")

-- Fire and frost: only traps bring them to a hunter's fight.
M.Cast(13813)
M.Fire("UNIT_COMBAT", "nameplate2", "WOUND", "", 120, 4)
Sprang("fire damage: the fire trap sprang")
M.Cast(13795)
M.Cast(13550)
M.HiddenAura("nameplate2")
M.Advance(3)
M.Fire("UNIT_COMBAT", "nameplate2", "WOUND", "", 21, 4)
Sprang("Immolation Trap's first burn, after its aura was taken for the sting's")
M.Cast(1499)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "RESIST", 0, 16)
Sprang("a frost resist: the trap sprang for nothing")
M.Cast(13795)
M.Fire("UNIT_COMBAT", "nameplate2", "IMMUNE", "", 0, 4)
Sprang("an immune enemy, for a fire trap")
M.Cast(1499)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "RESIST", 0, 64)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "RESIST", 0, 4)
check(ns.Traps.armed ~= nil, "a resist of another school is not the trap's")
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 80, 16)
check(ns.Traps.armed ~= nil, "frost damage never comes from a frost trap")
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 0, 1)
M.Fire("UNIT_COMBAT", "nameplate1", "MISS", "", 0, 1)
check(ns.Traps.armed ~= nil, "a miss says nothing")
M.inGroup = true
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "party1", "Cast-6", SECRET)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "RESIST", 0, 16)
check(ns.Traps.armed ~= nil, "a frost resist right after a group member's spell is theirs")
M.inGroup = false
M.Advance(1.625)
M.Fire("UNIT_COMBAT", "nameplate3", "WOUND", "RESIST", 0, 16)
check(ns.Traps.armed ~= nil, "a friendly unit's resist is not the trap's")
M.Advance(61)
M.combat, M.aurasSecret = false, false
NoErrors("while guessing")

---------------------------------------------------------------------------
-- The test trap, moving the icon, and the options.
---------------------------------------------------------------------------
before = #M.sounds
Slash("test")
eq(ns.Traps.armed and ns.Traps.armed.test, true, "/htt test shows a test trap")
eq(IconText(1), 15, "that runs for 15 seconds")
M.AddAura("nameplate1", 3355, 10)
check(ns.Traps.armed ~= nil, "a test trap never springs")
M.RemoveAura("nameplate1", 3355)
M.Advance(5.125)
eq(#M.sounds, before + 1, "its warning sounds too")
M.Advance(10)
eq(ns.Traps.armed, nil, "the test trap runs out")

Slash("unlock")
eq(ns.db.locked, false, "/htt unlock")
check(M.Visible(HunterTrapTimerFrame), "the icon shows to be moved")
eq(IconText(1), 60, "as a placeholder")
check(HunterTrapTimerFrame.mouse, "and takes the mouse")
HunterTrapTimerFrame.scripts.OnDragStart(HunterTrapTimerFrame)
check(HunterTrapTimerFrame.moving, "it can be dragged")
HunterTrapTimerFrame.center = { 1060, 640 }
HunterTrapTimerFrame.scripts.OnDragStop(HunterTrapTimerFrame)
HunterTrapTimerFrame.center = nil
eq(ns.db.x, 100, "the new position is saved (x)")
eq(ns.db.y, 100, "the new position is saved (y)")
local point = HunterTrapTimerFrame.points[1]
check(point[1] == "CENTER" and point[4] == 100 and point[5] == 100, "and applied")
Slash("lock")
eq(ns.db.locked, true, "/htt lock")
check(not M.Visible(HunterTrapTimerFrame), "the placeholder goes")
HunterTrapTimerFrame.scripts.OnDragStart(HunterTrapTimerFrame)
check(not HunterTrapTimerFrame.moving, "a locked icon cannot be dragged")

local boxes, sliders = Frames("CheckButton"), Frames("Slider")
eq(#boxes, 3, "three checkboxes")
eq(#sliders, 2, "two sliders")
boxes[1]:SetChecked(false)
boxes[1]:Click()
eq(ns.db.locked, false, "the lock checkbox unlocks")
boxes[1]:SetChecked(true)
boxes[1]:Click()

sliders[1]:SetValue(64, true)
eq(ns.db.iconSize, 64, "the size slider")
M.Cast(1499)
eq(Icons()[1].w, 64, "the icon grows")
eq(Icons()[1].text.font[2], 27, "and so do its seconds")

Button("Reset position"):Click()
eq(ns.db.x, 0, "Reset position puts the icon back (x)")
eq(ns.db.y, -150, "Reset position puts the icon back (y)")

sliders[2]:SetValue(0, true)
eq(ns.db.warnSeconds, 0, "the warning slider")
eq(sliders[2].Text.textValue, "Seconds left: |cffffffffOff|r", "0 turns the warning off")
before = #M.sounds
M.Advance(59)
eq(#M.sounds, before, "no warning sound")
eq(IconColor(1), WHITE, "no red")
check(not Icons()[1].flash:IsPlaying(), "no flash")
M.Advance(2)

sliders[2]:SetValue(10, true)
boxes[3]:SetChecked(false)
boxes[3]:Click()
eq(ns.db.warnSound, false, "the sound checkbox")
M.Cast(1499)
M.Advance(51)
eq(#M.sounds, before, "no sound when it is off")
check(Icons()[1].flash:IsPlaying(), "but the icon flashes")
boxes[2]:SetChecked(false)
boxes[2]:Click()
M.Advance(1)
check(not Icons()[1].flash:IsPlaying(), "the flash checkbox")
M.Advance(10)

Button("Test"):Click()
check(ns.Traps.armed and ns.Traps.armed.test, "the Test button")
M.Advance(16)

Slash("reset")
eq(ns.db.warnSound, true, "/htt reset restores the defaults")
eq(ns.db.iconSize, 48, "including the size")
eq(sliders[1].value, 48, "and the options show it")

Slash("")
M.Advance(0.5)
check(M.openedOptions, "/htt opens the options")
for _, line in ipairs(M.printed) do
    check(not line:find("open the game menu", 1, true), "the options opened: " .. line)
end
NoErrors("in the options")

---------------------------------------------------------------------------
-- The probe.
---------------------------------------------------------------------------
-- Recorded on demand only: until /htt probe log, it listens to nothing.
local function ProbeListens()
    for _, f in ipairs(M.allFrames) do
        local events = M.eventFrames[f]
        if events and events.PLAYER_REGEN_DISABLED then
            return true
        end
    end
    return false
end
check(not ProbeListens(), "the probe listens to no event before recording")
M.Cast(1499)
M.Fire("PLAYER_REGEN_DISABLED")
check(Has(ProbeText(), "(0 lines):\n  empty"), "nothing is logged before recording")
M.Advance(61)

before = #M.printed
Slash("probe log")
check(ProbeListens(), "/htt probe log starts recording")
check(M.printed[before + 1]:find("probe recording", 1, true) ~= nil, "and says so")
M.AddUnit("target", { name = "Kobold", auras = {} })
M.Cast(1499)
M.AddAura("nameplate1", 3355, 10)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 25, 16)
M.Fire("UNIT_AURA", "nameplate1", SECRET)
M.Fire("UNIT_AURA", "nameplate1", SECRET)
M.Fire("UNIT_AURA", "nameplate1", SECRET)
M.Fire("SPELL_UPDATE_COOLDOWN", 1499)
M.Fire("PLAYER_TOTEM_UPDATE", 1)
M.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
M.Cast(1499)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "party1", "Cast-11", SECRET)
M.HiddenAura("nameplate2")
M.Advance(1.625)
M.HiddenAura("nameplate2")
local text = ProbeText()
check(HunterTrapTimerProbe:IsShown(), "/htt probe opens its window")
check(Has(text, "Hunter Trap Timer " .. C_AddOns.GetAddOnMetadata("HunterTrapTimer", "Version") .. " - probe"),
    "the report's title")
check(Has(text, "Combat log restricted: true"), "the combat log answer")
check(Has(text, "1499 Freezing Trap: 0, 1, false; enabled true, active false"), "the trap spells known")
check(Has(text, "effect 3355 Freezing Trap Effect: 1, false"), "and their effects")
check(not Has(text, "14310 Freezing Trap"), "not the ranks unknown")
check(Has(text, "still recording"), "the report says it is still recording")
check(Has(text, "UNIT_SPELLCAST_SUCCEEDED player: 1499 Freezing Trap"), "the cast is logged")
check(Has(text, "addon: armed: freezing (spell 1499), 60 s"), "the addon's own notes")
check(Has(text, "UNIT_AURA nameplate1 (Kobold): added: 3355 Freezing Trap Effect, from player, by a player true"), "the aura is logged")
check(Has(text, "UNIT_SPELLCAST_SUCCEEDED party1 (Friend): secret"), "the group's casts are logged")
check(Has(text, "addon: aura on nameplate2 not the trap's: a group member's cast"), "and why an aura was not the trap's")
check(Has(text, "addon: sprang (guessed from an aura): freezing on nameplate2"), "and a guess")
check(Has(text, "addon: sprang (its effect 3355): freezing on nameplate1"), "the spring is logged")
check(Has(text, "UNIT_COMBAT nameplate1 (Kobold): WOUND  25, school 16"), "damage is logged")
check(Has(text, "payload secret; trap effects: 3355 found") and Has(text, "(x3)"), "repeats fold into one line")
check(Has(text, "SPELL_UPDATE_COOLDOWN 1499; trap 1499: enabled true"), "cooldowns are logged")
check(Has(text, "PLAYER_TOTEM_UPDATE 1: false, , 0, 0, 0"), "totems are logged")
check(Has(text, "NAME_PLATE_UNIT_REMOVED nameplate2 (Gnoll): dead false"), "nameplates going are logged")
check(Has(text, "Target: Kobold; yours: none; yours cc: none; its harmful auras:\n  none"), "the target's auras")
check(Has(text, "yours cc: " .. M.lastInstanceID .. " (cc filtered out false, duration table)"),
    "the hunter's crowd control on an enemy, by instance ID")

M.combat, M.aurasSecret = true, true
M.units.target.auras = { { spellId = 3355 } }
text = ProbeText()
check(Has(text, "In combat: true"), "in combat")
check(Has(text, "enabled true, active true, start secret, duration secret"), "secret cooldowns")
check(Has(text, "  1: secret"), "secret target auras")
check(Has(text, "yours: error: Auras cannot be accessed when secret while tainted"), "errors are shown")
M.combat, M.aurasSecret = false, false
M.units.target.auras = {}
NoErrors("in the probe")

Slash("probe clear")
check(Has(ProbeText(), "(0 lines, still recording):\n  empty"), "/htt probe clear empties the log")
for _ = 1, 250 do
    M.Fire("PLAYER_REGEN_DISABLED")
    M.Fire("PLAYER_REGEN_ENABLED")
end
check(Has(ProbeText(), "(400 lines, still recording)"), "the log keeps the last 400 lines")

-- Enemies are only logged around a trap.
Slash("probe clear")
M.Advance(61)
M.Fire("UNIT_AURA", "nameplate2", {})
check(Has(ProbeText(), "(0 lines, still recording)"), "nothing logged long after the last trap")

-- Run again, /htt probe log stops and shows the report.
HunterTrapTimerProbe:Hide()
Slash("probe log")
check(HunterTrapTimerProbe:IsShown(), "stopping shows the report")
text = HunterTrapTimerProbe.Edit.textValue
check(Has(text, "recording stopped") and not Has(text, "still recording"), "the log ends where recording stopped")
check(not ProbeListens(), "and the probe listens to nothing again")
M.Cast(1499)
check(not Has(ProbeText(), "armed: freezing"), "nothing more is logged")
M.Advance(61)
NoErrors("at the end of session 1")

---------------------------------------------------------------------------
-- Session 2: bad saved settings.
---------------------------------------------------------------------------
ns = NewSession({ saved = { iconSize = 1000, warnSeconds = -3, x = "a", y = 1e9, locked = "yes", showEffect = 0 / 0,
    warnFlash = false, version = 99 } })
NoErrors("with bad settings")
eq(ns.db.iconSize, 96, "the size is capped")
eq(ns.db.warnSeconds, 0, "the warning is at least 0")
eq(ns.db.x, 0, "a bad x is replaced")
eq(ns.db.y, 4000, "a far y is brought back")
eq(ns.db.locked, true, "a bad lock is replaced")
eq(ns.db.showEffect, nil, "the old effect setting is dropped")
eq(ns.db.warnFlash, false, "good settings are kept")
eq(ns.db.version, 1, "the version is set")
ns = NewSession({ saved = { iconSize = 0 / 0 } })
eq(ns.db.iconSize, 48, "NaN is replaced")

---------------------------------------------------------------------------
-- Session 2b: a /reload keeps the armed trap; a new login does not.
---------------------------------------------------------------------------
-- Puts a trap down, lets seconds pass, and leaves the game (PLAYER_LOGOUT,
-- as on a /reload or a logout); then comes back after a pause.
local function LeaveAndCome(spellID, seconds, reloading, pause)
    ns = NewSession()
    M.Fire("PLAYER_ENTERING_WORLD", true, false)
    if spellID then
        M.Cast(spellID)
    else
        Slash("test")
    end
    M.Advance(seconds)
    M.Fire("PLAYER_LOGOUT")
    local saved, clock = HunterTrapTimerDB, M.time
    ns = NewSession({ saved = saved, time = clock + (pause or 2) })
    M.Fire("PLAYER_ENTERING_WORLD", not reloading, reloading)
end

LeaveAndCome(1499, 20, true)
eq(ns.Traps.armed and ns.Traps.armed.trap.key, "freezing", "after a /reload the trap is armed again")
eq(IconText(1), 38, "with the time it has left")
eq(Icons()[1].cooldown.duration, 60, "and its whole sweep")
eq(ns.db.armed, nil, "the saved trap is cleared once taken back")
M.Advance(28.125)
eq(#M.sounds, 1, "its warning still comes")
M.Advance(10)
eq(ns.Traps.armed, nil, "and it runs out on time")
NoErrors("after a /reload")

LeaveAndCome(1499, 50, true)
M.Advance(1)
check(ns.Traps.armed ~= nil, "a trap with 8 seconds left is taken back")
eq(#M.sounds, 0, "a warning given before the /reload is not given again")
M.Advance(8)

LeaveAndCome(1499, 5, false)
eq(ns.Traps.armed, nil, "after a login the trap is gone with the character")
eq(ns.db.armed, nil, "and the saved trap is cleared")

LeaveAndCome(1499, 50, true, 15)
eq(ns.Traps.armed, nil, "a trap that ran out during the /reload is not taken back")
ns = NewSession()
M.Fire("PLAYER_ENTERING_WORLD", true, false)
M.Cast(1499)
Slash("clear")
M.Fire("PLAYER_LOGOUT")
eq(HunterTrapTimerDB.armed, nil, "a cleared trap is not saved for the /reload")
LeaveAndCome(nil, 5, true)
eq(ns.Traps.armed, nil, "nor a test trap")

-- Saved data that is not a trap is dropped.
ns = NewSession({ saved = { armed = { key = "net", spellID = 1499, start = M.time, duration = 60 } } })
M.Fire("PLAYER_ENTERING_WORLD", false, true)
eq(ns.Traps.armed, nil, "an unknown trap is not taken back")
ns = NewSession({ saved = { armed = { key = "freezing", spellID = "x", start = M.time, duration = 60 } } })
M.Fire("PLAYER_ENTERING_WORLD", false, true)
eq(ns.Traps.armed, nil, "nor one with a bad spell")
NoErrors("with bad saved traps")

---------------------------------------------------------------------------
-- Session 3: not a hunter.
---------------------------------------------------------------------------
ns = NewSession({ class = "MAGE", known = {} })
M.Cast(1499)
eq(ns.Traps.armed, nil, "other classes never see a trap")
check(Has(ProbeText(), "Trap spells you know"), "the probe still answers")
Slash("test")
eq(IconText(1), 15, "the test trap still shows")
NoErrors("for a mage")

---------------------------------------------------------------------------
-- Session 4: every client language.
---------------------------------------------------------------------------
-- KEYS: the texts the code looks up in its translations (from run.lua).
local isKey = {}
for _, key in ipairs(KEYS) do
    isKey[key] = true
end
local function Specs(text)
    local out = {}
    for spec in text:gmatch("%%[-0-9.]*[sd%%]") do
        out[#out + 1] = spec
    end
    return table.concat(out, " ")
end
check(#KEYS >= 20, "the texts the code translates were found: " .. #KEYS)
for _, locale in ipairs({ "deDE", "esES", "esMX", "frFR", "itIT", "koKR", "ptBR", "ruRU", "zhCN", "zhTW" }) do
    ns = NewSession({ locale = locale })
    local L = ns.L
    -- Complete, no stale keys, same placeholders.
    local missing, badSpecs, stale = {}, {}, {}
    for _, key in ipairs(KEYS) do
        local text = rawget(L, key)
        if text == nil then
            missing[#missing + 1] = key
        elseif Specs(text) ~= Specs(key) then
            badSpecs[#badSpecs + 1] = key .. " => " .. text
        end
    end
    for key in pairs(L) do
        if not isKey[key] then
            stale[#stale + 1] = key
        end
    end
    eq(#missing, 0, locale .. ": every text translated" .. (missing[1] and (" (missing: " .. missing[1] .. ")") or ""))
    eq(#badSpecs, 0, locale .. ": placeholders kept" .. (badSpecs[1] and (" (" .. badSpecs[1] .. ")") or ""))
    eq(#stale, 0, locale .. ": no unused texts" .. (stale[1] and (" (" .. stale[1] .. ")") or ""))
    -- The options page, the icon and the commands work in this language.
    eq(Frames("CheckButton")[1].Text.textValue, L["Lock the icon"], locale .. ": options page translated")
    eq(Frames("Slider")[2].Text.textValue, L["Seconds left"] .. ": |cffffffff" .. L["%d s"]:format(10) .. "|r",
        locale .. ": seconds in the client's language")
    local before = #M.printed
    Slash("help")
    Slash("unlock")
    eq(#M.printed, before + 6, locale .. ": help and unlock printed")
    eq(M.printed[#M.printed], "|cffabd473Hunter Trap Timer|r: " .. L["icon unlocked: drag it where you want it, then /htt lock."],
        locale .. ": unlock message translated")
    check(M.Visible(HunterTrapTimerFrame), locale .. ": the icon shows unlocked")
    NoErrors("in " .. locale)
end
-- The clients without a file of their own.
ns = NewSession({ locale = "enGB" })
eq(rawget(ns.L, "Icon"), nil, "enGB uses the English texts")
ns = NewSession({ locale = "ptPT" })
eq(ns.L["Icon"], "Ícone", "ptPT uses the Brazilian Portuguese texts")

---------------------------------------------------------------------------
-- Release files.
---------------------------------------------------------------------------
-- The changelog's newest entry is the version in the TOC.
local tocVersion = SOURCES["HunterTrapTimer.toc"]:match("## Version: ([%d%.]+)")
check(tocVersion ~= nil, "the TOC has a version")
eq(SOURCES["CHANGELOG.md"]:match("\n## ([%d%.]+)"), tocVersion, "the changelog's newest entry matches the TOC version")
-- The packager names the folder after package-as; the game needs it to match the TOC.
eq(SOURCES[".pkgmeta"]:match("package%-as: (%S+)"), "HunterTrapTimer", "packaged under the TOC's folder name")
check(SOURCES[".pkgmeta"]:find("\nignore:\n    %- Tests\n") ~= nil, "the tests are left out of the package")

eq(#leaks, 0, "no leaked globals: " .. table.concat(leaks, ", "))

print_real(("%d passed, %d failed"):format(passes, failures))
return failures
