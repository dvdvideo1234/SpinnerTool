--[[
 * Label    : The spinner sctipted entity
 * Author   : DVD ( dvd_video )
 * Date     : 13-03-2017
 * Location : /lua/entities/sent_spinner.lua
 * Requires : /lua/weapons/gmod_tool/stools/spinner.lua
 * Created  : Using tool requirement
 * Defines  : Advanced mortor scripted entity
]]--

AddCSLuaFile()

local gsSentHash  = "sent_spinner"
local gnMaxMod    = 50000
local gnMaxMass   = 50000
local gnMaxRadius = 1000

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

function ENT:GetCenter()
  if(SERVER)     then return self:GetPhysicsObject():GetMassCenter()
  elseif(CLIENT) then return self:GetNWVector(gsSentHash.."_cen") end
end

function ENT:IsToggled()
  if(SERVER)     then local oSpin = self[gsSentHash]; return oSpin.Togg
  elseif(CLIENT) then return self:GetNWVector(gsSentHash.."_togg") end
end

if(SERVER) then

  function ENT:Initialize()
    self[gsSentHash] = {}
    self[gsSentHash].On   = false    -- Enable/disable working
    self[gsSentHash].Tick = 0.01     -- Entity ticking interval
    self[gsSentHash].Dir  = 0        -- Power sign for reverse support
    self[gsSentHash].Togg = false    -- Toggle the spinner
    self[gsSentHash].PowT = Vector() -- Temporary power vector
    self[gsSentHash].LevT = Vector() -- Temporary lever vector
    self[gsSentHash].Radi = 0        -- Collision radius
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
        "Srart/stop",
        "Force pair spin magnitude",
        "Force pair spin leverage",
        "Force applyed in the center"
      })
      WireLib.CreateSpecialOutputs(self,
        {"RPM"}, {"NORMAL"}, {"Revolutions per minute"})
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
    oSent.AxiL = Vector() -- Local spin axis ( Up )
    oSent.AxiW = Vector() -- World spin axis ( Up ) allocate memory
    oSent.AxiL:Set(vDir); oSent.AxiL:Normalize()
    self:SetNWVector(gsSentHash.."_adir",oSent.AxiL); return true
  end

  function ENT:SetTorqueLever(vDir)
    local oSent = self[gsSentHash]
    if(vDir:Length() == 0) then
      ErrorNoHalt("ENT.SetTorqueLever: Force lever invalid\n"); self:Remove(); return false end
    oSent.LevL = Vector() -- Local force lever ( Right )
    oSent.LevW = Vector() -- World force lever ( Right ) allocate memory
    oSent.ForL = Vector() -- Local force spin direction ( Forward )
    oSent.ForW = Vector() -- World force spin direction ( Forward ) allocate memory
    oSent.LevL:Set(vDir)  -- Right
    oSent.LevL:Mul(-1)    -- This is used to fix the orthogonality
    oSent.ForL:Set(oSent.LevL:Cross(oSent.AxiL)) -- Forward
    oSent.LevL:Set(oSent.ForL:Cross(oSent.AxiL))
    oSent.ForL:Normalize(); self:SetNWVector(gsSentHash.."_fdir",oSent.ForL);
    oSent.LevL:Normalize(); self:SetNWVector(gsSentHash.."_ldir",oSent.LevL); return true
  end

  function ENT:SetToggled(bTogg)
    local oSent = self[gsSentHash]; oSent.Togg = tobool(bTogg) or false
    self:SetNWBool(gsSentHash.."_togg", oSent.Togg) end

  function ENT:Setup(stSpinner)
    self:SetPhysRadius(stSpinner.Radi)         -- Set the radius if given
    local oPhys = self:GetPhysicsObject()
    if(oPhys and oPhys:IsValid()) then
      self:SetToggled(stSpinner.Togg)          -- Is it going to be toggled
      self:SetTorqueAxis(stSpinner.AxiL)       -- Axis direction
      self:SetPower(stSpinner.Power)           -- Torque amount
      self:SetTorqueLever(stSpinner.LevL)      -- Lever diraction
      self:SetLever(stSpinner.Lever)           -- Leverage lenght
      self:SetNWVector(gsSentHash.."_cen", oPhys:GetMassCenter())
      local oSpin = self[gsSentHash]
      local nMass = math.Clamp(tonumber(stSpinner.Mass) or 1, 1, gnMaxMass)
      oPhys:SetMass(nMass); oSpin.Mass = nMass -- Mass
      oSpin.Prop = stSpinner.Prop              -- Model
      oSpin.KeyF = stSpinner.KeyF              -- Forward spin key ( positive power )
      oSpin.KeyR = stSpinner.KeyR              -- Forward spin key ( negative power )
    else ErrorNoHalt("ENT.Setup: Physics invalid\n"); self:Remove(); return false end
    return true -- Everything is fine !
  end

  function ENT:Think()
    local wOn, wPw, wLe, wFr
    if(WireLib) then
      wOn = (tobool  (self.Inputs["On"   ].Value) or false)
      wPw = (tonumber(self.Inputs["Power"].Value) or 0)
      wLe = (tonumber(self.Inputs["Lever"].Value) or 0)
      wFr =           self.Inputs["Force"].Value
    end
    local oSent = self[gsSentHash]
    local On = wOn or oSent.On
    local oPhys = self:GetPhysicsObject()
    local vCn   = self:LocalToWorld(oPhys:GetMassCenter())
    if(oPhys and oPhys:IsValid()) then
      if(On) then
        local Pos = self:GetPos()
        local Ang  = self:GetAngles()
        local Pw  = ((wPw ~= 0) and wPw or oSent.Power) * oSent.Dir
        local Le  = ((wLe ~= 0) and wLe or oSent.Lever)
        local vPwt, vLvt = oSent.PowT, oSent.LevT
        local vFrw, vLvw, vAxw = oSent.ForW, oSent.LevW, oSent.AxiW
              vFrw:Set(oSent.ForL); vFrw:Rotate(Ang)
              vLvw:Set(oSent.LevL); vLvw:Rotate(Ang)
              vAxw:Set(oSent.AxiL); vAxw:Rotate(Ang)
        oPhys:ApplyForceOffset(getPower(vPwt, vFrw,  Pw), getLever(vLvt, vCn, vLvw,  Le))
        oPhys:ApplyForceOffset(getPower(vPwt, vFrw, -Pw), getLever(vLvt, vCn, vLvw, -Le))
        if(WireLib) then -- Take the downforce into account ( if given )
          if(wFr and wFr:Length() > 0) then oPhys:ApplyForceCenter(wFr) end end
      end
      if(WireLib) then
        WireLib.TriggerOutput(self,"RPM", oPhys:GetAngleVelocity():Dot(oSent.AxiL) / 6) end
    else ErrorNoHalt("ENT.Think: Physics invalid\n"); self:Remove(); end
    self:NextThink(CurTime() + oSent.Tick); return true
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


