local frame = CreateFrame("Frame")

local DEFAULT_MAX_BUFFS = 32
local DEFAULT_MAX_DEBUFFS = 32

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff98HTFA:|r " .. msg)
end

local function EnsureSettings()
    if type(HTFA_Settings) ~= "table" then
        HTFA_Settings = {}
    end

    -- Migration from old v1.0.0 format
    if HTFA_Settings.enabled ~= nil then
        local enabled = HTFA_Settings.enabled

        if enabled then
            -- old addon enabled = hide everything
            HTFA_Settings.target = {
                buffs = false,
                debuffs = false,
            }
            HTFA_Settings.focus = {
                buffs = false,
                debuffs = false,
            }
        else
            -- old addon disabled = show everything
            HTFA_Settings.target = {
                buffs = true,
                debuffs = true,
            }
            HTFA_Settings.focus = {
                buffs = true,
                debuffs = true,
            }
        end

        HTFA_Settings.enabled = nil
    end

    if type(HTFA_Settings.target) ~= "table" then
        HTFA_Settings.target = {}
    end

    if type(HTFA_Settings.focus) ~= "table" then
        HTFA_Settings.focus = {}
    end

    if HTFA_Settings.target.buffs == nil then
        HTFA_Settings.target.buffs = false
    end
    if HTFA_Settings.target.debuffs == nil then
        HTFA_Settings.target.debuffs = false
    end
    if HTFA_Settings.focus.buffs == nil then
        HTFA_Settings.focus.buffs = false
    end
    if HTFA_Settings.focus.debuffs == nil then
        HTFA_Settings.focus.debuffs = false
    end
end

local function ApplyFrameSettings(unitFrame, settings)
    if not unitFrame or not settings then
        return
    end

    unitFrame.maxBuffs = settings.buffs and DEFAULT_MAX_BUFFS or 0
    unitFrame.maxDebuffs = settings.debuffs and DEFAULT_MAX_DEBUFFS or 0

    if TargetFrame_UpdateAuras then
        TargetFrame_UpdateAuras(unitFrame)
    end
end

local function ApplySettings()
    EnsureSettings()

    if TargetFrame then
        ApplyFrameSettings(TargetFrame, HTFA_Settings.target)
    end

    if FocusFrame then
        ApplyFrameSettings(FocusFrame, HTFA_Settings.focus)
    end
end

local function OnOff(value)
    if value then
        return "|cff00ff00ON|r"
    else
        return "|cffff0000OFF|r"
    end
end

local function PrintStatus()
    EnsureSettings()
    Print("Target buffs: " .. OnOff(HTFA_Settings.target.buffs))
    Print("Target debuffs: " .. OnOff(HTFA_Settings.target.debuffs))
    Print("Focus buffs: " .. OnOff(HTFA_Settings.focus.buffs))
    Print("Focus debuffs: " .. OnOff(HTFA_Settings.focus.debuffs))
end

local function PrintUsage()
    Print("Usage:")
    Print("/htfa status")
    Print("/htfa target buff on")
    Print("/htfa target buff off")
    Print("/htfa target debuff on")
    Print("/htfa target debuff off")
    Print("/htfa focus buff on")
    Print("/htfa focus buff off")
    Print("/htfa focus debuff on")
    Print("/htfa focus debuff off")
end

local function SetOption(frameKey, auraKey, state)
    EnsureSettings()

    HTFA_Settings[frameKey][auraKey] = state
    ApplySettings()

    Print(frameKey .. " " .. auraKey .. " -> " .. (state and "ON" or "OFF"))
end

local function CreateCheckbox(parent, label, description, x, y, getValue, setValue)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", x, y)

    if checkbox.Text then
        checkbox.Text:SetText(label)
    elseif _G[checkbox:GetName() .. "Text"] then
        _G[checkbox:GetName() .. "Text"]:SetText(label)
    end

    checkbox.tooltipText = label
    checkbox.tooltipRequirement = description

    checkbox:SetScript("OnClick", function(self)
        setValue(self:GetChecked() and true or false)
        ApplySettings()
    end)

    checkbox:SetScript("OnShow", function(self)
        self:SetChecked(getValue())
    end)

    return checkbox
end

local function CreateOptionsContent(parent)
    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Hide Target & Focus Auras")

    local subtitle = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetWidth(520)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetText("Choose which buffs and debuffs should be shown on the default Blizzard target and focus frames.")

    local targetHeader = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    targetHeader:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -20)
    targetHeader:SetText("Target Frame")

    CreateCheckbox(
        parent,
        "Show Target Buffs",
        "Enable buffs on the target frame.",
        20, -90,
        function()
            EnsureSettings()
            return HTFA_Settings.target.buffs
        end,
        function(value)
            HTFA_Settings.target.buffs = value
        end
    )

    CreateCheckbox(
        parent,
        "Show Target Debuffs",
        "Enable debuffs on the target frame.",
        20, -120,
        function()
            EnsureSettings()
            return HTFA_Settings.target.debuffs
        end,
        function(value)
            HTFA_Settings.target.debuffs = value
        end
    )

    local focusHeader = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    focusHeader:SetPoint("TOPLEFT", targetHeader, "BOTTOMLEFT", 0, -85)
    focusHeader:SetText("Focus Frame")

    CreateCheckbox(
        parent,
        "Show Focus Buffs",
        "Enable buffs on the focus frame.",
        20, -200,
        function()
            EnsureSettings()
            return HTFA_Settings.focus.buffs
        end,
        function(value)
            HTFA_Settings.focus.buffs = value
        end
    )

    CreateCheckbox(
        parent,
        "Show Focus Debuffs",
        "Enable debuffs on the focus frame.",
        20, -230,
        function()
            EnsureSettings()
            return HTFA_Settings.focus.debuffs
        end,
        function(value)
            HTFA_Settings.focus.debuffs = value
        end
    )

    local help = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", focusHeader, "BOTTOMLEFT", 0, -85)
    help:SetWidth(520)
    help:SetJustifyH("LEFT")
    help:SetText("Slash commands: /htfa status, /htfa target buff on/off, /htfa target debuff on/off, /htfa focus buff on/off, /htfa focus debuff on/off")
end

local function CreateOptionsPanel()
    -- Newer Settings API
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local panel = CreateFrame("Frame")
        CreateOptionsContent(panel)

        local category = Settings.RegisterCanvasLayoutCategory(panel, "Hide Target & Focus Auras")
        category.ID = "Hide Target & Focus Auras"
        Settings.RegisterAddOnCategory(category)
        return
    end

    -- Older Interface Options API fallback
    local panel = CreateFrame("Frame")
    panel.name = "Hide Target & Focus Auras"

    CreateOptionsContent(panel)

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")

frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        EnsureSettings()
        CreateOptionsPanel()
    end

    ApplySettings()
end)

SLASH_HTFA1 = "/htfa"
SlashCmdList["HTFA"] = function(msg)
    msg = tostring(msg or "")
    msg = msg:lower()
    msg = msg:gsub("^%s+", "")
    msg = msg:gsub("%s+$", "")

    if msg == "" or msg == "help" then
        PrintUsage()
        return
    end

    if msg == "status" then
        PrintStatus()
        return
    end

    local frameKey, auraType, state = msg:match("^(%S+)%s+(%S+)%s+(%S+)$")

    if not frameKey or not auraType or not state then
        Print("Invalid command.")
        PrintUsage()
        return
    end

    if frameKey ~= "target" and frameKey ~= "focus" then
        Print("Frame must be 'target' or 'focus'.")
        return
    end

    local auraKey
    if auraType == "buff" then
        auraKey = "buffs"
    elseif auraType == "debuff" then
        auraKey = "debuffs"
    else
        Print("Aura type must be 'buff' or 'debuff'.")
        return
    end

    local enabled
    if state == "on" then
        enabled = true
    elseif state == "off" then
        enabled = false
    else
        Print("State must be 'on' or 'off'.")
        return
    end

    SetOption(frameKey, auraKey, enabled)
end
