#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <csm>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>

#define V_MODEL "models/zbz/wpn/v_buffm249s.mdl"
#define P_MODEL "models/zbz/wpn/p_buffm249s.mdl"
#define W_MODEL "models/zbz/wpn/w_buffm249s.mdl"

#define DAMAGE_A 	190
#define DAMAGE_B	735

#define CSW_BUFFM249 CSW_M249
#define weapon_buffm249 "weapon_m249"

new const TRACER_ENTITY[][]={ "info_target", "func_breakable", "func_pushable", "func_wall", "func_wall_toggle", "func_door", "func_door_rotating",
		"func_button", "func_conveyor", "hostage_entity", "func_tank", "func_tankmortar", "func_tanklaser", "func_tankrocket", "button_target" }
		
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn, g_Attack, g_Event

new const WeaponSounds[][] = 
{
	"weapons/m249buff-1.wav",
	"weapons/m249buff-1-distant.wav",
	"weapons/buffm249-2.wav",
	"weapons/buffm249_scream.wav"
}
public plugin_precache()
{
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	for(new i = 0; i<sizeof(WeaponSounds); i++)
		precache_sound(WeaponSounds[i])
}
public plugin_init()
{
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	
	RegisterHookChain(RG_CBaseEntity_FireBullets3, "RG_FireBullets3")
	
	RegisterHam(Ham_Think, "beam", "BeamTraceThink");
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	for(new i=0; i<sizeof(TRACER_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, TRACER_ENTITY[i], "fw_TraceAttack")
		
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_buffm249, "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_buffm249, "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_Deploy, weapon_buffm249, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_Holster, weapon_buffm249, "fw_Item_Holster");
	RegisterHam(Ham_Item_AddToPlayer, weapon_buffm249, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Item_PostFrame, weapon_buffm249, "fw_Item_PostFrame");	
	RegisterHam(Ham_Weapon_Reload, weapon_buffm249, "fw_Weapon_Reload");
	RegisterHam(Ham_Weapon_Reload, weapon_buffm249, "fw_Weapon_Reload_Post", 1);	
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	cs_register_custom_item("M-249 Phoenix", 6500, 6, "GiveBuffM4", "buffm249")
}

public fw_PrecacheEvent_Post(type, const name[])
	if(equal("events/m249.sc", name)) g_Event = get_orig_retval()
	
public GiveBuffM4(id)
{
	if(!is_user_alive(id)) return;
	
	drop_weapons(id, 1)
	
	Set_BitVar(g_HadWpn,id)
	UnSet_BitVar(g_Attack,id)
	fm_give_item(id, "weapon_m249")
	
}
public fw_Remove_Item(id, itemid, slot)
{
	if(slot == 0)
	{
		UnSet_BitVar(g_HadWpn,id)
		UnSet_BitVar(g_Attack,id)
	}
}

public message_DeathMsg()
{
	// get value data
	static killer, weapon[32]
	killer = get_msg_arg_int(1)
	get_msg_arg_string(4, weapon, charsmax(weapon))
	
	if(Get_BitVar(g_HadWpn, killer) && equal(weapon, "m249"))
		set_msg_arg_string(4, "buffm249")
		
	return PLUGIN_CONTINUE
}
public RG_FireBullets3(iAttacker, Float:vecSrc[3], Float:vecDirShooting[3], Float:vecSpread, Float:flDistance, iPenetration, iBulletType, iDamage, Float:flRangeModifier, pevAttacker, bool:bPistol, shared_rand)
{
	if(!is_user_connected(iAttacker) || !Get_BitVar(g_HadWpn, iAttacker) || get_user_weapon(iAttacker) != CSW_BUFFM249) 
		return HC_CONTINUE;
	
	if(Get_BitVar(g_Attack, iAttacker))
		SetHookChainArg(8, ATYPE_INTEGER, pev(iAttacker, pev_fov)  < 90 ? DAMAGE_B : DAMAGE_A)
	
	return HC_CONTINUE;
}

public fw_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_BUFFM249 || !Get_BitVar(g_HadWpn, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3], pHit
		
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)
	get_tr2(Ptr, TR_pHit, pHit)
		
	static Wpn; Wpn = get_pdata_cbase(Attacker, 373)
	if(pev_valid(Wpn)) set_pev(Wpn, pev_vuser1, flEnd);
	
	Make_BulletHole(flEnd, pHit)
	
	return HAM_IGNORED
}
public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[32]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, "models/w_m249.mdl"))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_buffm249, entity)
		if(Get_BitVar(g_HadWpn, iOwner) && pev_valid(weapon))
		{
			set_pev(weapon, pev_impulse, 2423) 
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			UnSet_BitVar(g_HadWpn,iOwner)
			UnSet_BitVar(g_Attack,iOwner)
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_PrimaryAttack(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_HadWpn, Id))
		return
		
		
	Set_BitVar(g_Attack,Id)
}

public fw_PrimaryAttack_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_HadWpn, Id))
		return
		
	if(get_pdata_int(Id, 363) < 90)
	{
		if(get_pdata_int(Ent, 51, 4) > 0)
		{
			static Float:Origin[3], Float:vecTarget[3]; pev(Ent, pev_vuser1, vecTarget)
			Stock_Get_Postion(Id, 10.0, 3.0, -2.0, Origin);
			
			Stock_DrawBeam(Origin, vecTarget);
			set_pdata_float(Ent, 46, 0.45, 4)
			set_pdata_float(Ent, 47, 0.45, 4)
			set_pdata_float(Ent, 48, 1.45, 4)
		} else {
			set_pdata_float(Ent, 46, 0.45, 4)
			set_pdata_float(Ent, 47, 0.45, 4)
			set_pdata_float(Ent, 48, 1.45, 4)
			engfunc(EngFunc_EmitSound, Id, CHAN_WEAPON, WeaponSounds[3], 1.0, 0.7, 0, 100)
		}
		
	} else {
		set_pdata_float(Ent, 46, 0.065, 4)
		set_pdata_float(Ent, 47, 0.065, 4)
		set_pdata_float(Ent, 48, 1.0, 4)
		
		new Float:vRec[3]
		pev(Id, pev_punchangle, vRec)
		xs_vec_mul_scalar(vRec, 0.65, vRec)
		set_pev(Id, pev_punchangle, vRec)
	}
		
	UnSet_BitVar(g_Attack,Id)
}
public BeamTraceThink( Ent )
{
	if ( !pev_valid( Ent ) || pev( Ent , pev_iuser1 ) != 76253 )
		return HAM_IGNORED;
		
	static Float:flDmgtime; pev( Ent , pev_dmgtime , flDmgtime )
	
	if ( flDmgtime <= get_gametime() )
	{
		engfunc( EngFunc_RemoveEntity , Ent );
		return HAM_IGNORED;
	}
	
	set_pev( Ent , pev_renderamt , floatmin(255.0, floatmax(0.0, (pev(Ent, pev_dmgtime)-get_gametime())*255.0)) );
	set_pev( Ent , pev_nextthink , get_gametime() );
	
	return HAM_IGNORED;
}
public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2423)
	{
		Set_BitVar(g_HadWpn, id)
		set_pev(Ent, pev_impulse, 0)	
	}
		
	return HAM_HANDLED
}

public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_HadWpn, id))
		return HAM_IGNORED	
	
	if(get_user_button(id) & IN_ATTACK2 && get_pdata_float(ent, 47, 4) <= 0.0)
	{
		set_pdata_int(id, 363,get_pdata_int(id, 363) == 90 ? 80 : 90)
		set_pdata_float(ent, 47, 1.0, 4);
	}
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_BUFFM249)

	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(100 - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_BUFFM249, bpammo - temp1)
		
		set_pdata_int(ent, 54, 0, 4)
		
		fInReload = 0
	}		
	
	return HAM_IGNORED
}

public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_HadWpn, id))
		return HAM_IGNORED	
		
	set_pev(ent, pev_iuser1, -1)
	
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_BUFFM249)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0)
		return HAM_SUPERCEDE
	if(iClip >= 100)
		return HAM_SUPERCEDE			
	
	set_pev(ent, pev_iuser1, iClip)
	return HAM_HANDLED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_HadWpn, id))
		return HAM_IGNORED	
		
	if((get_pdata_int(ent, 54, 4) == 1))
	{ // Reload
		if(pev(ent, pev_iuser1) == -1)
			return HAM_IGNORED;
		set_pdata_float(id, 83, 2.2, 5)
		set_pdata_float(ent, 46, 4.5, 4)
		set_pdata_float(ent, 47, 4.5, 4)
		set_pdata_float(ent, 48, 6.5, 4)
		Set_WeaponAnim(id, 3)
	}
	
	return HAM_HANDLED
}

public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_HadWpn, Id))
		return
	set_pev(Id, pev_viewmodel2, V_MODEL)
	set_pev(Id, pev_weaponmodel2, P_MODEL)
	
	set_pdata_int(Id, 363, 90)
}

public fw_Item_Holster(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_HadWpn, Id))
		return
	
	set_pdata_int(Id, 363, 90)
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_BUFFM249 && Get_BitVar(g_HadWpn, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_BUFFM249 || !Get_BitVar(g_HadWpn, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	new Float:origin[3]; pev(invoker, pev_origin, origin)
	Set_WeaponAnim(invoker, random_num(1,2))
	emit_sound(invoker, CHAN_WEAPON, WeaponSounds[pev(invoker, pev_fov) < 90 ? 2 : 0], 1.0, 0.6, 0, PITCH_NORM)
	if(pev(invoker, pev_fov) < 90)
		engfunc(EngFunc_EmitAmbientSound, invoker, origin, WeaponSounds[1], 0.45, 0.2, 0, 100)

	return FMRES_SUPERCEDE
}

stock Stock_DrawBeam(Float:vStart[3], Float:vEnd[3])
{
	new Float: flMins[3];
	new Float: flMaxs[3];
	
	static iBeamEntity; iBeamEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "beam"));
	set_pev(iBeamEntity, pev_flags, pev(iBeamEntity, pev_flags) | FL_CUSTOMENTITY);
	set_pev(iBeamEntity, pev_skin, 0);
	set_pev(iBeamEntity, pev_sequence, 0);
	
	set_pev(iBeamEntity, pev_origin, vStart);
	set_pev(iBeamEntity, pev_angles, vEnd);
	set_pev(iBeamEntity, pev_modelindex, engfunc(EngFunc_ModelIndex, "sprites/laserbeam.spr"))
	set_pev(iBeamEntity, pev_scale, 20.0);
	set_pev(iBeamEntity, pev_rendercolor, Float: { 140.0 , 140.0 , 255.0 } );
	set_pev(iBeamEntity, pev_renderamt, 255.0);
	set_pev(iBeamEntity, pev_iuser1, 76253);
	set_pev(iBeamEntity, pev_rendermode, (pev(iBeamEntity, pev_rendermode) & 0x0F))
	
	flMins[0] = floatmin(vStart[0], vEnd[0]);
	flMins[1] = floatmin(vStart[1], vEnd[1]);
	flMins[2] = floatmin(vStart[2], vEnd[2]);
	
	flMaxs[0] = floatmax(vStart[0], vEnd[0]);
	flMaxs[1] = floatmax(vStart[1], vEnd[1]);
	flMaxs[2] = floatmax(vStart[2], vEnd[2]);
	
	xs_vec_sub(flMins, vStart, flMins);
	xs_vec_sub(flMaxs, vStart, flMaxs);
	
	set_pev(iBeamEntity, pev_mins, flMins);
	set_pev(iBeamEntity, pev_maxs, flMaxs);
	
	engfunc(EngFunc_SetSize, iBeamEntity, flMins, flMaxs);
	engfunc(EngFunc_SetOrigin, iBeamEntity, vStart);
	
	set_pev(iBeamEntity, pev_nextthink, get_gametime() + 0.5);
	set_pev(iBeamEntity, pev_dmgtime, get_gametime() + 1.5);
}
stock Make_BulletHole(Float:vecOrigin[3], iEnt)
{
	static szName[16]
	format(szName, 15, "{shot%i", random_num(1,5));
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(104)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_byte(get_decal_index(szName))
	write_short(iEnt)
	message_end()
				
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(109)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(iEnt)
	write_byte(get_decal_index(szName))
	message_end()
}

stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon entity
			static wname[32]; get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}
stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(0)
	message_end()
}

stock Stock_Get_Postion(id,Float:forw,Float:right, Float:up,Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
} 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/