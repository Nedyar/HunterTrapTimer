-- Display.lua: the armed trap's icon, with a clock sweep and the seconds left.
--
-- The seconds turn red, and the icon flashes, while the warning is on. The
-- icon goes when the trap runs out or springs.
local _, ns = ...
local L = ns.L

local Display = {}
ns.Display = Display

local PLACEHOLDER_ICON = "Interface\\Icons\\Spell_Frost_ChainsOfIce"
local WHITE = { 1, 1, 1 }
local RED = { 1, 0.25, 0.25 }

local anchor  -- the frame the icon hangs from, dragged while unlocked
local mover   -- the green cover and hint shown while unlocked
local icon

local function Layout()
    local size = ns.db.iconSize
    icon:SetSize(size, size)
    icon.text:SetFont(STANDARD_TEXT_FONT, math.floor(size * 0.42 + 0.5), "THICKOUTLINE")
end

local function CreateIcon()
    icon = CreateFrame("Frame", nil, anchor)
    icon:SetAllPoints()
    icon.border = icon:CreateTexture(nil, "BACKGROUND")
    icon.border:SetPoint("TOPLEFT", -2, 2)
    icon.border:SetPoint("BOTTOMRIGHT", 2, -2)
    icon.border:SetColorTexture(0, 0, 0, 1)
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
    Layout()
end

local function SetFlashing(flashing)
    if flashing and not icon.flash:IsPlaying() then
        icon.flash:Play()
    elseif not flashing and icon.flash:IsPlaying() then
        icon.flash:Stop()
    end
end

local function SetColor(color)
    icon.text:SetTextColor(color[1], color[2], color[3])
end

-- armed: Traps.armed.
local function ShowTrap(armed)
    if icon.entry ~= armed then
        icon.entry = armed
        icon.texture:SetTexture(armed.icon or PLACEHOLDER_ICON)
        icon.cooldown:SetCooldown(armed.start, armed.duration)
    end
    local left = math.max(0, armed.start + armed.duration - GetTime())
    local warning = ns.db.warnSeconds > 0 and left <= ns.db.warnSeconds
    icon.text:SetText(math.ceil(left))
    SetColor(warning and RED or WHITE)
    SetFlashing(warning and ns.db.warnFlash)
end

-- While unlocked with no trap down, the icon shows where it will be.
local function ShowPlaceholder()
    icon.entry = nil
    icon.texture:SetTexture(PLACEHOLDER_ICON)
    icon.cooldown:Clear()
    icon.text:SetText(ns.Traps.ARMED_DURATION)
    SetColor(WHITE)
    SetFlashing(false)
end

function Display.Refresh()
    if not anchor then
        return
    end
    local armed = ns.Traps.armed
    if armed then
        ShowTrap(armed)
    elseif not ns.db.locked then
        ShowPlaceholder()
    else
        icon.entry = nil
        SetFlashing(false)
    end
    mover:SetShown(not ns.db.locked)
    anchor:SetShown(armed ~= nil or not ns.db.locked)
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
    Layout()
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
    CreateIcon()

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
