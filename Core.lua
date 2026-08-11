local addonName, addon = ...;

local Settings;

local DefaultValues = {
	Left = 0,
	Right = 0,
	Bottom = 0,
    Top = 0
}


-- Callback Registry
local CallbackRegistry = CreateFrame("Frame");
Mixin(CallbackRegistry, CallbackRegistryMixin);
CallbackRegistry:OnLoad();

local callbackEvents = {};
for key in pairs(DefaultValues) do
    tinsert(callbackEvents, "SettingChanged."..key);
end
CallbackRegistry:GenerateCallbackEvents(callbackEvents);

addon.CallbackRegistry = CallbackRegistry;

local function GetSetting(key)
	return NookSettings[key];
end
addon.GetSetting = GetSetting;

local function SetSetting(key, value, input)
    if Settings then
        Settings[key] = value;
        CallbackRegistry:TriggerEvent("SettingChanged."..key, value, input);
    end
end
addon.SetSetting = SetSetting;


-- Core Functionality
function UpdateFOV()
    local left = GetSetting("Left") or 0;
    local right = GetSetting("Right") or 0;
    local bottom = GetSetting("Bottom") or 0;
    local top = GetSetting("Top") or 0;

    WorldFrame:ClearAllPoints();

    local parent = UIParent;
    local s = parent:GetEffectiveScale();
    PixelUtil.SetPoint(WorldFrame, "TOPLEFT", parent, "TOPLEFT", left * s, -top * s);
    PixelUtil.SetPoint(WorldFrame, "BOTTOMRIGHT", parent, "BOTTOMRIGHT", -right * s, bottom * s);
end

local function UpdateFOVAfterCutscene()
    C_Timer.After(0, UpdateFOV);
end

for key in pairs(DefaultValues) do
    CallbackRegistry:RegisterCallback("SettingChanged."..key, UpdateFOV);
end

-- Lifecycle Management
local function LoadSettings()
	NookSettings = NookSettings or {};

    Settings = NookSettings;
	for k, v in pairs(DefaultValues) do
		if Settings[k] == nil then
			Settings[k] = v
		end
	end

    for key, _ in pairs(DefaultValues) do
        CallbackRegistry:TriggerEvent("SettingChanged."..key, Settings[key]);
    end

	DefaultValues = nil
end

local NookFrame = CreateFrame("Frame");
NookFrame:RegisterEvent("ADDON_LOADED");
NookFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
NookFrame:RegisterEvent("UI_SCALE_CHANGED");
NookFrame:RegisterEvent("CINEMATIC_STOP");

NookFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            self:UnregisterEvent(event);
            LoadSettings();
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent(event);
        UpdateFOV();
    elseif event == "UI_SCALE_CHANGED" then
        UpdateFOV();
    elseif event == "CINEMATIC_STOP" then
        UpdateFOVAfterCutscene();
    end
end);