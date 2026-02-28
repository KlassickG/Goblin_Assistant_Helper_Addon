local ADDON_NAME = "GoblinAssistantHelper"
local db

local NEUTRAL_AH_SUBZONES = {
    ["Booty Bay"] = true,
    ["Gadgetzan"] = true,
    ["Everlook"]  = true,
}

StaticPopupDialogs["GOBLINASSISTANT_RELOAD"] = {
    text = "|cff00ff00[Goblin Assistant]|r Scan complete!\n%s\nReload UI to submit scanned prices?",
    button1 = "Reload UI",
    button2 = "Not Now",
    OnAccept = function() ReloadUI() end,
    timeout = 30,
    whileDead = false,
    hideOnEscape = true,
    showAlert = false,
}

local currentAHType = nil
local frame  -- forward declaration so the callback closure can reference it

local function detectAHType()
    local subzone = GetSubZoneText() or ""
    if NEUTRAL_AH_SUBZONES[subzone] then return "Neutral" end
    local faction = UnitFactionGroup("player")
    if faction == "Alliance" then return "Alliance" end
    if faction == "Horde" then return "Horde" end
    return "Unknown"
end


local auctionatorRegistered = false
local origAddMessage = nil
local debugMode = false

local function onFullScanConfirmed()
    local ok, err = pcall(function()
        if not db then return end
        local realm   = GetRealmName() or "Unknown"
        local faction = UnitFactionGroup("player") or "Unknown"
        local ahType  = currentAHType or detectAHType()
        db.lastScanRealm   = realm
        db.lastScanFaction = faction
        db.lastScanAHType  = ahType
        db.lastScanTime    = time()
        local label = realm .. " - " .. ahType .. " AH"
        StaticPopup_Show("GOBLINASSISTANT_RELOAD", label)
    end)
    if not ok then
        print("|cffff4444[Goblin Assistant]|r Callback error: " .. tostring(err))
    end
end

local function stripColorCodes(msg)
    return msg:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
end

local function hookChat()
    if origAddMessage then return end  -- already hooked
    origAddMessage = DEFAULT_CHAT_FRAME.AddMessage
    DEFAULT_CHAT_FRAME.AddMessage = function(self, msg, ...)
        origAddMessage(self, msg, ...)
        if msg then
            local plain = stripColorCodes(msg)
            if debugMode then
                origAddMessage(self, "|cffffff00[GAH DEBUG]|r " .. plain)
            end
            if plain:find("Auctionator") and plain:find("Finished processing") then
                onFullScanConfirmed()
            end
        end
    end
end

local function unhookChat()
    if origAddMessage then
        DEFAULT_CHAT_FRAME.AddMessage = origAddMessage
        origAddMessage = nil
    end
end

local function registerWithAuctionator()
    -- intentionally empty: full scan detection is done via chat hook only,
    -- because RegisterForDBUpdate fires for individual searches too.
end

frame = CreateFrame("Frame", ADDON_NAME .. "Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("AUCTION_HOUSE_SHOW")
frame:RegisterEvent("AUCTION_HOUSE_CLOSED")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON_NAME then
            GoblinAssistantHelperDB = GoblinAssistantHelperDB or {}
            db = GoblinAssistantHelperDB
            -- Attempt now; works if Auctionator loaded first via OptionalDeps.
            registerWithAuctionator()
        elseif name == "Auctionator" then
            -- Fallback: Auctionator finished loading after us.
            registerWithAuctionator()
        end
    elseif event == "AUCTION_HOUSE_SHOW" then
        currentAHType = detectAHType()
        hookChat()
    elseif event == "AUCTION_HOUSE_CLOSED" then
        currentAHType = nil
        unhookChat()
    end
end)

SLASH_GOBLINASSISTANT1 = "/gah"
SlashCmdList["GOBLINASSISTANT"] = function(msg)
    local cmd = msg and msg:lower():match("^%s*(%S+)") or ""
    if cmd == "debug" then
        debugMode = not debugMode
        print("|cff00ff00[Goblin Assistant]|r Debug mode: " .. (debugMode and "|cff00ff00ON|r (open AH to start logging)" or "|cffff4444OFF|r"))
    elseif cmd == "test" then
        print("|cff00ff00[Goblin Assistant]|r Testing popup...")
        onFullScanConfirmed()
    elseif db and db.lastScanRealm then
        print("|cff00ff00[Goblin Assistant]|r Last scan: " .. db.lastScanRealm .. " | " .. (db.lastScanAHType or "?") .. " AH | " .. (db.lastScanFaction or "?"))
    else
        print("|cff00ff00[Goblin Assistant]|r No scan captured yet this session. Commands: /gah debug, /gah test")
    end
end
