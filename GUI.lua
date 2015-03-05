local addonName = "Storytime"
local Core      = LibStub("AceAddon-3.0"):GetAddon("Storytime")
local GUI       = Core:NewModule("GUI", "AceEvent-3.0")
local AceGUI    = LibStub("AceGUI-3.0")

GUI.Window = nil

function GUI:OnInitialize()
    self:RegisterMessage('STORY_STATUS_CHANGED', 'OnStatusChange')
end

function GUI:OnStartStopButtonClick(button)
    if Core:IsStoryStarted() then
        Core:StopStory()
        button:SetText("Start Story")
    else
        Core:StartStory()
        button:SetText("End Story")
    end
end

function GUI:OnStatusChange()
    if not self:IsWindowOpen() then
        return
    end

    self.Window:SetStatusText('Status: '..Core:GetStatus())
end

function GUI:IsAllowedToOpenWindow()
    -- Prevent the user from opening two windows.
    if self:IsWindowOpen() then
        return false
    end

    local Utils = Core:GetModule("Utils")

    -- Only allow the leader to open the GUI.
    if not Utils:IsUnitLeader("player") then
        Core:Printf(Core.ERROR_NOT_LEADER)
        return false
    end

    return true
end

function GUI:IsWindowOpen()
    return self.Window ~= nil
end

function GUI:CreateRollsFrame(container)
    local heading = AceGUI:Create("Heading")
    heading:SetText("Rolls")
    heading:SetFullWidth(true)
    container:AddChild(heading)

    local text = AceGUI:Create("Label")
    text:SetText("This roll type simply asks the participants to roll. All roll results will be sent back to you and allows you to progress the story based upon them (for example, something could happen to the lowest roller).")
    text:SetFullWidth(true)
    container:AddChild(text)

    local button = AceGUI:Create("Button")
    button:SetText("Request Rolls")
    button:SetFullWidth(true)
    button:SetCallback("OnClick", function()
        Core:GetModule("Roll"):SendRollRequest("roll")
    end)
    container:AddChild(button)

    local heading = AceGUI:Create("Heading")
    heading:SetText("Freestyle Rolls")
    heading:SetFullWidth(true)
    container:AddChild(heading)

    local text = AceGUI:Create("Label")
    text:SetText("Freestyle rolls are of the classic \"Emote and Roll\" type. This roll type allows each participant to do one emote and then roll to see if they succeed or not.")
    text:SetFullWidth(true)
    container:AddChild(text)

    local button = AceGUI:Create("Button")
    button:SetText("Request Freestyle Rolls")
    button:SetFullWidth(true)
    button:SetCallback("OnClick", function()
        Core:GetModule("Roll"):SendRollRequest("freestyle")
    end)
    container:AddChild(button)

    local heading = AceGUI:Create("Heading")
    heading:SetText("Threshold Rolls")
    heading:SetFullWidth(true)
    container:AddChild(heading)

    local text = AceGUI:Create("Label")
    text:SetText("Threshold rolls allows you to set up thresholds the participants must beat in order to do or avoid certain things.")
    text:SetFullWidth(true)
    container:AddChild(text)

    self:CreateThresholdFields(container, true)
    self:CreateThresholdFields(container, false)
    self:CreateThresholdFields(container, false)

    local button = AceGUI:Create("Button")
    button:SetText("Request Threshold Rolls")
    button:SetFullWidth(true)
    button:SetCallback("OnClick", function()
        Core:GetModule("Roll"):SendRollRequest("threshold")
    end)
    container:AddChild(button)
end

function GUI:CreateStoryFrame(container)
    local button = AceGUI:Create("Button")
    if Core:IsStoryStarted() then
        button:SetText("End Story")
    else
        button:SetText("Start Story")
    end
    button:SetWidth(200)
    button:SetCallback("OnClick", function()
        self:OnStartStopButtonClick(button)
    end)
    container:AddChild(button)
end

function GUI:CreateTabGroup(window)
    local tab = AceGUI:Create("TabGroup")
    tab:SetLayout("Flow")
    tab:SetTabs({
        {
            text="Story",
            value="story"
        },
        {
            text="Rolls",
            value="rolls"
        }
    })
    tab:SetCallback("OnGroupSelected", function(container, event, group)
        container:ReleaseChildren()
        if group == "story" then
            self:CreateStoryFrame(container)
        elseif group == "rolls" then
            self:CreateRollsFrame(container)
        end
    end)
    tab:SelectTab("story")
    window:AddChild(tab)
end

function GUI:CreateThresholdFields(container, enabledByDefault)
    local group = AceGUI:Create("SimpleGroup")
    group:SetFullWidth(true)
    group:SetLayout("Flow")
    container:AddChild(group)

    local checkbox = AceGUI:Create("CheckBox")
    checkbox:SetType("checkbox")
    checkbox:SetValue(enabledByDefault)
    checkbox:SetRelativeWidth(0.05)
    group:AddChild(checkbox)

    local dropdown = AceGUI:Create("Dropdown")
    dropdown:SetList({
        below = "Below",
        above = "Above"
    })
    dropdown:SetMultiselect(false)
    dropdown:SetRelativeWidth(0.2)
    group:AddChild(dropdown)

    local slider = AceGUI:Create("Slider")
    slider:SetSliderValues(0, 100, 5)
    slider:SetValue(50)
    slider:SetLabel("Threshold")
    slider:SetRelativeWidth(0.3)
    group:AddChild(slider)

    local editbox = AceGUI:Create("EditBox")
    editbox:SetRelativeWidth(0.45)
    editbox:SetLabel("Description")
    group:AddChild(editbox)
end

function GUI:CreateWindow()
    self.Window = AceGUI:Create("Frame")
    self.Window:SetTitle(Core:GetName())
    self.Window:SetStatusText('Status: '..Core:GetStatus())
    self.Window:SetCallback("OnClose", function(widget)
        AceGUI:Release(widget)
        self.Window = nil
    end)
    self.Window:SetLayout("Fill")

    self:CreateTabGroup(self.Window)
end

function GUI:OpenWindow()
    -- Check if we're allowed to open a window.
    if not self:IsAllowedToOpenWindow() then
        return
    end

    self:CreateWindow()
end
