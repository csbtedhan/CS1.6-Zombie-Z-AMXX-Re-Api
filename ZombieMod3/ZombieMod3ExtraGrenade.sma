#include <amxmodx>
#include <fakemeta>
#include <zombiemodlimited>
#include <hamsandwich>
#include <fakemeta_util>


new g_Frozen[33], Float:g_flFrozenTime[33], Float:g_flDamageAreaTime[2][8192], Float:g_flSmokeTime[8192]

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, "models/frozen.mdl");
	engfunc(EngFunc_PrecacheModel, "sprites/frostexp_1.spr");
	engfunc(EngFunc_PrecacheModel, "sprites/frostexp_2.spr");

	engfunc(EngFunc_PrecacheSound, "weapons/frostnova.wav");
}
public plugin_init()
{
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_Think, "fw_Think");
	RegisterHam(Ham_Think, "grenade", "fw_Grenade_Think")

	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
}
public client_disconnected(id)
{
	RemoveFrozenIce(id)
	g_Frozen[id] = 0;

}
public fw_SetModel(Ent , const Model[])
{
	if(!pev_valid(Ent)) 
		return FMRES_IGNORED
	static szClass[32]
	pev(Ent, pev_classname, szClass, 31);
	if(!equal(szClass, "grenade"))
		return FMRES_IGNORED
	
	static id; id = pev(Ent, pev_owner)
	if(!pev_valid(id) || !is_user_connected(id))
		return FMRES_IGNORED;
		
	if(!cs_zb_is_zombie(id))
	{
		if(Model[7] == 'w' && Model[8] == '_' && Model[9] == 'f' && Model[10] == 'l')
		{
			set_pev(Ent, pev_iuser4, 2001);
		}
		if(Model[7] == 'w' && Model[8] == '_' && Model[9] == 's' && Model[10] == 'm')
		{
			set_pev(Ent, pev_iuser4, 2002);
			set_pev(Ent, pev_fuser2, get_gametime()+1.7)
			set_pev(Ent, pev_dmgtime, get_gametime()+20.7)
		}
	}
	return FMRES_IGNORED;
}
public fw_Think(Ent)
{
	if(!pev_valid(Ent)) 
		return;

	static szClass[32]
	pev(Ent, pev_classname, szClass, 31);
	if(equal(szClass, "zombiezdamage"))
		VaccineDamaging(Ent)
	if(isSmoke(Ent))
		SmokeThink(Ent)
}

public event_newround(id)
{
	RemoveAllFrozenIce()
	RemoveAllSmokeGas()
}

public fw_CSZB_OnStartRound(id)
{
	RemoveFrozenIce(id)
	g_Frozen[id] = 0;
}
public fw_CSZB_OnSpawn(id)
{
	RemoveFrozenIce(id)
	g_Frozen[id] = 0;

}
public fw_CSZB_Killed(victim, attacker)
{
	g_Frozen[victim] = 0;
	RemoveFrozenIce(victim)
}
public fw_CSZB_OnPreThink(id)
{
	if(!is_user_alive(id))
		return;
		
	
	if(!cs_zb_is_zombie(id))
	{
		if(g_Frozen[id]) 
		{
			g_Frozen[id] = 0;
			RemoveFrozenIce(id)
		}
	} else {
		if(g_Frozen[id])
		{
			new Float:vOrigin[3]; pev(id, pev_vuser4, vOrigin);
			set_pev(id, pev_origin, vOrigin);
			set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
			set_pdata_float(id, 83, 0.1);
			if(g_flFrozenTime[id] <= get_gametime())
			{
				set_pev(id, pev_takedamage, 2.0);
				g_Frozen[id] = 0;
				cs_zb_set_user_unstuck(id)
				RemoveFrozenIce(id)
			}
		}
	}
}
public fw_Grenade_Think(Ent)
{
	if(!pev_valid(Ent)) 
		return HAM_IGNORED;
		
	static Float:vOrigin[3]; pev(Ent, pev_origin, vOrigin);	
	static id; id = pev(Ent, pev_owner)
	if(!pev_valid(id))
		return HAM_IGNORED;
		
	if(cs_zb_is_zombie(id) && pev(Ent, pev_iuser1) == 477 && pev(Ent, pev_iuser4) == 2003)
	{
		engfunc(EngFunc_RemoveEntity, Ent)
		return HAM_IGNORED;
	}
	
	if(pev(Ent, pev_iuser4) == 2001 && get_gametime() >= pev(Ent, pev_dmgtime))
	{
		FrostExplode(vOrigin);
		engfunc(EngFunc_RemoveEntity, Ent);
		return HAM_SUPERCEDE;
	}
	if(pev(Ent, pev_iuser4) == 2002)
	{
		if(pev(Ent, pev_fuser2) <= get_gametime())
		{
			if((pev(Ent, pev_flags) & FL_ONGROUND && pev(Ent, pev_gamestate) == 0) || pev(Ent, pev_gamestate) != 0)
			{
				if(pev(Ent, pev_iuser3) != 1)
				{
					NitroNadeSmoking(Ent);
					set_pev(Ent, pev_fuser1, get_gametime() + 15.0)
					set_pev(Ent, pev_iuser3, 1)
				}
			}
			
			if(pev(Ent, pev_fuser1) <= get_gametime() && pev(Ent, pev_iuser3) == 1)
			{
				engfunc(EngFunc_RemoveEntity, Ent);
				return HAM_SUPERCEDE;
			}
		}
	}
	return HAM_IGNORED;
}
// Frost Explode
public FrostExplode(Float:vOrigin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte( TE_EXPLOSION );
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2]+20.0)
	write_short(engfunc(EngFunc_ModelIndex, "sprites/frostexp_1.spr"))
	write_byte(15);
	write_byte(30);
	write_byte(14);
	message_end();
	
	engfunc(EngFunc_EmitAmbientSound, 0 , vOrigin, "weapons/frostnova.wav", 1.0, 0.8, 0, 100);
	
	static pEnt, Float:pOrigin[3];
	pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, 250.0)) != 0 )
	{
		if(!pev_valid(pEnt) || !is_user_alive(pEnt) || !cs_zb_is_zombie(pEnt))
			continue;
				
		pev(pEnt, pev_origin, pOrigin);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte( TE_EXPLOSION );
		engfunc(EngFunc_WriteCoord, vOrigin[0])
		engfunc(EngFunc_WriteCoord, vOrigin[1])
		engfunc(EngFunc_WriteCoord, vOrigin[2])
		write_short(engfunc(EngFunc_ModelIndex, "sprites/frostexp_2.spr"))
		write_byte(15);
		write_byte(30);
		write_byte(14);
		message_end();
	
		set_pev(pEnt, pev_takedamage, 0.0)
		set_pev(pEnt, pev_vuser4, pOrigin);
		MakeFrozenIce(pEnt)
		g_Frozen[pEnt] = 1;
		g_flFrozenTime[pEnt] = get_gametime() + 3.0;
	}
	
}
// Vaccine Nade
public NitroNadeSmoking(ent)
{
	if(!pev_valid(ent))
		return;
		
	static Float:vel[3]
	vel[0] = random_float(-200.0, 200.0)
	vel[1] = random_float(-200.0, 200.0)
	vel[2] = random_float(240.0, 270.0)
					
	set_pev(ent, pev_velocity, vel)
	set_pev(ent, pev_iuser3, 1)
	set_pev(ent, pev_fuser1, get_gametime() + 15.0)
				
	new Float:origin[3], Float:color[3], Float:pos[3], Float:flAngle, pevAttacker = pev(ent, pev_owner)
	pev(ent, pev_origin, origin)
	
	if(!cs_zb_is_zombie(pevAttacker))
	{
		new pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		set_pev(pEnt, pev_origin, origin);
		set_pev(pEnt, pev_classname, "zombiezdamage")
		set_pev(pEnt, pev_fuser1, 350.0);
		set_pev(pEnt, pev_fuser2, 50.0);
		set_pev(pEnt, pev_owner, pevAttacker);
		set_pev(pEnt, pev_nextthink, get_gametime())
		g_flDamageAreaTime[0][pEnt] = get_gametime() + 15.0;
		g_flDamageAreaTime[1][pEnt] = get_gametime();
	}
	
	emit_sound(ent, CHAN_STATIC, "weapons/sg_explode.wav", 1.0, 0.6, 0, 100)
	for(new i=0;i<6;i++)
	{
		get_spherical_coord(origin, 50.0, flAngle, 0.0, pos);
		flAngle += 60.0;
		color = Float:{180.0, 230.0, 255.0}
		MakeSmoke(pos, color, 15.0, 0.1, 3.1)
	}
}
public VaccineDamaging(Ent)
{
	if(!pev_valid(Ent))
		return;
	
	new pevAttacker = pev(Ent, pev_owner)
	new Float:vOrigin[3]; pev(Ent, pev_origin, vOrigin);
	
	if(g_flDamageAreaTime[0][Ent] <= get_gametime() || cs_zb_is_zombie(pevAttacker))
	{
		engfunc(EngFunc_RemoveEntity, Ent)
		return;
	}
	set_pev(Ent, pev_nextthink, get_gametime())
	
	if(g_flDamageAreaTime[1][Ent] > get_gametime())
		return;
	
	g_flDamageAreaTime[1][Ent] = get_gametime() + 1.0;
	static Float:pOrigin[3];
	for(new id = 0; id < get_maxplayers(); id++)
	{
		if(!is_user_connected(id) || !is_user_alive(id) || !cs_zb_is_zombie(id) || id == pevAttacker)
			continue;
		
		pev(id, pev_origin, pOrigin);
		if(vector_distance(pOrigin, vOrigin) <= 350.0 && isClearLine(pOrigin, vOrigin))
		{
			if(pev(id, pev_takedamage) > 0.0)
				ExecuteHamB(Ham_TakeDamage, id, Ent, pevAttacker, 200.0, DMG_NERVEGAS)
		}
	}
}
public SmokeThink(Ent)
{
	if(!isSmoke(Ent))
		return;
		
	set_pev(Ent, pev_nextthink, get_gametime())
	
	new Float:flTemp, Float:flMaxScale, Float:flScale;
	pev(Ent, pev_scale, flScale);
	pev(Ent, pev_fuser2, flMaxScale);
	pev(Ent, pev_fuser1, flTemp);
	set_pev(Ent, pev_scale, floatmin(flMaxScale, flScale + floatabs(flTemp - get_gametime())));
	
	if(g_flSmokeTime[Ent] <= get_gametime())
	{
		if(pev(Ent, pev_iuser1) != 1)
		{
			set_pev(Ent, pev_iuser1, 1)
			g_flSmokeTime[Ent] = get_gametime() + 0.6;
		} else {
			engfunc(EngFunc_RemoveEntity, Ent);
			return;
		}
	}
	if(pev(Ent, pev_iuser1) == 1) set_pev(Ent, pev_renderamt, floatmin(255.0, floatmax(0.0, (g_flSmokeTime[Ent]-get_gametime())*255.0)))
	
}
stock MakeSmoke(Float:vOrigin[3], Float:vColor[3], Float:flTime, Float:flSize, Float:flMaxSize)
{
	static pEnt; pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	set_pev(pEnt, pev_origin, vOrigin);
	set_pev(pEnt, pev_classname, "zombie3zsmoke");
	engfunc(EngFunc_SetModel, pEnt, "sprites/gas_puff_01.spr")
	set_pev(pEnt, pev_rendermode, kRenderTransAlpha);
	set_pev(pEnt, pev_rendercolor, vColor)
	set_pev(pEnt, pev_renderamt, 255.0);
	set_pev(pEnt, pev_iuser1, 0);
	
	set_pev(pEnt, pev_scale, flSize);
	set_pev(pEnt, pev_fuser2, flMaxSize);
	set_pev(pEnt, pev_fuser1, get_gametime());
	set_pev(pEnt, pev_nextthink, get_gametime())
	
	g_flSmokeTime[pEnt] = get_gametime() + flTime
	static Float:vAngle[3]; vAngle[2] = random_float(-90.0, 90.0)
	set_pev(pEnt, pev_angles, vAngle);
}
stock MakeFrozenIce(id)
{
	static Float:vOrigin[3]
	static pEnt; pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	pev(id, pev_origin, vOrigin);
	vOrigin[2] -= 36.0
	set_pev(pEnt, pev_origin, vOrigin);
	engfunc(EngFunc_SetModel, pEnt, "models/frozen.mdl");
	set_pev(pEnt, pev_classname, "zombifrozen");
	set_pev(pEnt, pev_body, 1);
	set_pev(pEnt, pev_owner, id);
}
stock isSmoke(Ent)
{
	if(!pev_valid(Ent)) return 0;
	
	static szClassName[32]; pev(Ent, pev_classname,szClassName, 31);
	return (equal(szClassName, "zombie3zsmoke"))
}
stock RemoveFrozenIce(id)
{
	static pEnt = -1
	while(( pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "zombifrozen")) != 0)
		if(pev_valid(pEnt) && pev(pEnt, pev_owner) == id) engfunc(EngFunc_RemoveEntity, pEnt);
}
stock RemoveAllFrozenIce()
{
	static pEnt = -1
	while(( pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "zombifrozen")) != 0)
		if(pev_valid(pEnt)) engfunc(EngFunc_RemoveEntity, pEnt);
}
stock RemoveAllSmokeGas()
{
	static pEnt = -1
	while(( pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "zombiezdamage")) != 0)
		if(pev_valid(pEnt)) engfunc(EngFunc_RemoveEntity, pEnt);

	pEnt = -1
	while(( pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "zombie3zsmoke")) != 0)
		if(pev_valid(pEnt)) engfunc(EngFunc_RemoveEntity, pEnt);
}
stock get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length  = redius * floatcos(vertical_angle, degrees)
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
}
stock isClearLine(Float:vOrigin1[3], Float:vOrigin2[3])
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vOrigin1, vOrigin2, IGNORE_MONSTERS|IGNORE_GLASS, 0, 0);
	get_tr2(0, TR_flFraction, flFraction)
	
	if (flFraction < 1.0) return 0;

	return 1;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
