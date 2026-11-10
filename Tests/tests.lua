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

-- The icon of a slot.
local function Icon(slot)
    for _, f in ipairs(M.allFrames) do
        if f.parent == HunterTrapTimerFrame and f.roundSweep and f.slot == slot then
            return f
        end
    end
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
-- The trap springs, so it is gone: its icon goes.
---------------------------------------------------------------------------
M.AddUnit("nameplate1", { name = "Kobold" })
M.AddUnit("nameplate2", { name = "Gnoll" })
M.AddUnit("party1", { name = "Friend", friendly = true })

local function Sprang(slot, message)
    eq(Key(slot), nil, message)
    check(not M.Visible(Icon(slot)), message .. ": its icon is gone")
end

-- Its effect's aura, when it can be read.
M.Cast(1499)
M.Advance(5)
before = #M.sounds
M.AddAura("nameplate1", 3355, 10)
Sprang("frost", "the freeze's aura: the trap sprang")
M.Advance(60)
eq(#M.sounds, before, "no warning for a trap that sprang")
M.RemoveAura("nameplate1", 3355)

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

-- Auras that cannot be read, listed as readable.
M.aurasSecret = true
M.AddAura("nameplate1", 3355, 10)
check(Key("frost") ~= nil, "an aura the lookup cannot find is not noticed")
M.RemoveAura("nameplate1", 3355)
M.aurasSecret = false
M.Fire("UNIT_AURA", SECRET, SECRET)
M.Fire("UNIT_AURA", "nameplate1", SECRET)
check(Key("frost") ~= nil, "an update that cannot be read at all says nothing")
NoErrors("with secret auras")
M.Advance(61)

-- With both traps down, a readable aura tells which one sprang.
M.Cast(1499)
M.Cast(13795)
M.AddAura("nameplate1", 3355, 10)
Sprang("frost", "with both traps down, the freeze's aura springs the frost trap")
eq(Key("fire"), "immolation", "and not the fire trap")
M.RemoveAura("nameplate1", 3355)
M.Advance(2)
M.Cast(1499)
M.AddAura("nameplate2", 13797, 15)
Sprang("fire", "the burn's aura springs the fire trap")
eq(Key("frost"), "freezing", "and not the frost trap")
M.RemoveAura("nameplate2", 13797)
M.Advance(61)

---------------------------------------------------------------------------
-- In combat the effect cannot be read: an aura that turns up on an enemy,
-- with nothing else to explain it, is taken for the trap's.
---------------------------------------------------------------------------
M.combat, M.aurasSecret = true, true
M.Cast(1499)
M.HiddenAura("nameplate1")
Sprang("frost", "an unexplained aura on an enemy: the trap sprang")

-- Auras that something else explains.
M.Cast(1499)
M.Cast(13550)
M.HiddenAura("nameplate1")
check(Key("frost") ~= nil, "an aura right after the hunter's Serpent Sting is the sting's")
M.Advance(1.5)
M.HiddenAura("nameplate1")
check(Key("frost") ~= nil, "still 1.5 seconds after it")
M.Advance(0.125)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "pet", "Cast-4", 26177)
M.HiddenAura("nameplate1")
check(Key("frost") ~= nil, "an aura right after the pet's Charge is the pet's")
M.Advance(2)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "nameplate1", "Cast-5", SECRET)
M.HiddenAura("nameplate1")
check(Key("frost") ~= nil, "an aura right after the enemy's own cast is its own")
M.Fire("UNIT_AURA", "nameplate1", { isFullUpdate = false, removedAuraInstanceIDs = SECRET })
check(Key("frost") ~= nil, "an aura that goes is not the trap's")
M.AddUnit("nameplate3", { name = "Guard", friendly = true })
M.HiddenAura("nameplate3")
check(Key("frost") ~= nil, "a friendly unit's aura is not the trap's")
M.HiddenAura("party1")
check(Key("frost") ~= nil, "nor a group member's")
M.Advance(1.125)
M.HiddenAura("nameplate2")
Sprang("frost", "an aura nothing explains")

-- In a group, the group's casts explain auras too.
M.inGroup = true
M.Advance(1.625)
M.Cast(1499)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "party1", "Cast-7", SECRET)
M.HiddenAura("nameplate2")
check(Key("frost") ~= nil, "an aura right after a group member's cast is theirs")
M.Advance(1.625)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "partypet1", "Cast-8", SECRET)
M.HiddenAura("nameplate2")
check(Key("frost") ~= nil, "and so is one right after their pet's")
M.Advance(1.625)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "party1", "Cast-9", 75)
-- In a raid the hunter is a raid unit as well: their own casts are not the group's.
M.AddUnit("raid3", { name = "Tester", isPlayer = true, friendly = true })
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "raid3", "Cast-10", 1499)
M.HiddenAura("nameplate2")
Sprang("frost", "in a group, an aura nothing explains")
M.inGroup = false

-- Attacks that put no aura explain nothing, whatever their rank.
for _, attack in ipairs({ { 75, "Auto Shot" }, { 14261, "Raptor Strike" }, { 3044, "Arcane Shot" },
    { 14282, "Arcane Shot (higher rank)" } }) do
    M.Advance(1.625)
    M.Cast(1499)
    M.Cast(attack[1])
    M.HiddenAura("nameplate2")
    Sprang("frost", attack[2] .. " explains nothing")
end
M.Advance(1.625)
M.Cast(1499)
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "pet", "Cast-12", 17253)
M.HiddenAura("nameplate2")
Sprang("frost", "nor the pet's Bite")

-- Fire and frost: only traps bring them to a hunter's fight.
M.Cast(13813)
M.Fire("UNIT_COMBAT", "nameplate2", "WOUND", "", 120, 4)
Sprang("fire", "fire damage: the fire trap sprang")
M.Cast(13795)
M.Cast(13550)
M.HiddenAura("nameplate2")
M.Advance(3)
M.Fire("UNIT_COMBAT", "nameplate2", "WOUND", "", 21, 4)
Sprang("fire", "Immolation Trap's first burn, after its aura was taken for the sting's")
M.Cast(1499)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "RESIST", 0, 16)
Sprang("frost", "a frost resist: the trap sprang for nothing")
M.Cast(13795)
M.Fire("UNIT_COMBAT", "nameplate2", "IMMUNE", "", 0, 4)
Sprang("fire", "an immune enemy, for a fire trap")
M.Cast(1499)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "RESIST", 0, 64)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "RESIST", 0, 4)
check(Key("frost") ~= nil, "a resist of another school is not the trap's")
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 80, 16)
check(Key("frost") ~= nil, "frost damage never comes from a frost trap")
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 0, 1)
M.Fire("UNIT_COMBAT", "nameplate1", "MISS", "", 0, 1)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 20, SECRET)
check(Key("frost") ~= nil, "a miss, or a school that cannot be read, says nothing")
M.inGroup = true
M.Fire("UNIT_SPELLCAST_SUCCEEDED", "party1", "Cast-6", SECRET)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "RESIST", 0, 16)
check(Key("frost") ~= nil, "a frost resist right after a group member's spell is theirs")
M.inGroup = false
M.Advance(1.625)
M.Fire("UNIT_COMBAT", "nameplate3", "WOUND", "RESIST", 0, 16)
check(Key("frost") ~= nil, "a friendly unit's resist is not the trap's")
M.Advance(61)
NoErrors("while guessing")

---------------------------------------------------------------------------
-- Both traps down in combat: each springs on its own.
---------------------------------------------------------------------------
M.Cast(1499)
M.Cast(13795)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "RESIST", 0, 16)
Sprang("frost", "a frost resist springs the frost trap")
eq(Key("fire"), "immolation", "and leaves the fire trap")
eq(IconShift("fire"), 0, "whose icon stays first")
M.Cast(1499)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 40, 4)
Sprang("fire", "fire damage springs the fire trap")
eq(Key("frost"), "freezing", "and leaves the frost trap")
eq(IconShift("frost"), 0, "whose icon moves to the first place")

-- An aura that cannot be read may be either trap's: the fire trap's if fire
-- follows, as Immolation Trap's first burn does some 3 seconds after...
M.Advance(2)
M.Cast(13795)
M.HiddenAura("nameplate1")
check(Key("fire") ~= nil and Key("frost") ~= nil, "an aura either trap may have put springs neither at once")
M.Advance(3.125)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 21, 4)
Sprang("fire", "the burn that follows tells it was the fire trap's")
M.Advance(2)
eq(Key("frost"), "freezing", "and the frost trap stays")
-- ... and the frost trap's if no fire comes within 4 seconds.
M.Cast(13795)
M.HiddenAura("nameplate2")
M.Advance(3.875)
check(Key("frost") ~= nil, "the frost trap waits for fire")
M.HiddenAura("nameplate1")
M.Advance(0.25)
Sprang("frost", "with no fire after the aura, the frost trap sprang")
eq(Key("fire"), "immolation", "and the fire trap stays")
M.Advance(61)

-- Explosive Trap burns every enemy around it: its auras are not the frost
-- trap's, whether they come before its blast or just after.
M.Cast(1499)
M.Cast(13813)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 90, 4)
Sprang("fire", "Explosive Trap's blast springs the fire trap")
M.HiddenAura("nameplate1")
M.HiddenAura("nameplate2")
eq(Key("frost"), "freezing", "its burn on the enemies around, just after, is not the frost trap's")
M.Advance(1.625)
M.HiddenAura("nameplate2")
Sprang("frost", "an aura later is the frost trap's again")
M.Advance(61)
M.Cast(1499)
M.Cast(13813)
M.HiddenAura("nameplate1")
M.HiddenAura("nameplate2")
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 90, 4)
Sprang("fire", "the blast after the auras springs the fire trap")
M.Advance(4.125)
eq(Key("frost"), "freezing", "and the auras before it were the fire trap's too")
M.Advance(61)

-- Frost Trap leaves ice for 30 seconds: enemies slowed on it do not spring
-- the fire trap. Fire still does.
M.Cast(13795)
M.Cast(13809)
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "RESIST", 0, 16)
Sprang("frost", "Frost Trap sprang")
M.Advance(2)
M.HiddenAura("nameplate2")
eq(Key("fire"), "immolation", "an enemy slowed on its ice does not spring the fire trap")
M.Advance(20)
M.HiddenAura("nameplate1")
eq(Key("fire"), "immolation", "for the 30 seconds the ice lasts")
M.Fire("UNIT_COMBAT", "nameplate1", "WOUND", "", 21, 4)
Sprang("fire", "but fire springs the fire trap")
M.Advance(2)
M.Cast(13795)
M.Advance(6.125)
M.HiddenAura("nameplate1")
Sprang("fire", "once the ice is gone, an aura springs the fire trap again")
M.Advance(61)
M.combat, M.aurasSecret = false, false
NoErrors("with both traps down")

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
    if f.parent == HunterTrapTimerFrame and not f.slot then
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
boxes[3]:SetChecked(false)
boxes[3]:Click()
eq(ns.db.warnSound, false, "the sound checkbox")
M.Cast(1499)
M.Advance(51)
eq(#M.sounds, before, "no sound when it is off")
check(Icon("frost").flash:IsPlaying(), "but the icon flashes")
boxes[2]:SetChecked(false)
boxes[2]:Click()
M.Advance(1)
check(not Icon("frost").flash:IsPlaying(), "the flash checkbox")
M.Advance(10)

Button("Test"):Click()
check(ns.Traps.armed.frost and ns.Traps.armed.frost.test and ns.Traps.armed.fire.test, "the Test button")
M.Advance(21)

Slash("reset")
eq(ns.db.warnSound, true, "/htt reset restores the defaults")
eq(ns.db.iconSize, 37, "including the size")
eq(sliders[1].value, 37, "and the options show it")

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
M.Advance(1.625)
M.Cast(13795)
M.Cast(1499)
M.HiddenAura("nameplate2")
local text = ProbeText()
check(HunterTrapTimerProbe:IsShown(), "/htt probe opens its window")
check(Has(text, "Hunter Trap Timer " .. C_AddOns.GetAddOnMetadata("HunterTrapTimer", "Version") .. " - probe"),
    "the report's title")
check(Has(text, "Combat log restricted: true"), "the combat log answer")
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
check(Has(text, "addon: aura on nameplate2 not the trap's: a group member's cast"), "and why an aura was not the trap's")
check(Has(text, "addon: sprang (guessed from an aura): freezing on nameplate2"), "and a guess")
check(Has(text, "addon: sprang (its effect 3355): freezing on nameplate1"), "the spring is logged")
check(Has(text, "addon: aura on nameplate2: the frost trap's, unless fire follows"), "and an aura either trap may have put")
check(Has(text, "UNIT_COMBAT nameplate1 (Kobold): WOUND  25, school 16"), "damage is logged")
check(Has(text, "payload secret; trap effects: 3355 found") and Has(text, "(x3)"), "repeats fold into one line")
check(Has(text, "SPELL_UPDATE_COOLDOWN 1499; trap 1499: enabled true"), "cooldowns are logged")
check(Has(text, "PLAYER_TOTEM_UPDATE 1: false, , 0, 0, 0"), "totems are logged")
check(Has(text, "NAME_PLATE_UNIT_REMOVED nameplate2 (Gnoll): dead false"), "nameplates going are logged")
check(Has(text, "Target: Kobold; yours: none; yours cc: none; its harmful auras:\n  none"), "the target's auras")
check(Has(text, "yours cc: " .. M.lastInstanceID .. " (cc filtered out false, duration table)"),
    "the hunter's crowd control on an enemy, by instance ID")
M.Advance(4.125)
check(Has(ProbeText(), "addon: sprang (guessed from an aura with no fire after it): freezing on nameplate2"),
    "and what it was taken for")

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
eq(ns.db.version, 2, "the version is set")
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
