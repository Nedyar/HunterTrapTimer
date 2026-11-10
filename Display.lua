-- Display.lua: an icon for each armed trap, with a clock sweep and the
-- seconds left.
--
-- By default it looks and sits like a shaman's totem (Blizzard's
-- TotemFrame.xml for WoW Forever: a 37 pixel button holding the icon, 22
-- pixels and cut by "CircleMask", in the "UI-HUD-UnitFrame-TotemFrame" ring of
-- 30, a round sweep, the seconds below). The options make it square, put the
-- seconds on it, resize it, and free it to be dragged anywhere. The seconds
-- turn red, and the icon flashes, while the warning is on. The icon goes when
-- the trap runs out or springs.
--
-- A fire trap and a frost trap can be down at once, each with its icon: the
-- fire trap's first, as the fire totem's slot comes first, and the frost
-- trap's to its left, as far apart as totems in their row, which puts it
-- right under the level circle. A lone trap's icon always takes the first
-- place. (A column, the first try, the user swapped for this row:
-- screenshot, 2026-11-10.)
local _, ns = ...
local L = ns.L

local Display = {}
ns.Display = Display

-- While unlocked, the empty places show these.
local PLACEHOLDER_ICONS = {
    fire = "Interface\\Icons\\Spell_Fire_FlameShock",
    frost = "Interface\\Icons\\Spell_Frost_ChainsOfIce",
}
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
-- player's portrait, some 10 pixels right of the level circle, clear of the
-- pet frame (the user's choice, over stacking it below the pet frame as
-- Blizzard does with totems). And 8 more down, so that the second icon, under
-- the level circle, clears it: at the first height the circle's ring came 2
-- pixels into the place of that icon's (screenshot, 2026-11-10).
local PLAYER_X, PLAYER_Y = -16.5 - 30, 8.5 - 6.5 - 8
-- A totem's seconds: GameFontNormalSmall, gold from a minute up, white below
-- (AuraButtonMixin:UpdateDuration, BUFF_DURATION_WARNING_TIME).
local GOLD = { 1, 0.82, 0 }
local WHITE = { 1, 1, 1 }
local RED = { 1, 0.25, 0.25 }

local anchor  -- where the first icon sits; any icon drags it while unlocked
local mover   -- the green cover and hint shown while unlocked
local icons = {} -- one for each slot of Traps.SLOTS, in its order

local function UnderPlayerFrame()
    return ns.db.position == "player" and PlayerFrame ~= nil
end

-- The tooltip, as a totem's: the trap's name, its rank, and the time left,
-- in the client's words. While unlocked with no trap down, how to move it.
local function FillTooltip(icon)
    local entry = ns.Traps.armed[icon.slot]
    if entry then
        local plain = ns.Plain
        GameTooltip:SetText(plain(C_Spell.GetSpellName(entry.spellID)) or entry.trap.key, 1, 1, 1)
        local rank = plain(C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(entry.spellID))
        if rank and rank ~= "" then
            GameTooltip:AddLine(rank, 0.5, 0.5, 0.5)
        end
        local left = math.ceil(math.max(0, entry.start + entry.duration - GetTime()))
        GameTooltip:AddLine((SPELL_TIME_REMAINING_SEC or L["%d s"]):format(left), 1, 0.82, 0)
    else
        GameTooltip:SetText("Hunter Trap Timer", 1, 1, 1)
        GameTooltip:AddLine(L["Drag to move, then /htt lock"], 1, 0.82, 0)
    end
    GameTooltip:Show()
end

-- Dragged by hand, the icons are free where they were left. The first one's
-- center is in its own scale, the player frame's if it was under it.
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

-- A clock sweep over the icon; the lit part is the time left.
local function CreateSweep(icon)
    local sweep = CreateFrame("Cooldown", nil, icon, "CooldownFrameTemplate")
    sweep:SetReverse(true)
    sweep:SetDrawEdge(false)
    sweep:SetDrawBling(false)
    sweep:SetHideCountdownNumbers(true)
    return sweep
end

local function CreateIcon(slot)
    local icon = CreateFrame("Frame", nil, anchor)
    icon.slot = slot
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
    icon.squareSweep = CreateSweep(icon)
    icon.squareSweep:SetAllPoints()
    icon.roundSweep = CreateSweep(icon)
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

    -- Each icon brings up its own tooltip, and drags them all while unlocked.
    icon:RegisterForDrag("LeftButton")
    icon:SetScript("OnDragStart", function()
        if not ns.db.locked then
            anchor.dragging = true
            anchor:StartMoving()
        end
    end)
    icon:SetScript("OnDragStop", function()
        if anchor.dragging then
            anchor.dragging = nil
            anchor:StopMovingOrSizing()
            -- The position is the addon's to keep, not the client's layout cache.
            anchor:SetUserPlaced(false)
            SavePosition()
        end
    end)
    icon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
        FillTooltip(self)
    end)
    icon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    return icon
end

-- Shapes an icon and places its seconds, from the settings.
local function Layout(icon)
    local db, size = ns.db, ns.db.iconSize
    local round = db.shape == "round"
    icon:SetSize(size, size)
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
    icon.row = nil   -- so that Refresh places it again

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

-- How far left of the first icon the second one is. Round, as far as totems
-- are apart in their row; square, its edge, which sticks out 2 pixels, some
-- pixels clear of the first one's. The seconds below are narrower than the
-- icon, so they change nothing.
local function ColumnStep()
    local size = ns.db.iconSize
    if ns.db.shape == "round" then
        return size
    end
    return size + 4 * size / TOTEM_SIZE + 4
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
end

-- Below the icon, the seconds read as a totem's: "37 s", in the client's
-- language.
local function SecondsText(seconds)
    if ns.db.seconds == "below" then
        return (SECOND_ONELETTER_ABBR or L["%d s"]):format(seconds)
    end
    return seconds
end

-- entry: Traps.armed[icon.slot].
local function ShowTrap(icon, entry)
    if icon.entry ~= entry then
        icon.entry = entry
        icon.texture:SetTexture(entry.icon or PLACEHOLDER_ICONS[icon.slot])
        icon.sweep:SetCooldown(entry.start, entry.duration)
    end
    local left = math.max(0, entry.start + entry.duration - GetTime())
    local warning = ns.db.warnSeconds > 0 and left <= ns.db.warnSeconds
    local seconds = math.ceil(left)
    icon.text:SetText(SecondsText(seconds))
    if warning then
        SetColor(icon, RED)
    elseif ns.db.seconds == "below" and seconds >= (BUFF_DURATION_WARNING_TIME or 60) then
        SetColor(icon, GOLD)
    else
        SetColor(icon, WHITE)
    end
    SetFlashing(icon, warning and ns.db.warnFlash)
end

-- While unlocked, an empty place shows where its trap will be.
local function ShowPlaceholder(icon)
    icon.entry = nil
    icon.texture:SetTexture(PLACEHOLDER_ICONS[icon.slot])
    icon.sweep:Clear()
    icon.text:SetText(SecondsText(ns.Traps.ARMED_DURATION))
    SetColor(icon, WHITE)
    SetFlashing(icon, false)
end

function Display.Refresh()
    if not anchor then
        return
    end
    -- Edit Mode may have resized the player frame since.
    if UnderPlayerFrame() and anchor:GetScale() ~= PlayerFrame:GetScale() then
        anchor:SetScale(PlayerFrame:GetScale())
    end
    local locked, row = ns.db.locked, 0
    for _, icon in ipairs(icons) do
        local entry = ns.Traps.armed[icon.slot]
        if entry then
            ShowTrap(icon, entry)
        elseif not locked then
            ShowPlaceholder(icon)
        else
            icon.entry = nil
            SetFlashing(icon, false)
        end
        local shown = entry ~= nil or not locked
        if shown then
            row = row + 1
            if icon.row ~= row then
                icon.row = row
                icon:ClearAllPoints()
                icon:SetPoint("CENTER", anchor, "CENTER", -(row - 1) * ColumnStep(), 0)
            end
        end
        icon:SetShown(shown)
        -- The tooltip counts down with the icon, and goes with it.
        if GameTooltip:IsOwned(icon) then
            if shown then
                FillTooltip(icon)
            else
                GameTooltip:Hide()
            end
        end
    end
    mover:SetShown(not locked)
    anchor:SetShown(row > 0)
end

-- A warning starts: the flash is drawn by Refresh, the sound plays once.
function Display.Warn()
    if ns.db.warnSound then
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    end
end

-- Under the player frame, where a totem sits, or free on the screen. Under
-- it, the icons are drawn at the player frame's scale, as totems are, and
-- they follow the player frame when Edit Mode moves or resizes it.
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

function Display.ApplySettings()
    if not anchor then
        return
    end
    local db = ns.db
    Place()
    anchor:SetSize(db.iconSize, db.iconSize)
    for _, icon in ipairs(icons) do
        -- The mouse brings the tooltip up but clicks go through, unless
        -- unlocked to be dragged.
        icon:SetMouseMotionEnabled(true)
        icon:SetMouseClickEnabled(not db.locked)
        Layout(icon)
    end
    -- The whole row stays on the screen, not only the first place.
    anchor:SetClampRectInsets(-(#icons - 1) * ColumnStep(), 0, 0, 0)
    Display.Refresh()
end

function Display.Init()
    anchor = CreateFrame("Frame", "HunterTrapTimerFrame", UIParent)
    anchor:SetMovable(true)
    anchor:SetClampedToScreen(true)
    for index, slot in ipairs(ns.Traps.SLOTS) do
        icons[index] = CreateIcon(slot)
    end

    -- Unlocked, every place shows, so the cover spans them all, from the last
    -- one, leftmost, to the first.
    mover = CreateFrame("Frame", nil, anchor)
    mover:SetPoint("TOPLEFT", icons[#icons], "TOPLEFT")
    mover:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT")
    mover:SetFrameLevel(anchor:GetFrameLevel() + 20)
    local cover = mover:CreateTexture(nil, "OVERLAY")
    cover:SetAllPoints()
    cover:SetColorTexture(0.2, 0.8, 0.2, 0.35)
    local hint = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOM", mover, "TOP", 0, 6)
    hint:SetText(L["Drag to move, then /htt lock"])

    Display.ApplySettings()
end
