--[[
 * Label    : The spinner scripted entity
 * Author   : DVD ( dvd_video )
 * Date     : 13-03-2017
 * Location : /lua/entities/sent_spinner.lua
 * Requires : /lua/weapons/gmod_tool/stools/spinner.lua
 * Created  : Using tool requirement
 * Defines  : Advanced motor scripted entity
]]--

AddCSLuaFile()

local gsSentHash  = "sent_spinner"
local gnMaxMod    = 50000 -- Maximum module for power and lever
local gnMaxMass   = 50000 -- The maximum mass the entity can have
local gnMaxRadius = 1000  -- Maximum radius when rebuilding the collision model as sphere
local gnTimerCL   = 250   -- Interval to broadcast server data to the client looking ( milliseconds )

ENT.Type            = "anim"
if (WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = gsSentHash:gsub("sent_",""):gsub("^%l",string.upper)
else
  ENT.Base          = "base_gmodentity"
end
ENT.PrintName       = gsSentHash:gsub("sent_",""):gsub("^%l",string.upper)
ENT.Author          = "DVD"
ENT.Contact         = "dvd_video@abv.bg"
ENT.Editable        = true
ENT.Spawnable       = false
ENT.AdminSpawnable  = false

function ENT:GetPower()
  if(SERVER)     then local oSent = self[gsSentHash]; return oSent.Power
  elseif(CLIENT) then return self:GetNWFloat(gsSentHash.."_power") end
end

function ENT:GetLeverCount()
  if(SERVER)     then local oSent = self[gsSentHash]; return oSent.CLev
  elseif(CLIENT) then return self:GetNWInt(gsSentHash.."_lcnt") end
end

function ENT:GetLever()
  if(SERVER)     then local oSent = self[gsSentHash]; return oSent.Lever
  elseif(CLIENT) then return self:GetNWFloat(gsSentHash.."_lever") end
end

function ENT:GetTorqueAxis()
  if(SERVER)     then local oSent = self[gsSentHash]; return oSent.AxiL
  elseif(CLIENT) then return self:GetNWVector(gsSentHash.."_adir") end
end

function ENT:GetTorqueLever()
  if(SERVER)     then local oSent = self[gsSentHash]; return oSent.LevL
  elseif(CLIENT) then return self:GetNWVector(gsSentHash.."_ldir") end
end

function ENT:GetTorqueForce()
  if(SERVER)     then local oSent = self[gsSentHash]; return oSent.ForL
  elseif(CLIENT) then return self:GetNWVector(gsSentHash.."_fdir") end
end

function ENT:GetSpinCenter()
  if(SERVER)     then return self:GetPhysicsObject():GetMassCenter()
  elseif(CLIENT) then return self:GetNWVector(gsSentHash.."_cen") end
end

function ENT:IsToggled()
  if(SERVER)     then local oSent = self[gsSentHash]; return oSent.Togg
  elseif(CLIENT) then return self:GetNWVector(gsSentHash.."_togg") end
end

if(SERVER) then

  function ENT:Initialize()
    self[gsSentHash] = {}; local oSent = self[gsSentHash]
    oSent.Dir  = 0        -- Power sign for reverse support
    oSent.CLev = 0        -- How many spinner levers do we have (allocate)
    oSent.Radi = 0        -- Collision radius
    oSent.DAng = 0        -- Store the angle delta to avoid calculating it every frame on SV
    oSent.Tick = 5        -- Entity ticking interval ( milliseconds )
    oSent.TSnd = 0        -- Threshold time to sending the date to the client to view in DrawHUD
    oSent.On   = false    -- Enable/disable working
    oSent.Togg = false    -- Toggle the spinner
    oSent.LAng = Angle()  -- Temporary angle server-side used for rotation
    oSent.PowT = Vector() -- Temporary power vector
    oSent.LevT = Vector() -- Temporary lever vector
    oSent.ForL = Vector() -- Local force spin direction list (forward)
    oSent.LevL = Vector() -- Local lever list (right)
    oSent.AxiL = Vector() -- Local spin axis ( Up )
    oSent.LevW = Vector() -- World lever (right)(allocate memory)(temporary)
    oSent.ForW = Vector() -- World force spin direction (forward)(allocate memory)(temporary)
    oSent.AxiW = Vector() -- World spin axis ( Up ) allocate memory
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid  (SOLID_VPHYSICS)
    if(WireLib)then
      WireLib.CreateSpecialInputs(self,{
        "On",
        "Power",
        "Lever",
        "Force"
      }, { "NORMAL", "NORMAL", "NORMAL", "VECTOR"}, {
        " Start/Stop ",
        " Force spin magnitude ",
        " Force spin leverage ",
        " Center force vector "
      })
      WireLib.CreateSpecialOutputs(self,{
        "RPM" ,
        "Tick",
        "Margin",
        "Axis"
      }, { "NORMAL", "NORMAL", "NORMAL", "VECTOR"}, {
        " Revolutions per minute ",
        " CPU time consumption ",
        " Server execution margin ",
        " Spinner rotation axis "
      })
    end; return true
  end

  local function getPower(vRes, vVec, nNum)
    vRes:Set(vVec); vRes:Mul(nNum); return vRes end

  local function getLever(vRes, vPos, vVec, nNum)
    vRes:Set(vVec); vRes:Mul(nNum); vRes:Add(vPos); return vRes end

  function ENT:SetPhysRadius(nRad)
    local nRad = math.Clamp(tonumber(nRad) or 0, 0, gnMaxRadius)
    if(nRad > 0) then
      local oSent = self[gsSentHash]
      local vMin  = Vector(-nRad,-nRad,-nRad)
      local vMax  = Vector( nRad, nRad, nRad)
      self:PhysicsInitSphere(nRad)
      self:SetCollisionBounds(vMin, vMax)
      self:PhysWake(); oSent.Radi = nRad
    end; return true
  end

  function ENT:SetPower(nPow)
    local oSent = self[gsSentHash] -- Magnitude of the spinning force
    oSent.Power = math.Clamp((tonumber(nPow) or 0), -gnMaxMod, gnMaxMod)
    self:SetNWFloat(gsSentHash.."_power", oSent.Power); return true
  end

  function ENT:SetLever(nLev)
    local oSent = self[gsSentHash] -- Magnitude of the spinning force
    oSent.Lever = math.Clamp((tonumber(nLev) or 0), 0, gnMaxMod)
    if(oSent.Lever == 0) then -- Use the half of the bounding box size
      vMin, vMax = self:OBBMins(), self:OBBMaxs()
      oSent.Lever = ((vMax - vMin):Length()) / 2
    end
    self:SetNWFloat(gsSentHash.."_lever", oSent.Lever); return true
  end

  function ENT:SetTorqueAxis(vDir)
    local oSent = self[gsSentHash]
    if(vDir:Length() == 0) then
      ErrorNoHalt("ENT.SetTorqueAxis: Spin axis invalid\n"); self:Remove(); return false end
    oSent.AxiL:Set(vDir); oSent.AxiL:Normalize()
    self:SetNWVector(gsSentHash.."_adir",oSent.AxiL); return true
  end

  function ENT:SetTorqueLever(vDir, nCnt)
    local oSent = self[gsSentHash]
    local nCnt  = (tonumber(nCnt) or 0)
    if(nCnt <= 0) then
      ErrorNoHalt("ENT.SetTorqueLever: Lever count invalid\n"); self:Remove(); return false end
    if(vDir:Length() == 0) then
      ErrorNoHalt("ENT.SetTorqueLever: Force lever invalid\n"); self:Remove(); return false end
    oSent.CLev = nCnt
    oSent.DAng = (360 / nCnt)
    oSent.LevL:Set(vDir) -- Lever direction matched to player right
    oSent.ForL:Set(oSent.AxiL:Cross(oSent.LevL)) -- Force
    oSent.LevL:Set(oSent.ForL:Cross(oSent.AxiL)) -- Lever
    oSent.ForL:Normalize(); oSent.LevL:Normalize()
    self:SetNWInt(gsSentHash.."_lcnt",oSent.CLev)
    self:SetNWVector(gsSentHash.."_ldir",oSent.LevL); return true
  end

  function ENT:SetToggled(bTogg)
    local oSent = self[gsSentHash]; oSent.Togg = tobool(bTogg or false)
    self:SetNWBool(gsSentHash.."_togg", oSent.Togg) end

  function ENT:Setup(stSpinner)
    self:SetPhysRadius(stSpinner.Radi)         -- Set the radius if given
    local oPhys = self:GetPhysicsObject()
    if(oPhys and oPhys:IsValid()) then
      self:SetToggled(stSpinner.Togg)          -- Is it going to be toggled
      self:SetTorqueAxis(stSpinner.AxiL)       -- Axis direction
      self:SetPower(stSpinner.Power)           -- Torque amount
      self:SetTorqueLever(stSpinner.LevL, stSpinner.CLev) -- Lever direction and count
      self:SetLever(stSpinner.Lever)           -- Leverage length
      self:SetNWVector(gsSentHash.."_cen", oPhys:GetMassCenter())
      local oSent = self[gsSentHash]
      local nMass = math.Clamp(tonumber(stSpinner.Mass) or 1, 1, gnMaxMass)
      oPhys:SetMass(nMass); oSent.Mass = nMass -- Mass
      oSent.Prop = stSpinner.Prop              -- Model
      oSent.KeyF = stSpinner.KeyF              -- Forward spin key ( positive power )
      oSent.KeyR = stSpinner.KeyR              -- Forward spin key ( negative power )
    else ErrorNoHalt("ENT.Setup: Physics invalid\n"); self:Remove(); return false end
    collectgarbage(); return true -- Everything is fine !
  end

  -- In Wiremod this is done in /registerOperator("iwc", "", "n", function(self, args)/
  -- https://facepunch.com/showthread.php?t=1566053&p=52298677#post52298677
  -- https://github.com/wiremod/wire/blob/master/lua/entities/gmod_wire_expression2/core/core.lua#L232
  function ENT:HasWire(sIn)
    local tIn = (sIn and self.Inputs[sIn] or nil)
    return ((tIn and IsValid(tIn.Src)) and tIn or nil)
  end

  function ENT:ReadWire(sIn)
    local tIn = self:HasWire(sIn)
    return (tIn and tIn.Value or nil)
  end

  function ENT:WriteWire(sOut, anyVal)
    WireLib.TriggerOutput(self, sOut, anyVal)
  end

  function ENT:Think()
    local goTime = SysTime()
    local toTime = oSent.Tick -- Sampling time in milliseconds
    self:NextThink(goTime + (toTime / 1000)) -- Add seconds to seconds
    local oPhys = self:GetPhysicsObject()
    if(oPhys and oPhys:IsValid()) then
      local oSent = self[gsSentHash]
      local vCn, wFr = self:LocalToWorld(oPhys:GetMassCenter())
      if(WireLib) then wFr = self:ReadWire("Force")
        local wOn = self:ReadWire("On")
        local wPw = self:ReadWire("Power")
        local wLe = self:ReadWire("Lever")
        if(wLe ~= nil) then oSent.Lever = wLe end
        if(wOn ~= nil) then oSent.On = (wOn ~= 0) end
        if(wPw ~= nil) then oSent.Power, oSent.Dir = wPw, 1 end
      end -- Do not change internal setting with a peak when wire is disconnected
      if(oSent.On) then -- Disable toggling via numpad if wire is connected
        local vPwt, vLvt = oSent.PowT, oSent.LevT
        local vLew, vAxw, aLev = oSent.LevW, oSent.AxiW, oSent.LAng
        local Le, Pw, eA = oSent.Lever, (oSent.Power * oSent.Dir), self:GetAngles()
        vAxw:Set(oSent.AxiL); vAxw:Rotate(eA)
        vLew:Set(oSent.LevL); vLew:Rotate(eA)
        aLev:Set(vLew:AngleEx(vAxw))
        for ID = 1, oSent.CLev do
          local cLev, cFor = aLev:Forward(), aLev:Right(); cFor:Mul(-1)
          oPhys:ApplyForceOffset(getPower(vPwt, cFor, Pw), getLever(vLvt, vCn, cLev, Le))
          aLev:RotateAroundAxis(vAxw, oSent.DAng)
        end
        if(WireLib) then -- Take the down-force into account ( if given )
          if(wFr and wFr:Length() > 0) then oPhys:ApplyForceCenter(wFr) end
          self:WriteWire("Axis", vAxw)
        end
        local dtTime = (1000 * (SysTime() - goTime)) -- ( Seconds to milliseconds )
        if(oSent.TSnd >= gnTimerCL) then
          self:SetNWFloat(gsSentHash.."_power", Pw)
          self:SetNWFloat(gsSentHash.."_lever", Le)
          oSent.TSnd = 0
        else oSent.TSnd = oSent.TSnd + dtTime end
        if(dtTime > toTime) then
          ErrorNoHalt("ENT.Think: Spinner out of time margin\n"); self:Remove(); end
      end
      if(WireLib) then
        self:WriteWire("Tick", dtTime)
        self:WriteWire("Margin", ((dtTime / toTime) * 100))
        self:WriteWire("RPM" , oPhys:GetAngleVelocity():Dot(oSent.AxiL) / 6) end
    else ErrorNoHalt("ENT.Think: Physics invalid\n"); self:Remove(); end; return true
  end

  local function spinForward(oPly, oEnt)
    if(not (oEnt and oEnt:IsValid())) then return end
    if(not (oEnt:GetClass() == gsSentHash)) then return end
    local Data = oEnt[gsSentHash]
    if(Data.On and oEnt:IsToggled()) then
      Data.On = false
    else
      Data.Dir = 1
      Data.On  = true
    end
  end

  local function spinReverse(oPly, oEnt)
    if(not (oEnt and oEnt:IsValid())) then return end
    if(not (oEnt:GetClass() == gsSentHash)) then return end
    local Data = oEnt[gsSentHash]
    if(Data.On and oEnt:IsToggled()) then
      Data.On = false
    else
      Data.Dir = -1
      Data.On  = true
    end
  end

  local function spinStop(oPly, oEnt)
    if(not (oEnt and oEnt:IsValid())) then return end
    if(not (oEnt:GetClass() == gsSentHash)) then return end
    if(not oEnt:IsToggled()) then
      local Data = oEnt[gsSentHash]
      Data.Dir = 0
      Data.On  = false
    end
  end

  numpad.Register(gsSentHash.."_spinForward_On" , spinForward)
  numpad.Register(gsSentHash.."_spinForward_Off", spinStop)
  numpad.Register(gsSentHash.."_spinReverse_On" , spinReverse)
  numpad.Register(gsSentHash.."_spinReverse_Off", spinStop)

end


