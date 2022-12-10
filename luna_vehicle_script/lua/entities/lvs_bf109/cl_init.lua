include("shared.lua")

function ENT:OnSpawn()
	self:RegisterTrail( Vector(40,200,70), 0, 12, 2, 1000, 400 )
	self:RegisterTrail( Vector(40,-200,70), 0, 12, 2, 1000, 400 )
end

function ENT:OnTrail( active, id )
end

function ENT:StopSounds()
end

function ENT:OnFrame()
	local FT = RealFrameTime()

	self:AnimControlSurfaces( FT )
	self:AnimLandingGear( FT )
	self:AnimCabin( FT )
end

function ENT:AnimControlSurfaces( frametime )
	local FT = frametime * 10

	local Steer = self:GetSteer()

	local Pitch = -Steer.y * 30
	local Yaw = -Steer.z * 20
	local Roll = math.Clamp(-Steer.x * 60,-30,30)

	self.smPitch = self.smPitch and self.smPitch + (Pitch - self.smPitch) * FT or 0
	self.smYaw = self.smYaw and self.smYaw + (Yaw - self.smYaw) * FT or 0
	self.smRoll = self.smRoll and self.smRoll + (Roll - self.smRoll) * FT or 0
	
	self:ManipulateBoneAngles( 1, Angle( self.smRoll,0,0) )
	self:ManipulateBoneAngles( 2, Angle( self.smRoll,0,0) )
	
	self:ManipulateBoneAngles( 6, Angle( 0,0,self.smPitch) )
	
	self:ManipulateBoneAngles( 7, Angle( self.smYaw,0,0 ) )
end

--[[
function ENT:AnimRotor( frametime )
	local RPM = self:GetRPM()
	local PhysRot = RPM < 700
	self.RPM = self.RPM and (self.RPM + RPM * frametime * (PhysRot and 3 or 1)) or 0
	
	local Rot = Angle( self.RPM,0,0)
	Rot:Normalize() 
	self:ManipulateBoneAngles( 10, -Rot )
	
	self:SetBodygroup( 14, PhysRot and 1 or 0 ) 
end
]]

function ENT:AnimCabin( frametime )
	local bOn = self:GetActive()
	
	local TVal = bOn and 0 or 1
	
	local Speed = frametime * 4
	
	self.SMcOpen = self.SMcOpen and self.SMcOpen + math.Clamp(TVal - self.SMcOpen,-Speed,Speed) or 0
	
	self:ManipulateBoneAngles( 5 , Angle( -self.SMcOpen * 80,0,0) )
end

function ENT:AnimLandingGear( frametime )
	self._smLandingGear = self._smLandingGear and self._smLandingGear + (80 *  self:GetLandingGear() - self._smLandingGear) * frametime * 8 or 0
	
	self:ManipulateBoneAngles( 8, Angle( self._smLandingGear,0,0 ) )
	
	self:ManipulateBoneAngles( 9, Angle( -self._smLandingGear,0,0 ) )
	
	self:ManipulateBoneAngles( 3, Angle( -self._smLandingGear / 2,0,0) )
	self:ManipulateBoneAngles( 4, Angle( self._smLandingGear / 2,0,0) )
end