local addonName = "Storytime"
local Core      = LibStub("AceAddon-3.0"):GetAddon("Storytime")
local Utils     = Core:NewModule("Utils")

function Utils:GetLeaderUnit()
    if UnitIsGroupLeader("player") then
        return "player"
    end

    local leader = nil

    for i = 1, GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) do
        if UnitInRaid("player") then
            if UnitIsPlayer("raid"..i) and GetRaidRosterInfo(i).rank == 2 then
                leader = "raid"..i
                break
            end
        else
            if UnitIsPlayer("party"..i) and UnitIsGroupLeader("party"..i) then
                leader = "party"..i
                break
            end
        end
    end

    return leader
end

function Utils:GetTableAverage(t)
    local sum = 0
    local count= 0

    for k,v in pairs(t) do
        if type(v) == 'number' then
            sum = sum + v
            count = count + 1
        end
    end

    return (sum / count)
end

function Utils:GetTableLength(t)
    local count = 0
    for _ in pairs(t) do count = count + 1 end
    return count
end

function Utils:GetUnitNameWithClassColor(unit)
    local name, class = UnitClass(unit)
    local color       = RAID_CLASS_COLORS[class]

    return string.format("|cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, UnitName(unit))
end

function Utils:GetUnitSexPronoun(unit)
    local sex = UnitSex(unit)

    if sex == 2 then
        return "him"
    else
        return "her"
    end
end

function Utils:IsUnitLeader(unit)
    return UnitIsUnit(unit, self:GetLeaderUnit())
end
