-- Traps.lua: which traps are down, how long they have left, and how long the
-- effect of one that sprang lasts.
--
-- WoW Forever closes the combat log to addons (even registering it is an
-- error), so a trap is seen through the hunter's own casts, which are never
-- secret: UNIT_SPELLCAST_SUCCEEDED for "player". An armed trap lasts 60
-- seconds unless something steps on it. A fire trap and a frost trap can be
-- down at once; they share their 30 second cooldown, and a new trap replaces
-- only the one of its own school (the user, at Forever's launch, 2026-11-10;
-- in the beta they had seen a new trap replace any old one).
--
-- When a trap goes, sprung or run out, the client fires SPELL_UPDATE_COOLDOWN
-- with the trap's spell ID, plain even in combat, however far the hunter is
-- (/htt probe, 2026-11-16: every trap, near and far, with enemy nameplates
-- off, and sprung after its cooldown was over). It fires as the trap is cast
-- too: once for the global cooldown, just before UNIT_SPELLCAST_SENT, and
-- once for the trap's own cooldown, as it goes down. Nothing else seen fired
-- it. So that event tells that a trap sprang, and which one (Gone). Before,
-- the addon guessed from auras turning up on enemies and from fire or frost
-- on them: that saw only enemies near the hunter, and in a group could take
-- a poison or a proc for the trap. The user had the guesses dropped
-- (2026-11-16). The trap's effect on an enemy, when it can be read (out of
-- combat), tells the same at once (OnAura).
--
-- A trap that sprang then shows its effect, as long as it lasts (the user
-- asked for each trap's, 2026-11-17; Traps.effects):
-- - Freezing Trap's freeze. The enemy stays frozen up to its rank's time,
--   less if it is hurt. As long as it is, the hunter has an aura of their
--   own: the combat text shows "<Freezing Trap>" as the trap springs, and
--   "<Freezing Trap> fades" as the enemy breaks free. Which aura is secret in
--   combat, but the type of COMBAT_TEXT_UPDATE is not: SPELL_AURA_START as
--   the trap springs, SPELL_AURA_END as the freeze ends, at any distance and
--   with floating combat text off (/htt probe and the user, 2026-11-16). So
--   the freeze lasts until the first SPELL_AURA_END after it began, or its
--   rank's whole time. Another of the hunter's buffs that fades meanwhile
--   ends it early too, which the user accepted. The freeze took hold if, as
--   the trap sprang, that aura came, or the client fired
--   SPELL_UPDATE_COOLDOWN for FREEZE_TOOK_HOLD, as it did for every Freezing
--   Trap that caught an enemy.
-- - Immolation Trap's burn, on the enemy that got an aura as the trap sprang
--   (only enemies the hunter can see count: target, focus, mouseover,
--   nameplates). It lasts its whole time unless every enemy seen is seen to
--   die, or the hunter leaves combat: a burn keeps its enemy in combat while
--   it lasts, so out of it that enemy died or got away. That the burn was
--   dispelled cannot be told: then it runs its time out.
-- - Explosive Trap's fire and Frost Trap's ice, which stay on the ground
--   their whole time, whoever dies (the user, 2026-11-17).
-- Each trap's effect may end with a sound of the player's choosing
-- (ns.db.sounds, Display.EffectEnded).
--
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

-- /htt test shows one trap of each school, running out at different times.
Traps.TEST_DURATIONS = { fire = 20, frost = 15 }

-- An aura found on an enemy belongs to the trap only if it was put there
-- after the trap went down (this much earlier still counts, for rounding).
local LEEWAY = 0.5

-- A trap's SPELL_UPDATE_COOLDOWN this soon after it went down is its cast's
-- own. The soonest a trap was seen to spring was 0.9 seconds after it.
local ARMING = 0.5
-- A trap's SPELL_UPDATE_COOLDOWN is taken for its going this long after it
-- came, unless a trap of its school was cast meanwhile (or just before): then
-- it was that cast's global cooldown. A cast that goes off replaces the trap
-- anyway; one that fails leaves it down.
local CONFIRM = 0.4
-- One that comes this close to the end of the trap's 60 seconds is the trap
-- running out.
local LAST_MOMENT = 1.5

-- The client fires SPELL_UPDATE_COOLDOWN for this spell as a Freezing Trap
-- catches an enemy (/htt probe, 2026-11-16: every time, and never otherwise).
local FREEZE_TOOK_HOLD = 1324500
-- How close to the trap's going the signs of its effect come: that a freeze
-- took hold, and the auras that turn up on the enemies it caught (in the
-- same moment, in the probe).
local HOLD_WINDOW = 0.5
-- A SPELL_AURA_END this soon after the freeze began is not its end.
local FREEZE_SETTLE = 0.2
-- How long auras that turned up on enemies are kept, to find a burn's.
local KEEP_AURAS = 2

-- Forever kept Classic's spell IDs (wowhead Forever and wow-forever.gg, build
-- 1.60.1.70205). spells: the trap by rank; effects: the aura each rank puts on
-- the enemy; slot: the trap it replaces is the one in the same slot;
-- effect: what it does as it springs ("freeze", "burn", "flames" or "ice",
-- the last two on the ground); lasts: how
-- long, in seconds, by rank, the last for ranks past the list's (Classic's
-- times: the probe saw rank 1's freeze last 10 seconds, and Immolation
-- Trap's burn tick every 3 seconds).
Traps.LIST = {
    {
        key = "immolation",
        slot = "fire",
        spells = { 13795, 14302, 14303, 14304, 14305 },
        effects = { 13797, 14298, 14299, 14300, 14301 },
        effect = "burn",
        lasts = { 15 },
    },
    {
        key = "freezing",
        slot = "frost",
        spells = { 1499, 14310, 14311 },
        effects = { 3355, 14308, 14309 },
        effect = "freeze",
        lasts = { 10, 15, 20 },
    },
    {
        key = "frost",
        slot = "frost",
        spells = { 13809 },
        effects = { 13810 },
        effect = "ice",
        lasts = { 30 },
    },
    {
        key = "explosive",
        slot = "fire",
        spells = { 13813, 14316, 14317 },
        effects = { 13812, 14314, 14315 },
        effect = "flames",
        lasts = { 20 },
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
-- icon, start, duration, warned, test, goneAt }, or nil; goneAt: when its
-- SPELL_UPDATE_COOLDOWN came, waiting to be told (CONFIRM).
-- Traps.lastArmed[slot] is the last trap put down there, kept after it is
-- gone.
Traps.armed = {}
Traps.lastArmed = {}
-- Traps.effects[slot] is the effect of the last trap of that slot that
-- sprang, while it lasts: { kind (trap.effect), trap, rank, spellID (the
-- effect's), icon, start, duration, victims }, or nil. victims, of a burn:
-- { guid, unit, dead } for each enemy it caught that was seen.
Traps.effects = {}

local lastSent = {}             -- [slot] = GetTime() of the hunter's last cast of a trap of that school
local auraStartAt = -math.huge  -- of the last SPELL_AURA_START combat text: the hunter got an aura
local tookHoldAt = -math.huge   -- of the last SPELL_UPDATE_COOLDOWN for FREEZE_TOOK_HOLD
local recentAuras = {}          -- { unit, guid, at } for each aura that turned up on an enemy lately

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

-- What a slot's icon shows: its trap down, else its trap's effect, when
-- effects are shown.
function Traps.Shown(slot)
    return Traps.armed[slot] or ns.db.showEffects and Traps.effects[slot] or nil
end

-- Runs Traps.Update while a trap is down or an effect lasts.
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
    ticker:SetShown(next(Traps.armed) ~= nil or next(Traps.effects) ~= nil)
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

-- /htt clear: drops the countdowns, should they ever go wrong, the effects'
-- too. Returns whether there was one.
function Traps.Clear()
    local armed = Traps.Armed()
    if #armed == 0 and not next(Traps.effects) then
        return false
    end
    for _, entry in ipairs(armed) do
        ns.Log("cleared: %s", entry.trap.key)
    end
    wipe(Traps.armed)
    wipe(Traps.effects)
    Changed()
    return true
end

-- The enemies a burn that started at the time at caught: those an aura
-- turned up on then, each once (by GUID, or by unit when it is secret).
local function Victims(at)
    local victims, seen = {}, {}
    for _, aura in ipairs(recentAuras) do
        local key = aura.guid or aura.unit
        if math.abs(aura.at - at) <= HOLD_WINDOW and not seen[key] then
            seen[key] = true
            victims[#victims + 1] = { guid = aura.guid, unit = aura.unit, dead = false }
        end
    end
    return victims
end

-- entry's effect starts at the time at, lasting its rank's time unless left
-- is given (read from its aura). Kept only when effects are shown, or it
-- ends with a sound.
local function StartEffect(entry, at, left)
    local trap, rank = entry.trap, entry.rank
    if not (ns.db.showEffects or ns.db.sounds[trap.key].ended ~= "none") then
        return
    end
    local effectID = trap.effects[rank or 1]
    local effect = {
        kind = trap.effect, trap = trap, rank = rank, spellID = effectID,
        icon = Plain(C_Spell.GetSpellTexture(effectID)) or entry.icon,
        start = at, duration = left or trap.lasts[rank] or trap.lasts[#trap.lasts],
    }
    if effect.kind == "burn" then
        effect.victims = Victims(at)
    end
    Traps.effects[trap.slot] = effect
    ns.Log("%s: %.1f s%s", effect.kind, effect.duration,
        effect.victims and (", on %d enemies seen"):format(#effect.victims) or "")
end

-- A slot's effect is over (how it was told: why), with its trap's sound.
local function EndEffect(slot, why)
    local effect = Traps.effects[slot]
    Traps.effects[slot] = nil
    ns.Log("%s over (%s)", effect.kind, why)
    ns.Display.EffectEnded(effect)
    Changed()
end

-- entry sprang (how it was told: why) at the time at, so it is gone. landed:
-- its effect started (a freeze needs signs that it took hold); left: how
-- long it lasts, when read from its aura.
local function Sprang(entry, why, at, landed, left)
    ns.Log("sprang (%s): %s", why, entry.trap.key)
    Traps.armed[entry.trap.slot] = nil
    if landed then
        StartEffect(entry, at, left)
    end
    Changed()
end

-- Enemies whose auras can be read: the target, focus, mouseover and nameplates.
local function IsWatched(unit)
    return unit == "target" or unit == "focus" or unit == "mouseover" or unit:find("^nameplate%d") ~= nil
end

-- The aura of one of the trap's effects on unit, if it can be read, the
-- hunter put it there, and not before the trap went down: its spell ID, and
-- the seconds it has left (nil when they cannot be read).
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
                return effectID, applied and expires - GetTime() or nil
            end
        end
    end
end

-- Whether a UNIT_AURA update adds auras, whether they can be read or not.
local function AddsAuras(info)
    if ns.IsSecret(info) or type(info) ~= "table" then
        return false
    end
    local added = info.addedAuras
    return ns.IsSecret(added) or type(added) == "table" and #added > 0
end

-- An enemy's auras changed. One that turned up is kept a while, to find the
-- enemies a burn caught. A trap's effect on it, when it can be read, says
-- that trap sprang, and how long its effect lasts.
function Traps.OnAura(unit, info)
    unit = Plain(unit)
    if type(unit) ~= "string" or not IsWatched(unit) or Plain(UnitCanAttack("player", unit)) == false then
        return
    end
    local now = GetTime()
    if AddsAuras(info) then
        while recentAuras[1] and now - recentAuras[1].at > KEEP_AURAS do
            table.remove(recentAuras, 1)
        end
        recentAuras[#recentAuras + 1] = { unit = unit, guid = Plain(UnitGUID(unit)), at = now }
    end
    for _, entry in ipairs(Traps.Armed()) do
        if not entry.test then
            local effectID, left = FindEffect(unit, entry.trap, entry.start)
            if effectID then
                Sprang(entry, ("its effect %d on %s"):format(effectID, unit), now, true, left)
            end
        end
    end
end

-- An enemy may have died (UNIT_HEALTH, or its nameplate going): a burn whose
-- every enemy seen has died is over.
function Traps.OnUnitChanged(unit)
    unit = Plain(unit)
    if type(unit) ~= "string" or not IsWatched(unit) or Plain(UnitIsDead(unit)) ~= true then
        return
    end
    local guid = Plain(UnitGUID(unit))
    for slot, effect in pairs(Traps.effects) do
        local victims = effect.victims
        if victims and #victims > 0 then
            local alive = false
            for _, victim in ipairs(victims) do
                if victim.guid and victim.guid == guid or not victim.guid and victim.unit == unit then
                    victim.dead = true
                end
                alive = alive or not victim.dead
            end
            if not alive then
                EndEffect(slot, "the enemies it burned died")
            end
        end
    end
end

-- PLAYER_REGEN_ENABLED: out of combat, the enemies a burn caught are dead or
-- gone.
function Traps.OnCombatEnded()
    for slot, effect in pairs(Traps.effects) do
        if effect.kind == "burn" then
            EndEffect(slot, "you left combat")
        end
    end
end

-- SPELL_UPDATE_COOLDOWN: one with an armed trap's spell ID (the rank cast),
-- after its cast's own, says it went; it is told CONFIRM seconds later, in
-- Update.
function Traps.OnCooldown(spellID)
    spellID = Plain(spellID)
    if type(spellID) ~= "number" then
        return
    end
    local now = GetTime()
    if spellID == FREEZE_TOOK_HOLD then
        tookHoldAt = now
        return
    end
    for _, entry in pairs(Traps.armed) do
        if entry.spellID == spellID and not entry.test and not entry.goneAt and now - entry.start >= ARMING then
            entry.goneAt = now
        end
    end
end

-- UNIT_SPELLCAST_SENT for the hunter: a trap being cast.
function Traps.OnCastSent(spellID)
    local trap = Traps.Find(Plain(spellID))
    if trap then
        lastSent[trap.slot] = GetTime()
    end
end

-- UNIT_SPELLCAST_SUCCEEDED for the hunter: a trap goes down.
function Traps.OnSpellCast(unit, spellID)
    if Plain(unit) ~= "player" then
        return
    end
    spellID = Plain(spellID)
    local trap, rank = Traps.Find(spellID)
    if trap then
        Traps.Arm(trap, rank, spellID)
    end
end

-- COMBAT_TEXT_UPDATE: its type only, what it shows is secret. The hunter got
-- an aura (SPELL_AURA_START), or one of theirs faded (SPELL_AURA_END), which
-- ends a freeze.
function Traps.OnCombatText(kind)
    kind = Plain(kind)
    local now = GetTime()
    local freeze = Traps.effects.frost
    if kind == "SPELL_AURA_START" then
        auraStartAt = now
    elseif kind == "SPELL_AURA_END" and freeze and freeze.kind == "freeze" and now - freeze.start >= FREEZE_SETTLE then
        EndEffect("frost", "an aura of yours faded")
    end
end

-- entry's SPELL_UPDATE_COOLDOWN came CONFIRM seconds ago: it went, unless a
-- trap of its school was cast then. A Freezing Trap with signs that its
-- freeze took hold sprang, whenever that was; else, at its last moment, a
-- trap ran out.
local function Gone(entry)
    local at = entry.goneAt
    entry.goneAt = nil
    local slot = entry.trap.slot
    if (lastSent[slot] or -math.huge) >= at - CONFIRM then
        ns.Log("cooldown event of a new cast: %s stays", entry.trap.key)
        return
    end
    local freezing = entry.trap.effect == "freeze"
    local held = math.abs(tookHoldAt - at) <= HOLD_WINDOW or math.abs(auraStartAt - at) <= HOLD_WINDOW
    if freezing and held then
        Sprang(entry, "its cooldown event", at, true)
    elseif entry.start + entry.duration - at <= LAST_MOMENT then
        ns.Log("ran out: %s", entry.trap.key)
        Traps.armed[slot] = nil
    else
        Sprang(entry, "its cooldown event", at, not freezing)
    end
end

-- Tells the traps that went, ends those that have run out, starts their
-- warnings, and ends the effects whose time is up.
function Traps.Update()
    local now = GetTime()
    for _, entry in ipairs(Traps.Armed()) do
        local left = entry.start + entry.duration - now
        if entry.goneAt and now - entry.goneAt >= CONFIRM then
            Gone(entry)
        elseif left <= 0 then
            ns.Log("ran out: %s", entry.trap.key)
            Traps.armed[entry.trap.slot] = nil
        elseif not entry.warned and ns.db.warnSeconds > 0 and left <= ns.db.warnSeconds then
            entry.warned = true
            ns.Display.Warn(entry)
        end
    end
    for slot, effect in pairs(Traps.effects) do
        if now >= effect.start + effect.duration then
            EndEffect(slot, "its time is up")
        end
    end
    Changed()
end

-- /reload ---------------------------------------------------------------------

-- The traps stay in the world through a /reload, and GetTime() goes on, so
-- the armed traps are saved on the way out (PLAYER_LOGOUT) and taken back when
-- the interface comes back (PLAYER_ENTERING_WORLD with isReloadingUi). On a
-- real logout the traps go with the character, so a login never takes them
-- back. Effects are not kept.
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

    local events = CreateFrame("Frame")
    ns.RegisterUnitEvents(events, { "player" }, "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED")
    ns.RegisterEvents(events, "UNIT_AURA", "UNIT_HEALTH", "NAME_PLATE_UNIT_REMOVED", "SPELL_UPDATE_COOLDOWN",
        "COMBAT_TEXT_UPDATE", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT")
    events:SetScript("OnEvent", function(_, event, ...)
        if event == "UNIT_SPELLCAST_SENT" then
            -- unit, target, castGUID, spellID
            Traps.OnCastSent((select(4, ...)))
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...
            Traps.OnSpellCast(unit, spellID)
        elseif event == "UNIT_AURA" then
            Traps.OnAura(...)
        elseif event == "UNIT_HEALTH" or event == "NAME_PLATE_UNIT_REMOVED" then
            if next(Traps.effects) then
                Traps.OnUnitChanged((...))
            end
        elseif event == "SPELL_UPDATE_COOLDOWN" then
            Traps.OnCooldown((...))
        elseif event == "COMBAT_TEXT_UPDATE" then
            Traps.OnCombatText((...))
        elseif event == "PLAYER_REGEN_ENABLED" then
            Traps.OnCombatEnded()
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- isInitialLogin, isReloadingUi
            Traps.Restore((select(2, ...)))
        else
            Traps.Save()
        end
    end)
end
