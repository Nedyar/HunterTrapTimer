-- Probe.lua: /htt probe, a diagnostic of what WoW Forever lets an addon see of
-- a trap. The combat log is closed, so noticing that a trap sprang rests on
-- these answers (see Traps.lua). It is meant for the addon's author, so it is
-- in English and not translated.
--
-- /htt probe shows the current answers, and the log, in a window whose text
-- can be copied. The log is recorded on demand: /htt probe log starts it, and
-- run again stops it and shows the report. While recording, it logs the
-- hunter's casts, and what happens to enemies from the moment a trap goes
-- down until a while after it is gone. When not recording it
-- listens to no event at all. /htt probe clear empties the log.
local _, ns = ...
local Plain = ns.Plain

local Probe = {}
ns.Probe = Probe

local MAX_LINES = 400
local AFTER = 30          -- seconds the log goes on after the trap is gone (a freeze lasts up to 20)
-- A spell that, on build 70938, gets a SPELL_UPDATE_COOLDOWN as Freezing Trap
-- springs, as the combat text shows "<Freezing Trap>" on the hunter (and
-- "<Freezing Trap> fades" when the freeze ends, it seems): an aura on the
-- hunter while the enemy is frozen?
local FREEZE_AURA = 1324500
local MAX_AURAS = 40

local log = {}
local lastText, repeats   -- the last line's text, to fold repeats into one line
local activeUntil = 0
local recording = false
local events = CreateFrame("Frame")
local NoLog = ns.Log      -- Core's ns.Log, which does nothing

-- A value as text, control bytes as \ddd: the report's edit box refuses,
-- whole and with no error, a text holding one (on build 70938 a bitfield
-- CVar's value, "\2G", left the window empty).
local function Show(value)
    if ns.IsSecret(value) then
        return "secret"
    end
    return (tostring(value):gsub("%c", function(c)
        return ("\\%d"):format(c:byte())
    end))
end

-- An error message without its file and line, kept short.
local function ErrorText(message)
    return "error: " .. tostring(message):gsub("^.-:%d+: ", ""):sub(1, 80)
end

local function Collect(ok, ...)
    if not ok then
        return ErrorText((...))
    end
    local count = select("#", ...)
    if count == 0 then
        return "nothing"
    end
    local shown = {}
    for i = 1, count do
        shown[i] = Show((select(i, ...)))
    end
    return table.concat(shown, ", ")
end

-- What func(...) returns, each value shown; "missing" when the client lacks it.
local function Ask(func, ...)
    if not func then
        return "missing"
    end
    return Collect(pcall(func, ...))
end

local function Record(text)
    if ns.IsSecret(text) then
        text = "[a secret line]"
    end
    if text == lastText then
        repeats = repeats + 1
        log[#log] = ("%8.1f  %s (x%d)"):format(GetTime(), text, repeats)
        return
    end
    lastText, repeats = text, 1
    log[#log + 1] = ("%8.1f  %s"):format(GetTime(), text)
    if #log > MAX_LINES then
        table.remove(log, 1)
    end
end

-- Whether to log what happens to enemies: while a trap is down or an enemy
-- frozen, and for a while after.
local function Active()
    if next(ns.Traps.armed) or next(ns.Traps.effects) then
        activeUntil = GetTime() + AFTER
        return true
    end
    return GetTime() < activeUntil
end

local function IsWatched(unit)
    return unit == "target" or unit == "focus" or unit == "mouseover" or unit:find("^nameplate%d") ~= nil
end

local function UnitLabel(unit)
    return ("%s (%s)"):format(unit, Show((UnitName(unit))))
end

-- Whether a unit's GUID can be read: a burn's enemies are told by it.
local function GuidText(unit)
    local ok, guid = pcall(UnitGUID, unit)
    if not ok then
        return ErrorText(guid)
    end
    return ns.IsSecret(guid) and "secret" or guid and "plain" or "none"
end

local function SpellLabel(spellID)
    if ns.IsSecret(spellID) or spellID == nil then
        return Show(spellID)
    end
    return ("%s %s"):format(spellID, Ask(C_Spell.GetSpellName, spellID))
end

local function AuraText(aura)
    local expires = Plain(aura.expirationTime)
    return ("from %s, by a player %s, duration %s, %s s left"):format(Show(aura.sourceUnit), Show(aura.isFromPlayerOrPlayerPet),
        Show(aura.duration), expires and ("%.1f"):format(expires - GetTime()) or Show(aura.expirationTime))
end

-- What GetUnitAuraBySpellID says of the effect on unit.
local function EffectText(unit, effectID)
    local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, unit, effectID)
    if not ok then
        return ErrorText(aura)
    elseif ns.IsSecret(aura) then
        return "secret"
    elseif aura == nil then
        return "none"
    end
    return "found, " .. AuraText(aura)
end

-- The effects found on unit of the last trap of each school, or "none".
local function EffectsOn(unit)
    if not next(ns.Traps.lastArmed) then
        return "no trap yet"
    end
    local found = {}
    for _, slot in ipairs(ns.Traps.SLOTS) do
        local last = ns.Traps.lastArmed[slot]
        for _, effectID in ipairs(last and last.trap.effects or {}) do
            local answer = EffectText(unit, effectID)
            if answer ~= "none" then
                found[#found + 1] = ("%d %s"):format(effectID, answer)
            end
        end
    end
    return #found > 0 and table.concat(found, "; ") or "none"
end

-- The spell of the last trap put down, of either school (they share their
-- cooldown).
local function LastTrapSpell()
    local latest
    for _, entry in pairs(ns.Traps.lastArmed) do
        if not latest or entry.start > latest.start then
            latest = entry
        end
    end
    return latest and latest.spellID
end

-- The auras on unit that pass filter, by instance ID, as the client lists
-- them. This and IsAuraFilteredOutByInstanceID are not marked as secret in
-- the API documentation; whether they answer in combat is what is asked. The
-- first few IDs also say whether they are crowd control and what
-- GetAuraDuration gives for them.
local CC_FILTER = "HARMFUL|PLAYER|CROWD_CONTROL"
local function InstancesText(unit, filter)
    local A = C_UnitAuras
    if not A.GetUnitAuraInstanceIDs then
        return "missing"
    end
    local ok, ids = pcall(A.GetUnitAuraInstanceIDs, unit, filter)
    if not ok then
        return ErrorText(ids)
    elseif ns.IsSecret(ids) or type(ids) ~= "table" then
        return Show(ids)
    elseif #ids == 0 then
        return "none"
    end
    local shown = {}
    for index, id in ipairs(ids) do
        if index > 3 or ns.IsSecret(id) then
            shown[index] = Show(id)
        else
            shown[index] = ("%s (cc filtered out %s, duration %s)"):format(id,
                Ask(A.IsAuraFilteredOutByInstanceID, unit, id, CC_FILTER),
                Ask(function() return type(A.GetAuraDuration(unit, id)) end))
        end
    end
    return table.concat(shown, ", ")
end

-- Blizzard's nameplates sort an enemy's auras with code that may read them in
-- combat: crowd control in one list, the other debuffs of yours and your
-- pet's in another (those flagged for nameplates, or all of them with
-- nameplateShowAllPersonalAuras), buffs in a third, and show an icon for
-- each (Blizzard_NamePlateAuras.lua and Blizzard_NamePlates.xml, build
-- 70938). How many icons each list shows is asked here: if it can be read in
-- combat, it tells whether a new aura is the hunter's, or crowd control,
-- without reading the aura.
local function IconsShown(list)
    if not list then
        return "missing"
    end
    local shown = list:IsShown()
    if ns.IsSecret(shown) then
        return "secret"
    elseif not shown then
        return "hidden"
    end
    local count = 0
    for _, child in ipairs({ list:GetChildren() }) do
        local childShown = child:IsShown()
        if ns.IsSecret(childShown) then
            return "secret"
        elseif childShown then
            count = count + 1
        end
    end
    return tostring(count)
end

local function PlateText(unit)
    if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then
        return "missing"
    end
    local ok, text = pcall(function()
        local plate = C_NamePlate.GetNamePlateForUnit(unit)
        if ns.IsSecret(plate) then
            return "secret"
        end
        local auras = plate and plate.UnitFrame and plate.UnitFrame.AurasFrame
        if not auras then
            return "no nameplate"
        end
        return ("yours %s, crowd control %s, buffs %s"):format(IconsShown(auras.DebuffListFrame),
            IconsShown(auras.CrowdControlListFrame), IconsShown(auras.BuffListFrame))
    end)
    return ok and text or ErrorText(text)
end

-- A moment after an aura changes on unit, once Blizzard's own nameplate has
-- had the event, its icons, when they changed.
local lastPlate = {}
local function LogPlateLater(unit)
    C_Timer.After(0, function()
        local text = PlateText(unit)
        if recording and text ~= lastPlate[unit] then
            lastPlate[unit] = text
            Record(("plate %s: %s"):format(UnitLabel(unit), text))
        end
    end)
end

local function DescribeUpdate(info)
    if ns.IsSecret(info) then
        return "payload secret"
    elseif type(info) ~= "table" then
        return "payload " .. Show(info)
    elseif Plain(info.isFullUpdate) then
        return "full update"
    end
    local parts = {}
    local added = info.addedAuras
    if ns.IsSecret(added) then
        parts[#parts + 1] = "added: secret"
    elseif type(added) == "table" then
        for _, aura in ipairs(added) do
            if ns.IsSecret(aura) then
                parts[#parts + 1] = "added: secret aura"
            else
                parts[#parts + 1] = ("added: %s, %s"):format(SpellLabel(aura.spellId), AuraText(aura))
            end
        end
    end
    for _, key in ipairs({ "updatedAuraInstanceIDs", "removedAuraInstanceIDs" }) do
        local list = info[key]
        if ns.IsSecret(list) then
            parts[#parts + 1] = key .. ": secret"
        elseif type(list) == "table" and #list > 0 then
            parts[#parts + 1] = ("%s: %d"):format(key, #list)
        end
    end
    return #parts > 0 and table.concat(parts, "; ") or "nothing listed"
end

local function CooldownText(spellID)
    if not spellID then
        return "no trap yet"
    end
    local ok, info = pcall(C_Spell.GetSpellCooldown, spellID)
    if not ok then
        return "error"
    elseif ns.IsSecret(info) or type(info) ~= "table" then
        return Show(info)
    end
    return ("enabled %s, active %s, start %s, duration %s"):format(Show(info.isEnabled), Show(info.isActive),
        Show(info.startTime), Show(info.duration))
end

local function OnEvent(_, event, ...)
    if event:find("^UNIT_SPELLCAST_") then
        local unit, spellID = ..., select(event == "UNIT_SPELLCAST_SENT" and 4 or 3, ...)
        Record(("%s %s: %s"):format(event, Show(unit), SpellLabel(spellID)))
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        Record(event)
    elseif not Active() then
        return
    elseif event == "UNIT_AURA" and Plain((...)) == "player" then
        local ok, update = pcall(DescribeUpdate, (select(2, ...)))
        local found, aura = pcall(C_UnitAuras.GetPlayerAuraBySpellID, FREEZE_AURA)
        Record(("UNIT_AURA player: %s; %s on you: %s"):format(ok and update or "unreadable", SpellLabel(FREEZE_AURA),
            not found and ErrorText(aura) or ns.IsSecret(aura) and "secret" or aura and "found, " .. AuraText(aura) or "none"))
    elseif event == "COMBAT_TEXT_UPDATE" then
        Record(("COMBAT_TEXT_UPDATE %s: %s"):format(Show((...)), Ask(C_CombatText and C_CombatText.GetCurrentEventInfo)))
    elseif event == "UNIT_AURA" or event == "UNIT_COMBAT" then
        local unit = Plain((...))
        if type(unit) ~= "string" or not IsWatched(unit) then
            return
        end
        if event == "UNIT_AURA" then
            local ok, update = pcall(DescribeUpdate, (select(2, ...)))
            Record(("UNIT_AURA %s: %s; trap effects: %s; yours: %s; yours cc: %s"):format(UnitLabel(unit),
                ok and update or "unreadable", EffectsOn(unit), InstancesText(unit, "HARMFUL|PLAYER"),
                InstancesText(unit, CC_FILTER)))
            LogPlateLater(unit)
        else
            local _, action, flag, amount, school = ...
            Record(("UNIT_COMBAT %s: %s %s %s, school %s"):format(UnitLabel(unit), Show(action), Show(flag),
                Show(amount), Show(school)))
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        local spellID = LastTrapSpell()
        local updated, base, category, recovery = ...
        Record(("SPELL_UPDATE_COOLDOWN %s (base %s, category %s, recovery category %s); trap %s: %s"):format(SpellLabel(updated),
            Show(base), Show(category), Show(recovery), Show(spellID), CooldownText(spellID)))
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local unit = ...
        lastPlate[unit] = nil
        Record(("NAME_PLATE_UNIT_REMOVED %s: dead %s, GUID %s"):format(UnitLabel(unit), Ask(UnitIsDead, unit),
            GuidText(unit)))
    elseif event == "UNIT_HEALTH" then
        -- Only deaths, which end a burn (Traps.OnUnitChanged).
        local unit = Plain((...))
        if type(unit) == "string" and IsWatched(unit) and Plain(UnitIsDead(unit)) == true then
            Record(("UNIT_HEALTH %s: dead, GUID %s"):format(UnitLabel(unit), GuidText(unit)))
        end
    elseif event == "PLAYER_TOTEM_UPDATE" then
        local slot = ...
        Record(("PLAYER_TOTEM_UPDATE %s: %s"):format(Show(slot), Ask(GetTotemInfo, slot)))
    end
end

-- The report ------------------------------------------------------------------

local function EntryText(entry)
    if not entry then
        return "none"
    end
    return ("%s (spell %s), %.1f s left"):format(entry.trap.key, tostring(entry.spellID),
        entry.start + entry.duration - GetTime())
end

-- Each slot's armed trap: "fire: ...; frost: none".
local function ArmedText()
    local parts = {}
    for _, slot in ipairs(ns.Traps.SLOTS) do
        parts[#parts + 1] = ("%s: %s"):format(slot, EntryText(ns.Traps.armed[slot]))
    end
    return table.concat(parts, "; ")
end

-- The report's lines, with the last keep lines of the log (all of them when
-- keep is nil).
-- Each slot's effect: "fire: burn, 12.0 s left, 1 of 2 enemies dead; frost: none".
local function EffectsText()
    local parts = {}
    for _, slot in ipairs(ns.Traps.SLOTS) do
        local effect, text = ns.Traps.effects[slot], "none"
        if effect then
            text = ("%s, %.1f s left"):format(effect.kind, effect.start + effect.duration - GetTime())
            if effect.victims then
                local dead = 0
                for _, victim in ipairs(effect.victims) do
                    dead = dead + (victim.dead and 1 or 0)
                end
                text = text .. (", %d of %d enemies dead"):format(dead, #effect.victims)
            end
        end
        parts[#parts + 1] = ("%s: %s"):format(slot, text)
    end
    return table.concat(parts, "; ")
end

local function ReportLines(keep)
    local S = C_Secrets or {}
    local lines = {}
    local function Add(text, ...)
        local line = select("#", ...) > 0 and text:format(...) or text
        lines[#lines + 1] = ns.IsSecret(line) and "[a secret line]" or line
    end
    Add("Hunter Trap Timer %s - probe, %s, client %s", Ask(C_AddOns and C_AddOns.GetAddOnMetadata, "HunterTrapTimer", "Version"),
        date("%Y-%m-%d %H:%M:%S"), Ask(GetBuildInfo))
    Add("In combat: %s. In a group: %s. Secret restrictions: %s; auras secret: %s; cooldowns secret: %s. Combat log restricted: %s.",
        Ask(InCombatLockdown), Ask(IsInGroup), Ask(S.HasSecretRestrictions), Ask(S.ShouldAurasBeSecret), Ask(S.ShouldCooldownsBeSecret),
        Ask(C_CombatLog and C_CombatLog.IsCombatLogRestricted))
    Add("Armed: %s. Effects: %s.", ArmedText(), EffectsText())
    Add("")

    Add("Trap spells you know (cast secrecy, cooldown secrecy, cooldown secret now; cooldown), then their effects (aura secrecy, aura secret now, crowd control; on the target):")
    local known = 0
    for _, trap in ipairs(ns.Traps.LIST) do
        for rank, spellID in ipairs(trap.spells) do
            if Plain(IsPlayerSpell(spellID)) then
                known = known + 1
                local effectID = trap.effects[rank]
                Add("  %s: %s, %s, %s; %s", SpellLabel(spellID), Ask(S.GetSpellCastSecrecy, spellID),
                    Ask(S.GetSpellCooldownSecrecy, spellID), Ask(S.ShouldSpellCooldownBeSecret, spellID), CooldownText(spellID))
                Add("    effect %s: %s, %s, %s; %s", SpellLabel(effectID), Ask(S.GetSpellAuraSecrecy, effectID),
                    Ask(S.ShouldSpellAuraBeSecret, effectID), Ask(C_Spell.IsSpellCrowdControl, effectID),
                    EffectText("target", effectID))
            end
        end
    end
    if known == 0 then
        Add("  none")
    end

    local slots = Plain(GetNumTotemSlots and GetNumTotemSlots()) or 4
    Add("Totem slots (have, name, start, duration, icon, ...):")
    for slot = 1, slots do
        Add("  %d: %s", slot, Ask(GetTotemInfo, slot))
    end
    -- nameplateEnemyNpcAuraDisplay is a bitfield, one bit a list, read as
    -- Blizzard's nameplates read it.
    local CVar = C_CVar or {}
    local list = Enum and Enum.NamePlateEnemyNpcAuraDisplay or { Buffs = 1, Debuffs = 2, CrowdControl = 3 }
    local function Shown(index)
        return Ask(CVar.GetCVarBitfield, "nameplateEnemyNpcAuraDisplay", index)
    end
    Add("Nameplate auras: enemy lists (nameplateEnemyNpcAuraDisplay) debuffs %s, crowd control %s, buffs %s; all your debuffs %s (nameplateShowAllPersonalAuras); the target's nameplate: %s.",
        Shown(list.Debuffs), Shown(list.CrowdControl), Shown(list.Buffs), Ask(CVar.GetCVar, "nameplateShowAllPersonalAuras"),
        PlateText("target"))

    Add("Target: %s; yours: %s; yours cc: %s; its harmful auras:", Show((UnitName("target"))),
        InstancesText("target", "HARMFUL|PLAYER"), InstancesText("target", CC_FILTER))
    for index = 1, MAX_AURAS do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, "target", index, "HARMFUL")
        if not ok or ns.IsSecret(aura) then
            Add("  %d: %s", index, ok and "secret" or ErrorText(aura))
            break
        elseif aura == nil then
            if index == 1 then
                Add("  none")
            end
            break
        end
        Add("  %d: %s, %s", index, SpellLabel(aura.spellId), AuraText(aura))
    end
    Add("")

    Add("Log, oldest first (%d lines%s):", #log, recording and ", still recording" or "")
    local first = keep and math.max(1, #log - keep + 1) or 1
    if first > 1 then
        Add("  (the first %d left out: the window would not take them all)", first - 1)
    end
    for i = first, #log do
        lines[#lines + 1] = "  " .. log[i]
    end
    if #log == 0 then
        Add("  empty")
    end
    Add("")
    Add("To fill the log: /htt probe log, put a trap down near an enemy and let it spring (or run out), then /htt probe log again. /htt probe clear empties the log.")
    return lines
end

-- Whether the edit box holds all of text.
local function Holds(edit, text)
    return #(edit:GetText() or "") >= #text
end

-- line in printable ASCII, any other byte (and |) as \ddd, to show a line the
-- window would not take.
local function Escaped(line)
    return (line:gsub("[^ -{}~]", function(c)
        return ("\\%d"):format(c:byte())
    end))
end

-- Whether the edit box takes text.
local function Takes(edit, text)
    edit:SetText(text)
    return Holds(edit, text)
end

-- How many bytes from the start of text, which the edit box refuses whole, it
-- takes: where a refused byte is, or how much it takes at most.
local function LongestStart(edit, text)
    local taken, refused = 0, #text
    while refused - taken > 1 do
        local middle = math.floor((taken + refused) / 2)
        if Takes(edit, text:sub(1, middle)) then
            taken = middle
        else
            refused = middle
        end
    end
    return taken
end

-- Puts the report in the edit box. On build 70938 the edit box took none of
-- it, not even with no log at all, and with no error, while "abc" went in
-- (2026-11-16). So when it refuses the report, each line it will not take on
-- its own is shown escaped instead, and should the report still not go in,
-- the oldest log lines are left out, half of them at a time. Why it refused
-- (how much of the report's start it takes, and whether as much plain text
-- or two lines) is said at the top of the report, and in the chat.
local function FillReport(edit)
    local lines = ReportLines()
    local text = table.concat(lines, "\n")
    if Takes(edit, text) then
        return
    end
    local start = LongestStart(edit, text)
    local note = ("the window refused the whole report (%d bytes) with no error; it takes its first %d bytes, ending \"%s\", before \"%s\"; %d bytes of plain x it %s; a two-line text it %s"):format(
        #text, start, Escaped(text:sub(math.max(1, start - 39), start)), Escaped(text:sub(start + 1, start + 10)), start + 1,
        Takes(edit, ("x"):rep(start + 1)) and "takes" or "refuses too", Takes(edit, "a\nb") and "takes" or "refuses too")
    local keep, refused, firstRefused
    repeat
        refused, firstRefused = 0, nil
        for i, line in ipairs(lines) do
            if not Takes(edit, line) then
                lines[i] = "[refused: " .. Escaped(line) .. "]"
                refused = refused + 1
                firstRefused = firstRefused or lines[i]
            end
        end
        table.insert(lines, 2, ("Note: %s; %d lines it refused on their own are shown escaped."):format(note, refused))
        text = table.concat(lines, "\n")
        if Takes(edit, text) or keep == 0 then
            break
        end
        keep = math.floor((keep or #log) / 2)
        lines = ReportLines(keep)
    until false
    ns.Print("probe: %s; it refused %d lines on their own%s; %s.", note, refused,
        firstRefused and (", the first: " .. firstRefused:sub(1, 200)) or "",
        Holds(edit, text) and "the report then went in" or "it still took none of the report")
end

local reportWindow

-- A window with the text selected, to copy with Ctrl+C.
local function ShowReport()
    if not reportWindow then
        local window = CreateFrame("Frame", "HunterTrapTimerProbe", UIParent, "PortraitFrameTemplate")
        window:SetSize(680, 460)
        window:SetPoint("CENTER")
        window:SetFrameStrata("DIALOG")
        window:SetMovable(true)
        window:EnableMouse(true)
        window:RegisterForDrag("LeftButton")
        window:SetScript("OnDragStart", window.StartMoving)
        window:SetScript("OnDragStop", window.StopMovingOrSizing)
        window:SetPortraitToAsset("Interface\\Icons\\Spell_Frost_ChainsOfIce")
        window:SetTitle("Hunter Trap Timer - probe")
        tinsert(UISpecialFrames, window:GetName())
        -- The close button's own HideUIPanel does nothing for an addon's
        -- window in combat (CheckProtectedFunctionsAllowed, build 70938),
        -- so the window hides itself.
        window.onCloseCallback = function()
            window:Hide()
            return false
        end

        local hint = window:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        hint:SetPoint("TOPLEFT", 70, -36)
        hint:SetPoint("RIGHT", -20, 0)
        hint:SetJustifyH("LEFT")
        hint:SetText("Press Ctrl+A, then Ctrl+C, to copy the text.")

        local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 16, -66)
        scroll:SetPoint("BOTTOMRIGHT", -34, 16)
        local edit = CreateFrame("EditBox", nil, scroll)
        edit:SetMultiLine(true)
        edit:SetAutoFocus(false)
        edit:SetFontObject(ChatFontNormal)
        edit:SetWidth(620)
        pcall(edit.SetMaxLetters, edit, 0)
        pcall(edit.SetMaxBytes, edit, 0)
        edit:SetScript("OnEscapePressed", function()
            window:Hide()
        end)
        scroll:SetScrollChild(edit)
        window.Edit = edit
        reportWindow = window
    end
    FillReport(reportWindow.Edit)
    reportWindow:Show()
    reportWindow.Edit:SetFocus()
    reportWindow.Edit:HighlightText()
end

events:SetScript("OnEvent", OnEvent)

local function IsGroupUnit(unit)
    return unit:find("^party%d") ~= nil or unit:find("^partypet%d") ~= nil
        or unit:find("^raid%d") ~= nil or unit:find("^raidpet%d") ~= nil
end

-- The casts of everyone else, on a frame of their own: the group's and the
-- enemies', around a trap.
local otherCasts = CreateFrame("Frame")
otherCasts:SetScript("OnEvent", function(_, _, unit, _, spellID)
    unit = Plain(unit)
    if type(unit) ~= "string" or unit == "player" or unit == "pet" or not Active() then
        return
    elseif IsGroupUnit(unit) or IsWatched(unit) then
        Record(("UNIT_SPELLCAST_SUCCEEDED %s: %s"):format(UnitLabel(unit), SpellLabel(spellID)))
    end
end)

local function LogNote(text, ...)
    Record("addon: " .. text:format(...))
end

local function StartRecording()
    recording = true
    wipe(lastPlate)
    ns.Log = LogNote
    ns.RegisterUnitEvents(events, { "player", "pet" }, "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED")
    ns.RegisterEvents(events, "UNIT_AURA", "UNIT_COMBAT", "SPELL_UPDATE_COOLDOWN", "PLAYER_TOTEM_UPDATE",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "NAME_PLATE_UNIT_REMOVED", "COMBAT_TEXT_UPDATE", "UNIT_HEALTH")
    ns.RegisterEvents(otherCasts, "UNIT_SPELLCAST_SUCCEEDED")
    Record("recording started")
end

local function StopRecording()
    Record("recording stopped")
    recording = false
    ns.Log = NoLog
    events:UnregisterAllEvents()
    otherCasts:UnregisterAllEvents()
end

function Probe.Command(option)
    if option == "clear" then
        wipe(log)
        lastText = nil
        ns.Print("probe log cleared.")
    elseif option == "log" and not recording then
        StartRecording()
        ns.Print("probe recording: put a trap down near an enemy and let it spring (or run out), then /htt probe log again.")
    else
        if option == "log" then
            StopRecording()
        end
        ShowReport()
    end
end
