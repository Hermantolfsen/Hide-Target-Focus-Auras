local addonName = ...
local frame = CreateFrame("Frame")

-- Default settings
HTFA_Settings = HTFA_Settings or {
    enabled = true
}

local function ApplySettings()
    if not HTFA_Settings.enabled then return end

    if TargetFrame then
        TargetFrame.maxBuffs = 0
        TargetFrame.maxDebuffs = 0

        if TargetFrame_UpdateAuras then
            TargetFrame_UpdateAuras(TargetFrame)
        end
    end

    if FocusFrame then
        FocusFrame.maxBuffs = 0
        FocusFrame.maxDebuffs = 0

        if TargetFrame_UpdateAuras then
            TargetFrame_UpdateAuras(FocusFrame)
        end
    end
end

-- Events
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_TARGET_CHANGED")
frame:RegisterEvent("PLAYER_FOCUS_CHANGED")

frame:SetScript("OnEvent", ApplySettings)

-- Slash command
SLASH_HTFA1 = "/htfa"
SlashCmdList["HTFA"] = function(msg)
    msg = msg:lower()

    if msg == "on" then
        HTFA_Settings.enabled = true
        print("|cff00ff00HTFA: Enabled|r")
        ApplySettings()

    elseif msg == "off" then
        HTFA_Settings.enabled = false
        print("|cffff0000HTFA: Disabled (reload to restore frames)|r")

    else
        print("|cffffff00HTFA Commands:|r")
        print("/htfa on  - Enable")
        print("/htfa off - Disable")
    end
end