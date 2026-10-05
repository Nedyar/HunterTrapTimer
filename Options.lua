-- Options.lua: the settings page under Options > AddOns > Hunter Trap Timer.
local _, ns = ...
local L = ns.L

local Options = {}
ns.Options = Options

local refreshers = {}   -- functions that copy the settings into the widgets
local category

function Options.Refresh()
    for _, refresh in ipairs(refreshers) do
        refresh()
    end
end

local function Set(key, value)
    ns.db[key] = value
    ns.SettingsChanged()
end

-- Buttons grow to fit their text, which is longer in some languages.
local function FitButton(button, minWidth)
    button:SetWidth(math.max(minWidth, math.ceil(button:GetFontString():GetStringWidth()) + 24))
end

local function SetTooltip(widget, title, text)
    widget:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(title, 1, 1, 1)
        if text then
            GameTooltip:AddLine(text, 1, 0.82, 0, true)
        end
        GameTooltip:Show()
    end)
    widget:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- Widgets ---------------------------------------------------------------------

local function CreateHeader(page, text, x, y, width)
    local label = page:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    local line = page:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(1, 1, 1, 0.15)
    line:SetSize(width, 1)
    line:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -4)
end

-- A checkbox bound to a boolean setting.
local function CreateOption(page, x, y, key, label, tooltip)
    local box = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
    box:SetSize(24, 24)
    box:SetPoint("TOPLEFT", x, y)
    box.Text:SetFontObject("GameFontHighlight")
    box.Text:SetText(label)
    -- Clicking the label toggles the box too.
    box:SetHitRectInsets(0, -(box.Text:GetStringWidth() + 4), 0, 0)
    box:SetScript("OnClick", function(self)
        Set(key, self:GetChecked() and true or false)
    end)
    if tooltip then
        SetTooltip(box, label, tooltip)
    end
    refreshers[#refreshers + 1] = function()
        box:SetChecked(ns.db[key])
    end
end

local function CreateSlider(page, x, y, width, key, label, format)
    local low, high, step = unpack(ns.LIMITS[key])
    local slider = CreateFrame("Slider", nil, page, "UISliderTemplateWithLabels")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetSize(width, 17)
    slider:SetMinMaxValues(low, high)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider.Low:SetText(format(low))
    slider.High:SetText(format(high))
    local function ShowValue(value)
        slider.Text:SetText(("%s: |cffffffff%s|r"):format(label, format(value)))
    end
    slider:SetScript("OnValueChanged", function(_, value, userInput)
        value = ns.Snap(value, low, high, step)
        ShowValue(value)
        if userInput and value ~= ns.db[key] then
            Set(key, value)
        end
    end)
    slider:EnableMouseWheel(true)
    slider:SetScript("OnMouseWheel", function(self, delta)
        local value = ns.Snap(ns.db[key] + delta * step, low, high, step)
        if value ~= ns.db[key] then
            self:SetValue(value)
            Set(key, value)
        end
    end)
    refreshers[#refreshers + 1] = function()
        slider:SetValue(ns.db[key])
        ShowValue(ns.db[key])
    end
end

-- A label followed by radio buttons on one line, bound to a setting.
local function CreateChoice(page, x, y, key, label, choices)
    local title = page:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    title:SetPoint("TOPLEFT", x, y)
    title:SetText(label)
    local buttons = {}
    local function Refresh()
        for _, button in ipairs(buttons) do
            button:SetChecked(ns.db[key] == button.value)
        end
    end
    for i, choice in ipairs(choices) do
        local button = CreateFrame("CheckButton", nil, page, "UIRadioButtonTemplate")
        if i == 1 then
            button:SetPoint("LEFT", title, "RIGHT", 10, 0)
        else
            button:SetPoint("LEFT", buttons[i - 1].text, "RIGHT", 14, 0)
        end
        button.text:SetFontObject("GameFontHighlightSmall")
        button.text:SetText(choice.text)
        button:SetHitRectInsets(0, -(button.text:GetStringWidth() + 5), 0, 0)
        button.value = choice.value
        button:SetScript("OnClick", function(self)
            Set(key, self.value)
            Refresh()
        end)
        if choice.tooltip then
            SetTooltip(button, choice.text, choice.tooltip)
        end
        buttons[i] = button
    end
    refreshers[#refreshers + 1] = Refresh
end

local function CreateButton(page, text, onClick)
    local button = CreateFrame("Button", nil, page, "UIPanelButtonTemplate")
    button:SetHeight(22)
    button:SetText(text)
    FitButton(button, 120)
    button:SetScript("OnClick", onClick)
    return button
end

local function Seconds(value)
    if value == 0 then
        return L["Off"]
    end
    return L["%d s"]:format(value)
end

-- The page ------------------------------------------------------------------

local function CreatePage()
    local page = CreateFrame("Frame")
    page:Hide()
    -- Called by the settings panel whenever it shows the page.
    function page:OnRefresh()
        Options.Refresh()
    end

    local heading = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    heading:SetPoint("TOPLEFT", 16, -16)
    heading:SetText("Hunter Trap Timer")
    local intro = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    intro:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -8)
    intro:SetWidth(620)
    intro:SetJustifyH("LEFT")
    intro:SetText(L["Shows how long your trap stays armed: 60 seconds, unless something steps on it. WoW Forever hides the combat log from addons, and enemy auras in combat, so a trap that springs is recognized by a new aura on an enemy that nothing else explains, such as a spell of yours, your pet's or your group's. In a group, an effect that comes without a spell, such as a poison, can now and then be taken for it."])

    CreateHeader(page, L["Icon"], 16, -110, 620)
    CreateOption(page, 16, -134, "locked", L["Lock the icon"],
        L["Unlocked, the icon stays on screen and can be dragged with the mouse."])
    -- The player frame's name is the client's own, as Edit Mode shows it.
    local playerFrame = HUD_EDIT_MODE_PLAYER_FRAME_LABEL or "Player Frame"
    CreateChoice(page, 20, -170, "position", L["Position"], {
        { value = "player", text = L["Under the %s"]:format(playerFrame),
            tooltip = L["Under your portrait, clear of your pet's frame. It follows the %s when Edit Mode moves it."]:format(playerFrame) },
        { value = "free", text = L["Free"],
            tooltip = L["Where you drag it while the icon is unlocked."] },
    })
    CreateChoice(page, 20, -196, "shape", L["Shape"], {
        { value = "round", text = L["Round, like a totem"] },
        { value = "square", text = L["Square"] },
    })
    CreateChoice(page, 20, -222, "seconds", L["Seconds"], {
        { value = "below", text = L["Below the icon"] },
        { value = "center", text = L["On the icon"] },
    })
    CreateSlider(page, 24, -262, 220, "iconSize", L["Icon size"], function(value)
        return ("%d"):format(value)
    end)
    local test = CreateButton(page, L["Test"], function()
        ns.Traps.Test()
    end)
    test:SetPoint("TOPLEFT", 20, -300)
    SetTooltip(test, L["Test"], L["Shows a trap that runs out in 15 seconds."])
    local center = CreateButton(page, L["Reset position"], function()
        ns.db.position, ns.db.x, ns.db.y = ns.DEFAULTS.position, ns.DEFAULTS.x, ns.DEFAULTS.y
        ns.SettingsChanged()
        Options.Refresh()
    end)
    center:SetPoint("LEFT", test, "RIGHT", 8, 0)

    CreateHeader(page, L["Warning before it runs out"], 16, -350, 620)
    CreateSlider(page, 24, -394, 220, "warnSeconds", L["Seconds left"], Seconds)
    CreateOption(page, 16, -432, "warnFlash", L["Flash the icon"])
    CreateOption(page, 16, -460, "warnSound", L["Play a sound"])

    return page
end

-- Setup -----------------------------------------------------------------------

function Options.Init()
    category = Settings.RegisterCanvasLayoutCategory(CreatePage(), "Hunter Trap Timer")
    Settings.RegisterAddOnCategory(category)
    Options.Refresh()
end

function Options.Open()
    -- Settings.OpenToCategory goes through a restricted call on this client, and
    -- the panel opens from an event, so success is checked a moment later.
    local ok = category and pcall(Settings.OpenToCategory, category:GetID())
    C_Timer.After(0.3, function()
        if not ok or not SettingsPanel:IsShown() then
            ns.Print(L["open the game menu, then Options > AddOns > Hunter Trap Timer."])
        end
    end)
end
