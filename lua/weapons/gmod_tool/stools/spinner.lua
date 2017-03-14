--[[
 * Label    : The spinner tool script
 * Author   : DVD ( dvd_video )
 * Date     : 13-03-2017
 * Location : /lua/weapons/gmod_tool/stools/spinner.lua
 * Requires : /lua/entities/sent_spinner.lua
 * Created  : Using tool requirement
 * Defines  : Spinner manager script
]]--

local gsSentHash = "sent_spinner"
local gsToolName = "spinner"
local gsEntLimit = "spinners"
local gtPalette
if(CLIENT) then
  gtPalette = {}
  gtPalette["w"] = Color(255,255,255,255)
  gtPalette["r"] = Color(255, 0 , 0 ,255)
  gtPalette["g"] = Color( 0 ,255, 0 ,255)
  gtPalette["b"] = Color( 0 , 0 , 0 ,255)
  gtPalette["m"] = Color(255, 0 ,255,255)
  gtPalette["y"] = Color(255,255, 0 ,255)
  gtPalette["c"] = Color( 0 ,255,255,255)
end

if(SERVER) then

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
    eSpin:SetPos(vPos or Vector())
    eSpin:SetAngles(aAng or Angle())
    eSpin:Spawn()
    eSpin:Activate()
    eSpin:SetRenderMode(RENDERMODE_TRANSALPHA)
    eSpin:SetColor(Color(255,255,255,255))
    eSpin:DrawShadow(true)
    eSpin:PhysWake()
    eSpin:CallOnRemove("MaglevModuleNumpadCleanup", onMaglevModuleRemove,
      numpad.OnDown(oPly, stSpinner.KeyF , gsSentHash.."_SpinForward_On" , eSpin ),
      numpad.OnUp  (oPly, stSpinner.KeyF , gsSentHash.."_SpinForward_Off", eSpin ),
      numpad.OnDown(oPly, stSpinner.KeyR , gsSentHash.."_SpinReverse_On" , eSpin ),
      numpad.OnUp  (oPly, stSpinner.KeyR , gsSentHash.."_SpinReverse_Off", eSpin ))
    local phSpin = eSpin:GetPhysicsObject()
    if(not (phSpin and phSpin:IsValid())) then eSpin:Remove(); return nil end
    if(not sSpin:Setup(stSpinner)) then eSpin:Remove(); return nil end
    phSpin:EnableMotion(false); eSpin.owner = oPly -- Some SPPs actually use this value
    oPly:AddCount(gsEntLimit , eSpin); oPly:AddCleanup(gsEntLimit , eSpin) -- This sets the ownership
    return eSpin
  end

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
  ["model"     ] = "models/props_phx/trains/tracks/track_1x.mdl",
  ["keyfwd"    ] = "45",
  ["keyrev"    ] = "39",
  ["lever"     ] = "10",
  ["power"     ] = "100",
  ["radius"    ] = "0",
  ["toggle"    ] = "0",
  ["connect"   ] = "0",
  ["diraxis"   ] = "0", -- gtDirectionID
  ["dirlever"  ] = "0", -- gtDirectionID
  ["drawucs"   ] = "1",
  ["nocollide" ] = "0",
  ["constraint"] = "0" --
}

local gtDirectionID = {}
      gtDirectionID[1] = Vector( 1, 0, 0)
      gtDirectionID[2] = Vector( 0, 1, 0)
      gtDirectionID[3] = Vector( 0, 0, 1)
      gtDirectionID[4] = Vector(-1, 0, 0)
      gtDirectionID[5] = Vector( 0,-1, 0)
      gtDirectionID[6] = Vector( 0, 0,-1)

local function GetDirectionID(nID)
  return gtDirectionID[(tonumber(nID) or 0)]
end

function TOOL:GetMass()
  return math.Clamp(self:GetClientNumber("mass"),1,100000)
end

function TOOL:GetToggle()
  return tobool(self:GetClientNumber("toggle")) and true or false
end

function TOOL:GetPower()
  return math.Clamp(self:GetClientNumber("power"),0,100000)
end

function TOOL:GetRadius()
  return math.Clamp(self:GetClientNumber("radius"),0,1000)
end

function TOOL:GetLever()
  return math.Clamp(self:GetClientNumber("lever"),0,100000)
end

function TOOL:GetModel()
  return (self:GetClientInfo("model") or "")
end

function TOOL:GetKeys()
  return math.Clamp(self:GetClientNumber("keyfwd"),0,255),
         math.Clamp(self:GetClientNumber("keyrev"),0,255)
end

function TOOL:GetDrawUCS()
  return tobool(self:GetClientNumber("drawucs")) and true or false
end

function TOOL:GetLocalUCS()
  return math.floor(math.Clamp((self:GetClientNumber("diraxis" ) or 0), 0, 6)),
         math.floor(math.Clamp((self:GetClientNumber("dirlever") or 0), 0, 6))
end

function TOOL:GetNoCollide()
  return tobool(self:GetClientNumber("nocollide")) and true or false
end

function TOOL:LeftClick(stTrace)
  if(CLIENT) then return true end
  if(not stTrace.Hit) then return true end
  local stSpinner = {}
  local ply       = self:GetOwner()
  local dax, dlev = self:GetLocalUCS()
  stSpinner.Mass  = self:GetMass()
  stSpinner.Prop  = self:GetModel()
  stSpinner.Power = self:GetPower()
  stSpinner.Lever = self:GetLever()
  stSpinner.Togg  = self:GetToggle()
  stSpinner.KeyF, stSpinner.KeyR = self:GetKeys()
  local trEnt = stTrace.Entity
  if(stTrace.HitWorld) then
    if(dax == 0) then
      stSpinner.AxiL = stTrace.HitNormal -- Needs to automate the local variant
    else stSpinner.AxiL = GetDirectionID(dax) end
    if(dlev == 0) then
      stSpinner.LevL = ply:GetRight() -- Needs to automate the local variant
    else stSpinner.LevL = GetDirectionID(dlev) end
    if(dax ~= 0 and dlev ~= 0 and -- Do not spawn with invalid user axises
      stSpinner.AxiL:Dot(stSpinner.LevL) ~= 0) then return false end
    local eSpin = newSpinner(ply, vPos, aAng, stSpinner)
    if(eSpin) then
      undo.Create("Spinner")
        undo.AddEntity(eSpin)
        if(self:GetNoCollide() and trEnt and trEnt:IsValid()) then
          local cNc = constraint.NoCollide(eSpin, trEnt, 0, stTrace.PhysicsBone)
          if(cNc) then undo.AddEntity(cNc) end
        end
        undo.SetCustomUndoText("Spinner")
        undo.SetPlayer(ply)
      undoFinish()
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
      local model = string.GetFileFromFilename(trEnt:GetModel())
      ply:ConCommand(gsToolName.."_model "..model.."\n")
      ply:SendLua("GAMEMODE:AddNotify(\"Model: "..model.." selected !\", NOTIFY_UNDO, 6)")
      ply:SendLua("surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")"); return true
    elseif(cls == gsSentHash) then
      local phEnt = trEnt:GetPhysicsObject()
      ply:ConCommand(gsToolName.."_power " ..tostring(trEnt:GetPower()).."\n")
      ply:ConCommand(gsToolName.."_lever " ..tostring(trEnt:GetLever()).."\n")
      ply:ConCommand(gsToolName.."_toggle "..tostring(trEnt:GetToggle() and 1 or 0).."\n")
      ply:ConCommand(gsToolName.."_mass "  ..tostring(phEnt:GetMass()).."\n")
      ply:SendLua("GAMEMODE:AddNotify(\"Settings retrieved !\", NOTIFY_UNDO, 6)")
      ply:SendLua("surface.PlaySound(\"ambient/water/drip"..math.random(1, 4)..".wav\")"); return true
    end; return false
  end; return false
end

function TOOL:DrawHUD()
  if(self.GetDrawUCS()) then
    local stTrace = LocalPlayer():GetEyeTrace()
    local trEnt = stTrace.Entity
    if(trEnt and trEnt:IsValid() and trEnt:GetClass() == gsSentHash) then
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
      surface.DrawCircle(xyOO.x,xyOO.y,13,gtPalette["y"])
    end
  end
end

local ConVarList = TOOL:BuildConVarList()
function TOOL.BuildCPanel(CPanel)
  local CurY, pItem = 0 -- pItem is the current panel created
          CPanel:SetName(language.GetPhrase("tool."..gsToolName..".name"))
  pItem = CPanel:Help   (language.GetPhrase("tool."..gsToolName..".desc")); CurY = CurY + pItem:GetTall() + 2

  pItem = CPanel:AddControl( "ComboBox",{
              MenuButton = 1,
              Folder     = gsToolName,
              Options    = {["#Default"] = ConVarList},
              CVars      = table.GetKeys(ConVarList)}); CurY = CurY + pItem:GetTall() + 2

  CPanel:CheckBox("NoCollide with trace", gsToolName.."_nocollide")

  local pComboConst = CPanel:ComboBox("Axis direction", gsToolName.."_constraint")
        pComboConst:SetPos(2, CurY)
        pComboConst:SetTall(20)
        pComboConst:AddChoice("Skip", 0)
        pComboConst:AddChoice("Weld", 1)
        pComboConst:AddChoice("Axis", 2)
        pComboConst:AddChoice("Ball", 3)
        CurY = CurY + pComboConst:GetTall() + 2

  local pComboAxis = CPanel:ComboBox("Axis direction", gsToolName.."_diraxis")
        pComboAxis:SetPos(2, CurY)
        pComboAxis:SetTall(20)
        pComboAxis:AddChoice("Auto", 0)
        pComboAxis:AddChoice("+X"  , 1)
        pComboAxis:AddChoice("+Y"  , 2)
        pComboAxis:AddChoice("+Z"  , 3)
        pComboAxis:AddChoice("-X"  , 4)
        pComboAxis:AddChoice("-Y"  , 5)
        pComboAxis:AddChoice("-Z"  , 6)
        CurY = CurY + pComboAxis:GetTall() + 2

  local pComboAxis = CPanel:ComboBox("Lever direction", gsToolName.."_dirlever")
        pComboAxis:SetPos(2, CurY)
        pComboAxis:SetTall(20)
        pComboAxis:AddChoice("Auto", 0)
        pComboAxis:AddChoice("+X"  , 1)
        pComboAxis:AddChoice("+Y"  , 2)
        pComboAxis:AddChoice("+Z"  , 3)
        pComboAxis:AddChoice("-X"  , 4)
        pComboAxis:AddChoice("-Y"  , 5)
        pComboAxis:AddChoice("-Z"  , 6)
        CurY = CurY + pComboAxis:GetTall() + 2
end






