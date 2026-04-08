local frame = CreateFrame("Frame")

local function Print(msg)
    print("|cff00ff98HTFA:|r " .. msg)
end

local function EnsureSettings()
    if type(HTFA_Settings) ~= "table" then
        HTFA_Settings = {}
    end

    -- Migrate old v1.0.0 format
    if HTFA_Settings.enabled ~= nil then
        local enabled = HTFA_Settings.enabled

        if enabled then
            HTFA_Settings.target = {
                buffs = false,
                debuffs = false,
            }
            HTFA_Settings.focus = {
                buffs = false,
                debuffs = false,
            }
        else
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

local function OnOff(value)
    return value and "|cff00ff00ON|r" or "|cffff0000OFF|r"
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

local function HideAuraButton(button)
    if not button then return end
    button:SetAlpha(0)
    button:Hide()
end

local function ShowAuraButton(button)
    if not button then return end
    button:SetAlpha(1)
    button:Show()
end

local function ApplyPoolVisibility(pool, shouldShow)
    if not pool or type(pool.EnumerateActive) ~= "function" then
        return
    end

    for button in pool:EnumerateActive() do
        if shouldShow then
            ShowAuraButton(button)
        else
            HideAuraButton(button)
        end
    end
end

local function GetAuraDataForButton(unitFrame, button)
    if not button or not button.auraInstanceID or not unitFrame or not unitFrame.unit then
        return nil
    end

    if C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID then
        return C_UnitAuras.GetAuraDataByAuraInstanceID(unitFrame.unit, button.auraInstanceID)
    end

    return nil
end

local function ApplyMixedPool(unitFrame, pool)
    if not pool or type(pool.EnumerateActive) ~= "function" then
        return
    end

    local settings = HTFA_Settings.target
    if unitFrame == FocusFrame then
        settings = HTFA_Settings.focus
    end

    for button in pool:EnumerateActive() do
        local auraData = GetAuraDataForButton(unitFrame, button)
        local harmful = nil

        if auraData ~= nil and auraData.isHarmful ~= nil then
            harmful = auraData.isHarmful
        elseif button.isHarmfulAura ~= nil then
            harmful = button.isHarmfulAura
        end

        local shouldShow = true

        if harmful == true then
            shouldShow = settings.debuffs
        elseif harmful == false then
            shouldShow = settings.buffs
        else
            -- If we cannot classify it, default to showing it
            shouldShow = true
        end

        if shouldShow then
            ShowAuraButton(button)
        else
            HideAuraButton(button)
        end
    end
end

local function ApplyFrameAuras(unitFrame, settings)
    if not unitFrame or not settings then
        return
    end

    -- Preferred modern path: specific buff/debuff pools on auraPools
    if unitFrame.auraPools and type(unitFrame.auraPools.GetPool) == "function" then
        local buffPool = unitFrame.auraPools:GetPool("TargetBuffFrameTemplate")
        local debuffPool = unitFrame.auraPools:GetPool("TargetDebuffFrameTemplate")

        if buffPool or debuffPool then
            ApplyPoolVisibility(buffPool, settings.buffs)
            ApplyPoolVisibility(debuffPool, settings.debuffs)
            return
        end

        -- Fallback if Blizzard changes pool names and keeps one mixed pool system
        ApplyMixedPool(unitFrame, unitFrame.auraPools)
        return
    end

    -- Older / fallback containers
    if unitFrame.BuffFrame and unitFrame.BuffFrame.pool then
        ApplyPoolVisibility(unitFrame.BuffFrame.pool, settings.buffs)
    end

    if unitFrame.DebuffFrame and unitFrame.DebuffFrame.pool then
        ApplyPoolVisibility(unitFrame.DebuffFrame.pool, settings.debuffs)
    end
end

local function ApplyAllVisibleAuras()
    EnsureSettings()

    if TargetFrame then
        ApplyFrameAuras(TargetFrame, HTFA_Settings.target)
    end

    if FocusFrame then
        ApplyFrameAuras(FocusFrame, HTFA_Settings.focus)
    end
end

local function SetOption(frameKey, auraKey, state)
    EnsureSettings()
    HTFA_Settings[frameKey][auraKey] = state
    ApplyAllVisibleAuras()
    Print(frameKey .. " " .. auraKey .. " -> " .. (state and "ON" or "OFF"))
end

local function CreateCheckbox(parent, label, x, y, getValue, setValue)
    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", x, y)

    if checkbox.Text then
        checkbox.Text:SetText(label)
    end

    checkbox:SetScript("OnClick", function(self)
        setValue(self:GetChecked() and true or false)
        ApplyAllVisibleAuras()
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
    subtitle:SetText("Choose which buffs and debuffs are shown on the default Blizzard target and focus frames.")

    local targetHeader = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    targetHeader:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -20)
    targetHeader:SetText("Target Frame")

    CreateCheckbox(
        parent,
        "Show Target Buffs",
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
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local panel = CreateFrame("Frame")
        CreateOptionsContent(panel)

        local category = Settings.RegisterCanvasLayoutCategory(panel, "Hide Target & Focus Auras")
        Settings.RegisterAddOnCategory(category)
        return
    end

    local panel = CreateFrame("Frame")
    panel.name = "Hide Target & Focus Auras"
    CreateOptionsContent(panel)

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
end

local function HookFrame(frameToHook, settingsKey)
    if not frameToHook or frameToHook.HTFAHooked then
        return
    end

    frameToHook.HTFAHooked = true

    if type(frameToHook.UpdateAuras) == "function" then
        hooksecurefunc(frameToHook, "UpdateAuras", function(self)
            EnsureSettings()
            ApplyFrameAuras(self, HTFA_Settings[settingsKey])
        end)
    end
end

frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")

frame:SetScript("OnEvent", function(_, event)
    EnsureSettings()

    if event == "PLAYER_LOGIN" then
        CreateOptionsPanel()
    end

    if TargetFrame then
        HookFrame(TargetFrame, "target")
    end

    if FocusFrame then
        HookFrame(FocusFrame, "focus")
    end

    ApplyAllVisibleAuras()
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
