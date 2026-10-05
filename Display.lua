-- Display.lua: the armed trap's icon, with a clock sweep and the seconds left.
--
-- By default it looks and sits like a shaman's totem (Blizzard's
-- TotemFrame.xml for WoW Forever: a 37 pixel button holding the icon, 22
-- pixels and cut by "CircleMask", in the "UI-HUD-UnitFrame-TotemFrame" ring of
-- 30, a round sweep, the seconds below). The options make it square, put the
-- seconds on it, resize it, and free it to be dragged anywhere. The seconds
-- turn red, and the icon flashes, while the warning is on. The icon goes when
-- the trap runs out or springs.
local _, ns = ...
local L = ns.L

local Display = {}
ns.Display = Display

local PLACEHOLDER_ICON = "Interface\\Icons\\Spell_Frost_ChainsOfIce"
local TOTEM_SIZE = 37
local ROUND_ICON = 22 / TOTEM_SIZE
local ROUND_RING = 30 / TOTEM_SIZE
-- Where Blizzard puts a lone totem. TotemFrame's own anchor is overridden: it
-- is laid out in PlayerBottomManagedFrameContainer, whose top center sits 30
-- pixels right of the player frame's bottom center and 25 up (PlayerFrame.xml
-- and PlayerFrame.lua), in a 160 pixel row (PlayerFrameTemplates.xml) that
-- lays its children out from the left: "align center" only centers them
-- vertically (HorizontalLayoutMixin in LayoutFrame.lua). TotemFrame then pads
-- its button 15 pixels from its left and 2 up (TotemFrame.xml). So the
-- button's top left is 30 - 80 + 15 = 35 pixels left of that point, 27 up,
-- and its center 16.5 left and 8.5 up. (A first reading that took the row as
-- centered put the icon near the middle; the user saw totems sit further
-- left. Screenshots side by side, 2026-10-05, then matched the ring's top left
-- edge to the pixel.) The icon is anchored by its center there, so that any
-- size stays centered where a totem is. A hunter's pet frame, though, sits
-- right there, its round portrait into the icon; between it and the player's
-- portrait there is no room for a totem's icon (screenshots, 2026-10-06). So
-- the icon goes 30 pixels left and 6.5 down from the totem's place: under the
-- player's portrait, some 10 pixels right of the level circle and 5 below the
-- portrait's frame, clear of the pet frame (the user's choice, over stacking
-- it below the pet frame as Blizzard does with totems).
local PLAYER_X, PLAYER_Y = -16.5 - 30, 8.5 - 6.5
-- A totem's seconds: GameFontNormalSmall, gold from a minute up, white below
-- (AuraButtonMixin:UpdateDuration, BUFF_DURATION_WARNING_TIME).
local GOLD = { 1, 0.82, 0 }
local WHITE = { 1, 1, 1 }
local RED = { 1, 0.25, 0.25 }

local anchor  -- the frame the icon hangs from, dragged while unlocked
local mover   -- the green cover and hint shown while unlocked
local icon

local function UnderPlayerFrame()
    return ns.db.position == "player" and PlayerFrame ~= nil
end

-- A clock sweep over the icon; the lit part is the time left.
local function CreateSweep()
    local sweep = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    sweep:SetReverse(true)
    sweep:SetDrawEdge(false)
    sweep:SetDrawBling(false)
    sweep:SetHideCountdownNumbers(true)
    return sweep
end

local function CreateIcon()
    icon = CreateFrame("Frame", nil, anchor)
    icon:SetAllPoints()
    -- Square: a black edge around the icon.
    icon.edge = icon:CreateTexture(nil, "BACKGROUND")
    icon.edge:SetPoint("TOPLEFT", -2, 2)
    icon.edge:SetPoint("BOTTOMRIGHT", 2, -2)
    icon.edge:SetColorTexture(0, 0, 0, 1)
    icon.texture = icon:CreateTexture(nil, "ARTWORK")
    -- Round: the icon cut by a circle, in a totem's ring.
    icon.mask = icon:CreateMaskTexture()
    icon.mask:SetAtlas("CircleMask")
    icon.mask:SetAllPoints(icon.texture)
    icon.masked = false
    icon.ring = icon:CreateTexture(nil, "OVERLAY")
    icon.ring:SetAtlas("UI-HUD-UnitFrame-TotemFrame")

    -- A sweep for each shape: the round one is drawn with the circle, as
    -- Blizzard's totem buttons do (TotemFrame.lua).
    icon.squareSweep = CreateSweep()
    icon.squareSweep:SetAllPoints()
    icon.roundSweep = CreateSweep()
    icon.roundSweep:SetAllPoints(icon.texture)
    icon.roundSweep:SetSwipeColor(0, 0, 0, 0.65)
    local circle = C_Texture.GetAtlasInfo("CircleMask")
    if circle then
        icon.roundSweep:SetSwipeTexture(circle.file or circle.filename)
        icon.roundSweep:SetTexCoordRange({ x = circle.leftTexCoord, y = circle.topTexCoord },
            { x = circle.rightTexCoord, y = circle.bottomTexCoord })
    end

    -- The seconds sit above the sweep.
    local overlay = CreateFrame("Frame", nil, icon)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(icon.squareSweep:GetFrameLevel() + 2)
    icon.text = overlay:CreateFontString(nil, "OVERLAY")

    icon.flash = icon:CreateAnimationGroup()
    icon.flash:SetLooping("BOUNCE")
    local fade = icon.flash:CreateAnimation("Alpha")
    fade:SetFromAlpha(1)
    fade:SetToAlpha(0.3)
    fade:SetDuration(0.35)
end

-- Shapes the icon and places its seconds, from the settings.
local function Layout()
    local db, size = ns.db, ns.db.iconSize
    local round = db.shape == "round"
    local texture = icon.texture
    texture:ClearAllPoints()
    if round then
        texture:SetSize(size * ROUND_ICON, size * ROUND_ICON)
        texture:SetPoint("CENTER")
        texture:SetTexCoord(0, 1, 0, 1)
        icon.ring:ClearAllPoints()
        icon.ring:SetSize(size * ROUND_RING, size * ROUND_RING)
        icon.ring:SetPoint("CENTER", size / TOTEM_SIZE, -1.5 * size / TOTEM_SIZE)
    else
        texture:SetAllPoints()
        texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
    if round ~= icon.masked then
        if round then
            texture:AddMaskTexture(icon.mask)
        else
            texture:RemoveMaskTexture(icon.mask)
        end
        icon.masked = round
    end
    icon.ring:SetShown(round)
    icon.edge:SetShown(not round)
    local sweep, unused = icon.squareSweep, icon.roundSweep
    if round then
        sweep, unused = unused, sweep
    end
    unused:Clear()
    unused:Hide()
    sweep:Show()
    icon.sweep = sweep
    icon.entry = nil -- so that ShowTrap sets the sweep again

    local text = icon.text
    text:ClearAllPoints()
    if db.seconds == "below" then
        -- A totem's seconds overlap its button by 5 pixels, in its font, grown
        -- with the icon.
        text:SetPoint("TOP", icon, "BOTTOM", 0, round and 5 * size / TOTEM_SIZE or -2)
        text:SetFontObject(GameFontNormalSmall)
        local face, height, flags = GameFontNormalSmall:GetFont()
        text:SetFont(face, math.max(6, math.floor(height * size / TOTEM_SIZE + 0.5)), flags or "")
    else
        text:SetPoint("CENTER", texture, "CENTER")
        local face = round and size * ROUND_ICON * 0.6 or size * 0.42
        text:SetFont(STANDARD_TEXT_FONT, math.max(8, math.floor(face + 0.5)), "THICKOUTLINE")
    end
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

-- Below the icon, the seconds read as a totem's: "37 s", in the client's
-- language.
local function SecondsText(seconds)
    if ns.db.seconds == "below" then
        return (SECOND_ONELETTER_ABBR or L["%d s"]):format(seconds)
    end
    return seconds
end

-- armed: Traps.armed.
local function ShowTrap(armed)
    if icon.entry ~= armed then
        icon.entry = armed
        icon.texture:SetTexture(armed.icon or PLACEHOLDER_ICON)
        icon.sweep:SetCooldown(armed.start, armed.duration)
    end
    local left = math.max(0, armed.start + armed.duration - GetTime())
    local warning = ns.db.warnSeconds > 0 and left <= ns.db.warnSeconds
    local seconds = math.ceil(left)
    icon.text:SetText(SecondsText(seconds))
    if warning then
        SetColor(RED)
    elseif ns.db.seconds == "below" and seconds >= (BUFF_DURATION_WARNING_TIME or 60) then
        SetColor(GOLD)
    else
        SetColor(WHITE)
    end
    SetFlashing(warning and ns.db.warnFlash)
end

-- While unlocked with no trap down, the icon shows where it will be.
local function ShowPlaceholder()
    icon.entry = nil
    icon.texture:SetTexture(PLACEHOLDER_ICON)
    icon.sweep:Clear()
    icon.text:SetText(SecondsText(ns.Traps.ARMED_DURATION))
    SetColor(WHITE)
    SetFlashing(false)
end

-- The tooltip, as a totem's: the trap's name, its rank, and the time left,
-- in the client's words. While unlocked with no trap down, how to move it.
local function FillTooltip()
    local armed = ns.Traps.armed
    if armed then
        local plain = ns.Plain
        GameTooltip:SetText(plain(C_Spell.GetSpellName(armed.spellID)) or armed.trap.key, 1, 1, 1)
        local rank = plain(C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(armed.spellID))
        if rank and rank ~= "" then
            GameTooltip:AddLine(rank, 0.5, 0.5, 0.5)
        end
        local left = math.ceil(math.max(0, armed.start + armed.duration - GetTime()))
        GameTooltip:AddLine((SPELL_TIME_REMAINING_SEC or L["%d s"]):format(left), 1, 0.82, 0)
    else
        GameTooltip:SetText("Hunter Trap Timer", 1, 1, 1)
        GameTooltip:AddLine(L["Drag to move, then /htt lock"], 1, 0.82, 0)
    end
    GameTooltip:Show()
end

function Display.Refresh()
    if not anchor then
        return
    end
    -- Edit Mode may have resized the player frame since.
    if UnderPlayerFrame() and anchor:GetScale() ~= PlayerFrame:GetScale() then
        anchor:SetScale(PlayerFrame:GetScale())
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
    local shown = armed ~= nil or not ns.db.locked
    anchor:SetShown(shown)
    -- The tooltip counts down with the icon, and goes with it.
    if GameTooltip:IsOwned(anchor) then
        if shown then
            FillTooltip()
        else
            GameTooltip:Hide()
        end
    end
end

-- The warning starts: the flash is drawn by Refresh, the sound plays once.
function Display.Warn()
    if ns.db.warnSound then
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    end
end

-- Under the player frame, where a totem sits, or free on the screen. Under
-- it, the icon is drawn at the player frame's scale, as totems are, and it
-- follows the player frame when Edit Mode moves or resizes it.
local function Place()
    local db = ns.db
    anchor:ClearAllPoints()
    if UnderPlayerFrame() then
        anchor:SetScale(PlayerFrame:GetScale())
        anchor:SetPoint("CENTER", PlayerFrame, "BOTTOM", PLAYER_X, PLAYER_Y)
    else
        anchor:SetScale(1)
        anchor:SetPoint("CENTER", UIParent, "CENTER", db.x, db.y)
    end
end

-- Dragged by hand, the icon is free where it was left. Its center is in its
-- own scale, the player frame's if it was under it.
local function SavePosition()
    local x, y = anchor:GetCenter()
    local centerX, centerY = UIParent:GetCenter()
    local scale = anchor:GetEffectiveScale() / UIParent:GetEffectiveScale()
    ns.db.position = "free"
    ns.db.x = math.floor(x * scale - centerX + 0.5)
    ns.db.y = math.floor(y * scale - centerY + 0.5)
    ns.SettingsChanged()
    ns.Options.Refresh()
end

function Display.ApplySettings()
    if not anchor then
        return
    end
    local db = ns.db
    Place()
    anchor:SetSize(db.iconSize, db.iconSize)
    -- The mouse brings the tooltip up but clicks go through, unless unlocked
    -- to be dragged.
    anchor:SetMouseMotionEnabled(true)
    anchor:SetMouseClickEnabled(not db.locked)
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
        -- The position is the addon's to keep, not the client's layout cache.
        self:SetUserPlaced(false)
        SavePosition()
    end)
    anchor:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        FillTooltip()
    end)
    anchor:SetScript("OnLeave", function()
        GameTooltip:Hide()
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
