--[[
 * Label    : The spinner tool script
 * Author   : DVD ( dvd_video )
 * Date     : 13-03-2017
 * Location : /lua/weapons/gmod_tool/stools/spinner.lua
 * Requires : /lua/entities/sent_spinner.lua
 * Created  : Using tool requirement
 * Defines  : Spinner manager script
]]--
print("SPINNER:",SysTime())

local gsSentHash   = "sent_spinner"
local gsSentName   = gsSentHash:gsub("sent_","")
local gnVarFlags = bit.bor(FCVAR_ARCHIVE, FCVAR_ARCHIVE_XBOX, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)
local varMaxScale  = CreateConVar("sbox_max"..gsSentName.."_scale" , 50000, gnVarFlags, "Maximum scale for power and lever")
local varMaxMass   = CreateConVar("sbox_max"..gsSentName.."_mass"  , 50000, gnVarFlags, "The maximum mass the entity can have")
local varMaxRadius = CreateConVar("sbox_max"..gsSentName.."_radius", 1000, gnVarFlags, "Maximum radius when rebuilding the collision model as sphere")
local varBroadCast = CreateConVar("sbox_max"..gsSentName.."_broad" , 300, gnVarFlags, "Maximum time [ms] when reached the think method sends client stuff")
local varTickRate  = CreateConVar("sbox_max"..gsSentName.."_tick" , 5, gnVarFlags, "Maximum sampling time [ms] when the spinner is activated. Be careful!")

local gnRatio      = 1.61803398875
local gsToolName   = gsSentName
local gsToolNameU  = gsToolName.."_"
local gsEntLimit   = gsSentName.."s"
local gnMaxLin     = 1000
local gnMaxAng     = 360
local VEC_ZERO     = Vector()
local ANG_ZERO     = Angle ()
local gtPalette    = {}
      gtPalette["w"]  = Color(255,255,255,255)
      gtPalette["r"]  = Color(255, 0 , 0 ,255)
      gtPalette["g"]  = Color( 0 ,255, 0 ,255)
      gtPalette["b"]  = Color( 0 , 0 ,255,255)
      gtPalette["k"]  = Color( 0 , 0 , 0 ,255)
      gtPalette["m"]  = Color(255, 0 ,255,255)
      gtPalette["y"]  = Color(255,255, 0 ,255)
      gtPalette["c"]  = Color( 0 ,255,255,255)
      gtPalette["gh"] = Color(255,255,255,200)


if(SERVER) then

  CreateConVar("sbox_max"..gsEntLimit, 5, FCVAR_NOTIFY, "Maximum spinners to be spawned")

  cleanup.Register(gsEntLimit)

  local function onRemove(self, down, up)
    numpad.Remove(down)
    numpad.Remove(up)
  end

  function newSpinner(oPly,vPos,aAng,stSpinner)
    if(not oPly:CheckLimit(gsEntLimit)) then return nil end
    local eSpin = ents.Create(gsSentHash)
    if(not (eSpin and eSpin:IsValid())) then return nil end
    eSpin:SetCollisionGroup(COLLISION_GROUP_NONE)
    eSpin:SetSolid(SOLID_VPHYSICS)
    eSpin:SetMoveType(MOVETYPE_VPHYSICS)
    eSpin:SetNotSolid(false)
    eSpin:SetModel(stSpinner.Prop)
    eSpin:SetPos(vPos or VEC_ZERO)
    eSpin:SetAngles(aAng or ANG_ZERO)
    eSpin:PhysWake()
    eSpin:Spawn()
    eSpin:Activate()
    eSpin:SetRenderMode(RENDERMODE_TRANSALPHA)
    eSpin:SetColor(Color(255,255,255,255))
    eSpin:DrawShadow(true)
    eSpin:CallOnRemove(gsToolNameU.."NumpadCleanup", onRemove,
      numpad.OnDown(oPly, stSpinner.KeyF , gsSentHash.."_spinForward_On" , eSpin ),
      numpad.OnUp  (oPly, stSpinner.KeyF , gsSentHash.."_spinForward_Off", eSpin ),
      numpad.OnDown(oPly, stSpinner.KeyR , gsSentHash.."_spinReverse_On" , eSpin ),
      numpad.OnUp  (oPly, stSpinner.KeyR , gsSentHash.."_spinReverse_Off", eSpin ))
    if(not eSpin:Setup(stSpinner)) then eSpin:Remove(); return nil end
    eSpin.owner = oPly -- Some SPPs actually use this value. And ownership below
    oPly:AddCount(gsEntLimit , eSpin); oPly:AddCleanup(gsEntLimit , eSpin)
    return eSpin
  end

  duplicator.RegisterEntityClass(gsSentHash, newSpinner, "Pos", "Ang", gsSentHash)

end

if(CLIENT) then
  TOOL.Information = {
    { name = "info",  stage = 1   },
    { name = "left"         },
    { name = "right"        },
    { name = "reload"       }
  }
  language.Add("tool."..gsToolName..".left"     , "Create/Update spinner")
  language.Add("tool."..gsToolName..".right"    , "Copy settings")
  language.Add("tool."..gsToolName..".reload"   , "Remove spinner")
  language.Add("tool."..gsToolName..".category" , "Construction")
  language.Add("tool."..gsToolName..".name"     , "Spinner tool")
  language.Add("tool."..gsToolName..".desc"     , "Creates/updates a spinner entity")
  concommand.Add(gsToolNameU.."resetoffs", function(oPly,oCom,oArgs)
    oPly:ConCommand(gsToolNameU.."linx 0\n")
    oPly:ConCommand(gsToolNameU.."liny 0\n")
    oPly:ConCommand(gsToolNameU.."linz 0\n")
    oPly:ConCommand(gsToolNameU.."angp 0\n")
    oPly:ConCommand(gsToolNameU.."angy 0\n")
    oPly:ConCommand(gsToolNameU.."angr 0\n")
  end)
end

TOOL.Category   = language and language.GetPhrase("tool."..gsToolName..".category")
TOOL.Name       = language and language.GetPhrase("tool."..gsToolName..".name")
TOOL.Command    = nil -- Command on click (nil for default)
TOOL.ConfigName = nil -- Configure file name (nil for default)

TOOL.ClientConVar = {
  ["mass"      ] = "300",
  ["linx"      ] = "0",
  ["liny"      ] = "0",
  ["linz"      ] = "0",
  ["angp"      ] = "0",
  ["angy"      ] = "0",
  ["angr"      ] = "0",
  ["ghosting"  ] = "1",
  ["model"     ] = "models/props_phx/trains/tracks/track_1x.mdl",
  ["friction"  ] = "0",
  ["forcelim"  ] = "0",
  ["torqulim"  ] = "0",
  ["keyfwd"    ] = "45",
  ["keyrev"    ] = "39",
  ["lever"     ] = "10",
  ["levercnt"  ] = "2",
  ["power"     ] = "100",     -- Power of the spinner the bigger the faster
  ["radius"    ] = "0",       -- Radius if bigger than zero circular collision is used
  ["toggle"    ] = "0",       -- Remain in a spinning state when the numpad is released
  ["diraxis"   ] = "0",       -- Axis  direction ID matched to /pComboAxis/
  ["dirlever"  ] = "0",       -- Lever direction ID matched to /pComboLever/
  ["adviser"   ] = "1",       -- Enabled drawing the coordinates of the props or spinner parameters
  ["nocollide" ] = "0",       -- Enagled creates a no-collision constraint between it and trace
  ["constraint"] = "0",       -- Constraint type matched to /pComboConst/
  ["cusaxis"   ] = "[0,0,0]", -- Local custom spin axis vector
  ["cuslever"  ] = "[0,0,0]"  -- Local custom leverage vector
}

local function getVector(sV)
  local v = string.Explode(",",tostring(sV or ""):gsub("%[",""):gsub("%]",""))
  return Vector(tonumber(v[1]) or 0, tonumber(v[2]) or 0, tonumber(v[3]) or 0)
end

local function strVector(vV)
  return "["..tostring(vV.x or 0)..","..tostring(vV.y or 0)..","..tostring(vV.z or 0).."]"
end

local gtDirectionID = {}
      gtDirectionID[1] = Vector( 1, 0, 0)
      gtDirectionID[2] = Vector( 0, 1, 0)
      gtDirectionID[3] = Vector( 0, 0, 1)
      gtDirectionID[4] = Vector(-1, 0, 0)
      gtDirectionID[5] = Vector( 0,-1, 0)
      gtDirectionID[6] = Vector( 0, 0,-1)

local function GetDirectionID(nID)
  return gtDirectionID[(tonumber(nID) or 0)] or Vector()
end

function TOOL:GetDeviation()
  return Vector(math.Clamp(self:GetClientNumber("linx"),-gnMaxLin,gnMaxLin),
                math.Clamp(self:GetClientNumber("liny"),-gnMaxLin,gnMaxLin),
                math.Clamp(self:GetClientNumber("linz"),-gnMaxLin,gnMaxLin)),
         Angle (math.Clamp(self:GetClientNumber("angp"),-gnMaxAng,gnMaxAng),
                math.Clamp(self:GetClientNumber("angy"),-gnMaxAng,gnMaxAng),
                math.Clamp(self:GetClientNumber("angr"),-gnMaxAng,gnMaxAng))
end

function TOOL:GetCustomAxis()
  return getVector(self:GetClientInfo("cusaxis"))
end

function TOOL:GetLeverCount()
  return math.floor(math.Clamp(self:GetClientNumber("levercnt"), 1, gnMaxAng))
end

function TOOL:GetCustomLever()
  return getVector(self:GetClientInfo("cuslever"))
end

function TOOL:GetGhosting()
  return tobool(self:GetClientNumber("ghosting") or false)
end

function TOOL:GetMass()
  return math.Clamp(self:GetClientNumber("mass"),1,varMaxMass:GetFloat())
end

function TOOL:GetToggle()
  return tobool(self:GetClientNumber("toggle") or false)
end

function TOOL:GetPower()
  return math.Clamp(self:GetClientNumber("power"),-varMaxScale:GetFloat(),varMaxScale:GetFloat())
end

function TOOL:GetFriction()
  return math.Clamp(self:GetClientNumber("friction"),0,varMaxScale:GetFloat())
end

function TOOL:GetForceLimit()
  return math.Clamp(self:GetClientNumber("forcelim"),0,varMaxScale:GetFloat())
end

function TOOL:GetTorqueLimit()
  return math.Clamp(self:GetClientNumber("torqulim"),0,varMaxScale:GetFloat())
end

function TOOL:GetRadius()
  return math.Clamp(self:GetClientNumber("radius"),0,varMaxRadius:GetFloat())
end

function TOOL:GetLever()
  return math.Clamp(self:GetClientNumber("lever"),0,varMaxScale:GetFloat())
end

function TOOL:GetModel()
  return (self:GetClientInfo("model") or "")
end

function TOOL:GetKeys()
  return math.floor(math.Clamp(self:GetClientNumber("keyfwd"),0,255)),
         math.floor(math.Clamp(self:GetClientNumber("keyrev"),0,255))
end

function TOOL:GetAdviser()
  return tobool(self:GetClientNumber("adviser") or false)
end

function TOOL:GetDirectionID()
  return math.floor(math.Clamp((self:GetClientNumber("diraxis" ) or 0), 0, 6)),
         math.floor(math.Clamp((self:GetClientNumber("dirlever") or 0), 0, 6))
end

function TOOL:GetNoCollide()
  return tobool(self:GetClientNumber("nocollide") or false)
end

function TOOL:GetConstraint()
  return math.floor(math.Clamp(tonumber(self:GetClientNumber("constraint")) or 0,0,4))
end

function TOOL:GetVectors()
  local vA, vL = Vector(), Vector()
  local daxs, dlev = self:GetDirectionID()
  if(daxs == 0) then vA:Set(self:GetCustomAxis())
  else               vA:Set(GetDirectionID(daxs)) end
  if(dlev == 0) then vL:Set(self:GetCustomLever())
  else               vL:Set(GetDirectionID(dlev)) end
  vA:Normalize(); vL:Normalize(); return vA, vL
end

-- Recalculates the orientation based on the spin axis and lever axis
-- Updates force, lever and spin axises to be orthogonal to each other
-- vA  >> Local vector of the spin axis
-- vL  >> Local vector of the lever axis
function TOOL:RecalculateUCS(vA, vL)
  local cF = vA:Cross(vL)
  local cL = cF:Cross(vA)
  local cA = cL:Cross(cF)
  cF:Normalize(); cL:Normalize(); cA:Normalize()
  return cF, cL, cA
end

-- Updates direction of the spin axis and lever
function TOOL:UpdateVectors(stSpinner)
  local vF, vL, vA = self:RecalculateUCS(self:GetVectors())
  if(daxs ~= 0 and dlev ~= 0 and -- Do not spawn with invalid user axises
    math.abs(vA:Dot(vL)) > 0.01) then
    ErrorNoHalt("TOOL:UpdateVectors: Spinner axis not orthogonal to lever\n"); return false end
  if(not (type(vA) == "Vector")) then
    ErrorNoHalt("TOOL:UpdateVectors: Spinner axis missing <"..tostring(vA)..">\n"); return false end
  if(not (type(vL) == "Vector")) then
    ErrorNoHalt("TOOL:UpdateVectors: Spinner lever missing <"..tostring(vL)..">\n"); return false end
  if(vA:Length() == 0) then
    ErrorNoHalt("TOOL:UpdateVectors: Spinner axis zero\n"); return false end
  if(vL:Length() == 0) then
    ErrorNoHalt("TOOL:UpdateVectors: Spinner lever zero\n"); return false end
  stSpinner.AxiL, stSpinner.LevL = vA, vL; return true
end

-- Returns the hit-normal spawn position and orientation
function TOOL:ApplySpawn(oEnt, stTrace)
  if(not (oEnt and oEnt:IsValid())) then return false end
  if(not stTrace.Hit) then oEnt:Remove() return false end
  local oPos, oAng   = self:GetDeviation()
  local oPly, trNorm = self:GetOwner(), stTrace.HitNormal
  local vPos, aAng, lAxs, lLev = Vector(), Angle(), self:GetVectors()
  local lAng, vOBB = (lAxs:Cross(lLev):AngleEx(lAxs)), oEnt:OBBMins()
  aAng:Set(oEnt:AlignAngles(oEnt:LocalToWorldAngles(lAng + oAng),
           trNorm:Cross(oPly:GetRight()):AngleEx(trNorm)))
  vPos:Set(stTrace.HitPos);
  vPos:Add((math.abs(vOBB:Dot(lAxs))) * trNorm)
  vPos:Add(oPos.x * aAng:Forward())
  vPos:Add(oPos.y * aAng:Right())
  vPos:Add(oPos.z * aAng:Up())
  aAng:Normalize(); oEnt:SetPos(vPos); oEnt:SetAngles(aAng); return true
end

-- Creates a constant between spinner and trace
function TOOL:Constraint(eSpin, stTrace)
  local trEnt = stTrace and stTrace.Entity
  if(trEnt and trEnt:IsValid()) then
    local ncon = self:GetConstraint()
    local bcol = self:GetNoCollide()
    local nfor = self:GetForceLimit()
    local ntor = self:GetTorqueLimit()
    local nfri = self:GetFriction()
    local hpos = stTrace.HitPos
    local nbon = stTrace.PhysicsBone
    local vnrm = 1000 * stTrace.HitNormal -- Keep it long to avoid surface displacement
    if(ncon == 0 and bcol) then -- NoCollide
      local C = constraint.NoCollide(eSpin,trEnt,0,nbon)
      if(C) then eSpin:DeleteOnRemove(C); trEnt:DeleteOnRemove(C); return C end
    elseif(ncon == 1) then -- Weld
      local C = constraint.Weld(eSpin,trEnt,0,nbon,nfor,bcol,false)
      if(C) then eSpin:DeleteOnRemove(C); trEnt:DeleteOnRemove(C); return C end
    elseif(ncon == 2) then -- Axis
      local LPos1 = eSpin:GetPhysicsObject():GetMassCenter()
            LPos2 = trEnt:WorldToLocal((eSpin:LocalToWorld(LPos1) + vnrm))
      local C = constraint.Axis(eSpin,trEnt,0,nbon,LPos1,LPos2,nfor,ntor,nfri,(bcol and 1 or 0))
      if(C) then eSpin:DeleteOnRemove(C); trEnt:DeleteOnRemove(C); return C end
    elseif(ncon == 3) then -- Ball ( At the center of the spinner )
      local L = eSpin:GetPhysicsObject():GetMassCenter()
      local C = constraint.Ballsocket(trEnt,eSpin,nbon,0,L,nfor,ntor,(bcol and 1 or 0))
      if(C) then eSpin:DeleteOnRemove(C); trEnt:DeleteOnRemove(C); return C end
    elseif(ncon == 4) then -- Ball ( At the center of the base )
      local L = trEnt:WorldToLocal(hpos)
      local C = constraint.Ballsocket(eSpin,trEnt,nbon,0,L,nfor,ntor,(bcol and 1 or 0))
      if(C) then eSpin:DeleteOnRemove(C); trEnt:DeleteOnRemove(C); return C end
    else return false end
  end; return false
end

function TOOL:LeftClick(stTrace)
  if(CLIENT) then return true end
  if(not stTrace.Hit) then return true end
  local stSpinner = {}
  local ply       = self:GetOwner()
  stSpinner.Mass  = self:GetMass()
  stSpinner.Prop  = self:GetModel()
  stSpinner.Power = self:GetPower()
  stSpinner.Lever = self:GetLever()
  stSpinner.Togg  = self:GetToggle()
  stSpinner.Radi  = self:GetRadius()
  stSpinner.CLev  = self:GetLeverCount()
  stSpinner.KeyF, stSpinner.KeyR = self:GetKeys()
  local trEnt = stTrace.Entity
  if(stTrace.HitWorld) then
    if(not self:UpdateVectors(stSpinner)) then return false end
    local vPos   = stTrace.HitPos
    local aAng   = stTrace.HitNormal:Angle()
          aAng:RotateAroundAxis(aAng:Right(), 90)
          aAng = (aAng + (stSpinner.AxiL:Cross(stSpinner.LevL)):AngleEx(stSpinner.AxiL))
          aAng:Normalize()
    local eSpin = newSpinner(ply, vPos, aAng, stSpinner)
    if(eSpin) then
      self:ApplySpawn(eSpin, stTrace)
      undo.Create("Spinner")
        undo.AddEntity(eSpin)
        undo.SetCustomUndoText("Spinner spawn")
        undo.SetPlayer(ply)
      undo.Finish(); return true
    end
  else
    if(trEnt and trEnt:IsValid()) then
      if(not self:UpdateVectors(stSpinner)) then return false end
      if(trEnt:GetClass() == gsSentHash) then
        stSpinner.Radi = 0; trEnt:Setup(stSpinner) -- Do not recreate the physics on update
        ply:SendLua("GAMEMODE:AddNotify(\"Spinner updated !\", NOTIFY_UNDO, 6)")
        ply:SendLua("surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")")
        return true
      end
      local vPos = stTrace.HitPos
      local aAng = stTrace.HitNormal:Angle()
            aAng:RotateAroundAxis(aAng:Right(), 90)
            aAng = aAng + (stSpinner.AxiL:Cross(stSpinner.LevL)):AngleEx(stSpinner.AxiL)
      local eSpin  = newSpinner(ply, vPos, aAng, stSpinner)
      if(eSpin) then
        self:ApplySpawn(eSpin, stTrace)
        local C = self:Constraint(eSpin, stTrace)
        undo.Create("Spinner")
          undo.AddEntity(eSpin)
          if(C) then undo.AddEntity(C) end
          undo.SetCustomUndoText("Spinner linked")
          undo.SetPlayer(ply)
        undo.Finish(); return true
      end
    end
  end
end

function TOOL:RightClick(stTrace)
  if(CLIENT) then return true end
  if(not stTrace.Hit) then return true end
  local trEnt = stTrace.Entity
  if(trEnt and trEnt:IsValid()) then
    local ply = self:GetOwner()
    local cls = trEnt:GetClass()
    if(cls == "prop_physics") then
      local sPth = string.GetFileFromFilename(trEnt:GetModel())
      local vPos = trEnt:GetPos()
      local sAxs = strVector(trEnt:WorldToLocal(vPos + stTrace.HitNormal))
      local sLvr = strVector(trEnt:WorldToLocal(vPos + ply:GetRight()))
      ply:ConCommand(gsToolNameU.."cusaxis " ..sAxs.."\n") -- Vector as string
      ply:ConCommand(gsToolNameU.."cuslever "..sLvr.."\n") -- Vector as string
      ply:ConCommand(gsToolNameU.."model "   ..trEnt:GetModel().."\n")
      ply:SendLua("GAMEMODE:AddNotify(\"Model: "..sPth.." selected !\", NOTIFY_UNDO, 6)")
      ply:SendLua("surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")"); return true
    elseif(cls == gsSentHash) then
      local phEnt = trEnt:GetPhysicsObject()
      ply:ConCommand(gsToolNameU.."power "   ..tostring(trEnt:GetPower()).."\n") -- Number
      ply:ConCommand(gsToolNameU.."lever "   ..tostring(trEnt:GetLever()).."\n") -- Number
      ply:ConCommand(gsToolNameU.."levercnt "..tostring(trEnt:GetLeverCount()).."\n") -- Number
      ply:ConCommand(gsToolNameU.."toggle "  ..tostring(trEnt:IsToggled() and 1 or 0).."\n")
      ply:ConCommand(gsToolNameU.."mass "    ..tostring(phEnt:GetMass()).."\n")
      ply:SendLua("GAMEMODE:AddNotify(\"Settings retrieved !\", NOTIFY_UNDO, 6)")
      ply:SendLua("surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")"); return true
    end; return false
  end; return false
end

function TOOL:Reload(stTrace)
  if(CLIENT) then return true end
  if(not stTrace.Hit) then return true end
  local trEnt = stTrace.Entity
  if(trEnt and trEnt:IsValid() and trEnt:GetClass() == gsSentHash) then
    trEnt:Remove(); return true end
  return false
end

function TOOL:UpdateGhost(oEnt, oPly)
  if(not (oEnt and oEnt:IsValid())) then return end
  oEnt:SetNoDraw(false)
  oEnt:DrawShadow(false)
  oEnt:SetColor(gtPalette["gh"])
  local stTrace = util.TraceLine(util.GetPlayerTrace(oPly))
  if(not stTrace.Hit) then return end
  self:ApplySpawn(oEnt, stTrace)
end

function TOOL:Think()
  local model = self:GetModel() -- Ghost irrelevant
  local ply   = self:GetOwner() -- Player doing the thing
  if(util.IsValidModel(model)) then
    if(self:GetGhosting() and self:GetConstraint() ~= 0) then
      if(not (self.GhostEntity and
              self.GhostEntity:IsValid() and
              self.GhostEntity:GetModel() == model)) then
        self:MakeGhostEntity(model,VEC_ZERO,ANG_ZERO)
      end; self:UpdateGhost(self.GhostEntity, ply) -- In client single player the grost is skipped
    else self:ReleaseGhostEntity() end -- Delete the ghost entity when ghosting is disabled
  end
end

local function drawLineSpinner(xyS, xyE, sCl)
  surface.SetDrawColor(sCl and gtPalette[sCl] or gtPalette["w"])
  surface.DrawLine(xyS.x, xyS.y, xyE.x, xyE.y)
end

local function drawCircleSpinner(xyO, nRad, sCl)
  surface.DrawCircle(xyO.x, xyO.y, nRad, sCl and gtPalette[sCl] or gtPalette["w"])
end

function TOOL:DrawHUD()
  if(self:GetAdviser()) then
    local ply, axs = LocalPlayer(), 30
    local stTrace  = ply:GetEyeTrace()
    local trEnt    = stTrace.Entity
    local ratiom   = (gnRatio * 1000)
    local ratioc   = (gnRatio - 1) * 100
    local plyd     = (stTrace.HitPos - ply:GetPos()):Length()
    local radc     = 1.2 * math.Clamp(ratiom / plyd, 1, ratioc)
    if(trEnt and trEnt:IsValid()) then
      local cls    = trEnt:GetClass()
      if(cls == gsSentHash) then
        local trAng = trEnt:GetAngles()
        local trCen = trEnt:LocalToWorld(trEnt:GetSpinCenter())
        local nP, nL = trEnt:GetPower(), trEnt:GetLever()
        local nF, nE = axs * (nP / varMaxScale:GetFloat()), axs * (nP / math.abs(nP))
        local spCnt = trEnt:GetLeverCount()
        local spAxs = trEnt:GetTorqueAxis()
        local spLev = trEnt:GetTorqueLever()
        local wvAxs = Vector(); wvAxs:Set(spAxs); wvAxs:Rotate(trAng)
        local wvLev = Vector(); wvLev:Set(spLev); wvLev:Rotate(trAng)
        local dAng, dA = wvLev:AngleEx(wvAxs), (360 / spCnt)
        local xyOO, xyOA = trCen:ToScreen(), (axs * wvAxs + trCen):ToScreen()
        drawLineSpinner(xyOO, xyOA, "b")
        drawCircleSpinner(xyOO, radc, "y")
        for ID = 1, spCnt do
          local vlAn = dAng:Forward()
          local vfAn = dAng:Right(); vfAn:Mul(-1)
          local vLev = ((nL * vlAn) + trCen)
          local xyLE = vLev:ToScreen(); drawLineSpinner(xyOO, xyLE, "g")
          if(nP ~= 0) then
            local vFof = ((nF * vfAn) + vLev)
            local vFoe = ((nE * vfAn) + vLev)
            local xyFF = vFof:ToScreen(); drawLineSpinner(xyLE, xyFF, "y")
            local xyFE = vFoe:ToScreen(); drawLineSpinner(xyFF, xyFE, "r")
          end; dAng:RotateAroundAxis(wvAxs, dA)
        end
      elseif(cls == "prop_physics") then
        local vF, vL, vA, vPos
        local daxs, dlev = self:GetDirectionID()
        if(daxs == 0 and dlev == 0) then
          vF, vL, vA = self:RecalculateUCS(stTrace.HitNormal, ply:GetRight())
          vPos = trEnt:LocalToWorld(trEnt:GetNWVector(gsSentHash.."_cen"))
        else
          local vMin, vMax = trEnt:GetRenderBounds()
          vF, vL, vA = trEnt:GetForward(), trEnt:GetRight(), trEnt:GetUp()
          vPos = trEnt:LocalToWorld((vMax + vMin) / 2)
        end
        local aAng = trEnt:GetAngles()
        local xyO  = vPos:ToScreen()
        local xyX  = (vPos + axs * vF):ToScreen()
        local xyY  = (vPos + axs * vL):ToScreen()
        local xyZ  = (vPos + axs * vA):ToScreen()
        drawLineSpinner(xyO, xyX, "r")
        drawLineSpinner(xyO, xyY, "g")
        drawLineSpinner(xyO, xyZ, "b")
        drawCircleSpinner(xyO,radc,"y")
      end
    end
  end
end

local conVarList = TOOL:BuildConVarList()
function TOOL.BuildCPanel(CPanel)
  local CurY, pItem = 0 -- pItem is the current panel created
          CPanel:SetName(language.GetPhrase("tool."..gsToolName..".name"))
  pItem = CPanel:Help   (language.GetPhrase("tool."..gsToolName..".desc"))
  CurY  = CurY + pItem:GetTall() + 2

  pItem = CPanel:AddControl( "ComboBox",{
              MenuButton = 1,
              Folder     = gsToolName,
              Options    = {["#Default"] = conVarList},
              CVars      = table.GetKeys(conVarList)})
  CurY  = CurY + pItem:GetTall() + 2

  local pComboConst = CPanel:ComboBox("Constraint type", gsToolNameU.."constraint")
        pComboConst:SetPos(2, CurY)
        pComboConst:SetTall(20)
        pComboConst:AddChoice("Skip linking", 0)
        pComboConst:AddChoice("Weld spinner", 1)
        pComboConst:AddChoice("Axis normal" , 2)
        pComboConst:AddChoice("Ball spinner", 3)
        pComboConst:AddChoice("Ball trace"  , 4)
  CurY = CurY + pComboConst:GetTall() + 2

  local pComboAxis = CPanel:ComboBox("Axis direction", gsToolNameU.."diraxis")
        pComboAxis:SetPos(2, CurY)
        pComboAxis:SetTall(20)
        pComboAxis:AddChoice("Autosave", 0)
        pComboAxis:AddChoice("+X Red  ", 1)
        pComboAxis:AddChoice("+Y Green", 2)
        pComboAxis:AddChoice("+Z Blue ", 3)
        pComboAxis:AddChoice("-X Red  ", 4)
        pComboAxis:AddChoice("-Y Green", 5)
        pComboAxis:AddChoice("-Z Blue ", 6)
  CurY = CurY + pComboAxis:GetTall() + 2

  local pComboLever = CPanel:ComboBox("Lever direction", gsToolNameU.."dirlever")
        pComboLever:SetPos(2, CurY)
        pComboLever:SetTall(20)
        pComboLever:AddChoice("Autosave", 0)
        pComboLever:AddChoice("+X Red  ", 1)
        pComboLever:AddChoice("+Y Green", 2)
        pComboLever:AddChoice("+Z Blue ", 3)
        pComboLever:AddChoice("-X Red  ", 4)
        pComboLever:AddChoice("-Y Green", 5)
        pComboLever:AddChoice("-Z Blue ", 6)
  CurY = CurY + pComboLever:GetTall() + 2

  CPanel:AddControl( "Numpad", {  Label = "Key Forward:",
                  Command = gsToolNameU.."keyfwd",
                  ButtonSize = 10 } );

  CPanel:AddControl( "Numpad", {  Label = "Key Reverse:",
                  Command = gsToolNameU.."keyrev",
                  ButtonSize = 10 } );

  CPanel:NumSlider("Mass: "        , gsToolNameU.."mass"     , 1, varMaxMass:GetFloat(), 3)
  CPanel:NumSlider("Power: "       , gsToolNameU.."power"    ,-varMaxScale:GetFloat(), varMaxScale:GetFloat(), 3)
  CPanel:NumSlider("Friction: "    , gsToolNameU.."friction" , 0, varMaxScale:GetFloat(), 3)
  CPanel:NumSlider("Force limit: " , gsToolNameU.."forcelim" , 0, varMaxScale:GetFloat(), 3)
  CPanel:NumSlider("Torque limit: ", gsToolNameU.."torqulim" , 0, varMaxScale:GetFloat(), 3)
  CPanel:NumSlider("Lever: "       , gsToolNameU.."lever"    , 0, varMaxScale:GetFloat(), 3)
  CPanel:NumSlider("Lever count: " , gsToolNameU.."levercnt" , 1, gnMaxAng, 3)
  CPanel:NumSlider("Radius: "      , gsToolNameU.."radius"   , 0, varMaxRadius:GetFloat(), 3)
  CPanel:Button   ("V Reset offsets V", gsToolNameU.."resetoffs")
  CPanel:NumSlider("Offset X: "    , gsToolNameU.."linx"     , -gnMaxLin, gnMaxLin, 3)
  CPanel:NumSlider("Offset Y: "    , gsToolNameU.."liny"     , -gnMaxLin, gnMaxLin, 3)
  CPanel:NumSlider("Offset Z: "    , gsToolNameU.."linz"     , -gnMaxLin, gnMaxLin, 3)
  CPanel:NumSlider("Offset pitch: ", gsToolNameU.."angp"     , -gnMaxAng, gnMaxAng, 3)
  CPanel:NumSlider("Offset yaw: "  , gsToolNameU.."angy"     , -gnMaxAng, gnMaxAng, 3)
  CPanel:NumSlider("Offset roll: " , gsToolNameU.."angr"     , -gnMaxAng, gnMaxAng, 3)
  CPanel:CheckBox("Toggle", gsToolNameU.."toggle")
  CPanel:CheckBox("NoCollide with trace", gsToolNameU.."nocollide")
  CPanel:CheckBox("Enable ghosting", gsToolNameU.."ghosting")
  CPanel:CheckBox("Enable adviser", gsToolNameU.."adviser")
end






