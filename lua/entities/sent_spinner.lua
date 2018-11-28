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

local sysNow       = SysTime
local curNow       = CurTime
local gsSentHash   = "sent_spinner"
local gsSentName   = gsSentHash:gsub("sent_","")
local varMaxScale  = GetConVar("sbox_max"..gsSentName.."_scale")
local varMaxMass   = GetConVar("sbox_max"..gsSentName.."_mass")
local varMaxRadius = GetConVar("sbox_max"..gsSentName.."_radius")
local varBroadCast = GetConVar("sbox_max"..gsSentName.."_broad")
local varTickRate  = GetConVar("sbox_max"..gsSentName.."_tick")
local varRemoveER  = GetConVar("sbox_en" ..gsSentName.."_remerr")
local varEnableWT  = GetConVar("sbox_en" ..gsSentName.."_wdterr")
local varEnableDT  = GetConVar("sbox_en" ..gsSentName.."_timdbg")

ENT.Type            = "anim"
if (WireLib) then
  ENT.Base          = "base_wire_entity"
  ENT.WireDebugName = gsSentName:gsub("^%l",string.upper)
else
  ENT.Base          = "base_gmodentity"
end
ENT.PrintName       = gsSentName:gsub("^%l",string.upper)
ENT.Author          = "DVD"
ENT.Contact         = "dvd_video@abv.bg"
ENT.Editable        = true
ENT.Spawnable       = false
ENT.AdminSpawnable  = false

local function getSign(nN)
  return (nN / math.abs(nN))
end

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
  elseif(CLIENT) then return self:GetNWBool(gsSentHash.."_togg") end
end

if(SERVER) then
  -- Represents the arguments of ENT:BroadCast()
  local gtBroadCast = {
    [1] = {"SetNWFloat", gsSentHash.."_power", 0},
    [2] = {"SetNWFloat", gsSentHash.."_lever", 0}
  }
  -- Used for rate array output
  local gtRateMap = {
    [1]  = {"bcTot", 1000},
    [2]  = {"bcTim", 1000},
    [3]  = {"eTick", 1000},
    [4]  = {"thTim", 1000},
    [5]  = {"thEvt", 1000},
    [6]  = {"thDet", 1.00}
  }
  --[[
   * User sets the desired times in [ms] and the entity converts them to seconds
   * As it handles the times divides all input times by 1000 to convert [ms] to [s]
  ]]--
  function ENT:GetRateMap()
    local tmRate = self[gsSentHash].Rate
    local mpTime = tmRate.mpTim
    for ID = 1, #gtRateMap do
      local set = gtRateMap[ID]
      mpTime[ID] = (tmRate[set[1]] * set[2])
    end; return mpTime
  end

  function ENT:SetError(sMsg)
    local oSent  = self[gsSentHash]
    local idSent = ": ["..self:EntIndex().."]["..gsSentHash.."]"
    ErrorNoHalt(idSent..tostring(sMsg or "N/A"))
    if(oSent.IsERM) then self:Remove() end
  end

  function ENT:Initialize()
    self[gsSentHash] = {}; local oSent = self[gsSentHash]
    oSent.Dir  = 0        -- Power sign for reverse support
    oSent.CLev = 0        -- How many spinner levers do we have (allocate)
    oSent.Radi = 0        -- Collision radius
    oSent.DAng = 0        -- Store the angle delta to avoid calculating it every frame on SV
    oSent.Rate = {}       -- This holds the time rates for the entity
    oSent.Rate.bcTot = (varBroadCast:GetFloat() / 1000) -- Broadcast time sever-clients [ms] to [s]
    oSent.Rate.bcTim = (varBroadCast:GetFloat() / 1000) -- Broadcast compare value      [ms] to [s]
    oSent.Rate.eTick = (varTickRate:GetFloat()  / 1000) -- Entity ticking interval      [ms] to [s]
    oSent.Rate.thStO = 0 -- The time between each tick start (OLD) [s]
    oSent.Rate.thStN = 0 -- The time between each tick start (NEW) [s]
    oSent.Rate.thEnd = 0 -- The time when a tick exactly ends. Algorithm completion [s]
    oSent.Rate.thTim = 0 -- How much time does the think stuff requite (thEnd - thStO) [s]
    oSent.Rate.thEvt = 0 -- How much time does the think event requite (thStN - thStO) [s]
    oSent.Rate.thDet = 0 -- Tick duty cycle (thTim / thEvt * 100) []
    oSent.Rate.isRdy = false -- Initialization flag. Dropped on the second think
    oSent.Rate.isWDT = varEnableWT:GetBool() -- Translate SENT watchdog to an error
    oSent.Rate.mpTim = {} -- Here the debugging times are stored
    oSent.IsERM = varRemoveER:GetBool() -- Whenever to remove the entity on error
    oSent.IsTDB = varEnableDT:GetBool() -- Enables the tick rate system array output
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
        "Axis",
        (oSent.IsTDB and "Rate" or nil)
      }, { "NORMAL", "VECTOR", (oSent.IsTDB and "ARRAY" or nil)}, {
        " Revolutions per minute ",
        " Spinner rotation axis ",
        (oSent.IsTDB and " Benchmark times and events " or nil)
      })
    end; return true
  end

  local function getPower(vRes, vVec, nNum)
    vRes:Set(vVec); vRes:Mul(nNum); return vRes end

  local function getLever(vRes, vPos, vVec, nNum)
    vRes:Set(vVec); vRes:Mul(nNum); vRes:Add(vPos); return vRes end

  function ENT:SetPhysRadius(nRad)
    local nRad = math.Clamp(tonumber(nRad) or 0, 0, varMaxRadius:GetFloat())
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
    oSent.Power = math.Clamp((tonumber(nPow) or 0), -varMaxScale:GetFloat(), varMaxScale:GetFloat())
    self:SetNWFloat(gsSentHash.."_power", oSent.Power); return true
  end

  function ENT:SetLever(nLev)
    local oSent = self[gsSentHash] -- Magnitude of the spinning force
    oSent.Lever = math.Clamp((tonumber(nLev) or 0), 0, varMaxScale:GetFloat())
    if(oSent.Lever == 0) then -- Use the half of the bounding box size
      vMin, vMax = self:OBBMins(), self:OBBMaxs()
      oSent.Lever = ((vMax - vMin):Length()) / 2
    end
    self:SetNWFloat(gsSentHash.."_lever", oSent.Lever); return true
  end

  function ENT:SetTorqueAxis(vDir)
    local oSent = self[gsSentHash]
    if(vDir:Length() == 0) then
      self:SetError("ENT.SetTorqueAxis: Axis invalid"); return false end
    oSent.AxiL:Set(vDir); oSent.AxiL:Normalize()
    self:SetNWVector(gsSentHash.."_adir",oSent.AxiL); return true
  end

  function ENT:SetTorqueLever(vDir, nCnt)
    local oSent = self[gsSentHash]
    local nCnt  = (tonumber(nCnt) or 0); if(nCnt <= 0) then
      self:SetError("ENT.SetTorqueLever: Lever count invalid"); return false end
    if(vDir:Length() == 0) then
      self:SetError("ENT.SetTorqueLever: Force lever invalid"); return false end
    oSent.CLev, oSent.DAng = nCnt, (360 / nCnt)
    oSent.LevL:Set(vDir) -- Lever direction matched to player right
    oSent.ForL:Set(oSent.AxiL:Cross(oSent.LevL)) -- Force
    oSent.LevL:Set(oSent.ForL:Cross(oSent.AxiL)) -- Lever
    oSent.ForL:Normalize(); oSent.LevL:Normalize()
    self:SetNWInt(gsSentHash.."_lcnt",oSent.CLev)
    self:SetNWVector(gsSentHash.."_ldir",oSent.LevL); return true
  end

  function ENT:SetToggled(bTogg)
    local oSent = self[gsSentHash]; oSent.Togg = tobool(bTogg or false)
    self:SetNWBool(gsSentHash.."_togg", oSent.Togg)
  end

  function ENT:ApplyTweaks()
    local oSent  = self[gsSentHash]
    oSent.IsERM = varRemoveER:GetBool() -- Whenever to remove the entity on error
    oSent.IsTDB = varEnableDT:GetBool() -- Enables the tick rate system array output
    oSent.Rate.isWDT = varEnableWT:GetBool() -- Translate SENT watchdog to an error
    oSent.Rate.bcTot = (varBroadCast:GetFloat() / 1000) -- Broadcast time sever-clients [ms] to [s]
    oSent.Rate.bcTim = (varBroadCast:GetFloat() / 1000) -- Broadcast compare value      [ms] to [s]
    oSent.Rate.eTick = (varTickRate:GetFloat()  / 1000) -- Entity ticking interval      [ms] to [s]
  end

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
      local nMass = math.Clamp(tonumber(stSpinner.Mass) or 1, 1, varMaxMass:GetFloat())
      oPhys:SetMass(nMass); oSent.Mass = nMass -- Mass
      oSent.Prop = stSpinner.Prop              -- Model
      oSent.KeyF = stSpinner.KeyF              -- Forward spin key ( positive power )
      oSent.KeyR = stSpinner.KeyR              -- Forward spin key ( negative power )
    else self:SetError("ENT.Setup: Physics invalid"); return false end
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
    WireLib.TriggerOutput(self, sOut, anyVal); return self
  end

  function ENT:Tic()
    local tmRate = self[gsSentHash].Rate
    self:NextThink(curNow() + tmRate.eTick) -- Prepare the next think [s]
    tmRate.thStO = tmRate.thStN     -- The tick start time gets older [s]
    tmRate.thStN = sysNow()         -- Read the new think start time [s]
    if(tmRate.isRdy) then           -- When rate structure is initialized
      tmRate.thEvt = (tmRate.thStN - tmRate.thStO) -- Think event delta [s]
      tmRate.thTim = (tmRate.thEnd - tmRate.thStO) -- Think hook delta [s]
      tmRate.thDet = (tmRate.thTim / tmRate.thEvt) * 100 -- Think duty margin []
      if(tmRate.thTim >= tmRate.thEvt and tmRate.isWDT) then -- Watchdog error
        self:SetError("ENT.Tic: Duty margin fail ["..tostring(tmRate.thDet).."%]") end
      tmRate.bcTim = tmRate.bcTim - tmRate.thEvt         -- Update broadcast time [s]
    end
  end

  function ENT:Toc()
    local tmRate = self[gsSentHash].Rate
    tmRate.thEnd = sysNow()
    if(not tmRate.isRdy) then tmRate.isRdy = true end
    return self
  end

  function ENT:BroadCast(...)
    local tmRate = self[gsSentHash].Rate
    if(tmRate.bcTim <= 0) then
      local arList = {...}               -- Values stack for networking
      for ID = 1, #gtBroadCast do        -- Go trough all like a list
        local set = gtBroadCast[ID]      -- Get broadcaster setup
        local val = arList[ID] or set[3] -- Take current or default when empty
        local foo, key = set[1], set[2]  -- Get the broadcast pair values
        self[foo](self, key, val)        -- Send to the client the value given
      end; tmRate.bcTim = tmRate.bcTot
    end; return self
  end

  function ENT:Think() self:Tic()
    local nPw, nLe, wFr, wLe, wPw
    local oSent = self[gsSentHash]
    local oPhys = self:GetPhysicsObject()
    if(oPhys and oPhys:IsValid()) then
      local vCn = self:LocalToWorld(oPhys:GetMassCenter())
      if(WireLib) then
        local wOn = self:ReadWire("On")
              wPw = self:ReadWire("Power")
              wLe = self:ReadWire("Lever")
              wFr = self:ReadWire("Force")
        if(wOn ~= nil) then oSent.On = (wOn ~= 0) end -- On connected toggle with wire
      end -- Remember internal settings for lever and power when wire is disconnected
      if(oSent.On) then -- Disable toggling via numpad if wire is connected
        local vPwt, vLvt, eAng = oSent.PowT, oSent.LevT, self:GetAngles()
        local vLew, vAxw, aLev = oSent.LevW, oSent.AxiW, oSent.LAng
        nLe = (wLe and wLe or  oSent.Lever) -- Do not wipe internals in disconnect
        nPw = (wPw and wPw or (oSent.Power * oSent.Dir))
        vAxw:Set(oSent.AxiL); vAxw:Rotate(eAng)
        vLew:Set(oSent.LevL); vLew:Rotate(eAng)
        aLev:Set(vLew:AngleEx(vAxw))
        for ID = 1, oSent.CLev do
          local vL, vF = aLev:Forward(), aLev:Right(); vF:Mul(-1)
          oPhys:ApplyForceOffset(getPower(vPwt, vF, nPw), getLever(vLvt, vCn, vL, nLe))
          aLev:RotateAroundAxis(vAxw, oSent.DAng)
        end
        if(WireLib) then -- Take the down-force into account ( if given )
          if(wFr and wFr:Length() > 0) then oPhys:ApplyForceCenter(wFr) end
          self:WriteWire("Axis", vAxw)
        end
      end
      if(WireLib) then
        self:WriteWire("RPM", oPhys:GetAngleVelocity():Dot(oSent.AxiL) / 6) end
    else self:SetError("ENT.Think: Physics invalid"); end
    if(WireLib and oSent.IsTDB) then
      self:WriteWire("Rate", self:GetRateMap()) end
    nPw, nLe = (wPw and wPw or oSent.Power), (wLe and wLe or oSent.Lever)
    self:BroadCast(nPw, nLe):Toc(); return true
  end

  local function spinForward(oPly, oEnt)
    if(not (oEnt and oEnt:IsValid())) then return end
    if(not (oEnt:GetClass() == gsSentHash)) then return end
    local oSent = oEnt[gsSentHash]
    if(oEnt:IsToggled()) then
      if(oSent.Dir ~= 0) then
           oSent.On, oSent.Dir = false, 0
      else oSent.On, oSent.Dir = true , 1 end
    else
      oSent.On, oSent.Dir = true, 1
    end
  end

  local function spinReverse(oPly, oEnt)
    if(not (oEnt and oEnt:IsValid())) then return end
    if(not (oEnt:GetClass() == gsSentHash)) then return end
    local oSent = oEnt[gsSentHash]
    if(oEnt:IsToggled()) then
      if(oSent.Dir ~= 0) then
           oSent.On, oSent.Dir = false,  0
      else oSent.On, oSent.Dir = true , -1 end
    else
      oSent.On, oSent.Dir = true, -1
    end
  end

  local function spinStop(oPly, oEnt)
    if(not (oEnt and oEnt:IsValid())) then return end
    if(not (oEnt:GetClass() == gsSentHash)) then return end
    local oSent = oEnt[gsSentHash]
    if(not oEnt:IsToggled()) then
      oSent.On, oSent.Dir = false, 0
    end
  end

  numpad.Register(gsSentHash.."_spinForward_On" , spinForward)
  numpad.Register(gsSentHash.."_spinForward_Off", spinStop)
  numpad.Register(gsSentHash.."_spinReverse_On" , spinReverse)
  numpad.Register(gsSentHash.."_spinReverse_Off", spinStop)

end
