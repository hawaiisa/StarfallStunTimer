local SFST = CreateFrame("Frame","SFSTunTimerFrame")
SFST_DB = SFST_DB or {}

SFST:SetPoint("CENTER", UIParent, "CENTER" )
SFST:SetWidth(70)
SFST:SetHeight(35)
SFST:SetMovable(true)
SFST:EnableMouse(true)
SFST:SetClampedToScreen(true)

SFST.title = SFST:CreateFontString(nil, "OVERLAY", "GameFontNormal")
SFST.title:SetPoint("TOP", SFST, "TOP")
SFST.title:SetText("Starfall Stun CD")

SFST.timer = SFST:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
SFST.timer:SetPoint("BOTTOM", SFST, "BOTTOM")
SFST.timer:SetTextColor( 1, 1, 1, 1 )
SFST:Hide()

SFST:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE")
SFST:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE")
SFST:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE")

SFST:RegisterForDrag("LeftButton")
SFST:SetScript("OnDragStart", function()
    if IsShiftKeyDown() then
        this:StartMoving()
    end
end)

SFST:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local x, y = this:GetCenter()
    local ux, uy = UIParent:GetCenter()
    SFST_DB.x, SFST_DB.y = floor(x - ux + 0.5), floor(y - uy + 0.5)
end)

StarfallHit = "Your (.*) hits (.*) for (%d+) Arcane damage."
StarfallCrit = "Your (.*) crits (.*) for (%d+) Arcane damage."
SFSTunAffliction = "(.*) is afflicted by Starfall Stun."
SFSTunImmune = "Your Starfall Stun failed. (.*) is immune."

local function SFST_Delay()
    return GetTime()+0.5
end

local function SFST_CD()
    local _, _, _, _, cR = GetTalentInfo( 1, 9 )
    return 65 - ( cR * 5 )
end

function SFST_ShowTimer(duration, timerframe, parentframe)
    local timer = CreateFrame("Frame")
    timer.start = GetTime()
    timer.duration = duration
    timer.sec = 0
    timer:SetScript("OnUpdate", function()
        if GetTime() >= (this.start + this.sec) then
            this.sec = this.sec + 1
            if this.sec <= duration then
                timerframe:SetText(this.duration - this.sec)
                return
            end
            parentframe:Hide()
            this:SetScript("OnUpdate", nil)
        end
    end)
    timerframe:SetText(duration)
    parentframe:Show()
end

local function SFSTunTimer()
    if SFST_Interval and GetTime() > SFST_Interval then
        SFST_Spell, SFST_Creature, SFST_Interval = nil, nil, nil
    end
    if SFST_Timer and GetTime() < SFST_Timer then
        event = nil
    end
    if event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        if strfind( arg1, SFSTunImmune, 0) then
            SFST_Cooldown = SFST_CD()
            SFST_ShowTimer( SFST_Cooldown, SFST.timer, SFST )
        elseif strfind( arg1, StarfallHit, 0) then
            _, _, SFST_Spell, SFST_Creature = strfind( arg1, StarfallHit, 0 )
        elseif strfind( arg1, StarfallCrit, 0) then
        _, _, SFST_Spell, SFST_Creature = strfind( arg1, StarfallCrit, 0 )
        end
        if SFST_Spell == "Moonfire" or SFST_Spell == "Starfire" and not SFST_Interval then
            SFST_Interval = SFST_Delay()
        end
    elseif event == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" or event == "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE" and SFST_Interval and GetTime() < SFST_Interval then
        if strfind( arg1, SFSTunAffliction, 0) then
            _, _, SFST_StunCreature = strfind( arg1, SFSTunAffliction, 0)
            if strfind(SFST_Creature, SFST_StunCreature, 0) then
                SFST_Cooldown = SFST_CD()
                SFST_ShowTimer( SFST_Cooldown, SFST.timer, SFST )
            end
        end
    end
end
SFST:SetScript("OnEvent", SFSTunTimer )