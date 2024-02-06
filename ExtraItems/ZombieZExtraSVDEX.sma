#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <csm>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombiemodlimited>
#include <explosion>
#include <reapi>

#define V_MODEL "models/zbz/wpn/v_svdex.mdl"
#define P_MODEL "models/zbz/wpn/p_svdex.mdl"
#define W_MODEL "models/zbz/wpn/w_svdex.mdl"

#define GRENADE_DAMAGE		2750.0
#define GRENADE_RADIUS		350.0

#define CSW_SVDEX CSW_AK47
#define weapon_svdex "weapon_ak47"

new const TRACER_ENTITY[][]={ "info_target", "func_breakable", "func_pushable", "func_wall", "func_wall_toggle", "func_door", "func_door_rotating",
		"func_button", "func_conveyor", "hostage_entity", "func_tank", "func_tankmortar", "func_tanklaser", "func_tankrocket", "button_target" }
		
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn, g_Attack, g_Event

new const WeaponSounds[][] = 
{
	"weapons/svdex-1.wav",
	"weapons/svdex-2.wav"
}

// !! Sec Ammo
#define AMMO2_ID 15
#define AMMO2_AMOUNT 10

public plugin_precache()
{
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/wpn/grenade.mdl")
	
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
	RegisterHam(Ham_Touch, "grenade", "GrenadeExplode");
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	for(new i=0; i<sizeof(TRACER_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, TRACER_ENTITY[i], "fw_TraceAttack")
		
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_svdex, "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_svdex, "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_Deploy, weapon_svdex, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, weapon_svdex, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Item_PostFrame, weapon_svdex, "fw_Item_PostFrame");	
	RegisterHam(Ham_Weapon_Reload, weapon_svdex, "fw_Weapon_Reload");
	RegisterHam(Ham_Weapon_Reload, weapon_svdex, "fw_Weapon_Reload_Post", 1);	
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_svdex, "fw_Weapon_WeaponIdle_Post", 1);

	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	cs_register_custom_item("SVD MOD+ M-203", 7500, 4, "GiveBuffM4", "svdex")
}

public fw_PrecacheEvent_Post(type, const name[])
	if(equal("events/ak47.sc", name)) g_Event = get_orig_retval()
	
public GiveBuffM4(id)
{
	if(!is_user_alive(id)) return;
	
	drop_weapons(id, 1)
	
	Set_BitVar(g_HadWpn,id)
	UnSet_BitVar(g_Attack,id)
	fm_give_item(id, weapon_svdex)
	
	set_pdata_int(Attacker, 376 + AMMO2_ID, 1, 5)

	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
	if(pev_valid(Ent)) 
	{
		cs_set_weapon_ammo(Ent, 20)
		set_pev(Ent, pev_iuser3, AMMO2_AMOUNT);
	}
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
	
	if(Get_BitVar(g_HadWpn, killer) && equal(weapon, "ak47"))
		set_msg_arg_string(4, "svdex")
		
	return PLUGIN_CONTINUE
}
public RG_FireBullets3(iAttacker, Float:vecSrc[3], Float:vecDirShooting[3], Float:vecSpread, Float:flDistance, iPenetration, iBulletType, iDamage, Float:flRangeModifier, pevAttacker, bool:bPistol, shared_rand)
{
	if(!is_user_connected(iAttacker) || !Get_BitVar(g_HadWpn, iAttacker) || get_user_weapon(iAttacker) != CSW_SVDEX) 
		return HC_CONTINUE;
	
	if(Get_BitVar(g_Attack, iAttacker))
		SetHookChainArg(8, ATYPE_INTEGER, 450)
	
	return HC_CONTINUE;
}

public fw_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_SVDEX || !Get_BitVar(g_HadWpn, Attacker))
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
	
	if(equal(model, "models/w_ak47.mdl"))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_svdex, entity)
		if(Get_BitVar(g_HadWpn, iOwner) && pev_valid(weapon))
		{
			set_pev(weapon, pev_impulse, 2095) 
			set_pev(weapon, pev_iuser4, 0)
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
		return HAM_IGNORED
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return HAM_IGNORED
	if(!Get_BitVar(g_HadWpn, Id))
		return HAM_IGNORED
		
	if(pev(Ent, pev_iuser4) && get_pdata_float(Ent, 46, 4) <= 0.0)
	{
		if(pev(Ent, pev_iuser3)> 0)
		{
			CreateNade(Id)
			set_pev(Ent, pev_iuser3, pev(Ent, pev_iuser3)-1)
			Set_WeaponAnim(Id, pev(Ent, pev_iuser3)<=0?6:5)
			emit_sound(Id, CHAN_WEAPON, WeaponSounds[1], 1.0, 0.8, 0, PITCH_NORM)
			set_pdata_float(Ent, 46, 2.8, 4)
			set_pdata_float(Ent, 47, 2.8, 4)
			set_pdata_float(Ent, 48, 2.8+0.5, 4)

			//StockUpdateAmmo(Id, -1, pev(Ent, pev_iuser3))
			StockUpdateAmmo2(Id, pev(Ent, pev_iuser3))
		}
		return HAM_SUPERCEDE
	}
		
	Set_BitVar(g_Attack,Id)
	return HAM_IGNORED
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
		
	if(get_pdata_int(Ent, 51, 4) > 0 && pev(Ent, pev_iuser4)==0)
	{
		static Float:Origin[3], Float:vecTarget[3]; pev(Ent, pev_vuser1, vecTarget)
		Stock_Get_Postion(Id, 10.0, 3.0, -2.0, Origin);
		
		set_pdata_float(Ent, 46, 0.3, 4)
		set_pdata_float(Ent, 47, 0.3, 4)

		Stock_DrawBeam(Origin, vecTarget);
	}
	#if 0
	if(pev(Ent, pev_iuser4))
	{
		//StockUpdateAmmo(Id, -1, pev(Ent, pev_iuser3))
		StockUpdateAmmo2(Id, pev(Ent, pev_iuser3))
	}
	#endif 
	UnSet_BitVar(g_Attack,Id)
}
public fw_Weapon_WeaponIdle_Post( iEnt )
{
	if(pev_valid(iEnt) != 2)
		return
	static Id; Id = get_pdata_cbase(iEnt, 41, 4)
	if(get_pdata_cbase(Id, 373) != iEnt)
		return
	if(!Get_BitVar(g_HadWpn, Id))
		return
		
	if(get_pdata_float(iEnt, 48, 4) <= 0.25)
	{
		if(pev(iEnt, pev_iuser4) == 1) Set_WeaponAnim(Id, 4)
		else Set_WeaponAnim(Id, 0)
		
		set_pdata_float(iEnt, 48, 20.0, 4)
	}	
}
public BeamTraceThink( Ent )
{
	if ( !pev_valid( Ent ) || pev( Ent , pev_iuser1 ) != 76252 )
		return HAM_IGNORED;
		
	static Float:flDmgtime; pev( Ent , pev_dmgtime , flDmgtime )
	
	if ( flDmgtime <= get_gametime() )
	{
		engfunc( EngFunc_RemoveEntity , Ent );
		return HAM_IGNORED;
	}
	
	set_pev( Ent , pev_renderamt , floatmin(150.0, floatmax(0.0, (pev(Ent, pev_dmgtime)-get_gametime())*150.0)) );
	set_pev( Ent , pev_nextthink , get_gametime() );
	
	return HAM_IGNORED;
}
public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2095)
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
	#if 0
	if(pev(ent, pev_iuser4) && cs_get_user_bpammo(id, CSW_SVDEX) != pev(ent, pev_iuser3))
	{
		//set_pev(ent, pev_iuser2, cs_get_user_bpammo(id, CSW_SVDEX))
		//StockUpdateAmmo(id, -1, pev(ent, pev_iuser3))
		set_pev(ent,pev_gamestate, 1)
	}
	#endif 
	if(get_user_button(id) & IN_ATTACK2 && get_pdata_float(ent, 47, 4) <= 0.0)
	{
		set_pdata_float(ent, 46, 1.5, 4);
		set_pdata_float(ent, 47, 1.5, 4);
		set_pdata_float(ent, 48, 1.5+0.5, 4);
		set_pev(ent, pev_iuser4, 1-(pev(ent, pev_iuser4)))
		Set_WeaponAnim(id, pev(ent, pev_iuser4)?8:9)

#if 0
		if(pev(ent, pev_iuser4)) 
		{
			set_pev(ent, pev_iuser2, cs_get_user_bpammo(id, CSW_SVDEX))
			//StockUpdateAmmo(id, -1, pev(ent, pev_iuser3))
		} else {
			StockUpdateAmmo(id, get_pdata_int(ent, 51, 4), pev(ent, pev_iuser2));
		}
#endif 
	}
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_SVDEX)

	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(20 - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_SVDEX, bpammo - temp1)
		
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
	
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_SVDEX)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(pev(ent, pev_iuser4)!=0)
		return HAM_SUPERCEDE
	if(BPAmmo <= 0)
		return HAM_SUPERCEDE
	if(iClip >= 20)
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
		set_pdata_float(id, 83, 2.0, 5)
		set_pdata_float(ent, 46, 4.0, 4);
		set_pdata_float(ent, 47, 4.0, 4);
		set_pdata_float(ent, 48, 4.0+0.5, 4);
		Set_WeaponAnim(id, 2)
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
#if 0
	if(pev(Ent, pev_iuser4)) StockUpdateAmmo(Id, -1, pev(Ent, pev_iuser3))
	else 
	{
		if(pev(Ent,pev_gamestate)!=0)
			StockUpdateAmmo(Id, get_pdata_int(Ent, 51, 4), pev(Ent, pev_iuser2))
	}
#endif 
	Set_WeaponAnim(Id, pev(Ent, pev_iuser4) ? 7:3)
	set_pdata_string(Id, (492) * 4, "rifle", -1 , 20)
	Set_WpnList(Id)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_SVDEX && Get_BitVar(g_HadWpn, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_SVDEX || !Get_BitVar(g_HadWpn, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	new Float:origin[3]; pev(invoker, pev_origin, origin)
	Set_WeaponAnim(invoker, 1)
	emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.6, 0, PITCH_NORM)

	return FMRES_SUPERCEDE
}

public CreateNade(id)
{
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "grenade"))
	
	static Float:Origin[3], Float:Angles[3], Float:TargetOrigin[3], Float:Velocity[3], Float:pVelocity[3];
	
	Stock_Get_Postion(id, 0.0, 3.0, -2.0, Origin)
	Stock_Get_Postion(id, 100.0, 3.0, 12.0, TargetOrigin)
	
	pev(id, pev_velocity, pVelocity)
	pev(id, pev_v_angle, Angles)
	Angles[0] *= -1.0

	// set info for ent
	dllfunc(DLLFunc_Spawn, iEnt)
	set_pev(iEnt, pev_movetype, MOVETYPE_BOUNCE)
	engfunc(EngFunc_SetModel, iEnt, "models/zbz/wpn/grenade.mdl")
	set_pev(iEnt, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(iEnt, pev_mins, Float:{-1.0, -1.0, -1.0})
	
	set_pev(iEnt, pev_origin, Origin)
	set_pev(iEnt, pev_gravity, 0.6)
	set_pev(iEnt, pev_angles, Angles)
	set_pev(iEnt, pev_solid, SOLID_SLIDEBOX)
	set_pev(iEnt, pev_owner, id)
	set_pev(iEnt, pev_iuser1, 2046)
	set_pev(iEnt, pev_movetype, 6)
	
	xs_vec_sub(TargetOrigin, Origin, Velocity)
	xs_vec_normalize(Velocity, Velocity);
	xs_vec_mul_scalar(Velocity, 1250.0, Velocity)
	
	xs_vec_add(Velocity, pVelocity, Velocity);
	set_pev(iEnt, pev_velocity, Velocity)	

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(iEnt) // entity
	write_short(engfunc(EngFunc_ModelIndex, "sprites/smoke.spr")) // sprite
	write_byte(30)  // life
	write_byte(5)  // width
	write_byte(200) // r
	write_byte(200);  // g
	write_byte(200);  // b
	write_byte(200); // brightness
	message_end();
}
public GrenadeExplode(Ent, iPtd)
{
	if(!pev_valid(Ent) || pev(Ent, pev_iuser1)!= 2046)return;

	static Float:vecVelocity[3], Float:vecOrigin[3]; pev(Ent, pev_origin, vecOrigin);
	static pevAttacker; pevAttacker = pev(Ent, pev_owner);
	
	pev(Ent, pev_velocity, vecVelocity)
	CSGrenadeExplosion(vecOrigin, 1, 1, vecVelocity)
	
	if(!cs_zb_is_zombie(pevAttacker))
	{
		static Float:vOrigin[3], Float:flDist, Float:flDamage, pEnt; pEnt= -1
		while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vecOrigin, GRENADE_RADIUS)) != 0 )
		{
			if(!pev_valid(pEnt))
				continue;
				
			pev(pEnt, pev_origin, vOrigin);
			flDist = vector_distance(vOrigin, vecOrigin);
			flDamage = GRENADE_DAMAGE - floatmul(GRENADE_DAMAGE, floatdiv(flDist, GRENADE_RADIUS));
			
			if(isBreakable(pEnt) && flDamage <= 0.0) flDamage = floatdiv(GRENADE_DAMAGE, 2.0)

			if(flDamage > 0.0 && pev(pEnt, pev_health) > 0.0 && pev(pEnt, pev_takedamage) > 0.0)
				ExecuteHamB(Ham_TakeDamage, pEnt, Ent, pevAttacker, flDamage, isBreakable(pEnt) ? DMG_BLAST : DMG_MORTAR);
		}
	}
	engfunc(EngFunc_RemoveEntity, Ent)
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
	set_pev(iBeamEntity, pev_modelindex, engfunc(EngFunc_ModelIndex, "sprites/smoke.spr"))
	set_pev(iBeamEntity, pev_scale, 6.0);
	set_pev(iBeamEntity, pev_rendercolor, Float: { 224.0 , 224.0 , 255.0 } );
	set_pev(iBeamEntity, pev_renderamt, 150.0);
	set_pev(iBeamEntity, pev_iuser1, 76252);
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
#if 0
public StockUpdateAmmo(id, ammo, bpammo)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_SVDEX)
	write_byte(ammo)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(bpammo)
	message_end()
	
	cs_set_user_bpammo(id, CSW_SVDEX, bpammo)
}
#endif 

public StockUpdateAmmo2(id, ammo2) set_pdata_int(id, 376 + AMMO2_ID, ammo2, 5)

public Set_WpnList(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string(Get_BitVar(g_HadWpn, id) ? "weapon_svdex" : weapon_svdex)
	write_byte(2)
	write_byte(90)
	write_byte(AMMO2_ID)
	write_byte(AMMO2_AMOUNT)
	write_byte(0)
	write_byte(1)
	write_byte(CSW_SVDEX)
	write_byte(0)
	message_end()
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
stock isBreakable(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))

	if (equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable")) return 1;
	return 0;
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
