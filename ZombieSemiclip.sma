
#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <engine>

new g_EntSolid[8192]
new cvar_enable, cvar_fade, szEntityRegistered[512][32], classes_total

new szEntityBlocked[][] = { "func_vehicle" , "func_tracktrain" , "func_door" , "func_door_rotating" , "func_train" , "func_rotating" , "func_plat" , "func_platrot" }
new g_iEntityMovingEnd, g_iPlayerClashing, g_iLastClashed

const NO_WALL_WEAPONS =  (1<<CSW_P228)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_UMP45)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_MP5NAVY)|(1<<CSW_M3)|(1<<CSW_TMP)|(1<<CSW_KNIFE)|(1<<CSW_P90)


public plugin_init() 
{
	register_event("HLTV", "EventRoundStart", "a", "1=0", "2=0")
	
	cvar_enable = register_cvar("mp_semiclip", "1")
	cvar_fade  = register_cvar("mp_semiclip_fade", "1")
	
	register_forward(FM_PlayerPreThink, "fw_SemiClip_Start", 1)
	register_forward(FM_PlayerPostThink, "fw_SemiClip_End", 0)
	
	for(new x = 0 ; x < sizeof(szEntityBlocked); x ++ )
		RegisterHam(Ham_SetObjectCollisionBox, szEntityBlocked[x], "fw_EntitySemiclip_Start", 1)
	
	register_forward(FM_AddToFullPack, "fw_addToFullPack", 1)
	load_class()
}

public load_class()
{
	new linedata[32], file = fopen("entity_semiclip.txt", "rt")
	while (file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")
		if (!linedata[0] || linedata[0] == ';' || linedata[0] == '/') continue;
		
		format( szEntityRegistered[classes_total], 31, "%s", linedata)
		classes_total ++
		if(classes_total >= 512) break;
	}
	if (file) fclose(file)
}
//################################
// Event
//################################
public EventRoundStart()
{	
	unregister_forward(FM_UpdateClientData, g_iEntityMovingEnd, false)
	unregister_forward(FM_SetAbsBox, g_iPlayerClashing, false)
	g_iEntityMovingEnd = 0
}

//################################
// Render
//################################
public fw_addToFullPack(es, e, ent, host, hostflags, player, pSet)
{
	if(!get_pcvar_num(cvar_enable) || !pev_valid(host))
		return FMRES_IGNORED;
		
	new Float:flAmount, id = pev( host , pev_iuser2 )
	if ( is_user_alive( host ) ) id = host
	
	if ( !pev_valid(id) ||  !is_user_connected( id ) )
		return FMRES_IGNORED;
	
	if( isSemiClipEntity(id , ent) && !is_user_connected(ent) )
	{
		set_es(es, ES_Solid, SOLID_NOT)
		if( entity_range(ent, id) <= 130.0 && ent != id )
		{
			flAmount = entity_range(ent, id) / (130.0 / (255.0 - 10.0));
			if(get_pcvar_num(cvar_fade))
			{
				set_es(es, ES_RenderMode, kRenderTransAlpha)
				set_es(es, ES_RenderAmt, floatround((flAmount >= 0.0) ? flAmount + 10.0 : floatabs(flAmount - 255.0)) )
			}
		}	
	}
	
	if( isCostume(ent) )
	{
		new pEntity = pev(ent, pev_aiment)
		if( is_user_connected(pEntity) && entity_range(pEntity, id) <= 130.0 && pEntity != id && (get_user_team(pEntity) == get_user_team(id) || get_pcvar_num(cvar_enable) >= 2) )
		{
			flAmount = entity_range(pEntity, id) / (130.0 / (255.0 - 10.0));
			if(get_pcvar_num(cvar_fade))
			{
				set_es(es, ES_RenderMode, kRenderTransAlpha)
				set_es(es, ES_RenderAmt, floatround((flAmount >= 0.0) ? flAmount + 10.0 : floatabs(flAmount - 255.0)) )
			}
		}
	}
	
	if( !is_user_alive(ent) || !player ) 
		return FMRES_IGNORED;
		
	
	if(id != ent && (get_user_team(id) == get_user_team(ent) || get_pcvar_num(cvar_enable) >= 2) && entity_range(ent, id) <= 130.0)
	{
		flAmount = entity_range(ent, id) / (130.0 / (255.0 - 10.0));
		set_es(es, ES_Solid, SOLID_NOT)
			
		if(get_pcvar_num(cvar_fade))
		{
			set_es(es, ES_RenderMode, kRenderTransAlpha)
			set_es(es, ES_RenderAmt, floatround((flAmount >= 0.0) ? flAmount + 10.0 : floatabs(flAmount - 255.0)) )
		}
	}

	return FMRES_IGNORED
}
//################################
// Tracer Line
//################################
public fw_TraceLine_Post(Float:vStart[3], Float:vEnd[3], iNoMonsters, id, iTrace)
{
	if (!is_user_alive(id) || !get_tr2(iTrace, TR_StartSolid))
		return FMRES_IGNORED
	
	if ((1<<get_user_weapon(id)) & NO_WALL_WEAPONS)
	{
		engfunc(EngFunc_TraceLine, vStart, vEnd, IGNORE_MONSTERS, id, 0)
		static iHit
		iHit = get_tr2(0, TR_pHit)
		
		if (iHit >= 1 && iHit != get_tr2(iTrace, TR_pHit))
			return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}
//################################
// Un Block Entities
//################################
public fw_EntitySemiclip_Start(ent)
{
	if(!get_pcvar_num(cvar_enable))
		return
	
	if (PlayerSolidNot(ent, ent) && g_iEntityMovingEnd == 0)
	{
		g_iEntityMovingEnd = register_forward(FM_UpdateClientData, "fw_EntitySemiclip_End")
		g_iPlayerClashing = register_forward(FM_SetAbsBox, "fw_PlayerClashing")
		g_iLastClashed = 0
	}
}

public fw_EntitySemiclip_End(id)
{
	unregister_forward(FM_UpdateClientData, g_iEntityMovingEnd, false)
	unregister_forward(FM_SetAbsBox, g_iPlayerClashing, false)
	g_iEntityMovingEnd = 0
	
	PlayerSolid(id)
}

public fw_PlayerClashing(id)
{
	if (!pev_valid(id) || !is_user_alive(id))
		return
	
	if (g_iLastClashed && pev(g_iLastClashed, pev_solid) != SOLID_NOT)
	{
		set_pev(g_iLastClashed, pev_solid, SOLID_NOT)
	}
	
	if (pev(id, pev_solid) == SOLID_NOT)
	{
		if (pev(id, pev_flags) & FL_DUCKING)
		{
			static Float:fMaxs[3], Float:fViewOfs[3]
			pev(id, pev_maxs, fMaxs)
			pev(id, pev_view_ofs, fViewOfs)
			
			fMaxs[2] = fViewOfs[2]
			
			set_pev(id, pev_maxs, fMaxs)
		}
		
		set_pev(id, pev_solid, SOLID_SLIDEBOX)
		g_iLastClashed = id
	}
}

//#####################################
// Semiclip General
//#####################################
public fw_SemiClip_Start(id)
{
	if(!get_pcvar_num(cvar_enable) || !is_user_alive(id))
		return;
		
	static Ent, Float:vOrigin[3];
	pev(id, pev_origin, vOrigin);
		
	Ent = -1
	while((Ent = engfunc(EngFunc_FindEntityInSphere, Ent, vOrigin, 130.0)) != 0)
	{
		if(id != Ent && isSemiClipEntity(id, Ent) && g_EntSolid[Ent] == SOLID_NOT)
		{
			g_EntSolid[Ent] = pev(Ent, pev_solid)
			set_pev(Ent, pev_solid, SOLID_NOT)
		}
	}
}

public fw_SemiClip_End(id)
{
	if(!get_pcvar_num(cvar_enable) || !is_user_alive(id))
		return;
	
	static Ent, Float:vOrigin[3];
	pev(id, pev_origin, vOrigin);
	
	Ent = -1
	while((Ent = engfunc(EngFunc_FindEntityInSphere, Ent, vOrigin, 200.0)) != 0)
	{
		if(id != Ent && isSemiClipEntity(id, Ent) && g_EntSolid[Ent] != SOLID_NOT)
		{
			set_pev(Ent, pev_solid, is_user_alive(Ent) ? SOLID_SLIDEBOX : g_EntSolid[Ent])
			g_EntSolid[Ent] = SOLID_NOT
		}
	}
}

//#####################################
// Stock
//#####################################
stock PlayerSolidNot(id, i)
{
	static iNum, Float:flEntityAbsMin[3], Float:flEntityAbsMax[3], Float:flAbsMin[3], Float:flAbsMax[3]
	iNum = 0
	pev(i, pev_absmin, flEntityAbsMin)
	pev(i, pev_absmax, flEntityAbsMax)
	
	for (id = 1; id <= get_maxplayers(); id++)
	{
		if (!pev_valid(id) || !is_user_alive(id))
			continue;
		
		pev(id, pev_absmin, flAbsMin)
		pev(id, pev_absmax, flAbsMax)
		
		if (GetIntersects(flAbsMin, flAbsMax, flEntityAbsMin, flEntityAbsMax))
		{
			for (i = 1; i <= get_maxplayers(); i++)
			{
				if (pev(i, pev_solid) == SOLID_NOT || !isSemiClipEntity(id, i))
					continue
				
				set_pev(i, pev_solid, SOLID_NOT)
				iNum++
			}
		}
	}
	
	return iNum
}

stock PlayerSolid(id)
{			
	for (id = 1; id <= get_maxplayers(); id++)
	{
		if (!is_user_connected(id) || !is_user_alive(id))
			continue
		
		set_pev(id, pev_solid, SOLID_SLIDEBOX)
	}
}

stock GetIntersects(Float:flAbsMin[3], Float:flAbsMax[3], Float:flAbsMin2[3], Float:flAbsMax2[3])
{
	if (flAbsMin[0] > flAbsMax2[0] || flAbsMin[1] > flAbsMax2[1] || flAbsMin[2] > flAbsMax2[2] || flAbsMax[0] < flAbsMin2[0] || flAbsMax[1] < flAbsMin2[1] || flAbsMax[2] < flAbsMin2[2])
	{
		return 0
	}
	return 1
}
stock isSemiClipEntity(Player , Entity)
{
	if( !pev_valid(Entity) ) 
		return 0;
		
	if( !is_user_alive(Player) )
		return 0;
		
	if( is_user_alive(Entity) && (get_user_team(Entity) == get_user_team(Player) || get_pcvar_num(cvar_enable) >= 2) ) 
		return 1;
	
	static szClassName[32]; pev( Entity , pev_classname , szClassName , 31 );
	for( new i = 0 ; i < classes_total ; i ++ )
	{
		if ( equal( szClassName , szEntityRegistered[i] ) )
			return 1;
	}
	
	return 0;
}
stock isCostume(Entity)
{
	if( !pev_valid(Entity) ) return 0;
	
	static szClassName[32]; pev( Entity , pev_classname , szClassName , 31 );
	return ( equal( szClassName , "info_player_costume" ) )
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
