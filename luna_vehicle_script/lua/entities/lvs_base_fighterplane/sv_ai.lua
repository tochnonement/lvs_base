
function ENT:OnCreateAI()
	self:StartEngine()
end

function ENT:OnRemoveAI()
	self:StopEngine()
end

function ENT:RunAI()
	local RangerLength = 15000
	local mySpeed = self:GetVelocity():Length()
	local MinDist = 600 + mySpeed

	local StartPos = self:LocalToWorld( self:OBBCenter() )

	local TraceFilter = self:GetCrosshairFilterEnts()

	local FrontLeft = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,20,0) ):Forward() * RangerLength } )
	local FrontRight = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,-20,0) ):Forward() * RangerLength } )

	local FrontLeft2 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(25,65,0) ):Forward() * RangerLength } )
	local FrontRight2 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(25,-65,0) ):Forward() * RangerLength } )

	local FrontLeft3 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(-25,65,0) ):Forward() * RangerLength } )
	local FrontRight3 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(-25,-65,0) ):Forward() * RangerLength } )

	local FrontUp = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(-20,0,0) ):Forward() * RangerLength } )
	local FrontDown = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(20,0,0) ):Forward() * RangerLength } )

	local TraceForward = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:GetForward() * RangerLength } )
	local TraceDown = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + Vector(0,0,-RangerLength) } )
	local TraceUp = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + Vector(0,0,RangerLength) } )

	local cAvoid = Vector(0,0,0)

	local myRadius = self:BoundingRadius() 
	local myPos = self:GetPos()
	local myDir = self:GetForward()
	for _, v in pairs( LVS:GetVehicles() ) do
		if v == self then continue end

		local theirRadius = v:BoundingRadius() 
		local Sub = (myPos - v:GetPos())
		local Dir = Sub:GetNormalized()
		local Dist = Sub:Length()
		
		if Dist < (theirRadius + myRadius + 200) then
			if math.deg( math.acos( math.Clamp( myDir:Dot( -Dir ) ,-1,1) ) ) < 90 then
				cAvoid = cAvoid + Dir * (theirRadius + myRadius + 500)
			end
		end
	end

	local FLp = FrontLeft.HitPos + FrontLeft.HitNormal * MinDist + cAvoid * 8
	local FRp = FrontRight.HitPos + FrontRight.HitNormal * MinDist + cAvoid * 8

	local FL2p = FrontLeft2.HitPos + FrontLeft2.HitNormal * MinDist
	local FR2p = FrontRight2.HitPos + FrontRight2.HitNormal * MinDist

	local FL3p = FrontLeft3.HitPos + FrontLeft3.HitNormal * MinDist
	local FR3p = FrontRight3.HitPos + FrontRight3.HitNormal * MinDist

	local FUp = FrontUp.HitPos + FrontUp.HitNormal * MinDist
	local FDp = FrontDown.HitPos + FrontDown.HitNormal * MinDist

	local Up = TraceUp.HitPos + TraceUp.HitNormal * MinDist
	local Dp = TraceDown.HitPos + TraceDown.HitNormal * MinDist

	local TargetPos = (FLp+FRp+FL2p+FR2p+FL3p+FR3p+FUp+FDp+Up+Dp) / 10

	local alt = (StartPos - TraceDown.HitPos):Length()
	local ceiling = (StartPos - TraceUp.HitPos):Length()

	local Throttle = math.min( (StartPos - TraceForward.HitPos):Length() / mySpeed, 1 )

	if alt < 600 or ceiling < 600 then
		if ceiling < 600 then
			Throttle = 0
		else
			Throttle = 1

			if self:GetStability() < 0.5 then
				TargetPos.z = StartPos.z + 2000
			end
		end
	else
		if self:GetStability() < 0.5 then
			TargetPos.z = StartPos.z + 600
		else
			if alt > mySpeed then
				local Target = self._LastAITarget

				if not IsValid( self._LastAITarget ) or not self:AITargetInFront( self._LastAITarget, 135 ) or not self:AICanSee( self._LastAITarget ) then
					Target = self:AIGetTarget()
				end

				if IsValid( Target ) then
					if self:AITargetInFront( Target, 65 ) then
						TargetPos = Target:GetPos() + cAvoid * 8 + Target:GetVelocity() * math.abs(math.cos( CurTime() * 150 ) ) * 3
						
						Throttle = math.min( (StartPos - TargetPos):Length() / mySpeed, 1 )

						local tr = util.TraceHull( {
							start =  StartPos,
							endpos = (StartPos + self:GetForward() * 50000),
							mins = Vector( -50, -50, -50 ),
							maxs = Vector( 50, 50, 50 ),
							filter = TraceFilter
						} )

						local CanShoot = (IsValid( tr.Entity ) and tr.Entity.LVS and tr.Entity.GetAITEAM) and (tr.Entity:GetAITEAM() ~= self:GetAITEAM() or tr.Entity:GetAITEAM() == 0) or true

						if CanShoot then
							if self:AITargetInFront( Target, 15 ) then
								--self:HandleWeapons( true )
								self:PrimaryAttack()
								
								if self:AITargetInFront( Target, 10 ) then
									--self:HandleWeapons( true, true )
								end
							end
						end
					else
						if alt > 6000 and self:AITargetInFront( Target, 90 ) then
							TargetPos = Target:GetPos()
						end
					end
				end
			else
				TargetPos.z = StartPos.z + 2000
			end
		end
		self:RaiseLandingGear()
	end

	self:SetThrottle( Throttle )

	self.smTargetPos = self.smTargetPos and self.smTargetPos + (TargetPos - self.smTargetPos) * FrameTime() or self:GetPos()

	local TargetAng = (self.smTargetPos - self:GetPos()):GetNormalized():Angle()

	self:ApproachTargetAngle( TargetAng )
end