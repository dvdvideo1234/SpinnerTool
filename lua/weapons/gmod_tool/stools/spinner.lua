--[[
 * Label    : The spinner tool script
 * Author   : DVD ( dvd_video )
 * Date     : 13-03-2017
 * Location : /lua/weapons/gmod_tool/stools/spinner.lua
 * Requires : /lua/entities/sent_spinner.lua
 * Created  : Using tool requirement
 * Defines  : Spinner manager script
]]--


if(SERVER) then

  local gsLimit = "spinners"

  cleanup.Register(gsLimit)

  function newSpinner(pPly,sModel,vPos,aAng,nMass,iKeyF,iKeyR,nPow,vDirA,nLev,vDirL)
    if(not pPly:CheckLimit(gsLimit)) then return nil end
    local eSpin = ents.Create("sent_spinner")
    if(not (eSpin and eSpin:IsValid())) then return nil end
    eSpin:SetCollisionGroup(COLLISION_GROUP_NONE)
    eSpin:SetSolid(SOLID_VPHYSICS)
    eSpin:SetMoveType(MOVETYPE_VPHYSICS)
    eSpin:SetNotSolid(false)
    eSpin:SetModel(sModel)
    eSpin:SetPos(vPos or Vector())
    eSpin:SetAngles(aAng or Angle())
    eSpin:Spawn()
    eSpin:Activate()
    eSpin:SetRenderMode(RENDERMODE_TRANSALPHA)
    eSpin:SetColor(Color(255,255,255,255))
    eSpin:DrawShadow(true)
    eSpin:PhysWake()
    local phSpin = eSpin:GetPhysicsObject()
    if(not (phSpin and phSpin:IsValid())) then eSpin:Remove(); return nil end
    phSpin:EnableMotion(false); eSpin.owner = pPly -- Some SPPs actually use this value
    phSpin:SetMass(math.Clamp(tonumber(nMass) or 1, 1, 50000))
    pPly:AddCount(gsLimit , eSpin); pPly:AddCleanup(gsLimit , eSpin) -- This sets the ownership
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
  language.Add("tool."..gsToolNameL..".1"        , "Spinner manager")
  language.Add("tool."..gsToolNameL..".left"     , "Create/Update spinner")
  language.Add("tool."..gsToolNameL..".right"    , "Copy settings")
  language.Add("tool."..gsToolNameL..".reload"   , "Remove spinner")
  language.Add("tool."..gsToolNameL..".category" , "Construction")
  language.Add("tool."..gsToolNameL..".name"     , "Spinner manager")
end

TOOL.Category   = language.GetPhrase and language.GetPhrase("tool."..gsToolNameL..".category")
TOOL.Name       = language.GetPhrase and language.GetPhrase("tool."..gsToolNameL..".name")
TOOL.Command    = nil -- Command on click (nil for default)
TOOL.ConfigName = nil -- Configure file name (nil for default)

TOOL.ClientConVar = {
  [ "mass"      ] = "25000",
  [ "model"     ] = "models/props_phx/trains/tracks/track_1x.mdl",
  [ "keyfwd"    ] = 45,
  [ "keyrev"    ] = 39,
  [ "engunsnap" ] = "0"
}

function TOOL:GetMass()
  return math.Clamp(self:GetClientNumber("mass"),1,100000)
end

function TOOL:GetModel()
  return (self:GetClientInfo("model") or "")
end


function TOOL:LeftClick(stTrace)
  if(CLIENT) then return true end
  local ply   = self:GetOwner()
  local mass  = self:GetMass()
  local model = self:GetModel()
  if(stTrace.HitWorld) then
    local vOBB = oEnt:OBBMins()
    local vPos = stTrace.HitPos - stTrace.HitNormal * vOBB.z
    local aAng = ply:GetAimVector():Angle()
          aAng.p =  aAng.p + 90
    local eSpin = newSpinner(ply, vPos, aAng)
  end
end

















