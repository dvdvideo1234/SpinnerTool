--[[
 * Label    : The spinner sctipted entity
 * Author   : DVD ( dvd_video )
 * Date     : 13-03-2017
 * Location : /lua/entities/sent_spinner.lua
 * Requires : /lua/weapons/gmod_tool/stools/spinner.lua
 * Created  : Using tool requirement
 * Defines  : Advanced mortor scripted entity
]]--

local gsSentHash    = "sent_spinner"
local gsVectZero    = Vector()

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

function ENT:Initialize()
  self[gsSentHash] = {}
  self[gsSentHash].On   = false    -- Enable/disable working
  self[gsSentHash].Tick = 0        -- Entity ticking interval
  self[gsSentHash].Dir  = 0        -- Power sign for reverse support
  self[gsSentHash].PowT = Vector() -- Temporary power vector
  self[gsSentHash].LevT = Vector() -- Temporary lever vector
  self[gsSentHash].ForW = Vector() -- For force transformation to world
  self[gsSentHash].LevW = Vector() -- For Lever transformation to world
  self:PhysicsInit(SOLID_VPHYSICS)
  self:SetMoveType(MOVETYPE_VPHYSICS)
  self:SetSolid  (SOLID_VPHYSICS)
  local oPhys = self:GetPhysicsObject()
  if(oPhys and oPhys:IsValid()) then oPhys:Wake() end
  if (WireLib) then
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

if(SERVER) then

  local function getPower(vRes, vVec, nNum)
    vRes:Set(vVec); vRes:Mul(nNum); return vRes end

  local function getLever(vRes, vPos, vVec, nNum)
    vRes:Set(vVec); vRes:Mul(nNum); vRes:Add(vPos); return vRes end

  function ENT:SetPhysRadius(nRad)
    local nRad = (tonumber(nRad) or 0)
    if(nRad > 0) then
      oPhys = self:GetPhysicsObject()
      if(oPhys and oPhys:IsValid()) then
        self:PhysicsInitSphere(nRad)
        self:SetCollisionBounds(Vector(-nRad,-nRad,-nRad),Vector(nRad,nRad,nRad))
        oPhys:Wake()
      else ErrorNoHalt("SetRadiusPhysics: Phys invalid"); self:Remove(); return false; end
    end; return true
  end

  function ENT:SetPower(nPow)
    local oSent = self[gsSentHash] -- Magnitude of the spinning force
    oSent.Power = math.Clamp(((tonumber(nPow) or 0) / 2), -50000, 50000)
    self:SetNWFloat(gsSentHash.."_power", oSent.Power); return true
  end

  function ENT:SetLever(nLev)
    local oSent = self[gsSentHash] -- Magnitude of the spinning force
    oSent.Lever = math.Clamp((tonumber(nLev) or 0), 0, 50000)
    if(oSent.Lever == 0) then -- Use the half of the bounding box size
      vMin, vMax = oEnt:OBBMins(), oEnt:OBBMaxs()
      oSent.Lever = ((vMax - vMin):Length()) / 2
    end
    self:SetNWFloat(gsSentHash.."_lever", oSent.Lever); return true
  end

  function ENT:SetTorqueAxis(vDir)
    local oSent = self[gsSentHash]
    if(vDir:Length() == 0) then
      ErrorNoHalt("ENT.SetTorqueAxis: Spin axis invalid"); self:Remove(); return false end
    oSent.AxiL = Vector() -- Local spin axis ( Up )
    oSent.AxiL:Set(vDir); oSent.AxiL:Normalize()
    self:SetNWVector(gsSentHash.."_adir",oSent.AxiL); return true
  end

  function ENT:SetTorqueLever(vDir)
    local oSent = self[gsSentHash]
    if(vDir:Length() == 0) then
      ErrorNoHalt("ENT.SetTorqueLever: Force lever invalid"); self:Remove(); return false end
    oSent.LevL = Vector() -- Local force lever ( Right )
    oSent.ForL = Vector() -- Local force spin direction ( Forward )
    oSent.LevL:Set(vDir)  -- Right
    oSent.LevL:Mul(-1)
    oSent.ForL:Set(oSent.LevL:Cross(oSent.AxiL)) -- Forward
    oSent.LevL:Set(vFr:Cross(oSent.AxiL))
    oSent.ForL:Normalize(); self:SetNWVector(gsSentHash.."_fdir",oSent.ForL);
    oSent.LevL:Normalize(); self:SetNWVector(gsSentHash.."_ldir",oSent.LevL); return true
  end

  function ENT:Setup(stSpinner)
    local oPhys = self:GetPhysicsObject()
    -- Mass
    local nMass = math.Clamp(tonumber(stSpinner.Mass) or 0, 1, 50000)
    oPhys:SetMass(nMass); self[gsSentHash].Mass = nMass

  end

  function self:Think()
    local wOn, wPw, wLe, wFr
    if(WireLib) then
      wOn = (tobool  (self.Inputs["On"   ].Value) or false)
      wPw = (tonumber(self.Inputs["Power"].Value) or 0)
      wLe = (tonumber(self.Inputs["Lever"].Value) or 0)
      wFr =           self.Inputs["Force"].Value
    end
    local On = wOn or oSent.On
    if(On) then
      local oPhys = self:GetPhysicsObject()
      if(oPhys and oPhys:IsValid()) then
        local Pos = self:GetPos()
        local Ang = self:GetAngles()
        local oSent = self[gsSentHash]
        local Pw = ((wPw ~= 0) and (wPw / 2) or oSent.Power) * oSent.Dir
        local Le = (wLe ~= 0) and wLe       or oSent.Lever
        local vPwt, vLvt = oSent.PowT, oSent.LevT
        local vFrw, vLvw = oSent.ForW, oSent.LevW
              vFrw:Set(oSent.ForL); vFrw:Rotate(Ang)
              vLvw:Set(oSent.LevL); vLvw:Rotate(Ang)
        local vCn = oPhys:GetMassCenter(); vCn:Rotate(Ang); vCn:Add(Pos)
        oPhys:ApplyForceOffset(getPower(vPwt, vFrw,  Pw), getLever(vLvt, vCn, vLvw,  Le))
        oPhys:ApplyForceOffset(getPower(vPwt, vFrw, -Pw), getLever(vLvt, vCn, vLvw, -Le))
        if(WireLib) then
          if(wFr and wFr:Length() > 0) then oPhys:ApplyForceCenter(wFr) end
          local RPM = oPhys:GetAngleVelocity()
          WireLib.TriggerOutput(self,"RPM", self:Renew():Collect():Process():Control())
        end
      else ErrorNoHalt("ENT.Think: Physics invalid"); self:Remove(); end
    end
  end

  local function SpinForward(oPly, oEnt)
    if(not (oEnt and oEnt:IsValid())) then return end
    if(not (oEnt:GetClass() == gsSentHash)) then return end
    oEnt[gsSentHash].Dir = 1
    oEnt[gsSentHash].On  = true
  end

  local function SpinReverse(oPly, oEnt)
    if(not (oEnt and oEnt:IsValid())) then return end
    if(not (oEnt:GetClass() == gsSentHash)) then return end
    oEnt[gsSentHash].Dir = -1
    oEnt[gsSentHash].On  = true
  end

  local function SpinStop(oPly, oEnt)
    if(not (oEnt and oEnt:IsValid())) then return end
    if(not (oEnt:GetClass() == gsSentHash)) then return end
    oEnt[gsSentHash].Dir = 0
    oEnt[gsSentHash].On  = false
  end

  numpad.Register(gsSentHash.."_SpinForward_On" , SpinForward)
  numpad.Register(gsSentHash.."_SpinForward_Off", SpinStop)
  numpad.Register(gsSentHash.."_SpinReverse_On" , SpinReverse)
  numpad.Register(gsSentHash.."_SpinReverse_Off", SpinStop)

end


