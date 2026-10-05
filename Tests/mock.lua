-- Strict mock of the WoW Forever (1.60.1 / Midnight API) surface used by the addon.
-- Unknown widget methods raise, so typos are caught instead of silently ignored.
-- M holds the simulated world: the clock, the units and their auras, the
-- spells the player knows, and what the addon printed and played.
M = {
    printed = {}, errors = {}, sounds = {}, time = 1000, timers = {}, combat = false,
    units = {}, eventFrames = {}, allFrames = {}, known = {},
    aurasSecret = false,   -- C_Secrets says auras are secret now (combat restrictions)
}

-- Secret sentinel: any comparison, arithmetic or concatenation raises.
local function secretError() error("attempt to use a secret value", 2) end
SECRET = setmetatable({}, {
    __eq = secretError, __lt = secretError, __le = secretError, __concat = secretError,
    __add = secretError, __sub = secretError, __mul = secretError, __div = secretError,
    __index = secretError,
    __tostring = function() return "SECRET" end,
})
function issecretvalue(v) return rawequal(v, SECRET) end
function GetTime() return M.time end

function print(...)
    local parts = {}
    for i = 1, select("#", ...) do parts[#parts + 1] = tostring((select(i, ...))) end
    M.printed[#M.printed + 1] = table.concat(parts, " ")
end
function geterrorhandler() return function(e) M.errors[#M.errors + 1] = tostring(e) end end

function wipe(t) for k in pairs(t) do t[k] = nil end return t end
function strtrim(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
tinsert = table.insert
function date(format) assert(format == "%Y-%m-%d %H:%M:%S") return "2026-10-03 12:00:00" end

-- Widgets ----------------------------------------------------------------------

local KNOWN_EVENTS = {}
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_LOGIN", "UNIT_AURA", "UNIT_COMBAT", "SPELL_UPDATE_COOLDOWN",
    "PLAYER_TOTEM_UPDATE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UNIT_SPELLCAST_SENT",
    "UNIT_SPELLCAST_START", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
    "NAME_PLATE_UNIT_REMOVED", "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT" }) do
    KNOWN_EVENTS[e] = true
end
-- Registering these is forbidden on Forever; the addon must never try.
local FORBIDDEN_EVENTS = { COMBAT_LOG_EVENT_UNFILTERED = true, COMBAT_LOG_EVENT = true }

-- Widget API methods are PascalCase; reading an unknown one is a typo in the
-- addon. Lowercase keys are plain data fields and may be nil.
local function Strict(class, kind)
    return {
        __index = function(_, k)
            local v = class[k]
            if v == nil and type(k) == "string" and k:match("^%u") then
                error(kind .. " has no method '" .. k .. "'", 2)
            end
            return v
        end,
    }
end

local Region = {}
function Region:SetSize(w, h) self.w, self.h = w, h end
function Region:SetWidth(w) self.w = w end
function Region:SetHeight(h) self.h = h end
function Region:GetWidth() return self.w or 0 end
function Region:SetPoint(...) self.points = self.points or {}; self.points[#self.points + 1] = { ... } end
function Region:ClearAllPoints() self.points = {} end
function Region:SetAllPoints(target) self.points = { { "ALL", target } } end
function Region:Show() self.shown = true end
function Region:Hide() self.shown = false end
function Region:SetShown(s) self.shown = not not s end
function Region:IsShown() return self.shown end

local FontString = setmetatable({}, { __index = Region })
function FontString:SetText(t) self.textValue = t end
function FontString:GetText() return self.textValue end
function FontString:SetFont(path, size, flags)
    assert(type(path) == "string" and type(size) == "number" and type(flags) == "string", "bad SetFont args")
    self.font = { path, size, flags }
    return true
end
function FontString:SetFontObject(o) self.fontObject = o end
function FontString:SetTextColor(r, g, b) self.color = { r, g, b } end
function FontString:SetJustifyH() end
function FontString:GetStringWidth() return #tostring(self.textValue or "") * 6 end

local Texture = setmetatable({}, { __index = Region })
function Texture:SetColorTexture(r, g, b, a) self.color = { r, g, b, a } end
function Texture:SetTexture(path) assert(path ~= nil, "SetTexture(nil)") self.path = path end
function Texture:SetTexCoord(...) self.texCoord = { ... } end
-- Atlases the client has (the ones the addon uses, from Blizzard's TotemFrame.xml).
M.atlases = { CircleMask = true, ["UI-HUD-UnitFrame-TotemFrame"] = true }
function Texture:SetAtlas(atlas) assert(M.atlases[atlas], "unknown atlas " .. tostring(atlas)) self.atlas = atlas end
-- Masks: a texture keeps the masks added to it; removing one it lacks raises.
function Texture:AddMaskTexture(mask)
    assert(mask.kind == "MaskTexture", "AddMaskTexture needs a mask")
    self.masks = self.masks or {}
    assert(not self.masks[mask], "mask added twice")
    self.masks[mask] = true
end
function Texture:RemoveMaskTexture(mask)
    assert(self.masks and self.masks[mask], "RemoveMaskTexture of a mask not added")
    self.masks[mask] = nil
end
function Texture:IsMasked() return self.masks ~= nil and next(self.masks) ~= nil end

local FontStringMeta, TextureMeta = Strict(FontString, "FontString"), Strict(Texture, "Texture")
local function NewRegion(kind, parent)
    local r = { kind = kind, parent = parent, shown = true }
    return setmetatable(r, kind == "FontString" and FontStringMeta or TextureMeta)
end

local Animation = {}
function Animation:SetFromAlpha(a) self.from = a end
function Animation:SetToAlpha(a) self.to = a end
function Animation:SetDuration(d) self.duration = d end
local AnimationMeta = Strict(Animation, "Animation")

local AnimationGroup = {}
function AnimationGroup:SetLooping(mode) assert(mode == "BOUNCE" or mode == "REPEAT" or mode == "NONE") self.looping = mode end
function AnimationGroup:CreateAnimation(kind) assert(kind == "Alpha") return setmetatable({}, AnimationMeta) end
function AnimationGroup:Play() self.playing = true end
function AnimationGroup:Stop() self.playing = false end
function AnimationGroup:IsPlaying() return self.playing == true end
local AnimationGroupMeta = Strict(AnimationGroup, "AnimationGroup")

local Frame = setmetatable({}, { __index = Region })
function Frame:SetScript(name, fn) self.scripts[name] = fn end
function Frame:GetScript(name) return self.scripts[name] end
function Frame:RegisterEvent(event)
    if FORBIDDEN_EVENTS[event] then M.forbidden = event; error("ADDON_ACTION_FORBIDDEN") end
    if not KNOWN_EVENTS[event] then error("Attempt to register unknown event \"" .. event .. "\"") end
    M.eventFrames[self] = M.eventFrames[self] or {}
    M.eventFrames[self][event] = true
end
function Frame:RegisterUnitEvent(event, ...)
    self:RegisterEvent(event)
    local units = { ... }
    assert(#units >= 1 and #units <= 2, "RegisterUnitEvent takes one or two units")
    self.unitFilter = self.unitFilter or {}
    self.unitFilter[event] = {}
    for _, unit in ipairs(units) do self.unitFilter[event][unit] = true end
end
function Frame:UnregisterEvent(event) if M.eventFrames[self] then M.eventFrames[self][event] = nil end end
function Frame:UnregisterAllEvents() M.eventFrames[self] = nil; self.unitFilter = nil end
function Frame:SetFrameLevel(l) assert(type(l) == "number" and l >= 0 and l <= 10000, "bad frame level") self.level = l end
function Frame:GetFrameLevel() return self.level or 1 end
function Frame:CreateFontString(name, layer, template) return NewRegion("FontString", self) end
function Frame:CreateTexture(name, layer) return NewRegion("Texture", self) end
function Frame:CreateMaskTexture() return NewRegion("MaskTexture", self) end
function Frame:CreateAnimationGroup() return setmetatable({}, AnimationGroupMeta) end
function Frame:SetHitRectInsets(l, r, t, b) assert(type(r) == "number") end
function Frame:EnableMouseWheel() end
function Frame:Click() local s = self.scripts.OnClick if s then s(self, "LeftButton") end end
function Frame:SetText(t) self.textValue = t end
function Frame:GetText() return self.textValue end
function Frame:GetFontString()
    local text = self.textValue or ""
    return { GetStringWidth = function() return #text * 6 end }
end
-- CheckButton
function Frame:SetChecked(c) self.checked = not not c end
function Frame:GetChecked() return self.checked end
-- Slider
function Frame:SetMinMaxValues(a, b) self.min, self.max = a, b end
function Frame:SetValueStep(s) self.step = s end
function Frame:SetObeyStepOnDrag() end
function Frame:SetValue(v, userInput)
    self.value = v
    local s = self.scripts.OnValueChanged
    if s then s(self, v, userInput or false) end
end
function Frame:GetValue() return self.value end
-- EditBox
function Frame:SetMultiLine(multi) self.multiLine = multi end
function Frame:SetAutoFocus() end
function Frame:SetFontObject(o) self.fontObject = o end
function Frame:SetMaxLetters() end
function Frame:SetMaxBytes() end
function Frame:SetFocus() self.focus = true end
function Frame:HighlightText() end
-- ScrollFrame
function Frame:SetScrollChild(child) self.scrollChild = child end
-- Movable frames: the position is a center (x, y) in screen pixels.
function Frame:SetMovable(movable) self.movable = movable end
function Frame:SetClampedToScreen() end
function Frame:SetUserPlaced(placed) self.userPlaced = placed end
function Frame:EnableMouse(enabled) self.mouse = enabled end
function Frame:SetMouseMotionEnabled(enabled) self.mouseMotion = enabled end
function Frame:SetMouseClickEnabled(enabled) self.mouseClick = enabled end
function Frame:SetScale(scale) assert(type(scale) == "number" and scale > 0, "bad scale") self.scale = scale end
function Frame:GetScale() return self.scale or 1 end
function Frame:GetEffectiveScale() return (self.scale or 1) * (self.parent and self.parent:GetEffectiveScale() or 1) end
function Frame:RegisterForDrag() end
function Frame:StartMoving() assert(self.movable, "StartMoving on a frame that is not movable") self.moving = true end
function Frame:StopMovingOrSizing() self.moving = false end
function Frame:GetCenter()
    if self.center then return self.center[1], self.center[2] end
    local p = self.points and self.points[1]
    assert(p and p[1] == "CENTER" and p[2] == UIParent and p[3] == "CENTER", "GetCenter needs a CENTER point on UIParent")
    return 960 + p[4], 540 + p[5]
end
function Frame:SetFrameStrata(strata) self.strata = strata end
function Frame:GetName() return self.name end
-- PortraitFrameTemplate
function Frame:SetPortraitToAsset(path) assert(self.template == "PortraitFrameTemplate") self.portrait = path end
function Frame:SetTitle(title) assert(self.template == "PortraitFrameTemplate") self.title = title end
-- Cooldown
function Frame:SetCooldown(start, duration)
    assert(self.kind == "Cooldown" and type(start) == "number" and type(duration) == "number", "bad SetCooldown")
    self.start, self.duration = start, duration
end
function Frame:Clear() assert(self.kind == "Cooldown") self.start, self.duration = nil, nil end
function Frame:SetReverse(r) assert(self.kind == "Cooldown") self.reverse = r end
function Frame:SetDrawEdge() assert(self.kind == "Cooldown") end
function Frame:SetDrawBling() assert(self.kind == "Cooldown") end
function Frame:SetHideCountdownNumbers(h) assert(self.kind == "Cooldown") self.hideNumbers = h end
function Frame:SetSwipeColor(r, g, b, a) assert(self.kind == "Cooldown") self.swipeColor = { r, g, b, a } end
function Frame:SetSwipeTexture(path) assert(self.kind == "Cooldown" and type(path) == "string") self.swipeTexture = path end
function Frame:SetTexCoordRange(low, high)
    assert(self.kind == "Cooldown" and type(low.x) == "number" and type(high.y) == "number", "bad SetTexCoordRange")
    self.texCoordRange = { low, high }
end
local FrameMeta = Strict(Frame, "Frame")

local templates = {
    UICheckButtonTemplate = function(f) f.Text = f:CreateFontString() end,
    UISliderTemplateWithLabels = function(f)
        f.Text, f.Low, f.High = f:CreateFontString(), f:CreateFontString(), f:CreateFontString()
    end,
    UIPanelButtonTemplate = function() end,
    UIRadioButtonTemplate = function(f) f.text = f:CreateFontString() end,
    PortraitFrameTemplate = function() end,
    UIPanelScrollFrameTemplate = function() end,
    CooldownFrameTemplate = function(f) assert(f.kind == "Cooldown") end,
}
function CreateFrame(kind, name, parent, template)
    local f = setmetatable({ kind = kind, name = name, parent = parent, template = template, scripts = {}, shown = true }, FrameMeta)
    if name then _G[name] = f end
    if template then
        local init = templates[template]
        assert(init, "unknown template " .. tostring(template))
        init(f)
    end
    M.allFrames[#M.allFrames + 1] = f
    return f
end

-- A frame is drawn, and runs OnUpdate, only if it and its parents are shown.
function M.Visible(f)
    while f do
        if not f.shown then return false end
        f = f.parent
    end
    return true
end

-- Frames get an event in the order they were made, like in the game.
function M.Fire(event, ...)
    local unit = ...
    for _, frame in ipairs(M.allFrames) do
        local events = M.eventFrames[frame]
        local filter = frame.unitFilter and frame.unitFilter[event]
        if events and events[event] and frame.scripts.OnEvent and (not filter or filter[unit]) then
            frame.scripts.OnEvent(frame, event, ...)
        end
    end
end
-- Moves the clock on, running timers and the OnUpdate of shown frames every
-- step seconds. The step is a power of two, so the clock stays exact for
-- whole multiples of it.
function M.Advance(seconds, step)
    step = step or 1 / 16
    local target = M.time + seconds
    while M.time < target - 1e-9 do
        local delta = math.min(step, target - M.time)
        M.time = M.time + delta
        for i = #M.timers, 1, -1 do
            local t = M.timers[i]
            if t.at <= M.time then table.remove(M.timers, i); t.fn() end
        end
        for _, f in ipairs(M.allFrames) do
            local fn = f.scripts.OnUpdate
            if fn and M.Visible(f) then fn(f, delta) end
        end
    end
end

-- Globals and namespaces ------------------------------------------------------------

STANDARD_TEXT_FONT = "Fonts\\FRIZQT__.TTF"
SlashCmdList = {}
UIParent = CreateFrame("Frame", "UIParent")
UIParent.center = { 960, 540 }
UISpecialFrames = {}
ChatFontNormal = {}
-- The tooltip keeps its owner and lines, for the icon's tooltip.
GameTooltip = { lines = {} }
function GameTooltip:SetOwner(owner, anchor) self.owner, self.anchor, self.lines, self.shown = owner, anchor, {}, false end
function GameTooltip:SetText(text) self.lines = { text } end
function GameTooltip:AddLine(text) self.lines[#self.lines + 1] = text end
function GameTooltip:Show() self.shown = true end
function GameTooltip:Hide() self.shown, self.owner = false, nil end
function GameTooltip:IsOwned(frame) return self.owner == frame end
SOUNDKIT = { RAID_WARNING = 8959 }
-- Blizzard's player frame, and the texts the client translates.
PlayerFrame = CreateFrame("Frame", "PlayerFrame", UIParent)
SECOND_ONELETTER_ABBR = "%d s"
BUFF_DURATION_WARNING_TIME = 60
GameFontNormalSmall = { GetFont = function() return "Fonts\\FRIZQT__.TTF", 10, "" end }
SPELL_TIME_REMAINING_SEC = "%d |4second:seconds; remaining"
HUD_EDIT_MODE_PLAYER_FRAME_LABEL = "Player Frame"
C_Texture = {
    GetAtlasInfo = function(atlas)
        if atlas == "CircleMask" then
            return { file = "Interface/Common/CommonMaskCircle", leftTexCoord = 0, rightTexCoord = 1, topTexCoord = 0, bottomTexCoord = 1 }
        end
    end,
}
RESIST, IMMUNE = "Resist", "Immune"
CombatFeedbackText = { RESIST = RESIST, IMMUNE = IMMUNE }
function PlaySound(id, channel) assert(type(id) == "number") M.sounds[#M.sounds + 1] = id end

C_Timer = { After = function(delay, fn) M.timers[#M.timers + 1] = { at = M.time + delay, fn = fn } end }
-- Metadata comes from the real TOC.
C_AddOns = {
    GetAddOnMetadata = function(name, field)
        assert(name == "HunterTrapTimer", "metadata of another addon")
        return SOURCES["HunterTrapTimer.toc"]:match("## " .. field .. ": ([^\r\n]+)")
    end,
}
C_CombatLog = { IsCombatLogRestricted = function() return true end }
function GetBuildInfo() return "1.60.1", "70205", "Oct 1 2026", 16001 end
function GetLocale() return M.locale or "enUS" end
function InCombatLockdown() return M.combat end

Settings = {
    RegisterCanvasLayoutCategory = function(frame, name)
        local c = { frame = frame, name = name, GetID = function() return 1 end }
        M.mainCategory = c
        return c
    end,
    RegisterAddOnCategory = function(c) M.addonCategory = c end,
    OpenToCategory = function() M.openedOptions = true end,
}
SettingsPanel = { IsShown = function() return M.openedOptions == true end }

-- Units and spells ---------------------------------------------------------------

M.class = "HUNTER"
local CLASS_NAMES = { HUNTER = "Hunter", MAGE = "Mage" }
function UnitClass(unit) return CLASS_NAMES[M.class], M.class, 3 end
function UnitName(unit)
    if unit == "player" then return "Tester", nil end
    local u = M.units[unit]
    if u and u.secretName then return SECRET, nil end
    return u and u.name, nil
end
function UnitGUID(unit) local u = M.units[unit] return u and (u.secretGUID and SECRET or u.guid) end
function UnitCanAttack(_, unit) local u = M.units[unit] return u ~= nil and not u.friendly end
function UnitIsDead(unit) local u = M.units[unit] return u ~= nil and u.dead == true end
function IsInGroup() return M.inGroup == true end
-- A unit made with isPlayer or isPet is the player or the pet under another name.
function UnitIsUnit(a, b)
    if a == b then return true end
    local u = M.units[a]
    return u ~= nil and (b == "player" and u.isPlayer == true or b == "pet" and u.isPet == true)
end

M.spellNames = {
    [1499] = "Freezing Trap", [14310] = "Freezing Trap", [14311] = "Freezing Trap", [99001] = "Freezing Trap",
    [13795] = "Immolation Trap", [14302] = "Immolation Trap", [13809] = "Frost Trap", [13813] = "Explosive Trap",
    [3355] = "Freezing Trap Effect", [14309] = "Freezing Trap Effect", [13797] = "Immolation Trap Effect",
    [75] = "Auto Shot", [14282] = "Arcane Shot", [3044] = "Arcane Shot", [17253] = "Bite", [16827] = "Claw",
    [2973] = "Raptor Strike", [14261] = "Raptor Strike", [1978] = "Serpent Sting", [13550] = "Serpent Sting",
    [26177] = "Charge",
}
C_Spell = {
    GetSpellName = function(id) return M.spellNames[id] end,
    GetSpellTexture = function(id) return M.spellNames[id] and ("icon:" .. id) or nil end,
    GetSpellSubtext = function(id) return ({ [1499] = "Rank 1", [14311] = "Rank 3" })[id] or "" end,
    GetSpellCooldown = function(id)
        if M.combat then return { startTime = SECRET, duration = SECRET, isEnabled = true, isActive = true, modRate = 1 } end
        return { startTime = 0, duration = 0, isEnabled = true, isActive = false, modRate = 1 }
    end,
}
function IsPlayerSpell(id) return M.known[id] == true end
function GetNumTotemSlots() return 4 end
function GetTotemInfo(slot) return false, "", 0, 0, 0 end

-- M.units[token].auras = { { spellId, sourceUnit, isFromPlayerOrPlayerPet, duration, expirationTime, icon, name } }
-- An aura with secret = true reads as secret; while M.aurasSecret, every
-- query by spell ID finds nothing (RequiresNonSecretAura).
C_UnitAuras = {
    GetUnitAuraBySpellID = function(unit, spellID)
        assert(type(unit) == "string" and type(spellID) == "number", "bad GetUnitAuraBySpellID args")
        if M.aurasSecret then return nil end
        local u = M.units[unit]
        for _, aura in ipairs(u and u.auras or {}) do
            if aura.spellId == spellID then return aura.secret and SECRET or aura end
        end
    end,
    GetAuraDataByIndex = function(unit, index, filter)
        local u = M.units[unit]
        local aura = u and u.auras and u.auras[index]
        if aura and (aura.secret or M.aurasSecret) then return SECRET end
        return aura
    end,
    -- PLAYER: auras of the player's; CROWD_CONTROL: auras made with cc = true.
    GetUnitAuraInstanceIDs = function(unit, filter)
        if M.aurasSecret then error("Auras cannot be accessed when secret while tainted") end
        local ids = {}
        for _, aura in ipairs(M.units[unit] and M.units[unit].auras or {}) do
            if (not filter:find("PLAYER") or aura.isFromPlayerOrPlayerPet) and (not filter:find("CROWD_CONTROL") or aura.cc) then
                ids[#ids + 1] = aura.auraInstanceID
            end
        end
        return ids
    end,
    IsAuraFilteredOutByInstanceID = function(unit, id, filter)
        for _, aura in ipairs(M.units[unit].auras) do
            if aura.auraInstanceID == id then return filter:find("CROWD_CONTROL") ~= nil and not aura.cc end
        end
        return true
    end,
    GetAuraDuration = function() return {} end,
}
C_Secrets = {
    HasSecretRestrictions = function() return true end,
    ShouldAurasBeSecret = function() return M.aurasSecret end,
    ShouldCooldownsBeSecret = function() return M.combat end,
    ShouldSpellAuraBeSecret = function() return M.aurasSecret end,
    ShouldSpellCooldownBeSecret = function() return M.combat end,
    GetSpellAuraSecrecy = function() return 1 end,
    GetSpellCastSecrecy = function() return 0 end,
    GetSpellCooldownSecrecy = function() return 1 end,
}

-- Test helpers -------------------------------------------------------------------

function M.AddUnit(token, u) u.auras = u.auras or {}; u.guid = u.guid or ("Creature-" .. token); M.units[token] = u end
-- An aura put on a unit now, by the player unless source says otherwise.
M.lastInstanceID = 0
function M.AddAura(token, spellID, duration, opts)
    opts = opts or {}
    M.lastInstanceID = M.lastInstanceID + 1
    local aura = {
        spellId = spellID, name = M.spellNames[spellID], icon = "icon:" .. spellID,
        sourceUnit = opts.source or "player", isFromPlayerOrPlayerPet = opts.source == nil or opts.fromPlayer == true,
        duration = duration, expirationTime = (opts.appliedAt or M.time) + duration, secret = opts.secret,
        auraInstanceID = M.lastInstanceID, cc = spellID == 3355 or spellID == 14308 or spellID == 14309,
    }
    table.insert(M.units[token].auras, aura)
    M.Fire("UNIT_AURA", token, { isFullUpdate = false, addedAuras = { aura } })
    return aura
end
function M.RemoveAura(token, spellID)
    local auras = M.units[token].auras
    for i = #auras, 1, -1 do
        if auras[i].spellId == spellID then table.remove(auras, i) end
    end
    M.Fire("UNIT_AURA", token, { isFullUpdate = false, removedAuraInstanceIDs = { 1 } })
end
-- An aura added to a unit in combat: the update lists it, but secret.
function M.HiddenAura(token)
    M.Fire("UNIT_AURA", token, { isFullUpdate = false, addedAuras = SECRET })
end
function M.Damage(token, amount)
    M.Fire("UNIT_COMBAT", token, "WOUND", "", amount or 50, 1)
end
function M.Cast(spellID)
    M.Fire("UNIT_SPELLCAST_SENT", "player", "", "Cast-1", spellID)
    M.Fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-1", spellID)
end
