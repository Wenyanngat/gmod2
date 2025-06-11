AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
 
include('shared.lua')

function ENT:Initialize()
	self:SetModel( "models/weapons/w_medkit.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
 
    local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
	end
end

function ENT:Use(activator, caller) 
	if caller:Health()+45 >= caller:GetMaxHealth() then 
		caller:SetHealth(caller:GetMaxHealth())
	else
		caller:SetHealth(caller:Health()+45) 
	end
	self:Remove()
end 