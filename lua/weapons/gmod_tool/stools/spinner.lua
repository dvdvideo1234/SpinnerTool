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
local VEC_ZERO     = Vector()
local ANG_ZERO     = Angle ()
local goTool       = TOOL
local gtLang       = {}
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
local gtDirectionID = {}
      gtDirectionID[1] = Vector( 1, 0, 0)
      gtDirectionID[2] = Vector( 0, 1, 0)
      gtDirectionID[3] = Vector( 0, 0, 1)
      gtDirectionID[4] = Vector(-1, 0, 0)
      gtDirectionID[5] = Vector( 0,-1, 0)
      gtDirectionID[6] = Vector( 0, 0,-1)

local function setTranslate(sT)  -- Override translations file
  gtLang["tool."..gsToolName..".name"       ] = "Spinner tool"
  gtLang["tool."..gsToolName..".desc"       ] = "Creates/Updates a spinner entity"
  gtLang["tool."..gsToolName..".left"       ] = "Create/Update spinner"
  gtLang["tool."..gsToolName..".left_use"   ] = "Create/Update spinner"
  gtLang["tool."..gsToolName..".right"      ] = "Copy settings"
  gtLang["tool."..gsToolName..".right_use"  ] = "Copy settings"
  gtLang["tool."..gsToolName..".reload"     ] = "Remove spinner"
  gtLang["tool."..gsToolName..".constraint" ] = "Constraint type"
  gtLang["tool."..gsToolName..".constraint0"] = "Skip linking"
  gtLang["tool."..gsToolName..".constraint1"] = "Weld spinner"
  gtLang["tool."..gsToolName..".constraint2"] = "Axis normal"
  gtLang["tool."..gsToolName..".constraint3"] = "Ball spinner"
  gtLang["tool."..gsToolName..".constraint4"] = "Ball trace"
  gtLang["tool."..gsToolName..".diraxis"    ] = "Axis direction"
  gtLang["tool."..gsToolName..".diraxis0"   ] = "<Custom>"
  gtLang["tool."..gsToolName..".diraxis1"   ] = "+X Red"
  gtLang["tool."..gsToolName..".diraxis2"   ] = "+Y Green"
  gtLang["tool."..gsToolName..".diraxis3"   ] = "+Z Blue"
  gtLang["tool."..gsToolName..".diraxis4"   ] = "-X Red"
  gtLang["tool."..gsToolName..".diraxis5"   ] = "-Y Green"
  gtLang["tool."..gsToolName..".diraxis6"   ] = "-Z Blue"
  gtLang["tool."..gsToolName..".dirlever"   ] = "Lever direction"
  gtLang["tool."..gsToolName..".dirlever0"  ] = "<Custom>"
  gtLang["tool."..gsToolName..".dirlever1"  ] = "+X Red"
  gtLang["tool."..gsToolName..".dirlever2"  ] = "+Y Green"
  gtLang["tool."..gsToolName..".dirlever3"  ] = "+Z Blue"
  gtLang["tool."..gsToolName..".dirlever4"  ] = "-X Red"
  gtLang["tool."..gsToolName..".dirlever5"  ] = "-Y Green"
  gtLang["tool."..gsToolName..".dirlever6"  ] = "-Z Blue"
  gtLang["tool."..gsToolName..".keyfwd"     ] = "Key Forward:"
  gtLang["tool."..gsToolName..".keyrev"     ] = "Key Reverse:"
  gtLang["tool."..gsToolName..".mass"       ] = "Mass: "
  gtLang["tool."..gsToolName..".power"      ] = "Power: "
  gtLang["tool."..gsToolName..".friction"   ] = "Friction: "
  gtLang["tool."..gsToolName..".forcelim"   ] = "Force limit: "
  gtLang["tool."..gsToolName..".torqulim"   ] = "Torque limit: "
  gtLang["tool."..gsToolName..".lever"      ] = "Lever length: "
  gtLang["tool."..gsToolName..".levercnt"   ] = "Lever count: "
  gtLang["tool."..gsToolName..".radius"     ] = "Sphere radius: "
  gtLang["tool."..gsToolName..".resetoffs"  ] = "V Reset offsets V"
  gtLang["tool."..gsToolName..".linx"       ] = "Offset X: "
  gtLang["tool."..gsToolName..".liny"       ] = "Offset Y: "
  gtLang["tool."..gsToolName..".linz"       ] = "Offset Z: "
  gtLang["tool."..gsToolName..".angp"       ] = "Offset pitch: "
  gtLang["tool."..gsToolName..".angy"       ] = "Offset yaw: "
  gtLang["tool."..gsToolName..".angr"       ] = "Offset roll: "
  gtLang["tool."..gsToolName..".drwscale"   ] = "Draw scale: "
  gtLang["tool."..gsToolName..".toggle"     ] = "Toggle"
  gtLang["tool."..gsToolName..".nocollide"  ] = "NoCollide with trace"
  gtLang["tool."..gsToolName..".ghosting"   ] = "Enable ghosting"
  gtLang["tool."..gsToolName..".adviser"    ] = "Enable adviser"
  local sT = tostring(sT or ""); if(sT ~= "en") then
    local fT = CompileFile(("%s/lang/%s.lua"):format(gsToolName, sT))
    local bF, fFo = pcall(fT); if(bF) then
      local bS, tTo = pcall(fFo, gsToolName); if(bS) then
        for key, val in pairs(gtLang) do gtLang[key] = (tTo[key] or gtLang[key]) end
      else ErrorNoHalt(gsToolName..": setTranslate("..sT.."): "..tostring(tTo)) end
    else ErrorNoHalt(gsToolName..": setTranslate("..sT.."): "..tostring(fFo)) end
  end; for key, val in pairs(gtLang) do language.Add(key, val) end
end

local function getPhrase(sK)
  return (gtLang[tostring(sK)] or "Oops, missing ?")
end

if(SERVER) then

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
  setTranslate(varLng:GetString())
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

local function getVector(sV)
  local v = (","):Explode(tostring(sV or ""):gsub("%[",""):gsub("%]",""))
  return Vector(tonumber(v[1]) or 0, tonumber(v[2]) or 0, tonumber(v[3]) or 0)
end

local function strVector(vV)
  return "["..tostring(vV.x or 0)..","..tostring(vV.y or 0)..","..tostring(vV.z or 0).."]"
end

local function GetDirectionID(nID)
  return gtDirectionID[(tonumber(nID) or 0)] or Vector()
end

function TOOL:GetDeviation()
  local nMaxLine = varMaxLine:GetFloat()
  return Vector(math.Clamp(self:GetClientNumber("linx"),-nMaxLine,nMaxLine),
                math.Clamp(self:GetClientNumber("liny"),-nMaxLine,nMaxLine),
                math.Clamp(self:GetClientNumber("linz"),-nMaxLine,nMaxLine)),
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
  cF:Normalize(); cL:Normalize(); cA:Normalize(); return cF, cL, cA
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

function TOOL:NotifyUser(oPly, sMsg, sTyp, nSiz)
  ply:SendLua("GAMEMODE:AddNotify(\""..sTyp.."\", NOTIFY_"..sTyp..", "..nSiz..")")
  ply:SendLua("surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")")
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
        stSpinner.Radi = 0     -- Do not recreate the physics on update
        trEnt:Setup(stSpinner) -- Apply general data from the cvars
        trEnt:ApplyTweaks()    -- No need respawn the entity to update the tweaks
        self:NotifyUser(ply, "Updated !", "UNDO", 6)
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
          if(C) then undo.AddEntity(C) end
          undo.SetCustomUndoText("Spinner link")
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
      self:NotifyUser(ply, "Selected "..sPth.." !", "UNDO", 6); return true
    elseif(cls == gsSentHash) then
      local phEnt = trEnt:GetPhysicsObject()
      ply:ConCommand(gsToolNameU.."power "   ..tostring(trEnt:GetPower()).."\n") -- Number
      ply:ConCommand(gsToolNameU.."lever "   ..tostring(trEnt:GetLever()).."\n") -- Number
      ply:ConCommand(gsToolNameU.."levercnt "..tostring(trEnt:GetLeverCount()).."\n") -- Number
      ply:ConCommand(gsToolNameU.."toggle "  ..tostring(trEnt:IsToggled() and 1 or 0).."\n")
      ply:ConCommand(gsToolNameU.."mass "    ..tostring(phEnt:GetMass()).."\n")
      self:NotifyUser(ply, "Retrieved !", "UNDO", 6); return true
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
  oEnt:SetNoDraw(false); oEnt:DrawShadow(false)
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

function TOOL:DrawHUD()
  if(self:GetAdviser()) then
    local ply   = LocalPlayer()
    local stTr  = ply:GetEyeTrace()
    if(not stTr) then return end
    local trEnt = stTr.Entity
    local axs   = self:GetDrawScale()
    local radc  = self:GetRadiusRatio(stTr, ply)
    if(stTr.HitWorld) then
      local trCen = stTr.HitPos
      local xyO = trCen:ToScreen()
      local vF, vL, vA = self:RecalculateUCS(stTr.HitNormal, ply:GetRight())
      local xyX  = (trCen + axs * vF):ToScreen()
      local xyY  = (trCen + axs * vL):ToScreen()
      local xyZ  = (trCen + axs * vA):ToScreen()
      drawLineSpinner(xyO, xyX, "r")
      drawLineSpinner(xyO, xyY, "g")
      drawLineSpinner(xyO, xyZ, "b")
      drawCircleSpinner(xyO,radc,"y")
    elseif(trEnt and trEnt:IsValid()) then
      local cls = trEnt:GetClass()
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
          local vlAn, vfAn = dAng:Forward(), dAng:Right(); vfAn:Mul(-1)
          local vLev = (nL * vlAn); vLev:Add(trCen)
          local xyLE = vLev:ToScreen(); drawLineSpinner(xyOO, xyLE, "g")
          if(nP ~= 0) then
            local vF, vE = (nF * vfAn), (nE * vfAn); vF:Add(vLev); vE:Add(vLev)
            local xyFF = vF:ToScreen(); drawLineSpinner(xyLE, xyFF, "y")
            local xyFE = vE:ToScreen(); drawLineSpinner(xyFF, xyFE, "r")
          end; dAng:RotateAroundAxis(wvAxs, dA)
        end
      elseif(cls == "prop_physics") then
        local aAng = trEnt:GetAngles()
        local trCen, vMax = trEnt:GetRenderBounds()
              trCen:Add(vMax); trCen:Mul(0.5)
              trCen:Set(trEnt:LocalToWorld(trCen))
        local xyO, vF, vL, vA = trCen:ToScreen()
        if(input.IsKeyDown(KEY_LALT)) then
          vF, vL, vA = self:RecalculateUCS(self:GetVectors())
          vF:Rotate(aAng); vL:Rotate(aAng); vA:Rotate(aAng)
        else vF, vL, vA = self:RecalculateUCS(stTr.HitNormal, ply:GetRight()) end
        local xyX  = (trCen + axs * vF):ToScreen()
        local xyY  = (trCen + axs * vL):ToScreen()
        local xyZ  = (trCen + axs * vA):ToScreen()
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
  local nMaxLine  = varMaxLine:GetFloat()
  local nMaxScale = varMaxScale:GetFloat()
  local CurY, pItem, sTr = 0 -- pItem is the current panel created
          CPanel:SetName(getPhrase("tool."..gsToolName..".name"))
  pItem = CPanel:Help   (getPhrase("tool."..gsToolName..".desc"))
  CurY  = CurY + pItem:GetTall() + 2

  pItem = CPanel:AddControl( "ComboBox",{
              MenuButton = 1,
              Folder     = gsToolName,
              Options    = {["#Default"] = conVarList},
              CVars      = table.GetKeys(conVarList)})
  CurY  = CurY + pItem:GetTall() + 2
  
  sTr = "tool."..gsToolName..".constraint"
  local pComboConst = CPanel:ComboBox(getPhrase(sTr), gsToolNameU.."constraint")
        pComboConst:SetPos(2, CurY); pComboConst:SetTall(20)
        for iD = 0, 4 do pComboConst:AddChoice(getPhrase(sTr..iD), iD) end
  CurY = CurY + pComboConst:GetTall() + 2
  
  sTr = "tool."..gsToolName..".diraxis"
  local pComboAxis = CPanel:ComboBox(getPhrase(sTr), gsToolNameU.."diraxis")
        pComboAxis:SetPos(2, CurY); pComboAxis:SetTall(20)
        for iD = 0, 6 do pComboAxis:AddChoice(getPhrase(sTr..iD), iD) end
  CurY = CurY + pComboAxis:GetTall() + 2

  sTr = "tool."..gsToolName..".dirlever"
  local pComboLever = CPanel:ComboBox(getPhrase(sTr), gsToolNameU.."dirlever")
        pComboLever:SetPos(2, CurY); pComboLever:SetTall(20)
        for iD = 0, 6 do pComboLever:AddChoice(getPhrase(sTr..iD), iD) end
  CurY = CurY + pComboLever:GetTall() + 2

  CPanel:AddControl( "Numpad", {  Label = getPhrase("tool."..gsToolName..".keyfwd"),
                  Command = gsToolNameU.."keyfwd",
                  ButtonSize = 10 } );

  CPanel:AddControl( "Numpad", {  Label = getPhrase("tool."..gsToolName..".keyrev"),
                  Command = gsToolNameU.."keyrev",
                  ButtonSize = 10 } );

  CPanel:NumSlider(getPhrase("tool."..gsToolName..".mass"     ), gsToolNameU.."mass"     , 1, varMaxMass:GetFloat(), 3)
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".power"    ), gsToolNameU.."power"    ,-nMaxScale, nMaxScale, 3)
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".friction" ), gsToolNameU.."friction" , 0, nMaxScale, 3)
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".forcelim" ), gsToolNameU.."forcelim" , 0, nMaxScale, 3)
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".torqulim" ), gsToolNameU.."torqulim" , 0, nMaxScale, 3)
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".lever"    ), gsToolNameU.."lever"    , 0, nMaxScale, 3)
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".levercnt" ), gsToolNameU.."levercnt" , 1, gnMaxAng , 3)
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".radius"   ), gsToolNameU.."radius"   , 0, varMaxRadius:GetFloat(), 3)
  CPanel:Button   (getPhrase("tool."..gsToolName..".resetoffs"), gsToolNameU.."resetoffs")
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".linx"     ), gsToolNameU.."linx"     , -nMaxLine, nMaxLine, 3)
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".liny"     ), gsToolNameU.."liny"     , -nMaxLine, nMaxLine, 3)
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".linz"     ), gsToolNameU.."linz"     , -nMaxLine, nMaxLine, 3)
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".angp"     ), gsToolNameU.."angp"     , -gnMaxAng, gnMaxAng, 3)
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".angy"     ), gsToolNameU.."angy"     , -gnMaxAng, gnMaxAng, 3)
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".angr"     ), gsToolNameU.."angr"     , -gnMaxAng, gnMaxAng, 3)
  CPanel:NumSlider(getPhrase("tool."..gsToolName..".drwscale" ), gsToolNameU.."drwscale" , 0, nMaxLine, 3)
  CPanel:CheckBox (getPhrase("tool."..gsToolName..".toggle"   ), gsToolNameU.."toggle")
  CPanel:CheckBox (getPhrase("tool."..gsToolName..".nocollide"), gsToolNameU.."nocollide")
  CPanel:CheckBox (getPhrase("tool."..gsToolName..".ghosting" ), gsToolNameU.."ghosting")
  CPanel:CheckBox (getPhrase("tool."..gsToolName..".adviser"  ), gsToolNameU.."adviser")
end

-- listen for changes to the localify language and reload the tool's menu to update the localizations
if(CLIENT) then
  cvars.RemoveChangeCallback(varLng:GetName(), gsLisp.."lang")
  cvars.AddChangeCallback(varLng:GetName(), function(sNam, vO, vN) setTranslate(vN)
    local cPanel = controlpanel.Get(goTool.Mode); if(not IsValid(cPanel)) then return end
    cPanel:ClearControls(); goTool.BuildCPanel(cPanel)
  end, gsLisp.."lang")
end
