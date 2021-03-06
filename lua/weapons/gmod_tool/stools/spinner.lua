--[[
 * Label    : The spinner tool script
 * Author   : DVD ( dvd_video )
 * Date     : 13-03-2017
 * Location : /lua/weapons/gmod_tool/stools/spinner.lua
 * Requires : /lua/entities/sent_spinner.lua
 * Created  : Using tool requirement
 * Defines  : Spinner manager script
]]--
local gsSentHash   = "sent_spinner"
local varLng       = GetConVar("gmod_language")
local gsSentName   = gsSentHash:gsub("sent_","")
local gnVarFlags   = bit.bor(FCVAR_ARCHIVE, FCVAR_ARCHIVE_XBOX, FCVAR_NOTIFY, FCVAR_REPLICATED, FCVAR_PRINTABLEONLY)
local varMaxDirOfs = CreateConVar("sbox_max"..gsSentName.."_drofs" , 2000, gnVarFlags, "Maximum direction offset to overcome displacing unit vectors")
local varMaxScale  = CreateConVar("sbox_max"..gsSentName.."_scale" , 50000, gnVarFlags, "Maximum scale for power and lever")
local varMaxMass   = CreateConVar("sbox_max"..gsSentName.."_mass"  , 50000, gnVarFlags, "The maximum mass the entity can have")
local varMaxRadius = CreateConVar("sbox_max"..gsSentName.."_radius", 1000, gnVarFlags, "Maximum radius when rebuilding the collision model as sphere")
local varMaxLine   = CreateConVar("sbox_max"..gsSentName.."_line"  , 1000, gnVarFlags, "Maximum linear offset for general stuff and panel handling")
local varBroadCast = CreateConVar("sbox_max"..gsSentName.."_broad" , 250, gnVarFlags, "Maximum time [ms] when reached the think method sends client stuff")
local varTickRate  = CreateConVar("sbox_max"..gsSentName.."_tick"  , 10, gnVarFlags, "Maximum sampling time [ms] when the spinner is activated. Be careful!")
local varRemoveER  = CreateConVar("sbox_en" ..gsSentName.."_remerr", 1, gnVarFlags, "When enabled removes the spinner when an error is present")
local varEnableWT  = CreateConVar("sbox_en" ..gsSentName.."_wdterr", 1, gnVarFlags, "When enabled takes the watchdog timer for an actual error")
local varEnableDT  = CreateConVar("sbox_en" ..gsSentName.."_timdbg", 0, gnVarFlags, "When enabled outputs the rate status on the wire output")

local gsToolName   = gsSentName
local gsToolNameU  = gsToolName.."_"
local gsEntLimit   = gsSentName.."s"
local gnMaxAng     = 360
local gsLangForm   = ("%s"..gsToolName.."/lang/%s")
local VEC_ZERO     = Vector()
local ANG_ZERO     = Angle ()
local goTool       = TOOL
local gtLang       = {}
local gtPalette    = {}
local gtDirectID   = {}
local gtComboIcon  = {}

-- Fill up the palette with colors
gtPalette["w"]  = Color(255,255,255,255)
gtPalette["r"]  = Color(255, 0 , 0 ,255)
gtPalette["g"]  = Color( 0 ,255, 0 ,255)
gtPalette["b"]  = Color( 0 , 0 ,255,255)
gtPalette["k"]  = Color( 0 , 0 , 0 ,255)
gtPalette["m"]  = Color(255, 0 ,255,255)
gtPalette["y"]  = Color(255,255, 0 ,255)
gtPalette["c"]  = Color( 0 ,255,255,255)
gtPalette["gh"] = Color(255,255,255,200)

-- Initialize directions. Zero is custom
gtDirectID[1] = Vector( 1, 0, 0)
gtDirectID[2] = Vector( 0, 1, 0)
gtDirectID[3] = Vector( 0, 0, 1)
gtDirectID[4] = Vector(-1, 0, 0)
gtDirectID[5] = Vector( 0,-1, 0)
gtDirectID[6] = Vector( 0, 0,-1)

local function getTranslate(sT)
  local sN = gsLangForm:format("", sT..".lua")
  if(not file.Exists("lua/"..sN, "GAME")) then return nil end
  local fT = CompileFile(sN); if(not fT) then return nil end
  local bF, fF = pcall(fT); if(not bF) then return nil end
  local bS, tS = pcall(fF, gsToolName, gsEntLimit)
  if(not bF) then return nil end; return tS
end

local function setTranslate(sT)
  table.Empty(gtLang) -- Override translations file
  local tB = getTranslate("en"); if(not tB) then
    ErrorNoHalt(gsToolName..": setTranslate: Missing") end
  if(sT ~= "en") then local tC = getTranslate(sT); if(tC) then
    for key, val in pairs(tB) do tB[key] = (tC[key] or tB[key]) end end
  end; for key, val in pairs(tB) do gtLang[key] = tB[key]; language.Add(key, val) end
end

local function getPhrase(sK)
  local sK = tostring(sK) if(not gtLang[sK]) then
    ErrorNoHalt(gsToolName..": getPhrase("..sK.."): Missing")
    return "Oops, missing ?" -- Return some default translation
  end; return gtLang[sK]
end

if(SERVER) then

  -- Send language translations to the client to populate the menu
  local gtTransFile = file.Find(gsLangForm:format("lua/", "*.lua"), "GAME")
  for iD = 1, #gtTransFile do AddCSLuaFile(gsLangForm:format("", gtTransFile[iD])) end

  CreateConVar("sbox_max"..gsEntLimit, 10, FCVAR_NOTIFY, "Maximum spinners to be spawned")

  cleanup.Register(gsEntLimit)

  local function onRemove(self, fon, fof, ron, rof)
    numpad.Remove(fon); numpad.Remove(fof)
    numpad.Remove(ron); numpad.Remove(rof)
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
    eSpin:SetCreator(oPly)
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
  language.Add("tool."..gsToolName..".category" , "Construction")

  TOOL.Information = {
    { name = "info",  stage = 1   },
    { name = "left"         },
    { name = "right"        },
    { name = "reload"       }
  }

  -- Translate the meny and attach routine for reset
  setTranslate(varLng:GetString())
  concommand.Add(gsToolNameU.."resetoffs", function(oPly,oCom,oArgs)
    oPly:ConCommand(gsToolNameU.."linx 0\n")
    oPly:ConCommand(gsToolNameU.."liny 0\n")
    oPly:ConCommand(gsToolNameU.."linz 0\n")
    oPly:ConCommand(gsToolNameU.."angp 0\n")
    oPly:ConCommand(gsToolNameU.."angy 0\n")
    oPly:ConCommand(gsToolNameU.."angr 0\n")
  end)

  -- Contains the file paths for the icons
  gtComboIcon.Data = {}
  gtComboIcon.Icon = "icon16/%s.png"
  -- http://www.famfamfam.com/lab/icons/silk/preview.php
  gtComboIcon.Data["constraint"] = {
    None = "link_break",
    "brick_link", "chart_pie_link",
    "world_link", "lorry_link"
  }
  gtComboIcon.Data["diraxis"] = {
    None = "arrow_inout",
    "arrow_right", "arrow_down" ,
    "arrow_out"  , "arrow_left" ,
    "arrow_up"   , "arrow_in"
  }
  gtComboIcon.Data["dirlever"] = gtComboIcon.Data["diraxis"]

  -- listen for changes to the localify language and reload the tool's menu to update the localizations
  cvars.RemoveChangeCallback(varLng:GetName(), gsToolNameU.."lang")
  cvars.AddChangeCallback(varLng:GetName(), function(sNam, vO, vN) setTranslate(vN)
    local cPanel = controlpanel.Get(goTool.Mode); if(not IsValid(cPanel)) then return end
    cPanel:ClearControls(); goTool.BuildCPanel(cPanel)
  end, gsToolNameU.."lang")
end

TOOL.Category   = language and language.GetPhrase("tool."..gsToolName..".category")
TOOL.Name       = language and language.GetPhrase("tool."..gsToolName..".name")
TOOL.Command    = nil -- Command on click (nil for default)
TOOL.ConfigName = nil -- Configure file name (nil for default)

TOOL.ClientConVar = {
  ["mass"      ] = 300,     -- Spinner entity mass when created
  ["linx"      ] = 0,       -- Linear user deviation X
  ["liny"      ] = 0,       -- Linear user deviation Y
  ["linz"      ] = 0,       -- Linear user deviation Z
  ["angp"      ] = 0,       -- Angle user deviation pitch
  ["angy"      ] = 0,       -- Angle user deviation yaw
  ["angr"      ] = 0,       -- Angle user deviation roll
  ["ghosting"  ] = 1,       -- Draws the ghosted prop of the spinner when enabled
  ["model"     ] = "models/props_trainstation/trainstation_clock001.mdl", -- Spinner entity model
  ["friction"  ] = 0,       -- Friction for the constraints linking spinner to trace ( if available )
  ["forcelim"  ] = 0,       -- Force limit on for the constraints linking spinner to trace ( if available )
  ["torqulim"  ] = 0,       -- Torque limit on for the constraints linking spinner to trace ( if available )
  ["keyfwd"    ] = 45,      -- Key to spin forward ( to the force ref direction )
  ["keyrev"    ] = 39,      -- Key to spin in reverse
  ["lever"     ] = 10,      -- Defines how long each lever of the entity is
  ["levercnt"  ] = 2,       -- Defines how many force levers the entity created has
  ["drwscale"  ] = 30,      -- How long is the scaled force line
  ["power"     ] = 100,     -- Power of the spinner the bigger the faster
  ["radius"    ] = 0,       -- Radius if bigger than zero circular collision is used
  ["toggle"    ] = 0,       -- Remain in a spinning state when the numpad is released
  ["diraxis"   ] = 0,       -- Axis  direction ID matched to /pComboAxis/
  ["dirlever"  ] = 0,       -- Lever direction ID matched to /pComboLever/
  ["adviser"   ] = 1,       -- Enabled drawing the coordinates of the props or spinner parameters
  ["nocollide" ] = 0,       -- Enabled creates a no-collision constraint between it and the trace
  ["constraint"] = 0,       -- Constraint type matched to /pComboConst/
  ["cusaxis"   ] = "[0,0,0]", -- Local custom spin axis vector
  ["cuslever"  ] = "[0,0,0]"  -- Local custom leverage vector
}

local gtConvar = TOOL:BuildConVarList()

local function getVector(sV)
  local sB = tostring(sV or ""):gsub("%[",""):gsub("%]","")
  local tV = (","):Explode(sB)
  local nX = (tonumber(tV[1]) or 0)
  local nY = (tonumber(tV[2]) or 0)
  local nZ = (tonumber(tV[3]) or 0)
  return Vector(nX, nY, nZ)
end

local function strVector(vV)
  local sX = tostring(vV.x or 0)
  local sY = tostring(vV.y or 0)
  local sZ = tostring(vV.z or 0)
  return "["..sX..","..sY..","..sZ.."]"
end

local function getDirectionID(nID)
  local vD = gtDirectID[(tonumber(nID) or 0)]
  return (vD and vD or Vector())
end

local function getIconID(sKey, nID)
  local tD = gtComboIcon.Data[sKey]
  if(not tD) then return nil end
  local sI = (tD[nID] and tD[nID] or tD.None)
  return gtComboIcon.Icon:format(sI)
end

local function setComboBoxPanel(CPanel, sConv, nCnt)
  local sBase = "tool."..gsToolName.."."..sConv
  local sMenu, sTtip = getPhrase(sBase.."_con"), getPhrase(sBase)
  local pCombo, pLabel = CPanel:ComboBox(sMenu, gsToolNameU..sConv)
  pCombo:SetSortItems(false); pCombo:Dock(TOP); pCombo:SetTall(25)
  pCombo:UpdateColours(CPanel:GetSkin())
  pLabel:SetTooltip(sTtip); pCombo:SetTooltip(sTtip)
  for iD = 0, nCnt do local sI = getIconID(sConv, iD)
    pCombo:AddChoice(getPhrase(sBase..iD), iD, false, sI)
  end; return pCombo, pLabel
end

local function setNumSliderPanel(CPanel, sConv, nMin, nMax, nDig)
  local sBase = "tool."..gsToolName.."."..sConv
  local sMenu, sTtip = getPhrase(sBase.."_con"), getPhrase(sBase)
  local vDefv = gtConvar[gsToolNameU..sConv]
  local pItem = CPanel:NumSlider(sMenu, gsToolNameU..sConv, nMin, nMax, nDig)
  pItem:SetTooltip(sTtip); pItem:SetDefaultValue(vDefv); return pItem
end

local function setCheckBoxPanel(CPanel, sConv)
  local sBase = "tool."..gsToolName.."."..sConv
  local sMenu, sTtip = getPhrase(sBase.."_con"), getPhrase(sBase)
  local pItem = CPanel:CheckBox(sMenu, gsToolNameU..sConv)
  pItem:SetTooltip(sTtip); return pItem
end

function TOOL:NotifyUser(sMsg, sNot, iSiz)
  local user, isnd = self:GetOwner(), math.random(1, 4)
  local fmsg = "GAMEMODE:AddNotify('%s', NOTIFY_%s, %d)"
  local fsnd = "surface.PlaySound('ambient/water/drip%d.wav')"
  user:SendLua(fmsg:format(sMsg, sNot, iSiz))
  user:SendLua(fsnd:format(isnd))
end

function TOOL:GetDeviationPos()
  local nMaxLine = varMaxLine:GetFloat()
  return math.Clamp(self:GetClientNumber("linx"),-nMaxLine,nMaxLine),
         math.Clamp(self:GetClientNumber("liny"),-nMaxLine,nMaxLine),
         math.Clamp(self:GetClientNumber("linz"),-nMaxLine,nMaxLine)
end

function TOOL:GetDeviationAng()
  return math.Clamp(self:GetClientNumber("angp"),-gnMaxAng,gnMaxAng),
         math.Clamp(self:GetClientNumber("angy"),-gnMaxAng,gnMaxAng),
         math.Clamp(self:GetClientNumber("angr"),-gnMaxAng,gnMaxAng)
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

function TOOL:GetDrawScale()
  return math.Clamp(self:GetClientNumber("drwscale"),0,varMaxLine:GetFloat())
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
  else               vA:Set(getDirectionID(daxs)) end
  if(dlev == 0) then vL:Set(self:GetCustomLever())
  else               vL:Set(getDirectionID(dlev)) end
  vA:Normalize(); vL:Normalize(); return vA, vL
end

-- Recalculates the orientation based on the spin axis and lever axis
-- Updates force, lever and spin axises to be orthogonal to each other
-- vA > Local vector of the spin axis
-- vL > Local vector of the lever axis
function TOOL:RecalculateUCS(vA, vL)
  local cF = vA:Cross(vL)
  local cL = cF:Cross(vA)
  local cA = cL:Cross(cF)
  cF:Normalize(); cL:Normalize(); cA:Normalize()
  return cF, cL, cA
end

-- Updates direction of the spin axis and lever
function TOOL:UpdateVectors(stSpinner)
  local daxs, dlev = self:GetDirectionID()
  local vF, vL, vA = self:RecalculateUCS(self:GetVectors())
  if(math.abs(vA:Dot(vL)) > 0.001) then
    self:NotifyUser("Axis not orthogonal to lever!", "ERROR", 6); return false end
  if(math.abs(vA:Dot(vF)) > 0.001) then
    self:NotifyUser("Axis not orthogonal to force!", "ERROR", 6); return false end
  if(math.abs(vF:Dot(vL)) > 0.001) then
    self:NotifyUser("Force not orthogonal to lever!", "ERROR", 6); return false end
  if(not (type(vA) == "Vector")) then -- Do not spawn with invalid user axises
    self:NotifyUser("Axis missing <"..tostring(vA)..">!", "ERROR", 6); return false end
  if(not (type(vL) == "Vector")) then
    self:NotifyUser("Lever missing <"..tostring(vL)..">!", "ERROR", 6); return false end
  if(vA:Length() == 0) then
    self:NotifyUser("Spinner axis zero!", "ERROR", 6); return false end
  if(vL:Length() == 0) then
    self:NotifyUser("Spinner lever zero!", "ERROR", 6); return false end
  stSpinner.AxiL, stSpinner.LevL = vA, vL; return true
end

-- Returns the hit-normal spawn position and orientation
function TOOL:ApplySpawn(oEnt, stTrace)
  if(not (oEnt and oEnt:IsValid())) then return false end
  if(not stTrace.Hit) then oEnt:Remove() return false end
  local oPly, vOBB = self:GetOwner(), oEnt:OBBMins()
  local linx, liny, linz = self:GetDeviationPos()
  local angp, angy, angr = self:GetDeviationAng()
  local vU, vR = stTrace.HitNormal, oPly:GetRight()
  local vF, vA, vL = vU:Cross(vR), self:GetVectors()
  local vPos, aAng = Vector(), Angle()
  local lA = (vA:Cross(vL):AngleEx(vA))
  aAng:Set(oEnt:AlignAngles(oEnt:LocalToWorldAngles(lA), vU:Cross(vR):AngleEx(vU)))
  vPos:Set(stTrace.HitPos); vPos:Add((math.abs(vOBB:Dot(vA))) * vU)
  aAng:RotateAroundAxis(vU,  angy); vPos:Add(linz * vU)
  aAng:RotateAroundAxis(vR, -angp); vPos:Add(liny * vR)
  aAng:RotateAroundAxis(vF,  angr); vPos:Add(linx * vF)
  aAng:Normalize(); oEnt:SetPos(vPos); oEnt:SetAngles(aAng); return true
end

-- Creates a constant between spinner and trace
function TOOL:Constraint(eSpin, stTrace)
  local trEnt = stTrace and stTrace.Entity
  if(util.IsValidPhysicsObject(stTrace.Entity, stTrace.PhysicsBone)) then
    local ncon = self:GetConstraint()
    local bcol, nfor = self:GetNoCollide(), self:GetForceLimit()
    local ntor, nfri = self:GetTorqueLimit(), self:GetFriction()
    local hpos, nbon = stTrace.HitPos, stTrace.PhysicsBone
    -- Keep it long to avoid surface displacement
    if(ncon == 0 and bcol) then -- NoCollide
      local C = constraint.NoCollide(eSpin,trEnt,0,nbon)
      if(C) then eSpin:DeleteOnRemove(C); trEnt:DeleteOnRemove(C); return C end
    elseif(ncon == 1) then -- Weld
      local C = constraint.Weld(eSpin,trEnt,0,nbon,nfor,bcol,false)
      if(C) then eSpin:DeleteOnRemove(C); trEnt:DeleteOnRemove(C); return C end
    elseif(ncon == 2) then -- Axis
      local vEnrm = varMaxDirOfs:GetFloat() * stTrace.HitNormal
      local LPos1 = eSpin:GetPhysicsObject():GetMassCenter()
            LPos2 = trEnt:WorldToLocal((eSpin:LocalToWorld(LPos1) + vEnrm))
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
    local vPos, aAng = stTrace.HitPos, stTrace.HitNormal:Angle()
          aAng:RotateAroundAxis(aAng:Right(), 90)
          aAng = (aAng + (stSpinner.AxiL:Cross(stSpinner.LevL)):AngleEx(stSpinner.AxiL))
          aAng:Normalize()
    local eSpin = newSpinner(ply, vPos, aAng, stSpinner)
    if(eSpin) then
      self:ApplySpawn(eSpin, stTrace)
      local C = self:Constraint(eSpin, stTrace)
      undo.Create("Spinner")
        undo.AddEntity(eSpin)
        undo.SetPlayer(ply)
        if(C) then undo.AddEntity(C)
          undo.SetCustomUndoText("Spinner world") end
      undo.Finish(); return true
    end
  else
    if(trEnt and trEnt:IsValid()) then
      if(not self:UpdateVectors(stSpinner)) then return false end
      if(trEnt:GetClass() == gsSentHash) then
        stSpinner.Radi = 0     -- Do not recreate the physics on update
        trEnt:Setup(stSpinner) -- Apply general data from the cvars
        trEnt:ApplyTweaks()    -- No need respawn the entity to update the tweaks
        self:NotifyUser("Updated !", "UNDO", 6)
        return true
      end
      local vPos, aAng = stTrace.HitPos, stTrace.HitNormal:Angle()
            aAng:RotateAroundAxis(aAng:Right(), 90)
            aAng = aAng + (stSpinner.AxiL:Cross(stSpinner.LevL)):AngleEx(stSpinner.AxiL)
      local eSpin  = newSpinner(ply, vPos, aAng, stSpinner)
      if(eSpin) then self:ApplySpawn(eSpin, stTrace)
        local C = self:Constraint(eSpin, stTrace)
        undo.Create("Spinner")
          undo.AddEntity(eSpin)
          undo.SetPlayer(ply)
          if(C) then undo.AddEntity(C)
            undo.SetCustomUndoText("Spinner link") end
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
    if(cls == "prop_physics") then local sMod = trEnt:GetModel()
      local vPos, nEdr = trEnt:GetPos(), varMaxDirOfs:GetFloat()
      local sPth = string.GetFileFromFilename(sMod)
      local vAxs, vLvr = (nEdr * stTrace.HitNormal), (nEdr * ply:GetRight())
            vAxs:Add(vPos); vAxs:Set(trEnt:WorldToLocal(vAxs)); vAxs:Normalize()
            vLvr:Add(vPos); vLvr:Set(trEnt:WorldToLocal(vLvr)); vLvr:Normalize()
      local sAxs, sLvr = strVector(vAxs), strVector(vLvr)
      ply:ConCommand(gsToolNameU.."cusaxis " ..sAxs.."\n") -- Axis vector as string
      ply:ConCommand(gsToolNameU.."cuslever "..sLvr.."\n") -- Lever vector as string
      ply:ConCommand(gsToolNameU.."model "   ..sMod.."\n") -- Trace model as string
      self:NotifyUser("Selected "..sPth.." !", "UNDO", 6); return true
    elseif(cls == gsSentHash) then
      local phEnt = trEnt:GetPhysicsObject()
      ply:ConCommand(gsToolNameU.."power "   ..tostring(trEnt:GetPower()).."\n") -- Number
      ply:ConCommand(gsToolNameU.."lever "   ..tostring(trEnt:GetLever()).."\n") -- Number
      ply:ConCommand(gsToolNameU.."levercnt "..tostring(trEnt:GetLeverCount()).."\n") -- Number
      ply:ConCommand(gsToolNameU.."toggle "  ..tostring(trEnt:IsToggled() and 1 or 0).."\n")
      ply:ConCommand(gsToolNameU.."mass "    ..tostring(phEnt:GetMass()).."\n")
      self:NotifyUser("Retrieved !", "UNDO", 6); return true
    end; return false
  end; return false
end

function TOOL:Reload(stTrace)
  if(CLIENT) then return true end
  if(not stTrace.Hit) then return true end
  local trEnt, oPly = stTrace.Entity, self:GetOwner()
  if(trEnt and trEnt:IsValid() and -- Remove only valid
     trEnt:GetCreator() == oPly and -- entities that are
     trEnt:GetClass() == gsSentHash) -- my own spinners
  then trEnt:Remove() else -- Reverse the power otherwise
    local sPow = tostring(-self:GetPower())
    self:NotifyUser("Power reverse "..sPow.." !", "UNDO", 6)
    oPly:ConCommand(gsToolNameU.."power "..sPow.."\n") -- Number
  end; return true
end

function TOOL:UpdateGhost(oEnt, oPly)
  if(not (oEnt and oEnt:IsValid())) then return end
  if(not (oPly and oPly:IsValid() and oPly:IsPlayer())) then return end
  local stTrace = oPly:GetEyeTrace()
  local trEnt   = stTrace.Entity
  if(stTrace.Hit) then
    if(trEnt and -- Make sure we don't draw the ghost when a valid spinner is traced
       trEnt:IsValid() and -- Valid entity class of the existing trace entity
       trEnt:GetClass() == gsSentHash) then -- The trace is actual spinner SENT
      oEnt:SetNoDraw(true)
    else
      oEnt:SetNoDraw(false); oEnt:DrawShadow(false)
      oEnt:SetColor(gtPalette["gh"])
      self:ApplySpawn(oEnt, stTrace)
    end
  else oEnt:SetNoDraw(true) end
end

function TOOL:Think()
  local model = self:GetModel() -- Ghost irrelevant
  local ply   = self:GetOwner() -- Player doing the thing
  if(util.IsValidModel(model)) then
    if(self:GetGhosting()) then
      local ghEnt = self.GhostEntity -- Store a local reference to the ghost
      if(not (ghEnt and ghEnt:IsValid() and ghEnt:GetModel() == model)) then
        self:MakeGhostEntity(model,VEC_ZERO,ANG_ZERO) end;
      self:UpdateGhost(ghEnt, ply) -- In client single player the ghost is skipped
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

function TOOL:GetRadiusRatio(stTrace, oPly)
  local nRatio = 1.61803398875
  local ratiom = (nRatio * 1000)
  local ratioc = (nRatio - 1) * 100
  local plyd   = (stTrace.HitPos - oPly:GetPos()):Length()
  return (nRatio * math.Clamp(ratiom / plyd, 1, ratioc))
end

function TOOL:DrawUCS(vO, vF, vL, vA, nN, nR)
  local xyO =  vO:ToScreen()
  local xyX = (vO + nN * vF):ToScreen()
  local xyY = (vO + nN * vL):ToScreen()
  local xyZ = (vO + nN * vA):ToScreen()
  drawLineSpinner  (xyO, xyX, "r")
  drawLineSpinner  (xyO, xyY, "g")
  drawLineSpinner  (xyO, xyZ, "b")
  drawCircleSpinner(xyO, nR , "y")
end

function TOOL:DrawHUD()
  if(self:GetAdviser()) then
    local ply   = LocalPlayer()
    local stTr  = ply:GetEyeTrace()
    if(not stTr) then return end
    local trEnt = stTr.Entity
    local axis  = self:GetDrawScale()
    local radc  = self:GetRadiusRatio(stTr, ply)
    if(stTr.HitWorld) then
      local vF, vL, vA = self:RecalculateUCS(stTr.HitNormal, ply:GetRight())
      self:DrawUCS(stTr.HitPos, vF, vL, vA, axis, radc)
    elseif(trEnt and trEnt:IsValid()) then
      local cls = trEnt:GetClass()
      if(cls == gsSentHash) then
        local trAng = trEnt:GetAngles()
        local trCen = trEnt:LocalToWorld(trEnt:GetSpinCenter())
        local nP, nL = trEnt:GetPower(), trEnt:GetLever()
        local nF, nE = axis * (nP / varMaxScale:GetFloat()), axis * (nP / math.abs(nP))
        local spCnt = trEnt:GetLeverCount()
        local spAxs = trEnt:GetTorqueAxis()
        local spLev = trEnt:GetTorqueLever()
        local spAng = spLev:AngleEx(spAxs)
        local wpAng, dA = Angle(), (360 / spCnt)
        local wvAxs = Vector(); wvAxs:Set(spAxs); wvAxs:Rotate(trAng)
        local xyOO, xyOA = trCen:ToScreen(), (axis * wvAxs + trCen):ToScreen()
        drawLineSpinner(xyOO, xyOA, "b")
        drawCircleSpinner(xyOO, radc, "y")
        for ID = 1, spCnt do
          wpAng:Set(trEnt:LocalToWorldAngles(spAng))
          local vLev = wpAng:Forward(); vLev:Mul(nL); vLev:Add(trCen)
          local vFrc = wpAng:Right(); vFrc:Mul(-1)
          local xyLE = vLev:ToScreen(); drawLineSpinner(xyOO, xyLE, "g")
          if(nP ~= 0) then
            local vF, vE = (nF * vFrc), (nE * vFrc); vF:Add(vLev); vE:Add(vLev)
            local xyFF = vF:ToScreen(); drawLineSpinner(xyLE, xyFF, "y")
            local xyFE = vE:ToScreen(); drawLineSpinner(xyFF, xyFE, "r")
          end; spAng:RotateAroundAxis(spAxs, dA)
        end
      elseif(cls == "prop_physics") then
        local trAng, vF, vL, vA = trEnt:GetAngles()
        local trCen, vMax = trEnt:GetRenderBounds()
              trCen:Add(vMax); trCen:Mul(0.5)
              trCen:Set(trEnt:LocalToWorld(trCen))
        if(input.IsKeyDown(KEY_LALT)) then -- Read client vectors
          vF, vL, vA = self:RecalculateUCS(self:GetVectors())
          vF:Rotate(trAng); vL:Rotate(trAng); vA:Rotate(trAng)
        else -- Use the autogenerated trace vectors based on player right
          vF, vL, vA = self:RecalculateUCS(stTr.HitNormal, ply:GetRight())
        end -- Create and draw the coordinate system
        self:DrawUCS(trCen, vF, vL, vA, axis, radc)
      end
    end
  end
end

-- Enter `spawnmenu_reload` in the console to reload the panel
function TOOL.BuildCPanel(CPanel) local pItem
  local nMaxLine  = varMaxLine:GetFloat()
  local nMaxScale = varMaxScale:GetFloat()
  CPanel:ClearControls(); CPanel:DockPadding(5, 0, 5, 10)
  pItem = CPanel:SetName(getPhrase("tool."..gsToolName..".name"))
  pItem = CPanel:Help   (getPhrase("tool."..gsToolName..".desc"))

  pItem = vgui.Create("ControlPresets", CPanel)
  pItem:SetPreset(gsToolName)
  pItem:AddOption("Default", gtConvar)
  for key, val in pairs(table.GetKeys(gtConvar)) do
    pItem:AddConVar(val) end
  CPanel:AddItem(pItem)

  setComboBoxPanel(CPanel, "constraint", 4)
  setComboBoxPanel(CPanel, "diraxis"   , 6)
  setComboBoxPanel(CPanel, "dirlever"  , 6)

  pItem = vgui.Create("CtrlNumPad", CPanel)
  pItem:SetLabel1(getPhrase("tool."..gsToolName..".keyfwd_con"))
  pItem:SetLabel2(getPhrase("tool."..gsToolName..".keyrev_con"))
  pItem:SetConVar1(gsToolNameU.."keyfwd")
  pItem:SetConVar2(gsToolNameU.."keyrev")
  pItem.NumPad1:SetTooltip(getPhrase("tool."..gsToolName..".keyfwd"))
  pItem.NumPad2:SetTooltip(getPhrase("tool."..gsToolName..".keyrev"))
  CPanel:AddPanel(pItem)

  setNumSliderPanel(CPanel, "mass"     , 1, varMaxMass:GetFloat(), 3)
  setNumSliderPanel(CPanel, "power"    ,-nMaxScale, nMaxScale, 3)
  setNumSliderPanel(CPanel, "friction" , 0, nMaxScale, 3)
  setNumSliderPanel(CPanel, "forcelim" , 0, nMaxScale, 3)
  setNumSliderPanel(CPanel, "torqulim" , 0, nMaxScale, 3)
  setNumSliderPanel(CPanel, "lever"    , 0, nMaxScale, 3)
  setNumSliderPanel(CPanel, "levercnt" , 1, gnMaxAng , 0)
  setNumSliderPanel(CPanel, "radius"   , 0, varMaxRadius:GetFloat(), 3)

  pItem = CPanel:Button(getPhrase("tool."..gsToolName..".resetoffs_con"), gsToolNameU.."resetoffs")
       pItem:SetTooltip(getPhrase("tool."..gsToolName..".resetoffs"))

  setNumSliderPanel(CPanel, "linx"    , -nMaxLine, nMaxLine, 3)
  setNumSliderPanel(CPanel, "liny"    , -nMaxLine, nMaxLine, 3)
  setNumSliderPanel(CPanel, "linz"    , -nMaxLine, nMaxLine, 3)
  setNumSliderPanel(CPanel, "angp"    , -gnMaxAng, gnMaxAng, 3)
  setNumSliderPanel(CPanel, "angy"    , -gnMaxAng, gnMaxAng, 3)
  setNumSliderPanel(CPanel, "angr"    , -gnMaxAng, gnMaxAng, 3)
  setNumSliderPanel(CPanel, "drwscale", 0, nMaxLine, 3)
  setCheckBoxPanel (CPanel, "toggle"   )
  setCheckBoxPanel (CPanel, "nocollide")
  setCheckBoxPanel (CPanel, "ghosting" )
  setCheckBoxPanel (CPanel, "adviser"  )
end
