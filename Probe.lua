-- Probe.lua: /htt probe, a diagnostic of what WoW Forever lets an addon see of
-- a trap. The combat log is closed, so noticing that a trap sprang rests on
-- these answers (see Traps.lua). It is meant for the addon's author, so it is
-- in English and not translated.
--
-- /htt probe shows the current answers, and the log, in a window whose text
-- can be copied. The log is recorded on demand: /htt probe log starts it, and
-- run again stops it and shows the report. While recording, it logs the
-- hunter's casts, and what happens to enemies from the moment a trap goes
-- down until a while after it and its effect are gone. When not recording it
-- listens to no event at all. /htt probe clear empties the log.
local _, ns = ...
local Plain = ns.Plain

local Probe = {}
ns.Probe = Probe

local MAX_LINES = 400
local AFTER = 20          -- seconds the log goes on after the trap and its effect are gone
local MAX_AURAS = 40

local log = {}
local lastText, repeats   -- the last line's text, to fold repeats into one line
local activeUntil = 0
local recording = false
local events = CreateFrame("Frame")
local NoLog = ns.Log      -- Core's ns.Log, which does nothing

local function Show(value)
    if ns.IsSecret(value) then
        return "secret"
    end
    return tostring(value)
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

-- Whether to log what happens to enemies: while a trap or its effect is up,
-- and for a while after.
local function Active()
    if ns.Traps.armed or ns.Traps.effect then
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

local function SpellLabel(spellID)
    if ns.IsSecret(spellID) or spellID == nil then
        return Show(spellID)
    end
    return ("%s %s"):format(spellID, Ask(C_Spell.GetSpellName, spellID))
end

local function AuraText(aura)
    local expires = Plain(aura.expirationTime)
    return ("from %s, mine %s, duration %s, %s s left"):format(Show(aura.sourceUnit), Show(aura.isFromPlayerOrPlayerPet),
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

-- The last trap's effects found on unit, or "none".
local function EffectsOn(unit)
    local last = ns.Traps.lastArmed
    if not last then
        return "no trap yet"
    end
    local found = {}
    for _, effectID in ipairs(last.trap.effects) do
        local answer = EffectText(unit, effectID)
        if answer ~= "none" then
            found[#found + 1] = ("%d %s"):format(effectID, answer)
        end
    end
    return #found > 0 and table.concat(found, "; ") or "none"
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
        else
            local _, action, flag, amount, school = ...
            Record(("UNIT_COMBAT %s: %s %s %s, school %s"):format(UnitLabel(unit), Show(action), Show(flag),
                Show(amount), Show(school)))
        end
    elseif event == "SPELL_UPDATE_COOLDOWN" then
        local spellID = ns.Traps.lastArmed and ns.Traps.lastArmed.spellID
        Record(("SPELL_UPDATE_COOLDOWN %s; trap %s: %s"):format(Show((...)), Show(spellID), CooldownText(spellID)))
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local unit = ...
        Record(("NAME_PLATE_UNIT_REMOVED %s: dead %s"):format(UnitLabel(unit), Ask(UnitIsDead, unit)))
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
    return ("%s (spell %s%s), %.1f s left"):format(entry.trap.key, tostring(entry.spellID),
        entry.guessed and ", guessed" or "", entry.start + entry.duration - GetTime())
end

local function ReportText()
    local S = C_Secrets or {}
    local lines = {}
    local function Add(text, ...)
        lines[#lines + 1] = select("#", ...) > 0 and text:format(...) or text
    end
    Add("Hunter Trap Timer %s - probe, %s, client %s", Ask(C_AddOns and C_AddOns.GetAddOnMetadata, "HunterTrapTimer", "Version"),
        date("%Y-%m-%d %H:%M:%S"), Ask(GetBuildInfo))
    Add("In combat: %s. In a group: %s. Secret restrictions: %s; auras secret: %s; cooldowns secret: %s. Combat log restricted: %s.",
        Ask(InCombatLockdown), Ask(IsInGroup), Ask(S.HasSecretRestrictions), Ask(S.ShouldAurasBeSecret), Ask(S.ShouldCooldownsBeSecret),
        Ask(C_CombatLog and C_CombatLog.IsCombatLogRestricted))
    Add("Armed: %s. Effect: %s.", EntryText(ns.Traps.armed), EntryText(ns.Traps.effect))
    Add("")

    Add("Trap spells you know (cast secrecy, cooldown secrecy, cooldown secret now; cooldown), then their effects (aura secrecy, aura secret now; on the target):")
    local known = 0
    for _, trap in ipairs(ns.Traps.LIST) do
        for rank, spellID in ipairs(trap.spells) do
            if Plain(IsPlayerSpell(spellID)) then
                known = known + 1
                local effectID = trap.effects[rank]
                Add("  %s: %s, %s, %s; %s", SpellLabel(spellID), Ask(S.GetSpellCastSecrecy, spellID),
                    Ask(S.GetSpellCooldownSecrecy, spellID), Ask(S.ShouldSpellCooldownBeSecret, spellID), CooldownText(spellID))
                Add("    effect %s: %s, %s; %s", SpellLabel(effectID), Ask(S.GetSpellAuraSecrecy, effectID),
                    Ask(S.ShouldSpellAuraBeSecret, effectID), EffectText("target", effectID))
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
    for _, line in ipairs(log) do
        lines[#lines + 1] = "  " .. line
    end
    if #log == 0 then
        Add("  empty")
    end
    Add("")
    Add("To fill the log: /htt probe log, put a trap down near an enemy and let it spring (or run out), then /htt probe log again. /htt probe clear empties the log.")
    return table.concat(lines, "\n")
end

local reportWindow

-- A window with the text selected, to copy with Ctrl+C.
local function ShowReport(text)
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
    reportWindow.Edit:SetText(text)
    reportWindow:Show()
    reportWindow.Edit:SetFocus()
    reportWindow.Edit:HighlightText()
end

events:SetScript("OnEvent", OnEvent)

local function LogNote(text, ...)
    Record("addon: " .. text:format(...))
end

local function StartRecording()
    recording = true
    ns.Log = LogNote
    ns.RegisterUnitEvents(events, { "player", "pet" }, "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED")
    ns.RegisterEvents(events, "UNIT_AURA", "UNIT_COMBAT", "SPELL_UPDATE_COOLDOWN", "PLAYER_TOTEM_UPDATE",
        "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "NAME_PLATE_UNIT_REMOVED")
    Record("recording started")
end

local function StopRecording()
    Record("recording stopped")
    recording = false
    ns.Log = NoLog
    events:UnregisterAllEvents()
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
        ShowReport(ReportText())
    end
end
