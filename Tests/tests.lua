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

-- The trap down in a slot ("fire" or "frost"): its key, or nil.
local function Key(slot)
    local entry = ns.Traps.armed[slot]
    return entry and entry.trap.key
end
local function NoTrap()
    return next(ns.Traps.armed) == nil
end

-- The row's icons, in its order (made as it needs them).
local function RowIcons()
    local list = {}
    for _, f in ipairs(M.allFrames) do
        if f.parent == HunterTrapTimerFrame and f.roundSweep then
            list[#list + 1] = f
        end
    end
    return list
end
-- The first icon on screen showing a slot's trap or effect ("fire" or
-- "frost"), else a stand-in that is not on screen. The icons are redrawn
-- first: between ticks they lag by up to one tick.
local OFF_SCREEN = { shown = false }
local function Icon(slot)
    ns.Display.Refresh()
    for _, f in ipairs(RowIcons()) do
        if f.slot == slot and M.Visible(f) then
            return f
        end
    end
    return OFF_SCREEN
end
-- The texts on the row's icons on screen, in its order: "60 s, 29 s".
local function RowTexts()
    ns.Display.Refresh()
    local texts = {}
    for _, f in ipairs(RowIcons()) do
        if M.Visible(f) then
            texts[#texts + 1] = tostring(f.text.textValue)
        end
    end
    return table.concat(texts, ", ")
end
-- The newest effect of a slot's trap that lasts, or nil.
local function Effect(slot)
    local found
    for _, effect in ipairs(ns.Traps.effects) do
        if effect.trap.slot == slot then
            found = effect
        end
    end
    return found
end
-- The text shown on a slot's icon now ("37 s" below it, 37 on it), or nil
-- when it is not on screen. The icons are redrawn first: between ticks they
-- lag by up to one tick.
local function IconLabel(slot)
    ns.Display.Refresh()
    local icon = Icon(slot)
    return icon and M.Visible(icon) and icon.text.textValue or nil
end
-- The seconds in that text.
local function IconText(slot)
    local label = IconLabel(slot)
    return label and tonumber(tostring(label):match("%d+")) or label
end
local function IconColor(slot)
    local color = Icon(slot).text.color
    return ("%g,%g,%g"):format(color[1], color[2], color[3])
end
local WHITE, RED, GOLD = "1,1,1", "1,0.25,0.25", "1,0.82,0"
-- How far left of the first place a slot's icon sits (0: in the first place).
local function IconShift(slot)
    ns.Display.Refresh()
    local point = Icon(slot).points[1]
    assert(point[1] == "CENTER" and point[2] == HunterTrapTimerFrame and point[3] == "CENTER" and point[5] == 0,
        "icons sit in a row from the first place")
    return -point[4]
end

-- The frames of a kind, or of a kind and template.
local function Frames(kind, template)
    local list = {}
    for _, f in ipairs(M.allFrames) do
        if f.kind == kind and (not template or f.template == template) then
            list[#list + 1] = f
        end
    end
    return list
end
-- The options page's radio button showing text.
local function Radio(text)
    for _, f in ipairs(Frames("CheckButton", "UIRadioButtonTemplate")) do
        if f.text.textValue == text then
            return f
        end
    end
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
eq(ns.db.iconSize, 37, "defaults loaded: a totem's size")
check(M.mainCategory and M.mainCategory.name == "Hunter Trap Timer", "settings category registered")
check(M.addonCategory == M.mainCategory, "registered as addon category")
eq(SLASH_HUNTERTRAPTIMER1, "/htt", "slash command")
eq(M.forbidden, nil, "the combat log is never registered")
check(not M.Visible(HunterTrapTimerFrame), "nothing shows before a trap is down")

M.Cast(1499)
eq(Key("frost"), "freezing", "Freezing Trap is armed")
eq(IconText("frost"), 60, "the icon counts from 60")
eq(IconText("fire"), nil, "no fire trap, no fire icon")
eq(IconShift("frost"), 0, "a lone trap's icon takes the first place")
local icon = Icon("frost")
eq(icon.texture.path, "icon:1499", "the trap's icon")
eq(icon.sweep.start, M.time, "the sweep starts now")
eq(icon.sweep.duration, 60, "the sweep lasts 60 seconds")
check(icon.sweep.reverse, "the lit part is the time left")
eq(IconColor("frost"), GOLD, "a full minute shows gold, as a totem's")

M.Advance(20)
eq(IconText("frost"), 40, "40 seconds left after 20")
eq(IconColor("frost"), WHITE, "under a minute, white, as a totem's")
M.Advance(29.875)
eq(#M.sounds, 0, "no warning with more than 10 seconds left")
check(not icon.flash:IsPlaying(), "no flash yet")
M.Advance(0.25)
eq(#M.sounds, 1, "the warning sound plays with 10 seconds left")
eq(IconColor("frost"), RED, "the seconds turn red")
check(icon.flash:IsPlaying(), "the icon flashes")
M.Advance(5)
eq(#M.sounds, 1, "the sound plays once")
M.Advance(5)
eq(Key("frost"), nil, "the trap ran out after 60 seconds")
check(not M.Visible(HunterTrapTimerFrame), "the icon is gone")
check(not icon.flash:IsPlaying(), "the flash stopped")

-- A fire trap and a frost trap can be down at once; a new trap replaces only
-- the one of its own school.
M.Cast(1499)
M.Advance(10)
M.Cast(13795)
eq(Key("fire"), "immolation", "Immolation Trap is armed")
eq(Key("frost"), "freezing", "beside Freezing Trap")
eq(IconText("fire"), 60, "each with its icon: the fire trap's")
eq(IconText("frost"), 50, "and the frost trap's, counting on")
eq(Icon("fire").texture.path, "icon:13795", "the fire trap shows its own icon")
eq(IconShift("fire"), 0, "the fire trap's icon comes first")
eq(IconShift("frost"), 37, "the frost trap's to its left, as far apart as totems")
M.Cast(13813)
eq(Key("fire"), "explosive", "Explosive Trap replaces Immolation Trap")
eq(IconText("fire"), 60, "and counts from 60")
eq(Icon("fire").texture.path, "icon:13813", "with its own icon")
eq(Key("frost"), "freezing", "the frost trap stays")
M.Cast(13809)
eq(Key("frost"), "frost", "Frost Trap replaces Freezing Trap")
eq(IconText("frost"), 60, "and counts from 60")
eq(Key("fire"), "explosive", "the fire trap stays")
-- When the first icon goes, the other one takes its place.
M.Advance(30)
M.Cast(1499)
M.Advance(30.125)
eq(Key("fire"), nil, "the fire trap ran out")
eq(IconText("frost"), 30, "the frost trap counts on")
eq(IconShift("frost"), 0, "and its icon moves to the first place")
M.Advance(30)
check(NoTrap(), "both ran out")

-- Each trap warns on its own.
local before = #M.sounds
M.Cast(1499)
M.Advance(5)
M.Cast(13795)
M.Advance(45.125)
eq(#M.sounds, before + 1, "the frost trap's warning")
eq(IconColor("frost"), RED, "its seconds turn red")
eq(IconColor("fire"), WHITE, "not the fire trap's")
check(not Icon("fire").flash:IsPlaying(), "nor does the fire trap's icon flash")
M.Advance(5)
eq(#M.sounds, before + 2, "then the fire trap's")
eq(IconColor("fire"), RED, "and its seconds turn red")
M.Advance(10)
check(NoTrap(), "both ran out")

-- Casts that are not traps, or cannot be read, change nothing.
M.Cast(13795)
M.Cast(75)
eq(Key("fire"), "immolation", "another spell changes nothing")
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-2", SECRET)
eq(Key("fire"), "immolation", "a secret spell ID changes nothing")
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "pet", "Cast-3", 1499)
eq(Key("frost"), nil, "the pet's casts are not listened to")
NoErrors("with unreadable casts")

-- A rank the list lacks is still known by its name.
M.Cast(99001)
eq(Key("frost"), "freezing", "an unknown rank of Freezing Trap is found by name")
M.Advance(61)

-- /htt clear drops the countdowns, should they go wrong.
M.Cast(1499)
M.Cast(13795)
local sounds = #M.sounds
Slash("clear")
check(NoTrap(), "/htt clear drops both countdowns")
check(not M.Visible(HunterTrapTimerFrame), "and their icons")
eq(M.printed[#M.printed], "|cffabd473Hunter Trap Timer|r: countdown cleared.", "and says so")
M.Advance(61)
eq(#M.sounds, sounds, "a cleared trap gives no warning")
Slash("clear")
eq(M.printed[#M.printed], "|cffabd473Hunter Trap Timer|r: there is no countdown to clear.",
    "with no trap down, it says there is nothing to clear")
Slash("test")
Slash("clear")
check(NoTrap(), "it clears the test traps too")
NoErrors("clearing")

---------------------------------------------------------------------------
-- The trap springs, so it is gone: its icon goes. As a trap goes, sprung or
-- run out, the client fires SPELL_UPDATE_COOLDOWN with its spell ID, however
-- far the hunter is (M.Spring); it fires it as the trap is cast too (M.Cast).
-- The effects a trap shows once it sprang are set aside here, and tested
-- after.
---------------------------------------------------------------------------
M.AddUnit("nameplate1", { name = "Kobold" })
M.AddUnit("nameplate2", { name = "Gnoll" })
M.AddUnit("party1", { name = "Friend", friendly = true })
ns.db.showEffects = false
for _, sounds in pairs(ns.db.sounds) do
    sounds.ended = "none"
end

local function Sprang(slot, message)
    eq(Key(slot), nil, message)
    check(not M.Visible(Icon(slot)), message .. ": its icon is gone")
end

M.Cast(13809)
eq(Key("frost"), "frost", "the cast's own cooldown events leave the trap down")
M.Advance(5)
before = #M.sounds
M.Spring(13809)
eq(Key("frost"), "frost", "its cooldown event is told a moment later")
M.Advance(0.5)
Sprang("frost", "its cooldown event: the trap sprang")
M.Advance(60)
eq(#M.sounds, before, "no warning for a trap that sprang")

-- In combat, with no enemy in sight, and after its cooldown is over.
M.combat, M.aurasSecret = true, true
M.Cast(13813)
M.Advance(35)
M.Spring(13813)
M.Advance(0.5)
Sprang("fire", "a trap that springs after its cooldown, far away in combat")

-- With both down, the event tells which trap sprang.
M.Cast(13809)
M.Cast(13795)
M.Advance(2)
M.Spring(13795)
M.Advance(0.5)
Sprang("fire", "with both traps down, the fire trap's event springs it")
eq(Key("frost"), "frost", "and not the frost trap")
eq(IconShift("frost"), 0, "whose icon moves to the first place")
M.Spring(13809)
M.Advance(0.5)
Sprang("frost", "then the frost trap's springs it")

-- Events that are not the trap's going.
M.Cast(13795)
M.Fire("SPELL_UPDATE_COOLDOWN", 13795)
M.Advance(0.375)
M.Fire("SPELL_UPDATE_COOLDOWN", 13795)
M.Advance(0.5)
eq(Key("fire"), "immolation", "events just after its cast are the cast's own")
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", 13809)
M.Fire("SPELL_UPDATE_COOLDOWN", 13809)
M.Advance(0.5)
eq(Key("frost"), "frost", "even with no UNIT_SPELLCAST_SENT before them")
for _, other in ipairs({ 75, 1242139, 1324500, 13809, 13813, 14302 }) do
    M.Fire("SPELL_UPDATE_COOLDOWN", other)
end
M.Fire("SPELL_UPDATE_COOLDOWN", SECRET)
M.Fire("SPELL_UPDATE_COOLDOWN")
M.Advance(0.5)
eq(Key("fire"), "immolation", "another spell's event, another trap's or rank's, or a secret one, leave it down")
-- Cast again once its cooldown is over: the new cast's global cooldown comes
-- first. The trap stays though that cast fails...
M.Advance(30)
local first = ns.Traps.armed.fire
M.Fire("SPELL_UPDATE_COOLDOWN", 13795)
M.Fire("UNIT_SPELLCAST_SENT", "player", "", "Cast-1", 13795)
M.Fire("UNIT_SPELLCAST_FAILED", "player", "Cast-1", 13795)
M.Advance(0.5)
eq(ns.Traps.armed.fire, first, "a new cast's global cooldown is not the trap's going, though that cast failed")
-- ... and one that goes off replaces it.
M.Cast(13795)
M.Advance(0.5)
check(ns.Traps.armed.fire ~= first, "a new cast that goes off replaces it")
eq(IconText("fire"), 60, "counting from 60")
-- In its last moment, the event is the trap running out.
local notes = {}
ns.Log = function(text, ...)
    notes[#notes + 1] = text:format(...)
end
M.Advance(58.75)
M.Spring(13795)
M.Advance(0.5)
eq(Key("fire"), nil, "the trap is gone")
eq(notes[#notes], "ran out: immolation", "an event in its last moment is the trap running out")
M.Cast(13809)
M.Advance(60.125)
eq(notes[#notes], "ran out: frost", "a trap runs out after 60 seconds")
M.Spring(13809)
M.Advance(0.5)
eq(notes[#notes], "ran out: frost", "and its event after that changes nothing")
ns.Log = function() end
M.combat, M.aurasSecret = false, false
NoErrors("with cooldown events")

-- Its effect's aura, when it can be read, tells at once.
M.Cast(13809)
M.Advance(5)
M.AddAura("nameplate1", 13810, 10)
Sprang("frost", "Frost Trap's aura on an enemy: the trap sprang")
M.Spring(13809)
M.Advance(0.5)
check(NoTrap(), "and its cooldown event after it changes nothing")
M.RemoveAura("nameplate1", 13810)

-- Auras that are not this trap's.
M.Cast(1499)
M.AddAura("nameplate1", 3355, 20, { appliedAt = M.time - 5 })
check(Key("frost") ~= nil, "an aura from before the trap went down is not its effect")
M.RemoveAura("nameplate1", 3355)
M.AddAura("nameplate2", 3355, 10, { source = "nameplate3" })
check(Key("frost") ~= nil, "another hunter's freeze is not ours")
M.RemoveAura("nameplate2", 3355)
M.AddAura("nameplate2", 3355, 10, { source = "party1", fromPlayer = true })
check(Key("frost") ~= nil, "nor a group member's, though it is a player's")
M.RemoveAura("nameplate2", 3355)
M.AddAura("party1", 3355, 10)
check(Key("frost") ~= nil, "only enemies' auras are looked at")
M.RemoveAura("party1", 3355)
M.AddAura("nameplate1", 13797, 15)
check(Key("frost") ~= nil, "another trap's effect is not this trap's")
M.RemoveAura("nameplate1", 13797)

-- Auras that cannot be read, listed as readable; and, the guesses gone, an
-- aura that turns up on an enemy in combat says nothing.
M.aurasSecret = true
M.AddAura("nameplate1", 3355, 10)
check(Key("frost") ~= nil, "an aura the lookup cannot find is not noticed")
M.RemoveAura("nameplate1", 3355)
M.combat = true
M.HiddenAura("nameplate1")
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "RESIST", SECRET, 16)
check(Key("frost") ~= nil, "nor an aura that cannot be read, or a frost resist")
M.combat, M.aurasSecret = false, false
M.Fire("UNIT_AURA", SECRET, SECRET)
M.Fire("UNIT_AURA", "nameplate1", SECRET)
check(Key("frost") ~= nil, "an update that cannot be read at all says nothing")
NoErrors("with secret auras")
M.Advance(61)

-- With both traps down, a readable aura tells which one sprang.
M.Cast(13809)
M.Cast(13795)
M.AddAura("nameplate1", 13810, 10)
Sprang("frost", "with both traps down, Frost Trap's aura springs the frost trap")
eq(Key("fire"), "immolation", "and not the fire trap")
M.RemoveAura("nameplate1", 13810)
M.Advance(2)
M.Cast(13809)
M.AddAura("nameplate2", 13797, 15)
Sprang("fire", "the burn's aura springs the fire trap")
eq(Key("frost"), "frost", "and not the frost trap")
M.RemoveAura("nameplate2", 13797)
M.Advance(61)

---------------------------------------------------------------------------
-- A trap that sprang shows its effect while it lasts. A Freezing Trap that
-- catches an enemy: its icon stays for the freeze, the seconds in ice blue,
-- until the enemy breaks free, with a sound of its own.
---------------------------------------------------------------------------
local ICE, FIRE = "0.5,0.8,1", "1,0.55,0.2"
local BREAK = SOUNDKIT.ALARM_CLOCK_WARNING_3
ns.db.showEffects = true
for key, sounds in pairs(ns.db.sounds) do
    sounds.ended = ns.DEFAULT_SOUNDS[key].ended
end
-- The client sends the hunter's combat text only once its unit is set, which
-- Blizzard's combat text does only when "Show combat text" is on (/htt probe,
-- 2026-11-18): the addon sets it, and leaves Blizzard's "vehicle" alone.
eq(M.combatTextUnit, "player", "the addon has the client send the hunter's combat text")
M.combatTextUnit = "vehicle"
M.Fire("PLAYER_ENTERING_WORLD", false, false)
eq(M.combatTextUnit, "vehicle", "it leaves alone the unit Blizzard's combat text set")
M.combatTextUnit = nil
M.Fire("PLAYER_ENTERING_WORLD", false, false)
eq(M.combatTextUnit, "player", "and sets it again on entering the world, when none is set")
M.combat, M.aurasSecret = true, true
M.Cast(1499)
M.Advance(3)
before = #M.sounds
M.Spring(1499)
M.Advance(0.5)
eq(Key("frost"), nil, "the Freezing Trap sprang")
check(M.Visible(Icon("frost")), "its icon stays for the freeze")
eq(IconText("frost"), 9, "counting rank 1's 10 seconds, rounded down as the game's aura tooltips (9.5 left)")
eq(IconColor("frost"), ICE, "in ice blue")
icon = Icon("frost")
eq(icon.texture.path, "icon:3355", "with the freeze's icon")
eq(icon.sweep.duration, 10, "and its sweep")
check(not icon.flash:IsPlaying(), "it does not flash")
icon.scripts.OnEnter(icon)
eq(table.concat(GameTooltip.lines, " / "), "Freezing Trap Effect / Enemy frozen / 9 |4second:seconds; remaining",
    "its tooltip says the enemy is frozen")
icon.scripts.OnLeave(icon)
M.Advance(4)
M.AuraFades(true)
check(M.Visible(Icon("frost")), "a harmful aura fading on the hunter is not the freeze's end")
eq(#M.sounds, before, "and plays nothing")
M.AuraFades()
check(not M.Visible(Icon("frost")), "the hunter's aura fades: the enemy broke free, the icon goes")
eq(#M.sounds, before + 1, "a sound plays")
eq(M.sounds[#M.sounds], BREAK, "its own, not the warning's")
M.Advance(10)
eq(#M.sounds, before + 1, "once")
-- The enemy breaks free before the trap is told (CONFIRM): a sting's tick,
-- the pet. Its aura's fading still ends the freeze, once.
M.Cast(1499)
M.Advance(2)
before = #M.sounds
M.Spring(1499)
M.Advance(0.25)
M.AuraFades()
M.Advance(0.5)
eq(Key("frost"), nil, "the Freezing Trap sprang")
check(not M.Visible(Icon("frost")), "the enemy broke free before the trap was told: no freeze is shown")
eq(#M.sounds, before + 1, "its end's sound plays")
M.Advance(10)
eq(#M.sounds, before + 1, "once")
M.Cast(1499)
M.Advance(2)
M.AuraFades()
M.Advance(1)
M.Spring(1499)
M.Advance(0.0625)
M.AuraFades()
M.Advance(0.5)
eq(IconText("frost"), 9, "an aura that faded before the trap sprang, or as it did, does not end its freeze")
M.AuraFades()
check(not M.Visible(Icon("frost")), "its own aura's fading does")
-- A client that will not play that sound plays the warning's.
M.silentSounds[BREAK] = true
M.Cast(1499)
M.Advance(2)
M.Spring(1499)
M.Advance(0.5)
M.AuraFades()
eq(M.sounds[#M.sounds], SOUNDKIT.RAID_WARNING, "a client that will not play it plays the warning's sound instead")
M.silentSounds[BREAK] = nil

-- With no sign of its end, the freeze lasts its rank's whole time.
M.Cast(14311)
M.Advance(2)
M.Spring(14311)
M.Advance(0.5)
eq(IconText("frost"), 19, "rank 3 freezes for 20 seconds")
eq(Icon("frost").texture.path, "icon:14309", "with its rank's icon")
M.Advance(19.375)
check(M.Visible(Icon("frost")), "until its time is up")
before = #M.sounds
M.Advance(0.25)
check(not M.Visible(Icon("frost")), "then the enemy broke free")
eq(#M.sounds, before + 1, "with its sound")
M.Cast(99001)
M.Advance(2)
M.Spring(99001)
M.Advance(0.5)
eq(IconText("frost"), 19, "a rank found by name freezes for the longest time")
Slash("clear")

-- The freeze took hold if, as the trap sprang, the hunter got an aura or
-- spell 1324500's event came; with neither (an immune enemy), there is none.
M.Cast(1499)
M.Advance(2)
M.Spring(1499, { aura = false })
M.Advance(0.5)
check(M.Visible(Icon("frost")), "spell 1324500's event alone tells the freeze took hold")
Slash("clear")
M.Cast(1499)
M.Advance(2)
M.Spring(1499, { hold = false })
M.Advance(0.5)
check(M.Visible(Icon("frost")), "and so does the hunter's aura alone")
Slash("clear")
M.Cast(1499)
M.Advance(2)
M.CombatText("SPELL_AURA_START")
M.Advance(1)
M.Spring(1499, { aura = false, hold = false })
M.Advance(0.5)
Sprang("frost", "with no sign it took hold, or an aura a second before, no freeze")
M.Cast(1499)
M.Advance(59)
M.Spring(1499)
M.Advance(0.5)
check(M.Visible(Icon("frost")), "with the signs it took hold, a spring in the trap's last moment freezes too")
Slash("clear")

-- A new frost trap shows beside the freeze, which still ends with its sound.
M.Cast(1499)
M.Advance(2)
M.Spring(1499)
M.Advance(0.5)
M.Cast(13809)
eq(Key("frost"), "frost", "a new frost trap")
eq(RowTexts(), "60 s, 9 s", "shows first, beside the freeze")
before = #M.sounds
M.AuraFades()
eq(#M.sounds, before + 1, "the freeze still ends with its sound")
eq(RowTexts(), "60 s", "and the new trap stays")
Slash("clear")

-- The row grows as it needs to (the user's case, 2026-11-17): a Frost Trap,
-- an Immolation Trap 30 seconds later, the Frost Trap springs, and 30
-- seconds after the Immolation Trap a new Frost Trap.
M.Cast(13809)
M.Advance(30)
M.Cast(13795)
M.Advance(20)
M.Spring(13809)
M.Advance(0.5)
eq(RowTexts(), "40 s, 29 s", "the fire trap down, then Frost Trap's ice")
M.Advance(9.5)
M.Cast(13809)
eq(RowTexts(), "30 s, 60 s, 20 s", "a new frost trap makes three: the traps down first, then the ice")
local row = RowIcons()
eq(-row[3].points[1][4], 74, "the third place two steps left of the first")
eq(table.concat(HunterTrapTimerFrame.clampInsets, ","), "-74,0,0,0", "the whole row is kept on the screen")
eq(row[3].slot, "frost", "the ice, of the frost school")
eq(row[3].texture.path, "icon:13810", "with its icon")
Slash("unlock")
for _, f in ipairs(M.allFrames) do
    if f.parent == HunterTrapTimerFrame and not f.roundSweep then
        eq(f.points[1][2], row[3], "unlocked, the cover spans the whole row, to its third place")
    end
end
Slash("lock")
row[3].scripts.OnEnter(row[3])
eq(GameTooltip.lines[2], "Ice on the ground", "and its tooltip")
-- Its second Frost Trap springs: two ices on the ground, oldest first.
M.Advance(5)
M.Spring(13809)
M.Advance(0.5)
eq(RowTexts(), "25 s, 14 s, 29 s", "the second ice beside the first, oldest first")
eq(#ns.Traps.effects, 2, "two effects of one trap at once")
eq(GameTooltip.lines[2], "Ice on the ground", "the tooltip goes on with its icon's place")
row[3].scripts.OnLeave(row[3])
M.Advance(14.25)
eq(RowTexts(), "11 s, 0 s, 15 s", "an effect's last second reads 0, as the game's aura tooltips")
M.Advance(0.375)
eq(RowTexts(), "10 s, 14 s", "the first ice gone, the row closes up")
eq(table.concat(HunterTrapTimerFrame.clampInsets, ","), "-37,0,0,0", "and keeps what is left on the screen")
M.Advance(15.5)
eq(RowTexts(), "", "all gone")
check(not M.Visible(HunterTrapTimerFrame), "the row with them")

-- Two freezes at once (the second trap's cast after the cooldown, while the
-- first one's enemy is still frozen): an aura of the hunter's fading ends
-- the one due to end first.
M.Cast(1499)
M.Advance(25)
M.Spring(1499)
M.Advance(5)
M.Cast(14311)
M.Advance(2)
M.Spring(14311)
M.Advance(0.5)
eq(RowTexts(), "2 s, 19 s", "two freezes, oldest first")
M.AuraFades()
eq(RowTexts(), "19 s", "an aura fading ends the one due to end first")
Slash("clear")

-- Read out of combat, the freeze lasts as long as its aura.
M.combat, M.aurasSecret = false, false
M.Cast(1499)
M.Advance(2)
M.AddAura("nameplate1", 3355, 8)
eq(Key("frost"), nil, "the freeze's aura springs the trap at once")
eq(IconText("frost"), 8, "and the freeze lasts as long as the aura")
M.AuraFades()
check(M.Visible(Icon("frost")), "an aura of the hunter's fading as it began is not its end")
M.Spring(1499)
M.Advance(0.5)
eq(IconText("frost"), 7, "the trap's event after it changes nothing")
M.Advance(7.75)
check(not M.Visible(Icon("frost")), "then the enemy broke free")
M.RemoveAura("nameplate1", 3355)

-- Frost Trap's ice stays on the ground its 30 seconds, in combat or out.
M.combat, M.aurasSecret = true, true
M.Cast(13809)
M.Advance(2)
M.Spring(13809)
M.Advance(0.5)
eq(Key("frost"), nil, "Frost Trap sprang")
eq(IconText("frost"), 29, "its ice shows for 30 seconds")
eq(IconColor("frost"), ICE, "in ice blue")
icon = Icon("frost")
eq(icon.texture.path, "icon:13810", "with the ice's icon")
icon.scripts.OnEnter(icon)
eq(GameTooltip.lines[2], "Ice on the ground", "its tooltip says what it is")
icon.scripts.OnLeave(icon)
before = #M.sounds
M.Fire("PLAYER_REGEN_ENABLED")
M.AuraFades()
check(M.Visible(Icon("frost")), "leaving combat, or an aura of yours fading, leaves the ice")
M.Advance(29.25)
check(M.Visible(Icon("frost")), "it stays its 30 seconds")
M.Advance(0.375)
check(not M.Visible(Icon("frost")), "and goes then")
eq(#M.sounds, before + 1, "with its trap's sound")
eq(M.sounds[#M.sounds], BREAK, "the third alarm clock by default")

-- Immolation Trap's burn, on the enemies an aura turned up on as it sprang,
-- lasts until they are all seen to die.
M.AddUnit("target", { name = "Kobold", guid = M.units.nameplate1.guid })
M.AddUnit("nameplate4", { name = "Guard", friendly = true })
M.Cast(13795)
M.Advance(2)
M.Spring(13795)
M.HiddenAura("nameplate1")
M.HiddenAura("target")
M.HiddenAura("nameplate4")
M.Advance(0.5)
eq(Key("fire"), nil, "Immolation Trap sprang")
eq(IconText("fire"), 14, "its burn shows for 15 seconds")
eq(IconColor("fire"), FIRE, "in orange")
icon = Icon("fire")
eq(icon.texture.path, "icon:13797", "with the burn's icon")
icon.scripts.OnEnter(icon)
eq(GameTooltip.lines[2], "Burning", "its tooltip says what it is")
icon.scripts.OnLeave(icon)
eq(#Effect("fire").victims, 1, "on one enemy, seen as the target too, and not on a friend")
M.Advance(3)
M.HiddenAura("nameplate2")
M.units.nameplate2.dead = true
M.Fire("UNIT_HEALTH", "nameplate2")
check(M.Visible(Icon("fire")), "another enemy that dies leaves the burn")
before = #M.sounds
M.units.nameplate1.dead, M.units.target.dead = true, true
M.Fire("UNIT_HEALTH", "target")
check(not M.Visible(Icon("fire")), "the enemy it burned died, seen as the target: the burn is over")
eq(#M.sounds, before + 1, "with its trap's sound")
eq(M.sounds[#M.sounds], BREAK, "the third alarm clock by default")
M.units.nameplate1.dead, M.units.nameplate2.dead, M.units.target.dead = false, false, false
-- An enemy's nameplate goes as it dies, or as it goes out of sight.
M.Cast(13795)
M.Advance(2)
M.Spring(13795)
M.HiddenAura("nameplate1")
M.Advance(0.5)
M.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
check(M.Visible(Icon("fire")), "its nameplate going out of sight leaves the burn")
M.units.nameplate1.dead = true
M.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate1")
check(not M.Visible(Icon("fire")), "its nameplate going as it died ends it")
M.units.nameplate1.dead = false
-- Every enemy an aura turned up on as it sprang counts, and must die; one
-- whose GUID is secret is told by its unit.
M.units.nameplate2.secretGUID = true
M.Cast(13795)
M.Advance(2)
M.Spring(13795)
M.HiddenAura("nameplate1")
M.HiddenAura("nameplate2")
M.Advance(0.5)
eq(#Effect("fire").victims, 2, "every enemy an aura turned up on as it sprang counts")
M.units.nameplate1.dead = true
M.Fire("UNIT_HEALTH", "nameplate1")
check(M.Visible(Icon("fire")), "one of them dying leaves the burn")
M.units.nameplate2.dead = true
M.Fire("UNIT_HEALTH", "nameplate2")
check(not M.Visible(Icon("fire")), "both dead, it is over, the one with a secret GUID told by its unit")
M.units.nameplate1.dead, M.units.nameplate2.dead, M.units.nameplate2.secretGUID = false, false, nil

-- Explosive Trap's fire stays on the ground its 20 seconds, whoever dies.
M.Cast(13813)
M.Advance(2)
M.Spring(13813)
M.HiddenAura("nameplate1")
M.Advance(0.5)
eq(IconText("fire"), 19, "Explosive Trap's fire shows for 20 seconds (19.5 left, rounded down)")
eq(IconColor("fire"), FIRE, "in orange")
icon = Icon("fire")
eq(icon.texture.path, "icon:13812", "with the fire's icon")
icon.scripts.OnEnter(icon)
eq(GameTooltip.lines[2], "Fire on the ground", "its tooltip says what it is")
icon.scripts.OnLeave(icon)
eq(Effect("fire").victims, nil, "it keeps no enemies")
M.units.nameplate1.dead = true
M.Fire("UNIT_HEALTH", "nameplate1")
M.Fire("PLAYER_REGEN_ENABLED")
check(M.Visible(Icon("fire")), "an enemy dying, or leaving combat, leaves the fire")
M.units.nameplate1.dead = false
M.Advance(19.25)
check(M.Visible(Icon("fire")), "it stays its 20 seconds")
M.Advance(0.375)
check(not M.Visible(Icon("fire")), "and goes then")
-- With no enemy seen, it lasts until you leave combat, or its time is up.
M.Cast(13795)
M.Advance(2)
M.Spring(13795)
M.Advance(0.5)
eq(#Effect("fire").victims, 0, "a burn far away has no enemy seen")
M.Advance(5)
check(M.Visible(Icon("fire")), "it lasts")
M.Fire("PLAYER_REGEN_ENABLED")
check(not M.Visible(Icon("fire")), "until you leave combat")
M.Cast(13795)
M.Advance(2)
M.Spring(13795)
M.Advance(14.75)
check(M.Visible(Icon("fire")), "else it lasts its 15 seconds")
M.Advance(0.375)
check(not M.Visible(Icon("fire")), "and no more")
-- Read out of combat, a burn lasts as long as its aura.
M.combat, M.aurasSecret = false, false
M.Cast(13795)
M.Advance(2)
M.AddAura("nameplate1", 13797, 12)
eq(IconText("fire"), 12, "read out of combat, the burn lasts as long as its aura")
eq(#Effect("fire").victims, 1, "on the enemy it is on")
M.RemoveAura("nameplate1", 13797)
Slash("clear")

-- The options: effects not shown, and no sound.
M.combat, M.aurasSecret = true, true
ns.db.showEffects = false
M.Cast(1499)
M.Advance(2)
M.Spring(1499)
M.Advance(0.5)
Sprang("frost", "with effects not shown, the trap's icon goes")
before = #M.sounds
M.Advance(10)
eq(#M.sounds, before + 1, "the sound still plays as the enemy breaks free")
ns.db.sounds.immolation.ended, ns.db.sounds.immolation.early = "none", "none"
M.Cast(13795)
M.Advance(2)
M.Spring(13795)
M.Advance(0.5)
eq(Effect("fire"), nil, "and a burn with no sound for its end is not kept")
ns.db.sounds.immolation.early = "alarm2"
M.Cast(13795)
M.Advance(2)
M.Spring(13795)
M.Advance(0.5)
check(Effect("fire") ~= nil and not M.Visible(Icon("fire")), "one with a sound for its early end is, though not shown")
M.Fire("PLAYER_REGEN_ENABLED")
eq(M.sounds[#M.sounds], SOUNDKIT.ALARM_CLOCK_WARNING_2, "and leaving combat before its time plays that sound")
ns.db.sounds.immolation.ended, ns.db.sounds.immolation.early = "alarm2", "none"
M.Cast(13795)
M.Advance(2)
M.Spring(13795)
M.Advance(0.5)
check(Effect("fire") ~= nil, "so is one with a sound only for its time running out")
before = #M.sounds
M.Fire("PLAYER_REGEN_ENABLED")
eq(#M.sounds, before, "which an early end does not play")
M.Cast(13795)
M.Advance(2)
M.Spring(13795)
M.Advance(15)
eq(#M.sounds, before + 1, "but its time running out does")
eq(M.sounds[#M.sounds], SOUNDKIT.ALARM_CLOCK_WARNING_2, "that sound")
ns.db.sounds.immolation.ended, ns.db.sounds.immolation.early = "alarm3", "alarm3"
ns.db.sounds.freezing.ended, ns.db.sounds.freezing.early = "none", "none"
M.Cast(1499)
M.Advance(2)
M.Spring(1499)
M.Advance(0.5)
eq(Effect("frost"), nil, "with neither, no freeze is kept")
ns.db.showEffects = true
before = #M.sounds
M.Cast(1499)
M.Advance(2)
M.Spring(1499)
M.Advance(0.5)
check(M.Visible(Icon("frost")), "the freeze shown with no sound")
M.Advance(10)
eq(#M.sounds, before, "breaks free silently")
ns.db.sounds.freezing.ended, ns.db.sounds.freezing.early = "alarm3", "alarm3"

-- The freeze and the burn, on an enemy, can end early, with a sound of their
-- own (the user, 2026-11-18); run out, they play their end's.
local EARLY = SOUNDKIT.UI_BNET_TOAST
ns.db.sounds.freezing.early, ns.db.sounds.immolation.early = "toast", "toast"
M.Cast(1499)
M.Advance(2)
M.Spring(1499)
M.Advance(3)
before = #M.sounds
M.AuraFades()
eq(M.sounds[#M.sounds], EARLY, "an enemy breaking free before the freeze's time plays its early sound")
M.Cast(1499)
M.Advance(2)
M.Spring(1499)
M.Advance(0.25)
M.AuraFades()
M.Advance(0.5)
eq(M.sounds[#M.sounds], EARLY, "so does one breaking free before the trap was told")
M.Cast(1499)
M.Advance(2)
M.Spring(1499)
M.Advance(10)
eq(M.sounds[#M.sounds], BREAK, "the freeze running its time plays its end's")
M.Cast(1499)
M.Advance(2)
M.Spring(1499)
M.Advance(9.625)
M.AuraFades()
eq(M.sounds[#M.sounds], BREAK, "and so does its aura fading as its time is up")
eq(#M.sounds, before + 4, "each once")
M.Cast(13795)
M.Advance(2)
M.Spring(13795)
M.HiddenAura("nameplate1")
M.Advance(5)
M.units.nameplate1.dead = true
M.Fire("UNIT_HEALTH", "nameplate1")
eq(M.sounds[#M.sounds], EARLY, "the enemy a burn burns dying before its time plays its early sound")
M.units.nameplate1.dead = false
M.Cast(13795)
M.Advance(2)
M.Spring(13795)
M.HiddenAura("nameplate1")
M.Advance(15)
eq(M.sounds[#M.sounds], BREAK, "the burn running its time plays its end's")
M.Cast(13809)
M.Advance(2)
M.Spring(13809)
M.Advance(2)
M.Fire("PLAYER_REGEN_ENABLED")
M.AuraFades()
M.Advance(28.5)
eq(M.sounds[#M.sounds], BREAK, "the ice on the ground has no early end")
ns.db.sounds.freezing.early, ns.db.sounds.immolation.early = "alarm3", "alarm3"

-- /htt clear clears a freeze too.
M.Cast(1499)
M.Advance(2)
M.Spring(1499)
M.Advance(0.5)
Slash("clear")
check(Effect("frost") == nil and not M.Visible(Icon("frost")), "/htt clear clears the freeze too")
eq(M.printed[#M.printed], "|cffabd473Hunter Trap Timer|r: countdown cleared.", "and says so")
M.combat, M.aurasSecret = false, false
NoErrors("with freezes")

---------------------------------------------------------------------------
-- The test traps, moving the icons, and the options.
---------------------------------------------------------------------------
before = #M.sounds
Slash("test")
check(ns.Traps.armed.fire and ns.Traps.armed.fire.test and ns.Traps.armed.frost and ns.Traps.armed.frost.test,
    "/htt test shows a test trap of each school")
eq(IconText("fire"), 20, "a fire one for 20 seconds")
eq(IconText("frost"), 15, "and a frost one for 15")
eq(Icon("fire").texture.path, "icon:13795", "Immolation Trap")
eq(Icon("frost").texture.path, "icon:1499", "and Freezing Trap")
M.AddAura("nameplate1", 3355, 10)
check(Key("frost") ~= nil, "a test trap never springs")
M.RemoveAura("nameplate1", 3355)
M.Advance(5.125)
eq(#M.sounds, before + 1, "its warning sounds too")
M.Advance(5)
eq(#M.sounds, before + 2, "and then the other's")
M.Advance(10)
check(NoTrap(), "the test traps run out")

Slash("unlock")
eq(ns.db.locked, false, "/htt unlock")
check(M.Visible(HunterTrapTimerFrame), "the icons show to be moved")
eq(IconText("fire"), 60, "as placeholders: the fire trap's")
eq(IconText("frost"), 60, "and the frost trap's")
eq(Icon("fire").texture.path, "Interface\\Icons\\Spell_Fire_FlameShock", "each with an icon of its school")
eq(IconShift("frost"), 37, "each where it will show")
local fireIcon, frostIcon = Icon("fire"), Icon("frost")
local cover
for _, f in ipairs(M.allFrames) do
    if f.parent == HunterTrapTimerFrame and not f.roundSweep then
        cover = f
    end
end
check(cover and M.Visible(cover), "a cover shows over them")
local coverFrom, coverTo = cover.points[1], cover.points[2]
check(coverFrom[1] == "TOPLEFT" and coverFrom[2] == frostIcon and coverTo[1] == "BOTTOMRIGHT"
    and coverTo[2] == HunterTrapTimerFrame, "from the frost trap's place, on the left, to the fire trap's")
eq(table.concat(HunterTrapTimerFrame.clampInsets, ","), "-37,0,0,0", "the whole row is kept on the screen")
check(fireIcon.mouseClick and frostIcon.mouseClick, "they take clicks, to be dragged")
frostIcon.scripts.OnDragStart(frostIcon)
check(HunterTrapTimerFrame.moving, "either drags them")
HunterTrapTimerFrame.center = { 1060, 640 }
frostIcon.scripts.OnDragStop(frostIcon)
HunterTrapTimerFrame.center = nil
check(not HunterTrapTimerFrame.moving, "letting go stops it")
eq(ns.db.x, 100, "the new position is saved (x)")
eq(ns.db.position, "free", "dragging frees the icons from the player frame")
eq(HunterTrapTimerFrame.userPlaced, false, "and leaves their place out of the client's layout cache")
eq(ns.db.y, 100, "the new position is saved (y)")
local point = HunterTrapTimerFrame.points[1]
check(point[1] == "CENTER" and point[4] == 100 and point[5] == 100, "and applied")
Slash("lock")
eq(ns.db.locked, true, "/htt lock")
check(not M.Visible(HunterTrapTimerFrame), "the placeholders go")
fireIcon.scripts.OnDragStart(fireIcon)
check(not HunterTrapTimerFrame.moving, "a locked icon cannot be dragged")
HunterTrapTimerFrame.center = { 0, 0 }
fireIcon.scripts.OnDragStop(fireIcon)
HunterTrapTimerFrame.center = nil
eq(ns.db.x, 100, "and letting go of it moves nothing")
check(not fireIcon.mouseClick and fireIcon.mouseMotion and not frostIcon.mouseClick and frostIcon.mouseMotion,
    "locked, clicks go through the icons, but the mouse still brings their tooltips")
check(not HunterTrapTimerFrame.mouseClick and not HunterTrapTimerFrame.mouseMotion and not HunterTrapTimerFrame.mouse,
    "the frame they hang from never takes the mouse")

local boxes, sliders = Frames("CheckButton", "UICheckButtonTemplate"), Frames("Slider")
eq(#boxes, 3, "three checkboxes")
eq(boxes[3].Text.textValue, "Show how long its effect lasts", "the effects' checkbox")
boxes[3]:SetChecked(false)
boxes[3]:Click()
eq(ns.db.showEffects, false, "is bound to its setting")
boxes[3]:SetChecked(true)
boxes[3]:Click()
eq(ns.db.showEffects, true, "and turns it back on")

-- The sounds page, under the options: each trap's two sounds.
eq(#M.subcategories, 1, "the options have a page under them")
local soundsPage = M.subcategories[1]
eq(soundsPage.name, "Sounds", "for the sounds")
local dropdowns = {}
for _, f in ipairs(Frames("DropdownButton", "WowStyle1DropdownTemplate")) do
    if f.parent == soundsPage.frame then
        dropdowns[#dropdowns + 1] = f
    end
end
eq(#dropdowns, 10, "two dropdowns for each of the four traps, and a third for the freeze's and the burn's early end")
local rowNames = {}
for _, region in ipairs(soundsPage.frame.regions) do
    if region.kind == "FontString" and region.points and region.points[1][2] == 20 then
        rowNames[#rowNames + 1] = region.textValue
    end
end
eq(table.concat(rowNames, ", "), "Immolation Trap, Explosive Trap, Freezing Trap, Frost Trap",
    "the traps by school, by the client's names")
-- The rows go Immolation, Explosive, Freezing, Frost; each the warning's,
-- then its effect's running out, then, for Immolation and Freezing Trap,
-- its early end.
local immolationWarn, freezingWarn, freezingEnded = dropdowns[1], dropdowns[6], dropdowns[7]
eq(immolationWarn.selectedText, "Raid warning", "a warning sounds the raid warning by default")
eq(freezingEnded.selectedText, "Alarm clock 3", "an effect's end the third alarm clock")
eq(dropdowns[2].selectedText, "Alarm clock 3", "every trap's")
eq(dropdowns[3].selectedText .. ", " .. dropdowns[8].selectedText, "Alarm clock 3, Alarm clock 3",
    "and an early end too")
local xs = {}
for _, dropdown in ipairs(dropdowns) do
    xs[#xs + 1] = dropdown.points[1][2]
end
eq(table.concat(xs, " "), "190 345 500 190 345 190 345 500 190 345",
    "in three columns, the third only for Immolation and Freezing Trap")
M.Pick(dropdowns[8], "Whisper")
eq(ns.db.sounds.freezing.early, "whisper", "the early end's dropdown sets its sound")
M.Pick(dropdowns[8], "Alarm clock 3")
local names = {}
for _, entry in ipairs(immolationWarn.menu) do
    names[#names + 1] = entry.text
end
eq(table.concat(names, ", "), "None, Raid warning, Boss emote, Boss whisper, Ready check, Alarm clock 1, Alarm clock 2,"
    .. " Alarm clock 3, Whisper, Notification", "the sounds to choose from")
before = #M.sounds
M.Pick(freezingWarn, "Alarm clock 3")
eq(ns.db.sounds.freezing.warn, "alarm3", "choosing a sound sets it")
eq(M.sounds[#M.sounds], SOUNDKIT.ALARM_CLOCK_WARNING_3, "and plays it, to hear it")
eq(freezingWarn.selectedText, "Alarm clock 3", "the dropdown shows it")
M.Pick(immolationWarn, "None")
eq(#M.sounds, before + 1, "none plays nothing")
eq(#sliders, 2, "two sliders")
boxes[1]:SetChecked(false)
boxes[1]:Click()
eq(ns.db.locked, false, "the lock checkbox unlocks")
boxes[1]:SetChecked(true)
boxes[1]:Click()

sliders[1]:SetValue(64, true)
eq(ns.db.iconSize, 64, "the size slider")
M.Cast(1499)
M.Cast(13795)
eq(HunterTrapTimerFrame.w, 64, "the icons grow")
eq(Icon("frost").w, 64, "both of them")
eq(Icon("frost").text.font[2], 17, "and so do their seconds, in a totem's font")
eq(IconShift("frost"), 64, "and the space between them")
Slash("clear")
M.Cast(1499)

Button("Reset position"):Click()
eq(ns.db.x, 0, "Reset position puts the icon back (x)")
eq(ns.db.y, -150, "Reset position puts the icon back (y)")
eq(ns.db.position, "player", "under the player frame")
check(Radio("Under the Player Frame").checked, "and the option shows it")

sliders[2]:SetValue(0, true)
eq(ns.db.warnSeconds, 0, "the warning slider")
eq(sliders[2].Text.textValue, "Seconds left: |cffffffffOff|r", "0 turns the warning off")
before = #M.sounds
M.Advance(59)
eq(#M.sounds, before, "no warning sound")
eq(IconColor("frost"), WHITE, "no red")
check(not Icon("frost").flash:IsPlaying(), "no flash")
M.Advance(2)

sliders[2]:SetValue(10, true)
M.Cast(1499)
M.Cast(13795)
M.Advance(51)
eq(#M.sounds, before + 1, "each trap warns with its own sound: Freezing Trap's")
eq(M.sounds[#M.sounds], SOUNDKIT.ALARM_CLOCK_WARNING_3, "the one chosen for it")
check(Icon("fire").flash:IsPlaying(), "and Immolation Trap, with none, only flashes")
boxes[2]:SetChecked(false)
boxes[2]:Click()
M.Advance(1)
check(not Icon("frost").flash:IsPlaying(), "the flash checkbox")
M.Advance(10)

Button("Test"):Click()
check(ns.Traps.armed.frost and ns.Traps.armed.frost.test and ns.Traps.armed.fire.test, "the Test button")
M.Advance(21)

Slash("reset")
eq(ns.db.sounds.freezing.warn .. " " .. ns.db.sounds.immolation.warn, "raidWarning raidWarning",
    "/htt reset restores the defaults")
eq(ns.db.iconSize, 37, "including the size")
eq(sliders[1].value, 37, "and the options show it")
eq(freezingWarn.selectedText, "Raid warning", "the sounds too")
ns.db.sounds.freezing.warn = "toast"
eq(ns.DEFAULT_SOUNDS.freezing.warn, "raidWarning", "the defaults stay as they were")
Slash("reset")

-- By default the icon is a totem's: round, in a ring, the seconds below it,
-- under the player frame.
local anchorPoint = HunterTrapTimerFrame.points[1]
check(anchorPoint[1] == "CENTER" and anchorPoint[2] == PlayerFrame and anchorPoint[3] == "BOTTOM"
    and anchorPoint[4] == -46.5 and anchorPoint[5] == -6, "under the player's portrait, clear of the pet frame and the level circle")

-- At the player frame's scale, as totems are, even after Edit Mode resizes it.
PlayerFrame:SetScale(1.25)
ns.Display.Refresh()
eq(HunterTrapTimerFrame:GetScale(), 1.25, "the icon follows the player frame's scale")
-- Dragged from there, it is free where it was left, at the screen's scale.
Slash("unlock")
fireIcon.scripts.OnDragStart(fireIcon)
HunterTrapTimerFrame.center = { 848, 512 }
fireIcon.scripts.OnDragStop(fireIcon)
HunterTrapTimerFrame.center = nil
eq(ns.db.x .. "," .. ns.db.y, "100,100", "a scaled icon is saved where it is on the screen")
eq(HunterTrapTimerFrame:GetScale(), 1, "free, it has the screen's scale")
Slash("lock")
Button("Reset position"):Click()
eq(HunterTrapTimerFrame:GetScale(), 1.25, "back under the player frame, its scale again")
PlayerFrame:SetScale(1)
ns.Display.Refresh()

-- Each icon's tooltip, as a totem's: the trap, its rank and the time left.
M.Cast(1499)
M.Cast(13795)
frostIcon.scripts.OnEnter(frostIcon)
check(GameTooltip:IsOwned(frostIcon) and GameTooltip.shown, "the mouse over an icon shows its tooltip")
eq(table.concat(GameTooltip.lines, " / "), "Freezing Trap / Rank 1 / 60 |4second:seconds; remaining",
    "the trap's name, rank and time left")
M.Advance(10)
eq(GameTooltip.lines[3], "50 |4second:seconds; remaining", "counting down with the icon")
frostIcon.scripts.OnLeave(frostIcon)
check(not GameTooltip.shown, "and goes when the mouse leaves")
fireIcon.scripts.OnEnter(fireIcon)
eq(table.concat(GameTooltip.lines, " / "), "Immolation Trap / 50 |4second:seconds; remaining",
    "the other icon tells of its own trap")
Slash("clear")
check(not GameTooltip.shown, "or when the trap is gone")
Slash("unlock")
frostIcon.scripts.OnEnter(frostIcon)
eq(GameTooltip.lines[2], "Drag to move, then /htt lock", "unlocked with no trap, it says how to move the icons")
frostIcon.scripts.OnLeave(frostIcon)
Slash("lock")
M.Cast(1499)
M.Cast(13795)
local totem = Icon("frost")
check(totem.texture:IsMasked(), "the icon is cut round")
check(totem.ring.shown and totem.ring.atlas == "UI-HUD-UnitFrame-TotemFrame", "in a totem's ring")
check(not totem.edge.shown, "without the square edge")
eq(totem.sweep, totem.roundSweep, "with the round sweep")
eq(totem.roundSweep.swipeTexture, "Interface/Common/CommonMaskCircle", "drawn with the circle")
eq(totem.texture.w, 22, "the icon is a totem's 22 pixels")
eq(IconLabel("frost"), "60 s", "the seconds below, as a totem's")
eq(totem.text.points[1][1] .. " " .. totem.text.points[1][3], "TOP BOTTOM", "below the icon")

-- Square, the seconds on it, and back; the second icon keeps clear of the
-- first one.
Radio("Square"):Click()
eq(ns.db.shape, "square", "the shape option")
check(not totem.texture:IsMasked(), "a square icon is not cut")
check(not totem.ring.shown and totem.edge.shown, "and has the square edge")
eq(totem.sweep, totem.squareSweep, "and the square sweep")
check(not totem.roundSweep.shown, "the round sweep is hidden")
eq(totem.squareSweep.duration, 60, "the sweep is set again on the new shape")
eq(IconShift("frost"), 45, "square, the second icon clears the first one's edge")
eq(HunterTrapTimerFrame.clampInsets[1], -45, "and the row kept on the screen grows with it")
Radio("On the icon"):Click()
eq(ns.db.seconds, "center", "the seconds option")
eq(IconLabel("frost"), 60, "on the icon, just the number")
eq(totem.text.points[1][1], "CENTER", "in its middle")
eq(IconShift("frost"), 45, "the seconds on it change nothing")
Radio("Round, like a totem"):Click()
check(totem.texture:IsMasked() and totem.sweep == totem.roundSweep, "round again")
eq(IconShift("frost"), 37, "round again, as far apart as totems")
Radio("Below the icon"):Click()
eq(IconShift("frost"), 37, "and so with the seconds below, as it began")
Radio("Free"):Click()
eq(HunterTrapTimerFrame.points[1][2], UIParent, "free: where it was left on the screen")
Radio("Under the Player Frame"):Click()
eq(HunterTrapTimerFrame.points[1][2], PlayerFrame, "and back under the player frame")
M.Advance(61)
NoErrors("changing the icon")

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
-- Blizzard's nameplate, already showing the freeze among crowd control.
M.Plate("nameplate1", 0, 1, nil)
M.AddAura("nameplate1", 3355, 10)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", SECRET, 16)
M.Fire("UNIT_AURA", "nameplate1", SECRET)
M.Fire("UNIT_AURA", "nameplate1", SECRET)
M.Fire("UNIT_AURA", "nameplate1", SECRET)
M.Fire("SPELL_UPDATE_COOLDOWN", 1499)
M.Fire("SPELL_UPDATE_COOLDOWN", 1324500, 1324500, 0, 0)
M.AddUnit("player", { name = "Hunter", auras = { { spellId = 1324500, sourceUnit = "player", isFromPlayerOrPlayerPet = true,
    duration = 10, expirationTime = GetTime() + 10 } } })
M.Fire("UNIT_AURA", "player", { addedAuras = { SECRET } })
M.CombatText("SPELL_AURA_START")
M.Fire("PLAYER_TOTEM_UPDATE", 1)
M.Fire("NAME_PLATE_UNIT_REMOVED", "nameplate2")
M.Cast(1499)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "party1", "Cast-11", SECRET)
M.HiddenAura("nameplate2")
M.Advance(1.625)
M.HiddenAura("nameplate2")
M.Advance(1.625)
M.Spring(1499)
M.Advance(0.5)
M.Cast(13795)
M.Cast(1499)
M.HiddenAura("nameplate2")
local text = ProbeText()
check(HunterTrapTimerProbe:IsShown(), "/htt probe opens its window")
check(HunterTrapTimerProbe.onCloseCallback() == false and not HunterTrapTimerProbe:IsShown(),
    "its close button hides it itself (HideUIPanel will not in combat)")
ProbeText()
check(Has(text, "Hunter Trap Timer " .. C_AddOns.GetAddOnMetadata("HunterTrapTimer", "Version") .. " - probe"),
    "the report's title")
check(Has(text, "Combat log restricted: true"), "the combat log answer")
check(Has(text, "Combat text about: player (show combat text: 0)."), "which unit the combat text is about, and the option")
check(Has(text, "Armed: fire: immolation (spell 13795), 60.0 s left; frost: freezing (spell 1499), 60.0 s left."),
    "the traps down, by school")
check(Has(text, "1499 Freezing Trap: 0, 1, false; enabled true, active false"), "the trap spells known")
check(Has(text, "effect 3355 Freezing Trap Effect: 1, false"), "and their effects")
check(not Has(text, "14310 Freezing Trap"), "not the ranks unknown")
check(Has(text, "still recording"), "the report says it is still recording")
check(Has(text, "UNIT_SPELLCAST_SUCCEEDED player: 1499 Freezing Trap"), "the cast is logged")
check(Has(text, "addon: armed: freezing (spell 1499), 60 s"), "the addon's own notes")
check(Has(text, "UNIT_AURA nameplate1 (Kobold): added: 3355 Freezing Trap Effect, from player, by a player true"), "the aura is logged")
check(Has(text, "UNIT_SPELLCAST_SUCCEEDED party1 (Friend): secret"), "the group's casts are logged")
check(Has(text, "addon: sprang (its effect 3355 on nameplate1): freezing"), "a spring told by its effect is logged")
check(Has(text, "addon: sprang (its cooldown event): freezing"), "and one told by its cooldown event")
check(Has(text, "addon: freeze: 10.0 s"), "and the freeze")
check(Has(text, "Effects: freezing's freeze, 6.3 s left; freezing's freeze, 9.5 s left."),
    "the report tells the effects, oldest first")
check(Has(text, "UNIT_COMBAT nameplate1 (Kobold): WOUND  secret, school 16"), "damage is logged, its amount secret")
local _, plateLines = text:gsub("plate nameplate1 %(Kobold%): yours 0, crowd control 1, buffs hidden", "")
eq(plateLines, 1, "the icons on Blizzard's nameplate are logged a moment after an aura, once while they stay the same")
check(Has(text, "plate nameplate2 (Gnoll): no nameplate"), "and so is a unit with no nameplate")
check(Has(text, "effect 3355 Freezing Trap Effect: 1, false, true;"), "whether a trap's effect is crowd control")
check(Has(text, "Nameplate auras: enemy lists (nameplateEnemyNpcAuraDisplay) debuffs true, crowd control true, buffs true;"
    .. " all your debuffs 0 (nameplateShowAllPersonalAuras); the target's nameplate: no nameplate."), "the nameplate settings, bit by bit")
check(not Has(text, "Note: the window refused"), "the whole report goes in")
M.Plate("target", 2, 0, 1)
check(Has(ProbeText(), "the target's nameplate: yours 2, crowd control 0, buffs 1."), "and the target's icons")
M.plates.target = nil
check(Has(text, "payload secret; trap effects: 3355 found") and Has(text, "(x3)"), "repeats fold into one line")
check(Has(text, "SPELL_UPDATE_COOLDOWN 1499 Freezing Trap (base nil, category nil, recovery category nil); trap 1499: enabled true"),
    "cooldowns are logged")
check(Has(text, "SPELL_UPDATE_COOLDOWN 1324500 nil (base 1324500, category 0, recovery category 0); trap 1499:"),
    "with all the event says")
check(Has(text, "UNIT_AURA player: added: secret aura; 1324500 nil on you: found, from player, by a player true, duration 10, 10.0 s left"),
    "the hunter's own auras, and the one that may come with a freeze")
check(Has(text, "COMBAT_TEXT_UPDATE SPELL_AURA_START: secret"), "the combat text's type")
check(Has(text, "PLAYER_TOTEM_UPDATE 1: false, , 0, 0, 0"), "totems are logged")
check(Has(text, "NAME_PLATE_UNIT_REMOVED nameplate2 (Gnoll): dead false"), "nameplates going are logged")
check(Has(text, "Target: Kobold; yours: none; yours cc: none; its harmful auras:\n  none"), "the target's auras")
check(Has(text, "yours cc: " .. M.lastInstanceID .. " (cc filtered out false, duration table)"),
    "the hunter's crowd control on an enemy, by instance ID")
M.Advance(10)
check(Has(ProbeText(), "addon: freeze over (its time is up)"), "and its end")

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
M.Advance(61)
Slash("probe clear")
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

-- An edit box that takes no text past some length: the oldest log lines are
-- left out until the report goes in.
Slash("probe log")
for _ = 1, 30 do
    M.Cast(1499)
    M.Advance(1)
end
Slash("probe log")
local whole = ProbeText()
local printedBefore = #M.printed
M.editBoxLimit = #whole - 200
text = ProbeText()
check(text ~= "" and #text <= M.editBoxLimit, "a report too long for the window is cut to fit")
check(Has(text, "left out: the window would not take them all)"), "leaving out the oldest log lines")
local note = ("the window refused the whole report (%d bytes) with no error; it takes its first %d bytes, ending \"%s\", before \"%s\"; %d bytes of plain x it refuses too; a two-line text it takes")
    :format(#whole, #whole - 200, whole:sub(#whole - 239, #whole - 200):gsub("\n", "\\10"),
        (whole:sub(#whole - 199, #whole - 190):gsub("\n", "\\10")), #whole - 199)
check(Has(text, "\nNote: " .. note .. "; 0 lines it refused on their own are shown escaped.\n"), "and says why, under the title")
check(Has(text, "Hunter Trap Timer ") and Has(text, "recording stopped"), "keeping the report's head and the newest lines")
eq(M.printed[printedBefore + 1], "|cffabd473Hunter Trap Timer|r: probe: " .. note .. "; it refused 0 lines on their own; the report then went in.",
    "and in the chat")
M.editBoxLimit = 10
eq(ProbeText(), "", "a window that takes nothing does not hang the probe")
check(Has(M.printed[#M.printed], "it still took none of the report."), "and says so")
M.editBoxLimit = nil

-- A line the window will not take is shown escaped (| and other bytes as
-- \ddd), and the rest goes in whole.
M.AddUnit("target", { name = "K\195\179bold|x", auras = {} })
M.editBoxRefuses = "|x"
text = ProbeText()
check(Has(text, "\n[refused: Target: K\\195\\179bold\\124x; yours: "), "a line the window refuses is marked, its other bytes and | as \\ddd")
check(Has(text, "Target: K\\195\\179bold\\124\", before \"x; yours: \"; ") and Has(text, "bytes of plain x it takes;"),
    "the note shows the refused byte that stops it")
check(Has(text, "1 lines it refused on their own are shown escaped") and Has(text, "recording stopped")
    and not Has(text, "left out:"), "and the rest goes in, the whole log too")
check(Has(M.printed[#M.printed], "it refused 1 lines on their own, the first: [refused: Target: K\\195\\179bold"),
    "the chat says which")
M.editBoxRefuses = nil
M.AddUnit("target", { name = "Ko\2bold", auras = {} })
text = ProbeText()
check(Has(text, "Target: Ko\\2bold; yours: ") and not Has(text, "Note: the window refused"),
    "a value's control bytes are shown as \\ddd, so the window takes the report")
M.AddUnit("target", { name = "Kobold", auras = {} })
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
eq(ns.db.version, 3, "the version is set")
ns = NewSession({ saved = { version = 3, sounds = { freezing = { warn = "alarm1", ended = "loud" }, frost = "x",
    explosive = { ended = 7 } } } })
eq(ns.db.sounds.freezing.warn .. " " .. ns.db.sounds.freezing.ended, "alarm1 alarm3",
    "a trap's good sound is kept, an unknown one replaced")
eq(ns.db.sounds.frost.warn .. " " .. ns.db.sounds.explosive.ended .. " " .. ns.db.sounds.immolation.warn,
    "raidWarning alarm3 raidWarning", "bad or missing traps get the defaults")
-- Before 0.3.1 one sound played at every end: an early end keeps it.
ns = NewSession({ saved = { version = 3, sounds = { freezing = { ended = "toast" }, immolation = { ended = "x" },
    frost = { ended = "whisper", early = "toast" } } } })
eq(ns.db.sounds.freezing.early, "toast", "an early end keeps the sound chosen for the effect's end")
eq(ns.db.sounds.immolation.early, "alarm3", "or the default, when that one is unknown")
eq(ns.db.sounds.frost.early, nil, "an effect on the ground has no early end")
ns = NewSession({ saved = { version = 3, sounds = { freezing = { ended = "toast", early = "whisper" } } } })
eq(ns.db.sounds.freezing.early, "whisper", "a chosen early sound is kept")
-- Up to version 2 one checkbox turned every warning's sound on or off.
ns = NewSession({ saved = { version = 2, warnSound = false } })
eq(ns.db.sounds.immolation.warn .. " " .. ns.db.sounds.frost.warn, "none none", "warnings without sound stay so")
eq(ns.db.sounds.freezing.ended, "alarm3", "an effect's end still sounds")
eq(ns.db.warnSound, nil, "the old setting is dropped")
ns = NewSession({ saved = { version = 2, warnSound = true } })
eq(ns.db.sounds.immolation.warn, "raidWarning", "warnings with sound keep the raid warning")
ns = NewSession({ saved = { iconSize = 0 / 0 } })
eq(ns.db.iconSize, 37, "NaN is replaced")
ns = NewSession({ saved = { position = "left", shape = "star", seconds = 3 } })
eq(ns.db.position .. " " .. ns.db.shape .. " " .. ns.db.seconds, "player round below", "bad choices are replaced")

-- Version 1's square icon, free on the screen, moves to the totem's look
-- and place, unless it was moved or resized by hand.
ns = NewSession({ saved = { version = 1, iconSize = 48, x = 0, y = -150 } })
eq(ns.db.iconSize, 37, "version 1's default size becomes a totem's")
eq(ns.db.position, "player", "and its default place the player frame")
eq(ns.db.shape, "round", "and it is round")
ns = NewSession({ saved = { version = 1, iconSize = 64, x = 200, y = 10 } })
eq(ns.db.iconSize, 64, "a size of one's own is kept")
eq(ns.db.position, "free", "a moved icon stays where it was")
eq(HunterTrapTimerFrame.points[1][4], 200, "at its place")
ns = NewSession({ saved = { version = 2, iconSize = 48 } })
eq(ns.db.iconSize, 48, "from version 2 on, 48 is the player's own size")
NoErrors("moving the settings on")

---------------------------------------------------------------------------
-- Session 2b: a /reload keeps the armed traps; a new login does not.
---------------------------------------------------------------------------
-- Puts traps down (spells, in turn, seconds apart), lets seconds pass, and
-- leaves the game (PLAYER_LOGOUT, as on a /reload or a logout); then comes
-- back after a pause.
local function LeaveAndCome(spells, seconds, reloading, pause)
    ns = NewSession()
    M.Fire("PLAYER_ENTERING_WORLD", true, false)
    if spells then
        for index, spellID in ipairs(spells) do
            if index > 1 then
                M.Advance(10)
            end
            M.Cast(spellID)
        end
    else
        Slash("test")
    end
    M.Advance(seconds)
    M.Fire("PLAYER_LOGOUT")
    local saved, clock = HunterTrapTimerDB, M.time
    ns = NewSession({ saved = saved, time = clock + (pause or 2) })
    M.Fire("PLAYER_ENTERING_WORLD", not reloading, reloading)
end

LeaveAndCome({ 1499 }, 20, true)
eq(Key("frost"), "freezing", "after a /reload the trap is armed again")
eq(IconText("frost"), 38, "with the time it has left")
eq(Icon("frost").sweep.duration, 60, "and its whole sweep")
eq(ns.db.armed, nil, "the saved trap is cleared once taken back")
M.Advance(28.125)
eq(#M.sounds, 1, "its warning still comes")
M.Advance(10)
check(NoTrap(), "and it runs out on time")
NoErrors("after a /reload")

LeaveAndCome({ 1499, 13795 }, 5, true)
eq(Key("frost"), "freezing", "a /reload keeps both traps: the frost one")
eq(Key("fire"), "immolation", "and the fire one")
eq(IconText("frost"), 43, "each with the time it has left")
eq(IconText("fire"), 53, "the fire one too")
eq(IconShift("frost"), 37, "in their places")

LeaveAndCome({ 1499 }, 50, true)
M.Advance(1)
check(Key("frost") ~= nil, "a trap with 8 seconds left is taken back")
eq(#M.sounds, 0, "a warning given before the /reload is not given again")
M.Advance(8)

LeaveAndCome({ 1499, 13795 }, 5, false)
check(NoTrap(), "after a login the traps are gone with the character")
eq(ns.db.armed, nil, "and the saved traps are cleared")

LeaveAndCome({ 1499, 13795 }, 45, true, 10)
eq(Key("frost"), nil, "a trap that ran out during the /reload is not taken back")
eq(Key("fire"), "immolation", "but one that did not is")
ns = NewSession()
M.Fire("PLAYER_ENTERING_WORLD", true, false)
M.Cast(1499)
Slash("clear")
M.Fire("PLAYER_LOGOUT")
eq(HunterTrapTimerDB.armed, nil, "a cleared trap is not saved for the /reload")
LeaveAndCome(nil, 5, true)
check(NoTrap(), "nor test traps")

-- Version 0.1 saved one trap, as it was.
ns = NewSession({ time = 5000, saved = { armed = { key = "freezing", rank = 1, spellID = 1499, start = 4990, duration = 60 } } })
M.Fire("PLAYER_ENTERING_WORLD", false, true)
eq(Key("frost"), "freezing", "the trap version 0.1 saved is taken back")
eq(IconText("frost"), 50, "with the time it has left")

-- Saved data that is not a trap is dropped.
ns = NewSession({ saved = { armed = { key = "net", spellID = 1499, start = M.time, duration = 60 } } })
M.Fire("PLAYER_ENTERING_WORLD", false, true)
check(NoTrap(), "an unknown trap is not taken back")
ns = NewSession({ saved = { armed = { key = "freezing", spellID = "x", start = M.time, duration = 60 } } })
M.Fire("PLAYER_ENTERING_WORLD", false, true)
check(NoTrap(), "nor one with a bad spell")
ns = NewSession({ saved = { armed = { "freezing", 7, { key = "fire" } } } })
M.Fire("PLAYER_ENTERING_WORLD", false, true)
check(NoTrap(), "nor a list of things that are not traps")
NoErrors("with bad saved traps")

---------------------------------------------------------------------------
-- Session 3: not a hunter.
---------------------------------------------------------------------------
ns = NewSession({ class = "MAGE", known = {} })
M.Cast(1499)
check(NoTrap(), "other classes never see a trap")
check(Has(ProbeText(), "Trap spells you know"), "the probe still answers")
Slash("test")
eq(IconText("fire"), 20, "the test traps still show")
eq(IconText("frost"), 15, "both of them")
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
    eq(Frames("CheckButton", "UICheckButtonTemplate")[1].Text.textValue, L["Lock the icon"], locale .. ": options page translated")
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
