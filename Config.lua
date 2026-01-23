local addonName, addon = ...

local MIN_OFFSET = 0
local MAX_OFFSET = 500

local function ClampOffset(value)
	return math.max(MIN_OFFSET, math.min(MAX_OFFSET, value or 0))
end

local config = CreateFrame("Frame", "NookConfig")
config:Hide()

local function CreateSlider(parent, name, label, minVal, maxVal, step)
	local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
	slider:SetMinMaxValues(minVal, maxVal)
	slider:SetValueStep(step)
	slider:SetObeyStepOnDrag(true)
	slider:SetWidth(200)
	slider:SetHeight(20)

	_G[slider:GetName().."Low"]:SetText(minVal)
	_G[slider:GetName().."High"]:SetText(maxVal)
	_G[slider:GetName().."Text"]:SetText(label)

	return slider
end

local function CreateInputBox(parent)
	local frame = CreateFrame("Frame", nil, parent)
	frame:SetSize(200, 40)

	local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	editBox:SetSize(40, 20)
	editBox:SetPoint("TOPLEFT", 0, -10)
	editBox:SetAutoFocus(false)
	editBox:SetNumeric(true)

	frame.editBox = editBox

	return frame
end

local function UpdateSliderLabel(slider, label, value)
	_G[slider:GetName().."Text"]:SetText(label .. ": " .. value)
end

local function BuildOffsetControl(parent, key, label, anchor)
	local slider = CreateSlider(parent, "NookConfig"..label.."Slider", label, MIN_OFFSET, MAX_OFFSET, 1)

	if anchor then
		slider:SetPoint("TOPLEFT", anchor.relative, anchor.relativePoint or "BOTTOMLEFT", anchor.x or 0, anchor.y or 0)
	else
		slider:SetPoint("TOPLEFT", 26, -60)
	end

	local input = CreateInputBox(parent)
	input:SetPoint("LEFT", slider, "RIGHT", 30, 0)
	
	slider:SetScript("OnValueChanged", function(self, value)
		value = ClampOffset(value)
		addon.SetSetting(key, value, "slider")
		UpdateSliderLabel(self, label, value)
		input.editBox:SetText(tostring(value))
	end)

	slider:SetScript("OnShow", function(self)
		local value = ClampOffset(addon.GetSetting(key))
		self:SetValue(value)
		UpdateSliderLabel(self, label, value)
	end)

	input.editBox:SetScript("OnEnterPressed", function(self)
		local value = ClampOffset(tonumber(self:GetText()))
		slider:SetValue(value)
		self:ClearFocus()
	end)

	local initialValue = ClampOffset(addon.GetSetting(key))
	slider:SetValue(initialValue)
	input.editBox:SetText(tostring(initialValue))

	return slider
end

config:SetScript("OnShow", function(self)
	if self.initialized then return end
	self.initialized = true

	local title = self:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText("Nook - FOV Editor")

	local description = self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
	description:SetText("Adjust the size of black bars around the game viewport.")

	local topSlider = BuildOffsetControl(self, "Top", "Top", {relative = description, relativePoint = "BOTTOMLEFT", x = 10, y = -30})
	local bottomSlider = BuildOffsetControl(self, "Bottom", "Bottom", {relative = topSlider, relativePoint = "BOTTOMLEFT", x = 0, y = -40})
	local leftSlider = BuildOffsetControl(self, "Left", "Left", {relative = bottomSlider, relativePoint = "BOTTOMLEFT", x = 0, y = -40})
	BuildOffsetControl(self, "Right", "Right", {relative = leftSlider, relativePoint = "BOTTOMLEFT", x = 0, y = -40})
end)

local category, layout = Settings.RegisterCanvasLayoutCategory(config, "Nook")
Settings.RegisterAddOnCategory(category)

SLASH_NOOK1 = "/nook"
SlashCmdList["NOOK"] = function()
	Settings.OpenToCategory(category:GetID())
end