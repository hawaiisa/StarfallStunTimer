local SFST = CreateFrame("Frame","SFSTunTimerFrame")
SFST_DB = SFST_DB or {}

--Initiate UI elements
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

--Hide the UI elements until timer is started
SFST:Hide()

SFST:RegisterEvent("CHAT_MSG_SPELL_SELF_DAMAGE") --Registers player's hits.
SFST:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE") --Registers NPCs afflicted by Starfall Stun
SFST:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE") --Registers hostile players afflicted by Starfall Stun

--Make timer movable with shift-leftclick
SFST:RegisterForDrag("LeftButton")
SFST:SetScript("OnDragStart", function()
    if IsShiftKeyDown() then
        this:StartMoving()
    end
end)

SFST:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
end)

--Strings related to Moonfire, Starfire and Starfall Stun.
StarfallHit = "Your (.*) hits (.*) for (%d+) Arcane damage."
StarfallCrit = "Your (.*) crits (.*) for (%d+) Arcane damage."
SFSTunAffliction = "(.*) is afflicted by Starfall Stun."
SFSTunImmune = "Your Starfall Stun failed. (.*) is immune."

--0.5 sec. Time frame from moonfire/starfire hit is registered to register a Starfall Stun hit. 
local function SFST_Delay()
    return GetTime()+0.5
end
--Fetches rank of Starfall Stun talent and calculates CD 
local function SFST_CD()
    local _, _, _, _, cR = GetTalentInfo( 1, 9 )
    return 65 - ( cR * 5 )
end
--Timer function
function SFST_ShowTimer(duration, timerframe)
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
            timerframe:GetParent():Hide()
            this:SetScript("OnUpdate", nil)
        end
    end)
    timerframe:SetText(duration)
    timerframe:GetParent():Show()
end

local function SFSTunTimer()
    if SFST_Timeframe and GetTime() > SFST_Timeframe then
        SFST_Spell, SFST_HitCreature, SFST_Timeframe = nil, nil, nil --Clears variables if the 0.5 sec since last hit timeframe has passed.
    end
    if event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        if strfind( arg1, SFSTunImmune, 0) then --Start cooldown timer if target is immune to Starfall Stun
            SFST_Cooldown = SFST_CD()
            SFST_ShowTimer( SFST_Cooldown, SFST.timer )
        elseif strfind( arg1, StarfallHit, 0) then
            _, _, SFST_Spell, SFST_HitCreature = strfind( arg1, StarfallHit, 0 ) --Fetch what spell hit and what creature was hit
        elseif strfind( arg1, StarfallCrit, 0) then
            _, _, SFST_Spell, SFST_HitCreature = strfind( arg1, StarfallCrit, 0 ) --Fetch what spell crit and what creature was crit
        end
        if SFST_Spell == "Moonfire" or SFST_Spell == "Starfire" and not SFST_Timeframe then --If the spell was Moonfire or Starfire, set the 0.5 sec timeframe
            SFST_Timeframe = SFST_Delay()
        end
    elseif event == "CHAT_MSG_SPELL_PERIODIC_CREATURE_DAMAGE" or event == "CHAT_MSG_SPELL_PERIODIC_HOSTILEPLAYER_DAMAGE" and SFST_Timeframe and GetTime() < SFST_Timeframe then
        if strfind( arg1, SFSTunAffliction, 0) then
            _, _, SFST_StunCreature = strfind( arg1, SFSTunAffliction, 0)
            if strfind(SFST_HitCreature, SFST_StunCreature, 0) then --Check if creature hit/crit by Moonfire or Starfire matches the name of the one afflicted with Starfall Stun and starts timer. 
                SFST_Cooldown = SFST_CD()
                SFST_ShowTimer( SFST_Cooldown, SFST.timer )
            end
        end
    end
end
SFST:SetScript("OnEvent", SFSTunTimer )