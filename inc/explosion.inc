
public CSGrenadeExplosion(Float:vecOrigin[3], sprites, smoke, Float:vecVelocity[3])
{
	static Float:vecOut[3], Float:vecRandom[3]
	vecOut[0] = vecOrigin[0]
	vecOut[1] = vecOrigin[1]
	vecOut[2] = vecOrigin[2]
	if(vector_length(vecVelocity) > 0.0)
	{
		Stock_SetNewVelocity(20.0, vecVelocity, vecVelocity)
		xs_vec_add(vecOut, vecVelocity, vecOut)
	}
	else vecOut[2] -= 32.0;
	
	engfunc(EngFunc_TraceLine, vecOrigin, vecOut, 0, 0, 0)
	static Float:flFraction
	get_tr2(0, TR_flFraction, flFraction)
	
	static Float:vecEnd[3], Float:vecPlaneNorm[3]
	get_tr2(0, TR_vecEndPos, vecEnd)
	get_tr2(0, TR_vecPlaneNormal, vecPlaneNorm)
	
	if(flFraction != 1.0)
	{
		xs_vec_mul_scalar(vecPlaneNorm, (76.0 * 0.6), vecPlaneNorm)
		xs_vec_add(vecEnd, vecPlaneNorm, vecOut);
	}
	else vecOut=vecOrigin


	if(sprites)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(3)
		engfunc(EngFunc_WriteCoord, vecOut[0])
		engfunc(EngFunc_WriteCoord, vecOut[1])
		engfunc(EngFunc_WriteCoord, vecOut[2])
		write_short(engfunc(EngFunc_ModelIndex, "sprites/fexplo.spr"))
		write_byte(25)
		write_byte(30)
		write_byte(0)
		message_end()
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(3)
		engfunc(EngFunc_WriteCoord, vecOut[0] + random_float(-64.0, 64.0))
		engfunc(EngFunc_WriteCoord, vecOut[1] + random_float(-64.0, 64.0))
		engfunc(EngFunc_WriteCoord, vecOut[2] + random_float(30.0, 45.0))
		write_short(engfunc(EngFunc_ModelIndex, "sprites/eexplo.spr"))
		write_byte(25)
		write_byte(30)
		write_byte(0)
		message_end()

		new szDebris[64]
		format(szDebris, 63, "weapons/debris%i.wav", random(2)+1);
		engfunc(EngFunc_EmitAmbientSound, 0, vecOrigin, szDebris, 1.0, 0.65, 0, 100);
	}
	vecRandom = vecOut;
	vecRandom[0] += random_float(-64.0, 64.0);
	vecRandom[1] += random_float(-64.0, 64.0);
	vecRandom[2] += random_float(35.0, 45.0);

	xs_vec_sub(vecOrigin, vecOut, vecRandom)
	xs_vec_mul_scalar(vecRandom, 11.0, vecRandom);
	Draw_SparkShower(vecOrigin, vecRandom);
	
	Stock_DrawScorch(vecOrigin, vecVelocity)
	new iVec[3]; FVecIVec(vecOut, iVec);
	if(smoke) set_task(0.45, "Draw_AfterExplosion", 6000, iVec, 3);
}
public Draw_SparkShower(Float:vecOrigin[3], Float:vecDir[3])
{
	for(new i = 0; i<random_num(1, 3); i++)
	{
		new pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
		set_pev(pEnt, pev_origin, vecOrigin)
		set_pev(pEnt, pev_movetype, 10)
		set_pev(pEnt, pev_gravity, 0.5)
		set_pev(pEnt, pev_iuser1, random_num(3, 13))
		
		vecDir[0] += random_float(-50.0, 50.0)
		vecDir[1] += random_float(-50.0, 50.0)
		
		vecDir[2] = floatmin(120.0, vecDir[2]);
		vecDir[2] += random_float(90.0, 120.0)
		set_pev(pEnt, pev_velocity,vecDir);
		
		set_task(0.1, "Task_SparkShower", pEnt+2500,_,_,"b")
	}
}
public Draw_AfterExplosion(iParam[])
{
	new Float:vecOrigin[3];
	vecOrigin[0] = float(iParam[0])
	vecOrigin[1] = float(iParam[1])
	vecOrigin[2] = float(iParam[2])
	if(engfunc(EngFunc_PointContents, vecOrigin) == CONTENTS_WATER)
	{
		new Float:mins[3], Float:maxs[3];
		mins[0] = vecOrigin[0] - 64.0;
		mins[1] = vecOrigin[1] - 64.0;
		mins[2] = vecOrigin[2] - 64.0;
		maxs[0] = vecOrigin[0] + 64.0;
		maxs[1] = vecOrigin[1] + 64.0;
		maxs[2] = vecOrigin[2] + 64.0;

		UTIL_Bubbles(mins, maxs, 100);
	} else {
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(5)
		engfunc(EngFunc_WriteCoord, vecOrigin[0])
		engfunc(EngFunc_WriteCoord, vecOrigin[1])
		engfunc(EngFunc_WriteCoord, vecOrigin[2]-5.0)
		write_short(engfunc(EngFunc_ModelIndex, "sprites/steam1.spr"))
		write_byte(35+random(10))
		write_byte(5)
		message_end()
	}
	
}
public Task_SparkShower(pEnt)
{
	pEnt -= 2500
	if(!pev_valid(pEnt))
	{
		remove_task(pEnt+2500)
		return;
	}
	
	new Float:vecOrigin[3], Id
	pev(pEnt, pev_origin, vecOrigin)
	Id = pev(pEnt, pev_iuser1)
	if(Id <= 0)
	{
		engfunc(EngFunc_RemoveEntity, pEnt)
		remove_task(pEnt+2500)
		return;
	}
	set_pev(pEnt, pev_iuser1, Id - 1)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(9)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	message_end()
}

stock Stock_SetNewVelocity(Float:flNewSpeed, Float:vecVelocity[3], Float:vecOut[3])
{
	static Float:vecVelocityCN[3], Float:flY, Float:flX
	vecVelocityCN = vecVelocity
	flY = xs_vec_dot(vecVelocityCN, vecVelocityCN);

	if(flY) flX = floatsqroot(flNewSpeed*flNewSpeed / flY)
	xs_vec_mul_scalar(vecVelocityCN, flX, vecVelocityCN);

	if(flNewSpeed<0.0) xs_vec_mul_scalar(vecVelocityCN, -1.0, vecVelocityCN)
	vecOut = vecVelocityCN
	
	return 1
}
stock Stock_DrawScorch(Float:vecOrigin[3], Float:vecVelocity[3])
{
	static szName[16], Float:vecEnd[3], Float:vecHit[3], pHit
	format(szName, 15, "{scorch%i", random_num(1,3));
	
	vecEnd=vecOrigin
	if(vector_length(vecVelocity) > 0.0)
	{
		Stock_SetNewVelocity(20.0, vecVelocity, vecVelocity)
		xs_vec_add(vecEnd, vecVelocity, vecEnd)
	}
	else vecEnd[2] -= 20.0;

	engfunc(EngFunc_TraceLine, vecOrigin, vecEnd, 0, 0, 0)
	pHit = get_tr2(0, TR_pHit)
	get_tr2(0, TR_vecEndPos, vecHit)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(104);
	engfunc(EngFunc_WriteCoord, vecHit[0]);
	engfunc(EngFunc_WriteCoord, vecHit[1]);
	engfunc(EngFunc_WriteCoord, vecHit[2]);
	write_byte(engfunc(EngFunc_DecalIndex, szName));
	write_short(pev_valid(pHit) ? pHit : 0);
	message_end()
}
stock UTIL_Bubbles(Float:mins[3], Float:maxs[3], count)
{
	new Float:mid[3];
	mid[0] = (mins[0] + maxs[0]) * 0.5;
	mid[1] = (mins[1] + maxs[1]) * 0.5;
	mid[2] = (mins[2] + maxs[2]) * 0.5;

	new Float:flHeight = UTIL_WaterLevel(mid, mid[2], mid[2] + 1024.0);
	flHeight = flHeight - mins[2];

	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, mid, 0);
	write_byte(TE_BUBBLES);
	engfunc(EngFunc_WriteCoord, mins[0]);
	engfunc(EngFunc_WriteCoord, mins[1]);
	engfunc(EngFunc_WriteCoord, mins[2]);
	engfunc(EngFunc_WriteCoord, maxs[0]);
	engfunc(EngFunc_WriteCoord, maxs[1]);
	engfunc(EngFunc_WriteCoord, maxs[2]);
	engfunc(EngFunc_WriteCoord, flHeight);
	write_short(engfunc(EngFunc_ModelIndex, "sprites/bubble.spr"));
	write_byte(count);
	engfunc(EngFunc_WriteCoord, 8.0);
	message_end();
}

stock Float:UTIL_WaterLevel( Float:position[3], Float:minz, Float:maxz )
{
	new Float:midUp[3];
	midUp[0] = position[0];
	midUp[1] = position[1];
	midUp[2] = minz;

	if (engfunc(EngFunc_PointContents, midUp) != CONTENTS_WATER)
		return minz;

	midUp[2] = maxz
	if (engfunc(EngFunc_PointContents, midUp) == CONTENTS_WATER)
		return maxz;

	new Float:diff = maxz - minz;
	while(diff > 1.0)
	{
		midUp[2] = minz + diff/2.0
		if (engfunc(EngFunc_PointContents, midUp) == CONTENTS_WATER) minz = midUp[2];
		else maxz = midUp[2];
		diff = maxz - minz
	}

	return midUp[2]
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
