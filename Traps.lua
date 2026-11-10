-- Traps.lua: which traps are down, and how long they have left.
--
-- WoW Forever closes the combat log to addons (even registering it is an
-- error), so a trap is seen through the hunter's own casts, which are never
-- secret: UNIT_SPELLCAST_SUCCEEDED for "player". An armed trap lasts 60
-- seconds unless something steps on it. A fire trap and a frost trap can be
-- down at once; they share their 30 second cooldown, and a new trap replaces
-- only the one of its own school (the user, at Forever's launch, 2026-11-10;
-- in the beta they had seen a new trap replace any old one).
--
-- A trap that springs is gone, so its countdown ends. That it sprang shows
-- only in its effect on the enemy: an aura. The aura is secret while combat
-- restrictions are on, and a trap that springs puts the hunter in combat at
-- that very moment, so in practice it cannot be read (/htt probe, 2026-10-03).
-- What does come through is that the enemy gained an aura (UNIT_AURA lists
-- added auras, though secret). With a trap down, an aura that nothing else
-- explains is taken for the trap's (Explained): a spell of the hunter's, the
-- pet's or the group's just before explains it. In a group, effects that come
-- with no spell (poisons, weapon procs, totems) can still be taken for the
-- trap; the user chose to guess in groups anyway (2026-10-04). UNIT_COMBAT,
-- never secret, gives the spell school of what an enemy takes, and a hunter
-- and pet have no fire or frost spells but the traps, so fire damage, or a
-- resist or immunity of the trap's school, also tells that it sprang
-- (OnCombat).
--
-- With both traps down, an aura that cannot be read may be either's. A fire
-- trap that springs soon shows fire on the enemy as well, so the aura is
-- taken for the frost trap's only if no fire follows (FIRE_WAIT).
--
-- The trap's effect itself is not shown: the user narrowed the addon to the
-- armed trap's countdown (2026-10-04).
-- /htt probe (Probe.lua) shows what the client lets through.
local _, ns = ...
local Plain = ns.Plain

local Traps = {}
ns.Traps = Traps

Traps.ARMED_DURATION = 60
local TICK = 0.1

-- The traps that can be down at once, one of each school, in the order their
-- icons show.
Traps.SLOTS = { "fire", "frost" }
local SLOT_OF_SCHOOL = { [4] = "fire", [16] = "frost" }

-- /htt test shows one trap of each school, running out at different times.
Traps.TEST_DURATIONS = { fire = 20, frost = 15 }

-- An aura found on an enemy belongs to the trap only if it was put there
-- after the trap went down (this much earlier still counts, for rounding).
local LEEWAY = 0.5

-- How long after a cast of the hunter's, the pet's or the group's an aura it
-- puts on an enemy may still turn up (shots and spells fly), and after an
-- enemy's own cast an aura on it. A trap that springs may put its aura on
-- several enemies in that time too (Explosive Trap).
local CAST_WINDOW = 1.5
local ENEMY_CAST_WINDOW = 1

-- How long a fire trap may take to show fire after its aura: Immolation
-- Trap's first burn comes 3.1 to 3.2 seconds after it (/htt probe,
-- 2026-10-04), Explosive Trap's at once.
local FIRE_WAIT = 4

-- Frost Trap leaves an ice slick for 30 seconds when it springs, and every
-- enemy that walks onto it is slowed: an aura that is the slick's, not a new
-- trap's.
local FROST_SLICK = 30

-- Spells of the hunter's and the pet's that put no aura on an enemy, so they
-- explain none: attacks and shots that only deal damage (in the /htt probe
-- logs of 2026-10-04 no aura followed them), and spells on oneself or the
-- pet. By rank 1; the other ranks match by name. Aimed Shot is left out, as
-- it may put a healing debuff.
local NO_AURA_SPELLS = {
    75, 6603, 5019,                                 -- Auto Shot, Attack, Shoot
    2973, 1495, 3044, 2643, 1510,                   -- Raptor Strike, Mongoose Bite, Arcane Shot, Multi-Shot, Volley
    13165, 13163, 5118, 13159, 13161, 20043,        -- the aspects
    3045, 19263, 781, 5384, 6197, 19574,            -- Rapid Fire, Deterrence, Disengage, Feign Death, Eagle Eye, Bestial Wrath
    136, 6991, 883, 2641, 982, 1002,                -- Mend Pet, Feed Pet, Call Pet, Dismiss Pet, Revive Pet, Eyes of the Beast
    17253, 16827, 23099, 23145, 24450,              -- the pet's Bite, Claw, Dash, Dive, Prowl
}
local noAura, noAuraNames = {}, {}
for _, spellID in ipairs(NO_AURA_SPELLS) do
    noAura[spellID] = true
end

-- Forever kept Classic's spell IDs (wowhead Forever and wow-forever.gg, build
-- 1.60.1.70205). spells: the trap by rank; effects: the aura each rank puts on
-- the enemy; school: the spell school of the effect (Fire 4, Frost 16), as
-- UNIT_COMBAT gives it; slot: the trap it replaces is the one in the same
-- slot; hurts: the effect deals damage (the fire traps; the frost ones only
-- freeze or slow); slick: it leaves Frost Trap's ice.
Traps.LIST = {
    {
        key = "immolation",
        school = 4,
        slot = "fire",
        hurts = true,
        spells = { 13795, 14302, 14303, 14304, 14305 },
        effects = { 13797, 14298, 14299, 14300, 14301 },
    },
    {
        key = "freezing",
        school = 16,
        slot = "frost",
        spells = { 1499, 14310, 14311 },
        effects = { 3355, 14308, 14309 },
    },
    {
        key = "frost",
        school = 16,
        slot = "frost",
        slick = true,
        spells = { 13809 },
        effects = { 13810 },
    },
    {
        key = "explosive",
        school = 4,
        slot = "fire",
        hurts = true,
        spells = { 13813, 14316, 14317 },
        effects = { 13812, 14314, 14315 },
    },
}

local bySpell = {}  -- [spellID] = { trap = trap, rank = rank }
local byName = {}   -- [spell name] = trap, for ranks the list lacks
local byKey = {}    -- [key] = trap
local testTraps = {} -- [slot] = the trap /htt test shows there
for _, trap in ipairs(Traps.LIST) do
    byKey[trap.key] = trap
    testTraps[trap.slot] = testTraps[trap.slot] or trap
    for rank, spellID in ipairs(trap.spells) do
        bySpell[spellID] = { trap = trap, rank = rank }
    end
end

-- Traps.armed[slot] is the trap down in that slot: { trap, rank, spellID,
-- icon, start, duration, warned, test }, or nil. Traps.lastArmed[slot] is the
-- last trap put down there, kept after it is gone.
Traps.armed = {}
Traps.lastArmed = {}

local lastOwnCast = -math.huge    -- GetTime() of the hunter's or the pet's last cast that may put an aura
local lastGroupCast = -math.huge  -- of the last cast of another group member or their pet
local enemyCastAt = {}            -- [unit] = GetTime() of that enemy's last cast
local lastSprang = -math.huge     -- when the last trap sprang
local slickUntil = -math.huge     -- until when Frost Trap's ice is down
-- An aura that cannot be read, seen with both traps down: { at, unit, frost },
-- the frost trap's unless fire follows within FIRE_WAIT.
local pending

-- The trap a spell puts down, and its rank (nil when only the name matched).
function Traps.Find(spellID)
    if not spellID then
        return
    end
    local known = bySpell[spellID]
    if known then
        return known.trap, known.rank
    end
    local name = Plain(C_Spell.GetSpellName(spellID))
    return name and byName[name], nil
end

-- The traps down, in the order of Traps.SLOTS.
function Traps.Armed()
    local list = {}
    for _, slot in ipairs(Traps.SLOTS) do
        list[#list + 1] = Traps.armed[slot]
    end
    return list
end

-- Runs Traps.Update while a trap is down.
local ticker = CreateFrame("Frame")
ticker:Hide()
local sinceUpdate = 0
ticker:SetScript("OnUpdate", function(_, elapsed)
    sinceUpdate = sinceUpdate + elapsed
    if sinceUpdate >= TICK then
        sinceUpdate = 0
        Traps.Update()
    end
end)

local function Changed()
    ticker:SetShown(next(Traps.armed) ~= nil)
    ns.Display.Refresh()
end

-- Puts trap down in its slot, replacing the one there. start: when it went
-- down, now unless given (a trap taken back after /reload). Returns its entry.
function Traps.Arm(trap, rank, spellID, duration, start)
    local entry = {
        trap = trap, rank = rank, spellID = spellID,
        icon = Plain(C_Spell.GetSpellTexture(spellID)),
        start = start or GetTime(), duration = duration or Traps.ARMED_DURATION,
    }
    Traps.armed[trap.slot] = entry
    Traps.lastArmed[trap.slot] = entry
    ns.Log("armed: %s (spell %d), %d s", trap.key, spellID, entry.duration)
    Changed()
    return entry
end

-- Test traps, one of each school, to see the icons and the warning without
-- real ones.
function Traps.Test()
    for _, slot in ipairs(Traps.SLOTS) do
        local trap = testTraps[slot]
        Traps.Arm(trap, 1, trap.spells[1], Traps.TEST_DURATIONS[slot]).test = true
    end
end

-- /htt clear: drops the countdowns, should they ever go wrong (a trap was
-- taken for sprung too late, or not at all). Returns whether there was one.
function Traps.Clear()
    local armed = Traps.Armed()
    if #armed == 0 then
        return false
    end
    for _, entry in ipairs(armed) do
        ns.Log("cleared: %s", entry.trap.key)
    end
    wipe(Traps.armed)
    pending = nil
    Changed()
    return true
end

-- entry sprang on unit (how it was told: why) at the time at, now unless
-- given, so it is gone.
local function Sprang(entry, unit, why, at)
    at = at or GetTime()
    ns.Log("sprang (%s): %s on %s", why, entry.trap.key, unit)
    Traps.armed[entry.trap.slot] = nil
    lastSprang = at
    if entry.trap.slot == "fire" then
        -- The aura waiting to be told was the fire trap's.
        pending = nil
    end
    if entry.trap.slick then
        slickUntil = at + FROST_SLICK
    end
    Changed()
end

-- Enemies whose auras can be read: the target, focus, mouseover and nameplates.
local function IsWatched(unit)
    return unit == "target" or unit == "focus" or unit == "mouseover" or unit:find("^nameplate%d") ~= nil
end

-- The aura of one of the trap's effects on unit, if it can be read, the
-- hunter put it there, and not before the trap went down.
local function FindEffect(unit, trap, since)
    for _, effectID in ipairs(trap.effects) do
        local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, unit, effectID)
        aura = ok and Plain(aura)
        if aura then
            -- isFromPlayerOrPlayerPet is true for any player's aura, a group
            -- member's too (/htt probe, 2026-10-04), so only the source tells.
            local mine = Plain(aura.sourceUnit) == "player"
            local expires, duration = Plain(aura.expirationTime), Plain(aura.duration)
            local applied = expires and duration and duration > 0 and expires - duration
            if mine and not (applied and applied < since - LEEWAY) then
                return effectID
            end
        end
    end
end

-- Whether a UNIT_AURA update adds auras that cannot be read.
local function AddsHiddenAuras(info)
    if ns.IsSecret(info) or type(info) ~= "table" then
        return false
    end
    local added = info.addedAuras
    if ns.IsSecret(added) then
        return true
    elseif type(added) == "table" then
        for _, aura in ipairs(added) do
            if ns.IsSecret(aura) or type(aura) == "table" and ns.IsSecret(aura.spellId) then
                return true
            end
        end
    end
    return false
end

-- An aura that cannot be read turned up on unit while a trap is down. It is
-- taken for the trap's unless something else explains it: a cast just before
-- of the hunter's, the pet's or the group's (their spells put auras too), one
-- of the enemy's own, a trap that has just sprung, or Frost Trap's ice.
-- Returns what explains it, or nil.
local function Explained(unit)
    local now = GetTime()
    if now - lastOwnCast <= CAST_WINDOW then
        return "your or your pet's cast"
    elseif now - lastGroupCast <= CAST_WINDOW then
        return "a group member's cast"
    elseif now - (enemyCastAt[unit] or -math.huge) <= ENEMY_CAST_WINDOW then
        return "its own cast"
    elseif now - lastSprang <= CAST_WINDOW then
        return "the trap that just sprang"
    elseif now < slickUntil then
        return "Frost Trap's ice"
    elseif Plain(UnitCanAttack("player", unit)) == false then
        return "not an enemy"
    end
end

function Traps.OnAura(unit, info)
    unit = Plain(unit)
    if type(unit) ~= "string" or not IsWatched(unit) then
        return
    end
    local live = {}  -- the real traps down, test traps aside
    for _, entry in ipairs(Traps.Armed()) do
        if not entry.test then
            live[#live + 1] = entry
        end
    end
    if #live == 0 then
        return
    end
    local found = false
    for _, entry in ipairs(live) do
        local effectID = FindEffect(unit, entry.trap, entry.start)
        if effectID then
            Sprang(entry, unit, "its effect " .. effectID)
            found = true
        end
    end
    if found or not AddsHiddenAuras(info) then
        return
    end
    local reason = Explained(unit)
    if reason then
        ns.Log("aura on %s not the trap's: %s", unit, reason)
    elseif #live == 1 then
        Sprang(live[1], unit, "guessed from an aura")
    elseif not pending then
        pending = { at = GetTime(), unit = unit, frost = Traps.armed.frost }
        ns.Log("aura on %s: the frost trap's, unless fire follows", unit)
    end
end

-- Whether fire or frost on unit may be the trap's. The hunter and the pet
-- have none but the traps, so only a spell of the group's just before
-- explains it.
local function MayBeTrap(unit)
    return GetTime() - lastGroupCast > CAST_WINDOW and Plain(UnitCanAttack("player", unit)) ~= false
end

-- UNIT_COMBAT (never secret): what an enemy took, and of which spell school.
-- Fire or frost on an enemy while a trap of that school is down comes from
-- the trap (MayBeTrap): fire damage means the fire trap sprang, and a full
-- resist or an immunity that the trap sprang for nothing (Blizzard's
-- CombatFeedback reads a resist as a WOUND of 0 with the RESIST flag).
function Traps.OnCombat(unit, action, flags, amount, school)
    unit = Plain(unit)
    if type(unit) ~= "string" or not IsWatched(unit) then
        return
    end
    action, flags, amount, school = Plain(action), Plain(flags), Plain(amount), Plain(school)
    local entry = Traps.armed[SLOT_OF_SCHOOL[school] or ""]
    if not entry or entry.test or not MayBeTrap(unit) then
        return
    elseif action == "IMMUNE" then
        Sprang(entry, unit, "immune")
    elseif action == "WOUND" and flags == "RESIST" and amount == 0 then
        Sprang(entry, unit, "resisted")
    elseif action == "WOUND" and entry.trap.hurts and type(amount) == "number" and amount > 0 then
        Sprang(entry, unit, "fire damage")
    end
end

local function IsGroupUnit(unit)
    return unit:find("^party%d") ~= nil or unit:find("^partypet%d") ~= nil
        or unit:find("^raid%d") ~= nil or unit:find("^raidpet%d") ~= nil
end
Traps.IsGroupUnit = IsGroupUnit

-- Whether a group unit is the hunter or the pet, as in a raid they are raid
-- units too. By GUID when the comparison is secret.
local function IsSelf(unit)
    for _, own in ipairs({ "player", "pet" }) do
        local same = Plain(UnitIsUnit(unit, own))
        if same == nil then
            local guid = Plain(UnitGUID(unit))
            same = guid ~= nil and guid == Plain(UnitGUID(own))
        end
        if same then
            return true
        end
    end
    return false
end

-- Whether a spell puts no aura on an enemy (NO_AURA_SPELLS). A secret spell
-- may.
local function PutsNoAura(spellID)
    if not spellID then
        return false
    elseif noAura[spellID] then
        return true
    end
    local name = Plain(C_Spell.GetSpellName(spellID))
    return name ~= nil and noAuraNames[name] == true
end

-- Group members' spells are secret in combat, but that they cast is not.
function Traps.OnSpellCast(unit, spellID)
    unit, spellID = Plain(unit), Plain(spellID)
    if unit == "player" or unit == "pet" then
        local trap, rank = Traps.Find(spellID)
        if trap and unit == "player" then
            Traps.Arm(trap, rank, spellID)
        elseif not PutsNoAura(spellID) then
            lastOwnCast = GetTime()
        end
    elseif type(unit) ~= "string" then
        return
    elseif IsWatched(unit) then
        -- A group member as the target also casts under their own group unit.
        if Plain(UnitCanAttack("player", unit)) ~= false then
            enemyCastAt[unit] = GetTime()
        end
    elseif IsGroupUnit(unit) and not IsSelf(unit) and not PutsNoAura(spellID) then
        lastGroupCast = GetTime()
    end
end

-- Ends the traps that have run out, starts their warnings, and tells an aura
-- seen with both traps down: with no fire after it, the frost trap's.
function Traps.Update()
    local now = GetTime()
    for _, entry in ipairs(Traps.Armed()) do
        local left = entry.start + entry.duration - now
        if left <= 0 then
            ns.Log("ran out: %s", entry.trap.key)
            Traps.armed[entry.trap.slot] = nil
        elseif not entry.warned and ns.db.warnSeconds > 0 and left <= ns.db.warnSeconds then
            entry.warned = true
            ns.Display.Warn()
        end
    end
    if pending and now - pending.at >= FIRE_WAIT then
        local waited = pending
        pending = nil
        if Traps.armed.frost == waited.frost then
            Sprang(waited.frost, waited.unit, "guessed from an aura with no fire after it", waited.at)
            return
        end
    end
    Changed()
end

-- /reload ---------------------------------------------------------------------

-- The traps stay in the world through a /reload, and GetTime() goes on, so
-- the armed traps are saved on the way out (PLAYER_LOGOUT) and taken back when
-- the interface comes back (PLAYER_ENTERING_WORLD with isReloadingUi). On a
-- real logout the traps go with the character, so a login never takes them
-- back.
function Traps.Save()
    local saved = {}
    for _, entry in ipairs(Traps.Armed()) do
        if not entry.test then
            saved[#saved + 1] = {
                key = entry.trap.key, rank = entry.rank, spellID = entry.spellID,
                start = entry.start, duration = entry.duration, warned = entry.warned,
            }
        end
    end
    ns.db.armed = #saved > 0 and saved or nil
end

function Traps.Restore(isReloadingUi)
    local saved = ns.db.armed
    ns.db.armed = nil
    if not isReloadingUi or type(saved) ~= "table" then
        return
    end
    -- Version 0.1 saved the one trap it knew.
    if saved.key ~= nil then
        saved = { saved }
    end
    local now = GetTime()
    for _, one in ipairs(saved) do
        local trap = type(one) == "table" and byKey[one.key]
        if trap and type(one.spellID) == "number" and type(one.start) == "number"
            and type(one.duration) == "number" and one.start <= now and now < one.start + one.duration then
            local entry = Traps.Arm(trap, type(one.rank) == "number" and one.rank or nil, one.spellID, one.duration,
                one.start)
            entry.warned = one.warned == true
        end
    end
end

function Traps.Init()
    if not ns.isHunter then
        return
    end
    for _, trap in ipairs(Traps.LIST) do
        local name = Plain(C_Spell.GetSpellName(trap.spells[1]))
        if name then
            byName[name] = trap
        end
    end
    for _, spellID in ipairs(NO_AURA_SPELLS) do
        local name = Plain(C_Spell.GetSpellName(spellID))
        if name then
            noAuraNames[name] = true
        end
    end

    local events = CreateFrame("Frame")
    ns.RegisterEvents(events, "UNIT_SPELLCAST_SUCCEEDED", "UNIT_AURA", "UNIT_COMBAT", "PLAYER_ENTERING_WORLD",
        "PLAYER_LOGOUT")
    events:SetScript("OnEvent", function(_, event, unit, arg2, arg3, arg4, arg5)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            Traps.OnSpellCast(unit, arg3)
        elseif event == "UNIT_AURA" then
            Traps.OnAura(unit, arg2)
        elseif event == "UNIT_COMBAT" then
            Traps.OnCombat(unit, arg2, arg3, arg4, arg5)
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- unit is isInitialLogin, arg2 isReloadingUi.
            Traps.Restore(arg2)
        else
            Traps.Save()
        end
    end)
end
