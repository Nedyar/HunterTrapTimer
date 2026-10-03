-- Display.lua: the trap's icon, with a clock sweep and the seconds left.
--
-- The armed trap's icon comes first. When the trap springs, its icon turns
-- green and counts down the effect; a trap put down meanwhile shows beside it.
-- The seconds turn red, and the icon flashes, while the warning is on.
local _, ns = ...
local L = ns.L

local Display = {}
ns.Display = Display

local GAP = 6
local PLACEHOLDER_ICON = "Interface\\Icons\\Spell_Frost_ChainsOfIce"
local COLORS = {
    armed = { 1, 1, 1 },
    warning = { 1, 0.25, 0.25 },
    effect = { 0.3, 1, 0.3 },
}

local anchor  -- the frame the icons hang from, dragged while unlocked
local mover   -- the green cover and hint shown while unlocked
local icons = {}

local function Layout(icon, index)
    local size = ns.db.iconSize
    icon:SetSize(size, size)
    icon:ClearAllPoints()
    icon:SetPoint("TOPLEFT", anchor, "TOPLEFT", (index - 1) * (size + GAP), 0)
    icon.text:SetFont(STANDARD_TEXT_FONT, math.floor(size * 0.42 + 0.5), "THICKOUTLINE")
end

local function CreateIcon(index)
    local icon = CreateFrame("Frame", nil, anchor)
    icon.border = icon:CreateTexture(nil, "BACKGROUND")
    icon.border:SetPoint("TOPLEFT", -2, 2)
    icon.border:SetPoint("BOTTOMRIGHT", 2, -2)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    icon.texture:SetAllPoints()
    icon.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- The lit part of the icon is the time left.
    icon.cooldown = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    icon.cooldown:SetAllPoints()
    icon.cooldown:SetReverse(true)
    icon.cooldown:SetDrawEdge(false)
    icon.cooldown:SetDrawBling(false)
    icon.cooldown:SetHideCountdownNumbers(true)

    -- The seconds sit above the sweep.
    local overlay = CreateFrame("Frame", nil, icon)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(icon.cooldown:GetFrameLevel() + 2)
    icon.text = overlay:CreateFontString(nil, "OVERLAY")
    icon.text:SetPoint("CENTER")

    icon.flash = icon:CreateAnimationGroup()
    icon.flash:SetLooping("BOUNCE")
    local fade = icon.flash:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0.3)
    fade:SetDuration(0.35)

    Layout(icon, index)
    icons[index] = icon
    return icon
end

local function SetFlashing(icon, flashing)
    if flashing and not icon.flash:IsPlaying() then
        icon.flash:Play()
    elseif not flashing and icon.flash:IsPlaying() then
        icon.flash:Stop()
    end
end

local function SetColor(icon, color)
    icon.text:SetTextColor(color[1], color[2], color[3])
    if color == COLORS.effect then
        icon.border:SetColorTexture(color[1], color[2], color[3], 1)
    else
        icon.border:SetColorTexture(0, 0, 0, 1)
    end
end

-- entry: Traps.armed or Traps.effect.
local function ShowEntry(icon, entry, now, isEffect)
    if icon.entry ~= entry then
        icon.entry = entry
        icon.texture:SetTexture(entry.icon or PLACEHOLDER_ICON)
        icon.cooldown:SetCooldown(entry.start, entry.duration)
    end
    local left = math.max(0, entry.start + entry.duration - now)
    icon.text:SetText(math.ceil(left))
    local warning = not isEffect and ns.db.warnSeconds > 0 and left <= ns.db.warnSeconds
    SetColor(icon, isEffect and COLORS.effect or warning and COLORS.warning or COLORS.armed)
    SetFlashing(icon, warning and ns.db.warnFlash)
    icon:Show()
end

-- While unlocked with no trap down, an icon shows where they will be.
local function ShowPlaceholder(icon)
    icon.entry = nil
    icon.texture:SetTexture(PLACEHOLDER_ICON)
    icon.cooldown:Clear()
    icon.text:SetText(ns.Traps.ARMED_DURATION)
    SetColor(icon, COLORS.armed)
    SetFlashing(icon, false)
    icon:Show()
end

function Display.Refresh()
    if not anchor then
        return
    end
    local now, used = GetTime(), 0
    local armed, effect = ns.Traps.armed, ns.Traps.effect
    if armed then
        used = used + 1
        ShowEntry(icons[used] or CreateIcon(used), armed, now, false)
    end
    if effect then
        used = used + 1
        ShowEntry(icons[used] or CreateIcon(used), effect, now, true)
    end
    if used == 0 and not ns.db.locked then
        used = 1
        ShowPlaceholder(icons[1] or CreateIcon(1))
    end
    for index = used + 1, #icons do
        local icon = icons[index]
        icon.entry = nil
        SetFlashing(icon, false)
        icon:Hide()
    end
    mover:SetShown(not ns.db.locked)
    anchor:SetShown(used > 0)
end

-- The warning starts: the flash is drawn by Refresh, the sound plays once.
function Display.Warn()
    if ns.db.warnSound then
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    end
end

local function SavePosition()
    local x, y = anchor:GetCenter()
    local centerX, centerY = UIParent:GetCenter()
    ns.db.x = math.floor(x - centerX + 0.5)
    ns.db.y = math.floor(y - centerY + 0.5)
    ns.SettingsChanged()
end

function Display.ApplySettings()
    if not anchor then
        return
    end
    local db = ns.db
    anchor:ClearAllPoints()
    anchor:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
    anchor:SetSize(db.iconSize, db.iconSize)
    anchor:EnableMouse(not db.locked)
    for index, icon in ipairs(icons) do
        Layout(icon, index)
    end
    Display.Refresh()
end

function Display.Init()
    anchor = CreateFrame("Frame", "HunterTrapTimerFrame", UIParent)
    anchor:SetMovable(true)
    anchor:SetClampedToScreen(true)
    anchor:RegisterForDrag("LeftButton")
    anchor:SetScript("OnDragStart", function(self)
        if not ns.db.locked then
            self:StartMoving()
        end
    end)
    anchor:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)

    mover = CreateFrame("Frame", nil, anchor)
    mover:SetAllPoints()
    mover:SetFrameLevel(anchor:GetFrameLevel() + 20)
    local cover = mover:CreateTexture(nil, "OVERLAY")
    cover:SetAllPoints()
    cover:SetColorTexture(0.2, 0.8, 0.2, 0.35)
    local hint = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOM", mover, "TOP", 0, 6)
    hint:SetText(L["Drag to move, then /htt lock"])

    Display.ApplySettings()
end
