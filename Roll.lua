local addonName = "Storytime"
local Core      = LibStub("AceAddon-3.0"):GetAddon("Storytime")
local Roll      = Core:NewModule("Roll", "AceComm-3.0", "AceSerializer-3.0")

Roll.Allowed    = false
Roll.InProgress = false
Roll.History    = {}
Roll.Owner      = nil
Roll.Results    = {}
Roll.Type       = nil

function Roll:OnRollAnnouncement(sender, player, roll, rollType)
    local Utils = Core:GetModule("Utils")

    if not Utils:IsUnitLeader(sender) then
        return
    end

    if rollType == "freestyle" then
        Core:Printf(Core.MSG_ANNOUNCE_FREESTYLE, Utils:GetUnitNameWithClassColor(player), roll, 50, "succeeded")
    elseif rollType == "roll" then
        Core:Printf(Core.MSG_ANNOUNCE_ROLL, Utils:GetUnitNameWithClassColor(player), roll)
    elseif rollType == "skip" then
        Core:Printf(Core.MSG_ANNOUNCE_SKIP, Utils:GetUnitNameWithClassColor(player))
    elseif rollType == "threshold" then
        Core:Printf(Core.MSG_ANNOUNCE_THRESHOLD, Utils:GetUnitNameWithClassColor(player), roll, "die")
    end
end

function Roll:OnRollCommand()
    if not self:IsAllowedToRoll() then
        return
    end

    local roll = math.random(1, 100)
    table.insert(self.History, roll)

    self:SendCommMessage(addonName, self:Serialize({
        event = "roll_response",
        roll  = roll
    }), "WHISPER", self:GetOwner())

    self:SetAllowed(false)
    self:SetOwner(nil)
end

function Roll:OnRollRequest(sender, rollType)
    local Utils = Core:GetModule("Utils")

    if not Utils:IsUnitLeader(sender) then
        return
    end

    self:SetAllowed(true)
    self:SetOwner(sender)

    if rollType == "freestyle" then
        Core:Printf(Core.MSG_REQUEST_FREESTYLE, Utils:GetUnitNameWithClassColor(sender), Utils:GetUnitSexPronoun(sender))
    elseif rollType == "roll" then
        Core:Printf(Core.MSG_REQUEST_ROLL, Utils:GetUnitNameWithClassColor(sender))
    elseif rollType == "threshold" then
        Core:Printf(Core.MSG_REQUEST_THRESHOLD, Utils:GetUnitNameWithClassColor(sender))
        -- @todo: print thresholds
        Core:Printf(Core.MSG_REQUEST_THRESHOLD2)
    end
end

function Roll:OnRollResponse(sender, roll)
    if not self:IsAllowedToRespond(sender) then

    end

    local Utils   = Core:GetModule("Utils")
    local results = self:GetResults()
    results[UnitName(sender)] = roll

    self:SendCommMessage(addonName, self:Serialize({
        event    = "roll_announcement",
        player   = sender,
        rollType = self:GetType(),
        roll     = roll
    }), "RAID")
end

function Roll:IsAllowedToRoll()
    return self:GetAllowed()
end

function Roll:IsAllowedToSendRequest()
    local Utils = Core:GetModule("Utils")

    if not Utils:IsUnitLeader("player") then
        return false
    end

    if not Core:IsStoryStarted() then
        return false
    end

    if self:IsRollInProgress() then
        return false
    end

    return true
end

function Roll:IsAllowedToRespond(unit)
    return self:GetResults()[UnitName(unit)] == false
end

function Roll:IsRollInProgress()
    return self:GetInProgress()
end

function Roll:GetAllowed()
    return self.Allowed
end

function Roll:GetInProgress()
    return self.InProgress
end

function Roll:GetOwner()
    return self.Owner
end

function Roll:GetResults()
    return self.Results
end

function Roll:GetType()
    return self.Type
end

function Roll:SetAllowed(allowed)
    self.Allowed = allowed
end

function Roll:SetInProgress(inProgress)
    self.InProgress = inProgress
end

function Roll:SetOwner(owner)
    self.Owner = owner
end

function Roll:SetResults(results)
    self.Results = results
end

function Roll:SetType(type)
    self.Type = type
end

function Roll:SendRollRequest(type)
    if not self:IsAllowedToSendRequest() then
        return
    end

    local results = {}

    results[UnitName("player")] = false

    for i = 1, GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) do
        if UnitInRaid("player") then
            if UnitIsPlayer("raid"..i) then
                results[UnitName("raid"..i)] = false
            end
        else
            if UnitIsPlayer("party"..i) then
                results[UnitName("party"..i)] = false
            end
        end
    end

    self:SetResults(results)
    self:SetInProgress(true)
    self:SetType(type)
    Core:SetStatus(Core.STATUS_WAITING_FOR_ROLLS)

    self:SendCommMessage(addonName, self:Serialize({
        event    = "roll_request",
        rollType = self:GetType()
    }), "RAID")
end
