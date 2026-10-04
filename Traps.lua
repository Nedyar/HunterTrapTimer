-- Traps.lua: which trap is down, and how long it has left.
--
-- WoW Forever closes the combat log to addons (even registering it is an
-- error), so a trap is seen through the hunter's own casts, which are never
-- secret: UNIT_SPELLCAST_SUCCEEDED for "player". An armed trap lasts 60
-- seconds unless something steps on it. Only one trap can be down at a time,
-- whatever its kind (the user, 2026-10-03), so a new one replaces the old.
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
-- The trap's effect itself is not shown: the user narrowed the addon to the
-- armed trap's countdown (2026-10-04).
-- /htt probe (Probe.lua) shows what the client lets through.
local _, ns = ...
local Plain = ns.Plain

local Traps = {}
ns.Traps = Traps

Traps.ARMED_DURATION = 60
Traps.TEST_DURATION = 15
local TICK = 0.1

-- An aura found on an enemy belongs to the trap only if it was put there
-- after the trap went down (this much earlier still counts, for rounding).
local LEEWAY = 0.5

-- How long after a cast of the hunter's, the pet's or the group's an aura it
-- puts on an enemy may still turn up (shots and spells fly), and after an
-- enemy's own cast an aura on it.
local CAST_WINDOW = 1.5
local ENEMY_CAST_WINDOW = 1

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
-- UNIT_COMBAT gives it; hurts: the effect deals damage (the fire traps; the
-- frost ones only freeze or slow).
Traps.LIST = {
    {
        key = "immolation",
        school = 4,
        hurts = true,
        spells = { 13795, 14302, 14303, 14304, 14305 },
        effects = { 13797, 14298, 14299, 14300, 14301 },
    },
    {
        key = "freezing",
        school = 16,
        spells = { 1499, 14310, 14311 },
        effects = { 3355, 14308, 14309 },
    },
    {
        key = "frost",
        school = 16,
        spells = { 13809 },
        effects = { 13810 },
    },
    {
        key = "explosive",
        school = 4,
        hurts = true,
        spells = { 13813, 14316, 14317 },
        effects = { 13812, 14314, 14315 },
    },
}

local bySpell = {}  -- [spellID] = { trap = trap, rank = rank }
local byName = {}   -- [spell name] = trap, for ranks the list lacks
for _, trap in ipairs(Traps.LIST) do
    for rank, spellID in ipairs(trap.spells) do
        bySpell[spellID] = { trap = trap, rank = rank }
    end
end

-- Traps.armed is the trap that is down: { trap, rank, spellID, icon, start,
-- duration, warned, test } or nil. Traps.lastArmed is the last trap put down,
-- kept after it is gone.

local lastOwnCast = -math.huge    -- GetTime() of the hunter's or the pet's last cast that may put an aura
local lastGroupCast = -math.huge  -- of the last cast of another group member or their pet
local enemyCastAt = {}            -- [unit] = GetTime() of that enemy's last cast

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
    ticker:SetShown(Traps.armed ~= nil)
    ns.Display.Refresh()
end

-- start: when it went down, now unless given (a trap taken back after /reload).
function Traps.Arm(trap, rank, spellID, duration, start)
    Traps.armed = {
        trap = trap, rank = rank, spellID = spellID,
        icon = Plain(C_Spell.GetSpellTexture(spellID)),
        start = start or GetTime(), duration = duration or Traps.ARMED_DURATION,
    }
    Traps.lastArmed = Traps.armed
    ns.Log("armed: %s (spell %d), %d s", trap.key, spellID, Traps.armed.duration)
    Changed()
end

-- A test trap, to see the icon and the warning without a real one.
function Traps.Test()
    local trap = Traps.LIST[2]
    Traps.Arm(trap, 1, trap.spells[1], Traps.TEST_DURATION)
    Traps.armed.test = true
end

-- /htt clear: drops the countdown, should it ever go wrong (the trap was
-- taken for sprung too late, or not at all). Returns whether there was one.
function Traps.Clear()
    local armed = Traps.armed
    if not armed then
        return false
    end
    ns.Log("cleared: %s", armed.trap.key)
    Traps.armed = nil
    Changed()
    return true
end

-- The armed trap sprang on unit (how it was told: why), so it is gone.
local function Sprang(unit, why)
    ns.Log("sprang (%s): %s on %s", why, Traps.armed.trap.key, unit)
    Traps.armed = nil
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

-- An aura that cannot be read turned up on unit while the trap is down. It is
-- taken for the trap's unless something else explains it: a cast just before
-- of the hunter's, the pet's or the group's (their spells put auras too), or
-- one of the enemy's own. Returns what explains it, or nil.
local function Explained(unit)
    local now = GetTime()
    if now - lastOwnCast <= CAST_WINDOW then
        return "your or your pet's cast"
    elseif now - lastGroupCast <= CAST_WINDOW then
        return "a group member's cast"
    elseif now - (enemyCastAt[unit] or -math.huge) <= ENEMY_CAST_WINDOW then
        return "its own cast"
    elseif Plain(UnitCanAttack("player", unit)) == false then
        return "not an enemy"
    end
end

function Traps.OnAura(unit, info)
    local armed = Traps.armed
    unit = Plain(unit)
    if not armed or armed.test or type(unit) ~= "string" or not IsWatched(unit) then
        return
    end
    local effectID = FindEffect(unit, armed.trap, armed.start)
    if effectID then
        Sprang(unit, "its effect " .. effectID)
    elseif AddsHiddenAuras(info) then
        local reason = Explained(unit)
        if reason then
            ns.Log("aura on %s not the trap's: %s", unit, reason)
        else
            Sprang(unit, "guessed from an aura")
        end
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
-- the trap (MayBeTrap): fire damage means a fire trap sprang, and a full
-- resist or an immunity that the trap sprang for nothing (Blizzard's
-- CombatFeedback reads a resist as a WOUND of 0 with the RESIST flag).
function Traps.OnCombat(unit, action, flags, amount, school)
    local armed = Traps.armed
    unit = Plain(unit)
    if not armed or armed.test or type(unit) ~= "string" or not IsWatched(unit) then
        return
    end
    action, flags, amount, school = Plain(action), Plain(flags), Plain(amount), Plain(school)
    if school ~= armed.trap.school or not MayBeTrap(unit) then
        return
    elseif action == "IMMUNE" then
        Sprang(unit, "immune")
    elseif action == "WOUND" and flags == "RESIST" and amount == 0 then
        Sprang(unit, "resisted")
    elseif action == "WOUND" and armed.trap.hurts and type(amount) == "number" and amount > 0 then
        Sprang(unit, "fire damage")
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

-- Ends a trap that has run out and starts the warning.
function Traps.Update()
    local armed = Traps.armed
    if armed then
        local left = armed.start + armed.duration - GetTime()
        if left <= 0 then
            ns.Log("ran out: %s", armed.trap.key)
            Traps.armed = nil
        elseif not armed.warned and ns.db.warnSeconds > 0 and left <= ns.db.warnSeconds then
            armed.warned = true
            ns.Display.Warn()
        end
    end
    Changed()
end

-- /reload ---------------------------------------------------------------------

-- The trap stays in the world through a /reload, and GetTime() goes on, so the
-- armed trap is saved on the way out (PLAYER_LOGOUT) and taken back when the
-- interface comes back (PLAYER_ENTERING_WORLD with isReloadingUi). On a real
-- logout the trap goes with the character, so a login never takes it back.
function Traps.Save()
    local armed = Traps.armed
    if armed and not armed.test then
        ns.db.armed = {
            key = armed.trap.key, rank = armed.rank, spellID = armed.spellID,
            start = armed.start, duration = armed.duration, warned = armed.warned,
        }
    else
        ns.db.armed = nil
    end
end

function Traps.Restore(isReloadingUi)
    local saved = ns.db.armed
    ns.db.armed = nil
    if not isReloadingUi or type(saved) ~= "table" then
        return
    end
    local trap
    for _, candidate in ipairs(Traps.LIST) do
        if candidate.key == saved.key then
            trap = candidate
        end
    end
    local now = GetTime()
    if trap and type(saved.spellID) == "number" and type(saved.start) == "number"
        and type(saved.duration) == "number" and saved.start <= now and now < saved.start + saved.duration then
        Traps.Arm(trap, type(saved.rank) == "number" and saved.rank or nil, saved.spellID, saved.duration, saved.start)
        Traps.armed.warned = saved.warned == true
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
