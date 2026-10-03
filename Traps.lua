-- Traps.lua: which trap is down, and how long it has left.
--
-- WoW Forever closes the combat log to addons (even registering it is an
-- error), so a trap is seen through the hunter's own casts, which are never
-- secret: UNIT_SPELLCAST_SUCCEEDED for "player". An armed trap lasts 60
-- seconds unless something steps on it. Only one trap can be down at a time,
-- whatever its kind (the user, 2026-10-03), so a new one replaces the old.
--
-- That a trap sprang shows only in its effect on the enemy: an aura. The
-- icon then moves on to the effect. The aura is secret while combat
-- restrictions are on, and a trap that springs puts the hunter in combat at
-- that very moment, so in practice it cannot be read (/htt probe, 2026-10-03).
-- What does come through is that the enemy gained an aura (UNIT_AURA lists
-- added auras, though secret). With a trap down, an aura that nothing else
-- explains is taken for the trap's effect (MayGuess). Damage to a frozen
-- enemy (UNIT_COMBAT, never secret) ends the freeze, as it does in the game.
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

-- How long after a cast of the hunter's or the pet's an aura it puts on an
-- enemy may still turn up (shots fly), and after an enemy's own cast an aura
-- on it.
local OWN_CAST_WINDOW = 1.5
local ENEMY_CAST_WINDOW = 1

-- Automatic attacks, which put no aura on the enemy: Auto Shot, Attack, Shoot.
local NO_AURA = { [75] = true, [6603] = true, [5019] = true }

-- Forever kept Classic's spell IDs (wowhead Forever and wow-forever.gg, build
-- 1.60.1.70205). spells: the trap by rank; effects: the aura each rank puts on
-- the enemy; effectDuration: how long the effect lasts by rank (the last one
-- for higher ranks), used when the aura's own times cannot be read; onEnemy:
-- the effect is on the enemy that sprang the trap, so it ends when that enemy
-- dies (the others leave an area on the ground); breaks: damage breaks the
-- effect (the freeze), so it ends with its aura or with damage to the enemy.
Traps.LIST = {
    {
        key = "immolation",
        spells = { 13795, 14302, 14303, 14304, 14305 },
        effects = { 13797, 14298, 14299, 14300, 14301 },
        effectDuration = { 15 },
        onEnemy = true,
    },
    {
        key = "freezing",
        spells = { 1499, 14310, 14311 },
        effects = { 3355, 14308, 14309 },
        effectDuration = { 10, 15, 20 },
        onEnemy = true,
        breaks = true,
    },
    {
        key = "frost",
        spells = { 13809 },
        effects = { 13810 },
        effectDuration = { 30 },
    },
    {
        key = "explosive",
        spells = { 13813, 14316, 14317 },
        effects = { 13812, 14314, 14315 },
        effectDuration = { 20 },
    },
}

local bySpell = {}  -- [spellID] = { trap = trap, rank = rank }
local byName = {}   -- [spell name] = trap, for ranks the list lacks
for _, trap in ipairs(Traps.LIST) do
    for rank, spellID in ipairs(trap.spells) do
        bySpell[spellID] = { trap = trap, rank = rank }
    end
end

-- Traps.armed is the trap that is down, and Traps.effect the one that sprang,
-- while its effect lasts: { trap, rank, spellID, icon, start, duration } or
-- nil. The effect also has the enemy it is on (unit, and its GUID when
-- known), its spellID is nil when the effect was guessed, and guessed is set.
-- Traps.lastArmed is the last trap put down, kept after it is gone.

local lastOwnCast = -math.huge  -- GetTime() of the hunter's or the pet's last cast that may put an aura
local enemyCastAt = {}          -- [unit] = GetTime() of that enemy's last cast

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

local function EffectDuration(trap, rank)
    local list = trap.effectDuration
    return list[math.min(rank or #list, #list)]
end

-- Runs Traps.Update while there is something to count down.
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
    ticker:SetShown(Traps.armed ~= nil or Traps.effect ~= nil)
    ns.Display.Refresh()
end

function Traps.Arm(trap, rank, spellID, duration)
    Traps.armed = {
        trap = trap, rank = rank, spellID = spellID,
        icon = Plain(C_Spell.GetSpellTexture(spellID)),
        start = GetTime(), duration = duration or Traps.ARMED_DURATION,
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

-- The armed trap sprang on unit: the trap is gone, and its effect starts. aura
-- is the effect's aura when it could be read, nil when the effect was guessed.
local function Spring(unit, aura, effectID)
    local armed = Traps.armed
    Traps.armed = nil
    local now = GetTime()
    local expires = aura and Plain(aura.expirationTime)
    local duration = aura and Plain(aura.duration)
    local start
    if expires and duration and duration > 0 and expires > now then
        start = expires - duration
    else
        start, duration = now, EffectDuration(armed.trap, armed.rank)
    end
    ns.Log("sprang%s: %s on %s (effect %s), %.1f s", aura and "" or " (guessed)", armed.trap.key, unit,
        tostring(effectID), duration)
    if ns.db.showEffect then
        Traps.effect = {
            trap = armed.trap, rank = armed.rank, spellID = effectID,
            icon = aura and Plain(aura.icon) or armed.icon,
            start = start, duration = duration,
            unit = unit, guid = Plain(UnitGUID(unit)), guessed = aura == nil,
        }
    end
    Changed()
end

-- Enemies whose auras can be read: the target, focus, mouseover and nameplates.
local function IsWatched(unit)
    return unit == "target" or unit == "focus" or unit == "mouseover" or unit:find("^nameplate%d") ~= nil
end

-- The aura of spellID on unit; ok is false when the query failed.
local function GetAura(unit, spellID)
    local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, unit, spellID)
    if not ok then
        return false
    end
    return true, aura
end

-- The aura of one of the trap's effects on unit, if it can be read, the
-- hunter put it there, and not before the trap went down.
local function FindEffect(unit, trap, since)
    for _, effectID in ipairs(trap.effects) do
        local _, aura = GetAura(unit, effectID)
        aura = Plain(aura)
        if aura then
            local mine = Plain(aura.isFromPlayerOrPlayerPet) == true or Plain(aura.sourceUnit) == "player"
            local expires, duration = Plain(aura.expirationTime), Plain(aura.duration)
            local applied = expires and duration and duration > 0 and expires - duration
            if mine and not (applied and applied < since - LEEWAY) then
                return aura, effectID
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
-- taken for the trap's effect unless something else explains it: a cast of
-- the hunter's or the pet's just before (their shots put auras too), or one
-- of the enemy's own. In a group, other players' auras would be taken for it,
-- so this is only done alone.
local function MayGuess(unit)
    local now = GetTime()
    return not IsInGroup() and now - lastOwnCast > OWN_CAST_WINDOW
        and now - (enemyCastAt[unit] or -math.huge) > ENEMY_CAST_WINDOW
        and Plain(UnitCanAttack("player", unit)) ~= false
end

-- Whether an aura of this spell would be secret now, so that not finding it
-- says nothing.
local function AuraSecret(spellID)
    if not (C_Secrets and C_Secrets.ShouldSpellAuraBeSecret) then
        return false
    end
    local ok, secret = pcall(C_Secrets.ShouldSpellAuraBeSecret, spellID)
    return not ok or Plain(secret) ~= false
end

-- Whether unit is the enemy the effect is on: the same GUID, or the same unit
-- when the GUID could not be read.
local function IsEffectUnit(effect, unit)
    if effect.guid then
        return Plain(UnitGUID(unit)) == effect.guid
    end
    return unit == effect.unit
end

local function EndEffect(why, unit)
    ns.Log("effect ended (%s): %s on %s", why, Traps.effect.trap.key, unit)
    Traps.effect = nil
    Changed()
end

-- A freeze ends early when damage breaks it, so when its aura is gone.
local function CheckEffect(unit)
    local effect = Traps.effect
    if not (effect and effect.trap.breaks and effect.spellID and IsEffectUnit(effect, unit))
        or AuraSecret(effect.spellID) then
        return
    end
    local ok, aura = GetAura(unit, effect.spellID)
    if ok and not ns.IsSecret(aura) and aura == nil then
        EndEffect("aura gone", unit)
    end
end

function Traps.OnAura(unit, info)
    unit = Plain(unit)
    if not (Traps.armed or Traps.effect) or type(unit) ~= "string" or not IsWatched(unit) then
        return
    end
    local armed = Traps.armed
    if armed and not armed.test then
        local aura, effectID = FindEffect(unit, armed.trap, armed.start)
        if aura then
            Spring(unit, aura, effectID)
            return
        elseif AddsHiddenAuras(info) and MayGuess(unit) then
            Spring(unit, nil, nil)
            return
        end
    end
    CheckEffect(unit)
end

-- The unit the effect's enemy is now known as: its own, else the target,
-- focus, mouseover or a nameplate with its GUID. Nil when it is none of them.
local OTHER_UNITS = { "target", "focus", "mouseover" }
local function FindEffectUnit(effect)
    if not effect.guid or IsEffectUnit(effect, effect.unit) then
        return effect.unit
    end
    for _, unit in ipairs(OTHER_UNITS) do
        if IsEffectUnit(effect, unit) then
            return unit
        end
    end
    for index = 1, 40 do
        local unit = "nameplate" .. index
        if IsEffectUnit(effect, unit) then
            return unit
        end
    end
end

-- An effect on one enemy ends when the enemy dies (UnitIsDead is never
-- secret). It is checked on every tick, and when the enemy's nameplate goes,
-- which happens on death but also out of range.
local function CheckDeath(unit)
    local effect = Traps.effect
    if effect and effect.trap.onEnemy and Plain(UnitIsDead(unit)) then
        EndEffect("died", unit)
    end
end

function Traps.OnPlateRemoved(unit)
    local effect = Traps.effect
    unit = Plain(unit)
    if effect and type(unit) == "string" and IsEffectUnit(effect, unit) then
        CheckDeath(unit)
    end
end

-- Damage (never secret) to the frozen enemy breaks the freeze.
function Traps.OnDamage(unit, action)
    local effect = Traps.effect
    unit = Plain(unit)
    if effect and effect.trap.breaks and type(unit) == "string" and Plain(action) == "WOUND"
        and IsEffectUnit(effect, unit) then
        EndEffect("damage", unit)
    end
end

function Traps.OnSpellCast(unit, spellID)
    unit, spellID = Plain(unit), Plain(spellID)
    if unit == "player" or unit == "pet" then
        local trap, rank = Traps.Find(spellID)
        if trap and unit == "player" then
            Traps.Arm(trap, rank, spellID)
        elseif not (spellID and NO_AURA[spellID]) then
            lastOwnCast = GetTime()
        end
    elseif type(unit) == "string" and IsWatched(unit) then
        enemyCastAt[unit] = GetTime()
    end
end

-- Ends what has run out and starts the warning.
function Traps.Update()
    local now = GetTime()
    local armed, effect = Traps.armed, Traps.effect
    if armed then
        local left = armed.start + armed.duration - now
        if left <= 0 then
            ns.Log("ran out: %s", armed.trap.key)
            Traps.armed = nil
        elseif not armed.warned and ns.db.warnSeconds > 0 and left <= ns.db.warnSeconds then
            armed.warned = true
            ns.Display.Warn()
        end
    end
    if effect and now >= effect.start + effect.duration then
        Traps.effect = nil
    elseif effect and effect.trap.onEnemy then
        local unit = FindEffectUnit(effect)
        if unit then
            effect.unit = unit
            CheckDeath(unit)
        end
    end
    Changed()
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

    local events = CreateFrame("Frame")
    ns.RegisterEvents(events, "UNIT_SPELLCAST_SUCCEEDED", "UNIT_AURA", "UNIT_COMBAT", "NAME_PLATE_UNIT_REMOVED")
    events:SetScript("OnEvent", function(_, event, unit, arg2, arg3)
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            Traps.OnSpellCast(unit, arg3)
        elseif event == "UNIT_AURA" then
            Traps.OnAura(unit, arg2)
        elseif event == "UNIT_COMBAT" then
            Traps.OnDamage(unit, arg2)
        else
            Traps.OnPlateRemoved(unit)
        end
    end)
end
