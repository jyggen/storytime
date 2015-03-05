local addonName = "Storytime"
local Storytime = LibStub("AceAddon-3.0"):NewAddon(addonName, "AceConsole-3.0", "AceComm-3.0", "AceEvent-3.0", "AceSerializer-3.0")

Storytime.ERROR_NOT_LEADER         = "|cffff0000You're not the storyteller.|r"
Storytime.ERROR_UNKNOWN_COMMAND    = "|cffff0000Unknown command.|r"
Storytime.MSG_NEW_STORY_STARTED    = "%s started a new story. Good luck and have fun!"
Storytime.MSG_REQUEST_FREESTYLE    = "%s is asking you to emote and then type |cff33ff99/story roll|r to roll against %s, or |cff33ff99/story skip|r to skip."
Storytime.MSG_REQUEST_ROLL         = "%s is asking you to roll. Type |cff33ff99/story roll|r to roll or |cff33ff99/story skip|r to skip."
Storytime.MSG_REQUEST_THRESHOLD    = "%s is asking you to roll against the following thresholds:"
Storytime.MSG_REQUEST_THRESHOLD2   = "Type |cff33ff99/story roll|r to roll and then emote appropriately, or |cff33ff99/story skip|r to skip."
Storytime.MSG_ROLL_HISTORY         = "You rolled |cff33ff99%i|r times with an average roll of |cff33ff99%i|r."
Storytime.MSG_ANNOUNCE_FREESTYLE   = "%s rolled |cff33ff99%i|r against |cff33ff99%i|r and %s."
Storytime.MSG_ANNOUNCE_ROLL        = "%s rolled |cff33ff99%i|r."
Storytime.MSG_ANNOUNCE_SKIP        = "%s chose to |cff33ff99skip|r their roll."
Storytime.MSG_ANNOUNCE_THRESHOLD   = "%s rolled |cff33ff99%i|r and must %s."
Storytime.MSG_STORY_ENDED          = "%s finished the story!"
Storytime.STATUS_IDLE              = "Idle."
Storytime.STATUS_NOT_IN_PROGRESS   = "No story in progress."
Storytime.STATUS_WAITING_FOR_ROLLS = "Waiting on rolls."

Storytime.Started = false
Storytime.Status  = Storytime.STATUS_NOT_IN_PROGRESS

function Storytime:OnCommReceived(prefix, message, distribution, sender)
    if prefix ~= addonName then
        return
    end

    local status, message = self:Deserialize(message)

    if message.event == "roll_announcement" then
        self:GetModule("Roll"):OnRollAnnouncement(sender, message.player, message.roll, message.rollType)
    elseif message.event == "roll_request" then
        self:GetModule("Roll"):OnRollRequest(sender, message.rollType)
    elseif message.event == "roll_response" then
        self:GetModule("Roll"):OnRollResponse(sender, message.roll)
    elseif message.event == "start" then
        self:OnStartEvent(sender)
    elseif message.event == "stop" then
        self:OnStopEvent(sender)
    end
end

function Storytime:OnInitialize()
    self:RegisterComm("Storytime")
    self:RegisterChatCommand("story", "StoryProcessorFunc")
    self:SetStatus(self.STATUS_NOT_IN_PROGRESS)
end

function Storytime:OnStartEvent(sender)
    local Utils = self:GetModule("Utils")

    if not Utils:IsUnitLeader(sender) then
        return
    end

    if self:IsStoryStarted() then
        return
    end

    self:SetStarted(true)
    self:Printf(self.MSG_NEW_STORY_STARTED, Utils:GetUnitNameWithClassColor(sender))
end

function Storytime:OnStopEvent(sender)
    local Utils = self:GetModule("Utils")

    if not Utils:IsUnitLeader(sender) then
        return
    end

    if not self:IsStoryStarted() then
        return
    end

    self:SetStarted(false)
    self:Printf(self.MSG_STORY_ENDED, Utils:GetUnitNameWithClassColor(sender))

    -- Storytime:PrintRollHistory()
    -- Storytime:ClearRollHistory()
    -- @todo: Clean up states etc.
end

function Storytime:IsStoryStarted()
    return self:GetStarted() == true
end

function Storytime:GetStarted()
    return self.Started
end

function Storytime:GetStatus()
    return self.Status
end

function Storytime:SetStarted(started)
    self.Started = started
    self:SendMessage('STORY_STARTED_CHANGED')
end

function Storytime:SetStatus(status)
    self.Status = status
    self:SendMessage('STORY_STATUS_CHANGED')
end

function Storytime:StartStory()
    local Utils = self:GetModule("Utils")
    if not Utils:IsUnitLeader("player") or self:IsStoryStarted() then
        return
    end

    self:SendCommMessage(addonName, self:Serialize({
        event = "start"
    }), "RAID")

    self:SetStatus(self.STATUS_IDLE)
end

function Storytime:StopStory()
    local Utils = self:GetModule("Utils")
    if not Utils:IsUnitLeader("player") or not self:IsStoryStarted() then
        return
    end

    self:SendCommMessage(addonName, self:Serialize({
        event = "stop"
    }), "RAID")

    self:SetStatus(self.STATUS_NOT_IN_PROGRESS)
    -- @todo: Clean up roll states etc.
end

function Storytime:StoryProcessorFunc(input)
    method = self:GetArgs(input)
    if method == nil then
        self:GetModule("GUI"):OpenWindow()
    elseif method == "roll" then
        self:GetModule("Roll"):OnRollCommand()
    elseif method == "skip" then
        self:SkipCommandHandler()
    else
        self:Printf(Storytime.ERROR_UNKNOWN_COMMAND)
    end
end
