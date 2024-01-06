#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <csm>
#include <fakemeta_util>
#include <hamsandwich>
#include <reapi>

#define V_MODEL "models/zbz/wpn/v_desperado_d3a3.mdl"
#define P_MODEL "models/zbz/wpn/p_desperado_m_d3a3.mdl"
#define P_MODEL2 "models/zbz/wpn/p_desperado_w_d3a3.mdl"
#define W_MODEL "models/zbz/wpn/w_secgroup1.mdl"

#define CSW_DESPERADO CSW_DEAGLE
#define weapon_desperado "weapon_deagle"


new const TRACER_ENTITY[][]={ "info_target", "func_breakable", "func_pushable", "func_wall", "func_wall_toggle", "func_door", "func_door_rotating",
		"func_button", "func_conveyor", "hostage_entity", "func_tank", "func_tankmortar", "func_tanklaser", "func_tankrocket", "button_target" }
		
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn, g_Attack, g_Event

new const WeaponSounds[] = "weapons/dprdb-1.wav"
public plugin_precache()
{
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(P_MODEL2)
	precache_model(W_MODEL)
	
	engfunc(EngFunc_PrecacheSound, "weapons/dprd_reload_m.wav")
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	precache_sound(WeaponSounds)
}

public plugin_init()
{
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	RegisterHookChain(RG_CBaseEntity_FireBullets3, "RG_FireBullets3")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	for(new i=0; i<sizeof(TRACER_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, TRACER_ENTITY[i], "fw_TraceAttack")
		
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_desperado, "fw_Weapon_WeaponIdle_Post", 1);
	RegisterHam(Ham_Item_Deploy, weapon_desperado, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, weapon_desperado, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Item_PostFrame, weapon_desperado, "fw_Item_PostFrame");	
	RegisterHam(Ham_Weapon_Reload, weapon_desperado, "fw_Weapon_Reload");
	RegisterHam(Ham_Weapon_Reload, weapon_desperado, "fw_Weapon_Reload_Post", 1);	
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	cs_register_custom_item("Python Desperado", 1500, 1, "GiveDSP", "desperado")
}

public fw_PrecacheEvent_Post(type, const name[])
	if(equal("events/deagle.sc", name)) g_Event = get_orig_retval()
	
public fw_Remove_Item(id, itemid, slot)
{
	if(slot == 1) {
		UnSet_BitVar(g_HadWpn,id)
		UnSet_BitVar(g_Attack,id)
	}
}
public GiveDSP(id)
{
	if(!is_user_alive(id)) return;
	
	drop_weapons(id, 2)
	
	Set_BitVar(g_HadWpn,id)
	UnSet_BitVar(g_Attack,id)
	fm_give_item(id, "weapon_deagle")
	
	cs_set_user_bpammo(id, CSW_DESPERADO, 200)
	
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_DESPERADO)
	if(pev_valid(Ent)) 
	{
		cs_set_weapon_ammo(Ent, 10)
		set_pev(Ent, pev_iuser3, 10)
		set_pev(Ent, pev_iuser4, 10)
	}
}

public message_DeathMsg()
{
	// get value data
	static killer, weapon[32]
	killer = get_msg_arg_int(1)
	get_msg_arg_string(4, weapon, charsmax(weapon))
	
	if(Get_BitVar(g_HadWpn, killer) && equal(weapon, "deagle"))
		set_msg_arg_string(4, "desperado")
		
	return PLUGIN_CONTINUE
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_DESPERADO && Get_BitVar(g_HadWpn, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}
public RG_FireBullets3(iAttacker, Float:vecSrc[3], Float:vecDirShooting[3], Float:vecSpread, Float:flDistance, iPenetration, iBulletType, iDamage, Float:flRangeModifier, pevAttacker, bool:bPistol, shared_rand)
{
	if(!is_user_connected(iAttacker) || !Get_BitVar(g_HadWpn, iAttacker) || get_user_weapon(iAttacker) != CSW_DESPERADO) 
		return HC_CONTINUE;
	
	if(Get_BitVar(g_Attack, iAttacker))
		SetHookChainArg(8, ATYPE_INTEGER, 200)
	
	return HC_CONTINUE;
}

public fw_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_DESPERADO || !Get_BitVar(g_HadWpn, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3], pHit
		
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)
	get_tr2(Ptr, TR_pHit, pHit)
			
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
	
	if(equal(model, "models/w_deagle.mdl"))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_desperado, entity)
		if(Get_BitVar(g_HadWpn, iOwner) && pev_valid(weapon))
		{
			set_pev(weapon, pev_impulse, 2031) 
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			UnSet_BitVar(g_HadWpn,iOwner)
			UnSet_BitVar(g_Attack,iOwner)
			set_pev(entity, pev_body, 4)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2031)
	{
		Set_BitVar(g_HadWpn, id)
		set_pev(Ent, pev_impulse, 0)
	}
		
	return HAM_HANDLED
}

public fw_Weapon_WeaponIdle_Post( iEnt )
{
	if(pev_valid(iEnt) != 2)
		return HAM_IGNORED
	static Id; Id = get_pdata_cbase(iEnt, 41, 4)
	if(get_pdata_cbase(Id, 373) != iEnt)
		return HAM_IGNORED
	if(!Get_BitVar(g_HadWpn, Id))
		return HAM_IGNORED
		
	if(get_pdata_float(iEnt, 48, 4) <= 0.1)
	{
		if(pev(iEnt, pev_iuser2)!=1)
			Set_WeaponAnim(Id, pev(iEnt, pev_iuser1) ? 8 : 0)
		else Set_WeaponAnim(Id, pev(iEnt, pev_iuser1) ? 10 : 2)
		set_pdata_float(iEnt, 48, 20.0, 4)
		return HAM_HANDLED
	}	
	return HAM_IGNORED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_DESPERADO|| !Get_BitVar(g_HadWpn, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	static Ent; Ent = fm_get_user_weapon_entity(invoker, CSW_DESPERADO)
	new Float:origin[3]; pev(invoker, pev_origin, origin)
	Set_WeaponAnim(invoker, pev(Ent, pev_iuser1)?13:5)
	emit_sound(invoker, CHAN_WEAPON, WeaponSounds, 1.0, 0.6, 0, PITCH_NORM)

	return FMRES_SUPERCEDE
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) != CSW_DESPERADO || !Get_BitVar(g_HadWpn, id))
		return FMRES_IGNORED
		
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_DESPERADO)
	static CurButton;CurButton = get_uc(uc_handle, UC_Buttons)
	static iClip, bpammo; iClip = get_pdata_int(Ent, 51, 4);
	bpammo = cs_get_user_bpammo(id, CSW_DESPERADO)
	
	if((CurButton&IN_ATTACK) && get_pdata_float(id, 83, 5) <= 0.0)
	{
		CurButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons,CurButton);
		
		set_pev(Ent, pev_iuser2, 0);
		if(pev(Ent, pev_iuser1))
		{
			Set_WeaponAnim(id, 15);
			set_pev(Ent, pev_iuser1, 0);
	
			set_pdata_float(Ent, 46, 0.12, 4)
			set_pdata_float(Ent, 47, 0.12, 4)
			
			set_pdata_float(Ent, 48, 0.12 + 0.5, 4);
			set_pev(Ent, pev_iuser3, iClip)
			if(pev(Ent, pev_iuser4) < 10)
			{
				set_pdata_int(Ent, 51, pev(Ent, pev_iuser4) + (min(10 - pev(Ent, pev_iuser4), bpammo)), 4);
				cs_set_user_bpammo(id, CSW_DESPERADO, bpammo - (min(10 - pev(Ent, pev_iuser4), bpammo)))
			} else set_pdata_int(Ent, 51, pev(Ent, pev_iuser4), 4); 
			set_pev(Ent, pev_iuser4, 0)
			
			set_pev(id, pev_weaponmodel2, P_MODEL)
		} else {
			if(get_pdata_float(Ent, 51, 4) > 0 && get_pdata_float(Ent, 46, 4) <= 0.0)
			{
				Set_BitVar(g_Attack,id)
				ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)
				UnSet_BitVar(g_Attack,id)
				
				set_pdata_float(Ent, 46, 0.12, 4);
				set_pdata_float(Ent, 47, 0.12, 4);
				set_pdata_float(Ent, 48, 0.12 + 0.5, 4);
			}
		}
	}
	if((CurButton&IN_ATTACK2) && get_pdata_float(id, 83, 5) <= 0.0)
	{
		set_pev(Ent, pev_iuser2, 0);
		
		if(pev(Ent, pev_iuser1)!=1)
		{
			Set_WeaponAnim(id, 7);
			set_pev(Ent, pev_iuser1, 1);
	
			set_pdata_float(Ent, 46, 0.12, 4)
			set_pdata_float(Ent, 47, 0.12, 4)
			
			set_pdata_float(Ent, 48, 0.12 + 0.5, 4);
			set_pev(Ent, pev_iuser4, iClip)
			if(pev(Ent, pev_iuser3) < 10)
			{
				set_pdata_int(Ent, 51, pev(Ent, pev_iuser3) + (min(10 - pev(Ent, pev_iuser3), bpammo)), 4);
				cs_set_user_bpammo(id, CSW_DESPERADO, bpammo - (min(10 - pev(Ent, pev_iuser3), bpammo)))
			} else set_pdata_int(Ent, 51, pev(Ent, pev_iuser3), 4);
			set_pev(Ent, pev_iuser3, 0)
			
			set_pev(id, pev_weaponmodel2, P_MODEL2)
		} else {
			if(get_pdata_float(Ent, 51, 4) > 0 && get_pdata_float(Ent, 46, 4) <= 0.0)
			{
				Set_BitVar(g_Attack,id)
				ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)
				UnSet_BitVar(g_Attack,id)
				
				set_pdata_float(Ent, 46, 0.12, 4);
				set_pdata_float(Ent, 47, 0.12, 4);
				set_pdata_float(Ent, 48, 0.12 + 0.5, 4);
			}
		}
	}
	
	if(get_pdata_float(Ent, 46, 4) > 0.0)
		return FMRES_IGNORED
	
	if(get_speed(id) > 150 && (CurButton&IN_FORWARD) && get_entity_flags(id) & FL_ONGROUND)
	{
		if(pev(Ent, pev_iuser2)!=1)
		{
			Set_WeaponAnim(id, pev(Ent, pev_iuser1)?9:1)
			set_pdata_float(Ent, 48, 0.5, 4)
			set_pev(Ent, pev_iuser2, 1);
		}
		
	} else {
		if(pev(Ent, pev_iuser2)==1)
		{
			set_pdata_float(Ent, 48, 0.5, 4)
			set_pev(Ent, pev_iuser2, 0);
			Set_WeaponAnim(id, pev(Ent, pev_iuser1)?11:3)
		}
	}
	return FMRES_IGNORED
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
	set_pev(Id, pev_weaponmodel2, pev(Ent, pev_iuser1)?P_MODEL2:P_MODEL)
	
	if(get_speed(Id) > 150 && get_entity_flags(Id) & FL_ONGROUND)
	{
		set_pev(Ent, pev_iuser2, 1);
		Set_WeaponAnim(Id, pev(Ent, pev_iuser1)?9:1);
		set_pdata_float(Ent, 48, 0.5, 4);
	} else {
		Set_WeaponAnim(Id, pev(Ent, pev_iuser1)?12:4);
		set_pev(Ent, pev_iuser2, 0);
	}
}
public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_HadWpn, id))
		return HAM_IGNORED	
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_DESPERADO)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(10 - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)	
		cs_set_user_bpammo(id, CSW_DESPERADO, bpammo - temp1)
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
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_DESPERADO)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0)
		return HAM_SUPERCEDE
	if(iClip >= 10)
		return HAM_SUPERCEDE			
	set_pev(ent, pev_iuser2, 0);
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
	{
		set_pdata_float(ent, 46, 0.92, 4);
		set_pdata_float(ent, 47, 0.92, 4);
		set_pdata_float(ent, 48, 0.92 + 0.5, 4);
		
		set_pdata_float(id, 83, 0.92, 5)
		Set_WeaponAnim(id, pev(ent, pev_iuser1)?14:6)
	}
	
	return HAM_HANDLED
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
