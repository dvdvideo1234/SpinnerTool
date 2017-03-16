--[[
 * Label    : The spinner tool script
 * Author   : DVD ( dvd_video )
 * Date     : 13-03-2017
 * Location : /lua/weapons/gmod_tool/stools/spinner.lua
 * Requires : /lua/entities/sent_spinner.lua
 * Created  : Using tool requirement
 * Defines  : Spinner manager script
]]--

local gsSentHash  = "sent_spinner"
local gsToolName  = "spinner"
local gsToolNameU = gsToolName.."_"
local gsEntLimit  = "spinners"
local gnMaxMod    = 50000
local gnMaxMass   = 50000
local gnMaxRad    = 1000
local gtPalette
local VEC_ZERO    = Vector()
local ANG_ZERO    = Angle ()

if(CLIENT) then
  gtPalette = {}
  gtPalette["w"]  = Color(255,255,255,255)
  gtPalette["r"]  = Color(255, 0 , 0 ,255)
  gtPalette["g"]  = Color( 0 ,255, 0 ,255)
  gtPalette["b"]  = Color( 0 , 0 , 0 ,255)
  gtPalette["m"]  = Color(255, 0 ,255,255)
  gtPalette["y"]  = Color(255,255, 0 ,255)
  gtPalette["c"]  = Color( 0 ,255,255,255)
  gtPalette["gh"] = Color(255,255,255,200)
end

if(SERVER) then

  CreateConVar("sbox_max"..gsEntLimit, 5, FCVAR_NOTIFY, "Maximum spinners to be spawned")

  cleanup.Register(gsEntLimit)

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
    eSpin:Spawn()
    eSpin:Activate()
    eSpin:SetRenderMode(RENDERMODE_TRANSALPHA)
    eSpin:SetColor(Color(255,255,255,255))
    eSpin:DrawShadow(true)
    eSpin:PhysWake()
    eSpin:CallOnRemove("MaglevModuleNumpadCleanup", onMaglevModuleRemove,
      numpad.OnDown(oPly, stSpinner.KeyF , gsToolNameU.."SpinForward_On" , eSpin ),
      numpad.OnUp  (oPly, stSpinner.KeyF , gsToolNameU.."SpinForward_Off", eSpin ),
      numpad.OnDown(oPly, stSpinner.KeyR , gsToolNameU.."SpinReverse_On" , eSpin ),
      numpad.OnUp  (oPly, stSpinner.KeyR , gsToolNameU.."SpinReverse_Off", eSpin ))
    local phSpin = eSpin:GetPhysicsObject()
    if(not (phSpin and phSpin:IsValid())) then eSpin:Remove(); return nil end
    if(not sSpin:Setup(stSpinner)) then eSpin:Remove(); return nil end
    phSpin:EnableMotion(false); eSpin.owner = oPly -- Some SPPs actually use this value
    oPly:AddCount(gsEntLimit , eSpin); oPly:AddCleanup(gsEntLimit , eSpin) -- This sets the ownership
    return eSpin
  end

  duplicator.RegisterEntityClass(gsSentHash, newSpinner, "Pos", "Ang", gsSentHash)

end

if(CLIENT) then
  TOOL.Information = {
    { name = "info",  stage = 1   },
    { name = "left"         },
    { name = "right"        },
    { name = "right_use",   icon2 = "gui/e.png" },
    { name = "reload"       }
  }
  language.Add("tool."..gsToolName..".1"        , "Spinner manager")
  language.Add("tool."..gsToolName..".left"     , "Create/Update spinner")
  language.Add("tool."..gsToolName..".right"    , "Copy settings")
  language.Add("tool."..gsToolName..".reload"   , "Remove spinner")
  language.Add("tool."..gsToolName..".category" , "Construction")
  language.Add("tool."..gsToolName..".name"     , "Spinner manager")
end

TOOL.Category   = language.GetPhrase and language.GetPhrase("tool."..gsToolName..".category")
TOOL.Name       = language.GetPhrase and language.GetPhrase("tool."..gsToolName..".name")
TOOL.Command    = nil -- Command on click (nil for default)
TOOL.ConfigName = nil -- Configure file name (nil for default)

TOOL.ClientConVar = {
  ["mass"      ] = "300",
  ["ghosting"  ] = "1",
  ["model"     ] = "models/props_phx/trains/tracks/track_1x.mdl",
  ["keyfwd"    ] = "45",
  ["keyrev"    ] = "39",
  ["lever"     ] = "10",
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

function TOOL:GetCustomAxis()
  return getVector(self:GetClientInfo("cusaxis"))
end

function TOOL:GetCustomLever()
  return getVector(self:GetClientInfo("cuslever"))
end

function TOOL:GetGhosting()
  tobool(self:GetClientNumber("ghosting") or false)
end

function TOOL:GetMass()
  return math.Clamp(self:GetClientNumber("mass"),1,gnMaxMass)
end

function TOOL:GetToggle()
  return tobool(self:GetClientNumber("toggle") or false)
end

function TOOL:GetPower()
  return math.Clamp(self:GetClientNumber("power"),-gnMaxMod,gnMaxMod)
end

function TOOL:GetRadius()
  return math.Clamp(self:GetClientNumber("radius"),0,gnMaxRad)
end

function TOOL:GetLever()
  return math.Clamp(self:GetClientNumber("lever"),0,gnMaxMod)
end

function TOOL:GetModel()
  return (self:GetClientInfo("model") or "")
end

function TOOL:GetKeys()
  return math.Clamp(self:GetClientNumber("keyfwd"),0,255),
         math.Clamp(self:GetClientNumber("keyrev"),0,255)
end

function TOOL:GetAdviser()
  return tobool(self:GetClientNumber("adviser") or false)
end

function TOOL:GetLocalUCS()
  return math.floor(math.Clamp((self:GetClientNumber("diraxis" ) or 0), 0, 6)),
         math.floor(math.Clamp((self:GetClientNumber("dirlever") or 0), 0, 6))
end

function TOOL:GetNoCollide()
  return tobool(self:GetClientNumber("nocollide") or false)
end

function TOOL:GetConstraint()
  return math.floor(math.Clamp(tonumber(self:GetClientNumber("constraint")) or 0,0,3))
end

-- Updates direction of the spin axis and lever
function TOOL:UpdateVectors(stSpinner)
  local dax, dlev = self:GetLocalUCS()
  if(daxs == 0) then stSpinner.AxiL = self:GetCustomAxis()
  else               stSpinner.AxiL = GetDirectionID(daxs) end
  if(dlev == 0) then stSpinner.LevL = self:GetCustomLever()
  else               stSpinner.LevL = GetDirectionID(dlev) end
  if(daxs ~= 0 and dlev ~= 0 and -- Do not spawn with invalid user axises
    math.abs(stSpinner.AxiL:Dot(stSpinner.LevL)) > 0.01) then
  return false end; return true
end

-- Returns the hit-normal spawn position and orientation
function TOOL:GetStateSpawn(oEnt, stTrace)
  if(not (oEnt and oEnt:IsValid())) then return nil end
  if(stTrace.Hit) then
    local vPos, aAng = Vector(), Angle()
          vPos:Set(stTrace.HitPos); aAng:Set(stTrace.HitNormal:Angle())
          aAng:RotateAroundAxis(aAng:Right(), 90)
    local lAxs = oEnt:GetTorqueAxis()
    local lLev = oEnt:GetTorqueLever()
    local lAng = (lAxs:Cross(lLev):AngleEx(lAxs))
    local vOBB = oEnt:OBBMins(); vOBB:Rotate(lAng)
          vPos:Add(-vOBB.z * stTrace.HitNormal)
          aAng:Add(lAng); aAng:Normalize()
    return vPos, vAng
  else return nil end
end

-- Creates a constant between spinner and trace
function TOOL:Constraint(eSpin, stTrace)
  local trEnt = stTrace and stTrace.Entity
  if(trEnt and trEnt:IsValid()) then
    local ncon = self:GetConstraint()
    local bcol = self:GetNoCollide()
    local nfor = 0 -- Force  limit ( for now unbreakable )
    local ntor = 0 -- Torque limit ( for now unbreakable )
    local nfri = 0 -- Friction     ( for now frictionless )
    local nbon = stTrace.PhysicsBone
    local vnrm = stTrace.HitNormal
    if(ncon == 0 and bcol) then -- NoCollide
      local C = constraint.NoCollide(eSpin,trEnt,0,nbon)
      if(C) then eSpin:DeleteOnRemove(C); trEnt:DeleteOnRemove(C); return C end
    elseif(ncon == 1) then -- Weld
      local C = constraint.Weld(eSpin,trEnt,0,nbon,nfor,bcol,false)
      if(C) then eSpin:DeleteOnRemove(C); trEnt:DeleteOnRemove(C); return C end
    elseif(ncon == 2) then -- Axis
      local LPos1 = eSpin:GetPhysicsObject():GetMassCenter()
      local LPos2 = eSpin:LocalToWorld(LPos1); LPos2:Add(vnrm)
            LPos2:Set(trEnt:WorldToLocal(LPos2))
      local C = constraint.Axis(eSpin,trEnt,0,nbon,LPos1,LPos2,nfor,ntor,nfri,(bcol and 1 or 0))
      if(C) then eSpin:DeleteOnRemove(C); trEnt:DeleteOnRemove(C); return C end
    elseif(ncon == 3) then -- Ball ( At the center of the spinner )
      local M = eSpin:GetPhysicsObject():GetMassCenter()
      local C = constraint.Ballsocket(trEnt,eSpin,nbon,0,M,nfor,ntor,(bcol and 1 or 0))
      if(C) then eSpin:DeleteOnRemove(C); trEnt:DeleteOnRemove(C); return C end
    else return false end
  end; return false
end

function TOOL:LeftClick(stTrace)
  if(CLIENT) then return true end
  if(not stTrace.Hit) then return true end
  local stSpinner = {}
  local ply       = self:GetOwner()
  local constr    = self:GetConstraint()
  stSpinner.Mass  = self:GetMass()
  stSpinner.Prop  = self:GetModel()
  stSpinner.Power = self:GetPower()
  stSpinner.Lever = self:GetLever()
  stSpinner.Togg  = self:GetToggle()
  stSpinner.Rad   = self:GetRadius()
  stSpinner.KeyF, stSpinner.KeyR = self:GetKeys()
  local trEnt = stTrace.Entity
  if(stTrace.HitWorld) then
    if(not self:UpdateVectors(stSpinner)) then return false end
    local vPos   = stTrace.HitNormal
    local aAng   = stTrace.HitNormal:Angle()
          aAng:RotateAroundAxis(aAng:Right(), 90)
          aAng:Add((stSpinner.AxiL:Cross(stSpinner.LevL)):AngleEx(stSpinner.AxiL))
    local eSpin = newSpinner(ply, vPos, aAng, stSpinner)
    if(eSpin) then
      local vPos, aAng = self:GetStateSpawn(eSpin, stTrace)
      if(not (vPos and aAng)) then eSpin:Remove(); return false end
      eSpin:SetPos(vPos); eSpin:SetAngles(aAng)
      undo.Create("Spinner")
        undo.AddEntity(eSpin)
        undo.SetCustomUndoText("Spinner free")
        undo.SetPlayer(ply)
      undo.Finish()
    end
  else
    if(trEnt and trEnt:IsValid()) then
      if(not self:UpdateVectors(stSpinner)) then return false end
      local vPos   = stTrace.HitNormal
      local aAng   = stTrace.HitNormal:Angle()
            aAng:RotateAroundAxis(aAng:Right(), 90)
            aAng:Add((stSpinner.AxiL:Cross(stSpinner.LevL)):AngleEx(stSpinner.AxiL))
      local eSpin  = newSpinner(ply, vPos, aAng, stSpinner)
      if(eSpin) then
        local vPos, aAng = self:GetStateSpawn(eSpin, stTrace)
        if(not (vPos and aAng)) then eSpin:Remove(); return false end
        eSpin:SetPos(vPos); eSpin:SetAngles(aAng)
        local C = self:Constraint(eSpin, stTrace)
        undo.Create("Spinner")
          undo.AddEntity(eSpin)
          if(C) then undo.AddEntity(C) end
          undo.SetCustomUndoText("Spinner link")
          undo.SetPlayer(ply)
        undo.Finish()
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
      local sAxs = tostring(trEnt:WorldToLocal(vPos + stTrace.HitNormal))
      local sLvr = tostring(trEnt:WorldToLocal(vPos + ply:GetRight()))
      ply:ConCommand(gsToolNameU.."cusaxis " ..sAxs.."\n") -- Vector as string
      ply:ConCommand(gsToolNameU.."cuslever "..sLvr.."\n") -- Vector as string
      ply:ConCommand(gsToolNameU.."model "   ..trEnt:GetModel().."\n")
      ply:SendLua("GAMEMODE:AddNotify(\"Model: "..sPth.." selected !\", NOTIFY_UNDO, 6)")
      ply:SendLua("surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")"); return true
    elseif(cls == gsSentHash) then
      local phEnt = trEnt:GetPhysicsObject()
      ply:ConCommand(gsToolNameU.."power " ..tostring(trEnt:GetPower()).."\n") -- Number
      ply:ConCommand(gsToolNameU.."lever " ..tostring(trEnt:GetLever()).."\n") -- Number
      ply:ConCommand(gsToolNameU.."toggle "..tostring(trEnt:GetToggle() and 1 or 0).."\n")
      ply:ConCommand(gsToolNameU.."mass "  ..tostring(phEnt:GetMass()).."\n")
      ply:SendLua("GAMEMODE:AddNotify(\"Settings retrieved !\", NOTIFY_UNDO, 6)")
      ply:SendLua("surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")"); return true
    end; return false
  end; return false
end

function TOOL:UpdateGhost(oEnt, oPly)
  if(not (oEnt and oEnt:IsValid())) then return end
  oEnt:SetNoDraw(true)
  oEnt:DrawShadow(false)
  oEnt:SetColor(gtPalette["gh"])
  local stTrace = util.TraceLine(util.GetPlayerTrace(oPly))
  local trEnt   = stTrace.Entity
  if(not stTrace.Hit) then return end
  if(trEnt and trEnt:IsValid()) then
    local trPhys = trEnt:GetPhysicsObject()
    if(trPhys and trPhys:IsValid()) then
      trEnt:SetNWVector(gsToolNameU.."vmc", trPhys:GetMassCenter())
    end
  end
  local vPos, aAng = self:GetStateSpawn(oEnt, stTrace)
  if(vPos and aAng) then
    oEnt:SetPos(vPos); oEnt:SetAngles(aAng); oEnt:SetNoDraw(false)
  else -- Cannot be calculated by some reason
    local vHit, aHit = stTrace.HitPos, stTrace.HitNormal:Angle()
          aHit:RotateAroundAxis(aHit:Right(), 90)
    oEnt:SetPos(vHit); oEnt:SetAngles(aHit); oEnt:SetNoDraw(false)
  end
end

function TOOL:Think()
  local model = self:GetModel() -- Ghost irrelevant
  local ply   = self:GetOwner()
  if(util.IsValidModel(model)) then
    if(self:GetGhosting()) then
      if(not (self.GhostEntity and
              self.GhostEntity:IsValid() and
              self.GhostEntity:GetModel() == model)) then
        self:MakeGhostEntity(model,VEC_ZERO,ANG_ZERO)
      end; self:UpdateGhost(self.GhostEntity, ply) -- In client single player the grost is skipped
    else self:ReleaseGhostEntity() end -- Delete the ghost entity when ghosting is disabled
  end
end

function TOOL:DrawHUD()
  if(self.GetAdviser()) then
    local ply     = LocalPlayer()
    local stTrace = ply:GetEyeTrace()
    local trEnt   = stTrace.Entity
    local ratiom  = (gnRatio * 1000)
    local ratioc  = (gnRatio - 1) * 100
    local plyd    = (stTrace.HitPos - ply:GetPos()):Length()
    local radc    = 1.2 * math.Clamp(ratiom / plyd, 1, ratioc)
    if(trEnt and trEnt:IsValid() then
      if(trEnt:GetClass() == gsSentHash) then
        local aA = trEnt:GetAngles()
        local vO = trEnt:GetOrgin()
        local nP, nL = trEnt:GetPower(), trEnt:GetLever()
        local sL, sF = trEnt:GetTorqueLever()
        local vA = Vector(); vA:Add(trEnt:GetTorqueAxis()); vA:Rotate(aA)
        local vL = Vector(); vL:Add(sL); vL:Rotate(aA)
        local vF = Vector(); vF:Add(sF); vF:Rotate(aA)
        local xyOO, xyOA = vO:ToScreen(), (vO + vA):ToScreen()
        local xyLL, xyLR = (vO - nL * vL):ToScreen(), (vO + nL * vL):ToScreen()
        local xyFF, xyFR = (vO - nL * vL - nP * vF):ToScreen(), (vO + nL * vL + nP * vF):ToScreen()
        surface.SetDrawColor(gtPalette["b"])
        surface.DrawLine(xyOO.x,xyOO.y,xyOA.x,xyOA.y)
        surface.SetDrawColor(gtPalette["g"])
        surface.DrawLine(xyOO.x,xyOO.y,xyLL.x,xyLL.y)
        surface.DrawLine(xyOO.x,xyOO.y,xyLR.x,xyLR.y)
        surface.SetDrawColor(gtPalette["r"])
        surface.DrawLine(xyOO.x,xyOO.y,xyFF.x,xyFF.y)
        surface.DrawLine(xyOO.x,xyOO.y,xyFR.x,xyFR.y)
        surface.DrawCircle(xyOO.x,xyOO.y,radc,gtPalette["y"])
      else
        local vPos = trEnt:GetNWVector(gsToolNameU.."vmc")
        local aAng = trEnt:GetAngles()
        local xyO  = vPos:ToScreen()
        local xyX  = (vPos + 30 * trEnt:GetForward()):ToScreen()
        local xyY  = (vPos + 30 * trEnt:GetRight()):ToScreen()
        local xyZ  = (vPos + 30 * trEnt:GetUp()):ToScreen()
        surface.SetDrawColor(gtPalette["r"])
        surface.DrawLine(xyO.x,xyO.y,xyX.x,xyX.y)
        surface.SetDrawColor(gtPalette["g"])
        surface.DrawLine(xyO.x,xyO.y,xyY.x,xyY.y)
        surface.SetDrawColor(gtPalette["b"])
        surface.DrawLine(xyO.x,xyO.y,xyZ.x,xyZ.y)
        surface.DrawCircle(xyOO.x,xyOO.y,radc,gtPalette["y"])
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
        pComboConst:AddChoice("None", 0)
        pComboConst:AddChoice("Weld", 1)
        pComboConst:AddChoice("Axis", 2)
        pComboConst:AddChoice("Ball", 3)
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

  CPanel:NumSlider("Power: " , gsToolNameU.."power" ,-gnMaxMod, gnMaxMod, 3)
  CPanel:NumSlider("Lever: " , gsToolNameU.."lever" ,        0, gnMaxMod, 3)
  CPanel:NumSlider("Radius: ", gsToolNameU.."radius",        0, gnMaxRad, 3)
  CPanel:CheckBox("NoCollide with trace", gsToolNameU.."nocollide")
  CPanel:CheckBox("Enable ghosting", gsToolNameU.."nocollide")
  CPanel:CheckBox("Enable adviser", gsToolNameU.."adviser")
end






