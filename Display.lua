-- Display.lua: an icon for each armed trap, with a clock sweep and the
-- seconds left.
--
-- By default it looks and sits like a shaman's totem (Blizzard's
-- TotemFrame.xml for WoW Forever: a 37 pixel button holding the icon, 22
-- pixels and cut by "CircleMask", in the "UI-HUD-UnitFrame-TotemFrame" ring of
-- 30, a round sweep, the seconds below). The options make it square, put the
-- seconds on it, resize it, and free it to be dragged anywhere. The seconds
-- turn red, and the icon flashes, while the warning is on. The icon goes when
-- the trap runs out; one that springs shows its effect's icon and time while
-- it lasts (Traps.effects), the seconds in ice blue for a freeze or Frost
-- Trap's ice, in orange for a burn or Explosive Trap's fire. The warning's
-- sound, and the one as an effect ends, are each trap's own (ns.db.sounds).
--
-- The icons make a row, from the first place leftwards, as far apart as
-- totems in their row (the second right under the level circle): first the
-- traps down, the fire trap's then the frost trap's, as the fire totem's
-- slot comes first, then the effects that last, oldest first. So the row
-- grows as it needs to: a trap down and its school's effects show side by
-- side, two effects of one trap too (the user, 2026-11-17: a Frost Trap's
-- ice, a fire trap and a new frost trap down make three icons). A lone
-- icon always takes the first place. (A column, the first try, the user
-- swapped for this row: screenshot, 2026-11-10.)
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
local ICE = { 0.5, 0.8, 1 }
local FIRE = { 1, 0.55, 0.2 }
-- An effect's seconds, and the line its tooltip adds.
local EFFECT_COLORS = { freeze = ICE, burn = FIRE, flames = FIRE, ice = ICE }
local function EffectLine(kind)
    if kind == "freeze" then
        return L["Enemy frozen"]
    elseif kind == "burn" then
        return L["Burning"]
    elseif kind == "flames" then
        return L["Fire on the ground"]
    end
    return L["Ice on the ground"]
end

-- The whole seconds shown for left: a trap's rounded up, as Blizzard's
-- totems' (TotemFrame.lua); an effect's down, as the game's aura tooltips,
-- which the user compares them with (screenshots, 2026-11-17: rounded up,
-- the freeze read one second more than the enemy's aura).
local function ShownSeconds(entry, left)
    return entry.kind and math.floor(left) or math.ceil(left)
end

local anchor  -- where the first icon sits; any icon drags it while unlocked
local mover   -- the green cover and hint shown while unlocked
local icons = {} -- made as the row needs them: icons[i] shows its i-th place
local shownCount -- how many places the row shows

local function UnderPlayerFrame()
    return ns.db.position == "player" and PlayerFrame ~= nil
end

-- The tooltip, as a totem's: the trap's name, its rank, and the time left,
-- in the client's words; an effect's says what it is. While unlocked, an
-- empty place's, how to move them.
local function FillTooltip(icon)
    local entry = icon.entry
    if entry then
        local plain = ns.Plain
        GameTooltip:SetText(plain(C_Spell.GetSpellName(entry.spellID)) or entry.trap.key, 1, 1, 1)
        local rank = plain(C_Spell.GetSpellSubtext and C_Spell.GetSpellSubtext(entry.spellID))
        if rank and rank ~= "" then
            GameTooltip:AddLine(rank, 0.5, 0.5, 0.5)
        end
        if entry.kind then
            local color = EFFECT_COLORS[entry.kind]
            GameTooltip:AddLine(EffectLine(entry.kind), color[1], color[2], color[3])
        end
        local left = ShownSeconds(entry, math.max(0, entry.start + entry.duration - GetTime()))
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

-- An icon; slot, the school of what it shows, is set as it shows it.
local function CreateIcon()
    local icon = CreateFrame("Frame", nil, anchor)
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

-- entry: a trap down or an effect.
local function ShowTrap(icon, entry)
    if icon.entry ~= entry then
        icon.entry = entry
        icon.texture:SetTexture(entry.icon or PLACEHOLDER_ICONS[icon.slot])
        icon.sweep:SetCooldown(entry.start, entry.duration)
    end
    local left = math.max(0, entry.start + entry.duration - GetTime())
    local warning = not entry.kind and ns.db.warnSeconds > 0 and left <= ns.db.warnSeconds
    local seconds = ShownSeconds(entry, left)
    icon.text:SetText(SecondsText(seconds))
    if entry.kind then
        SetColor(icon, EFFECT_COLORS[entry.kind])
    elseif warning then
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

-- The row's places, in order: { slot, entry }. The traps down, the fire
-- trap's first; while unlocked, a trap's place shows even with none down.
-- Then, when shown, the effects that last, oldest first.
local function Places()
    local places = {}
    for _, slot in ipairs(ns.Traps.SLOTS) do
        local entry = ns.Traps.armed[slot]
        if entry or not ns.db.locked then
            places[#places + 1] = { slot = slot, entry = entry }
        end
    end
    if ns.db.showEffects then
        for _, effect in ipairs(ns.Traps.effects) do
            places[#places + 1] = { slot = effect.trap.slot, entry = effect }
        end
    end
    return places
end

-- The mouse brings an icon's tooltip up but clicks go through, unless
-- unlocked to be dragged.
local function ApplyIconSettings(icon)
    icon:SetMouseMotionEnabled(true)
    icon:SetMouseClickEnabled(not ns.db.locked)
    Layout(icon)
end

-- The icon of the row's index-th place, made when first needed.
local function GetIcon(index)
    if not icons[index] then
        icons[index] = CreateIcon()
        ApplyIconSettings(icons[index])
    end
    return icons[index]
end

function Display.Refresh()
    if not anchor then
        return
    end
    -- Edit Mode may have resized the player frame since.
    if UnderPlayerFrame() and anchor:GetScale() ~= PlayerFrame:GetScale() then
        anchor:SetScale(PlayerFrame:GetScale())
    end
    local places = Places()
    for index, place in ipairs(places) do
        local icon = GetIcon(index)
        icon.slot = place.slot
        if place.entry then
            ShowTrap(icon, place.entry)
        else
            ShowPlaceholder(icon)
        end
        if icon.row ~= index then
            icon.row = index
            icon:ClearAllPoints()
            icon:SetPoint("CENTER", anchor, "CENTER", -(index - 1) * ColumnStep(), 0)
        end
        icon:Show()
        -- The tooltip counts down with the icon.
        if GameTooltip:IsOwned(icon) then
            FillTooltip(icon)
        end
    end
    for index = #places + 1, #icons do
        local icon = icons[index]
        icon.entry = nil
        SetFlashing(icon, false)
        icon:Hide()
        -- ... and goes with it.
        if GameTooltip:IsOwned(icon) then
            GameTooltip:Hide()
        end
    end
    if shownCount ~= #places then
        shownCount = #places
        -- The whole row stays on the screen, not only the first place, and
        -- the unlocked cover spans it, from the last place, leftmost.
        local last = math.max(shownCount, 1)
        anchor:SetClampRectInsets(-(last - 1) * ColumnStep(), 0, 0, 0)
        mover:ClearAllPoints()
        mover:SetPoint("TOPLEFT", GetIcon(last), "TOPLEFT")
        mover:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT")
    end
    mover:SetShown(not ns.db.locked)
    anchor:SetShown(#places > 0)
end

-- entry's warning starts: the flash is drawn by Refresh, its trap's sound
-- plays once.
function Display.Warn(entry)
    ns.PlaySound(ns.db.sounds[entry.trap.key].warn)
end

-- A trap's effect ended, early or as its time was up: its trap's sound for
-- that.
function Display.EffectEnded(effect, early)
    local sounds = ns.db.sounds[effect.trap.key]
    ns.PlaySound(early and sounds.early or sounds.ended)
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
        ApplyIconSettings(icon)
    end
    -- The places are as far apart as the size makes them.
    shownCount = nil
    Display.Refresh()
end

function Display.Init()
    anchor = CreateFrame("Frame", "HunterTrapTimerFrame", UIParent)
    anchor:SetMovable(true)
    anchor:SetClampedToScreen(true)

    -- Unlocked, the cover spans the row (Refresh anchors it).
    mover = CreateFrame("Frame", nil, anchor)
    mover:SetFrameLevel(anchor:GetFrameLevel() + 20)
    local cover = mover:CreateTexture(nil, "OVERLAY")
    cover:SetAllPoints()
    cover:SetColorTexture(0.2, 0.8, 0.2, 0.35)
    local hint = mover:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    hint:SetPoint("BOTTOM", mover, "TOP", 0, 6)
    hint:SetText(L["Drag to move, then /htt lock"])

    Display.ApplySettings()
end
