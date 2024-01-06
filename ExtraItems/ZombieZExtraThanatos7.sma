#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <csm>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombiemodlimited>

#define V_MODEL "models/zbz/wpn/v_thanatos7.mdl"
#define P_MODEL "models/zbz/wpn/p_thanatos7.mdl"
#define W_MODEL "models/zbz/wpn/w_primgroup1.mdl"
#define S_MODEL "models/zbz/wpn/thanatos7_scythe.mdl"

#define CSW_THANATOS7 	CSW_M249
#define weapon_thanatos7	"weapon_m249"
#define SCYTHE_NAME		"thanatos7scythe"

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn, g_Attack, g_Event

new const TRACER_ENTITY[][]={ "info_target", "func_breakable", "func_pushable", "func_wall", "func_wall_toggle", "func_door", "func_door_rotating",
		"func_button", "func_conveyor", "hostage_entity", "func_tank", "func_tankmortar", "func_tanklaser", "func_tankrocket", "button_target" }
		
new const WeaponSounds[][] =
{
	"weapons/thanatos7-1.wav",
	"weapons/thanatos7_scytheshoot.wav"
}
public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	engfunc(EngFunc_PrecacheModel, S_MODEL)
	
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		precache_sound(WeaponSounds[i])
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}

public plugin_init() 
{
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_Think, "fw_Think")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack")
	for(new i=0; i<sizeof(TRACER_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, TRACER_ENTITY[i], "fw_TraceAttack")

	RegisterHam(Ham_Item_Deploy, weapon_thanatos7, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, weapon_thanatos7, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Item_PostFrame, weapon_thanatos7, "fw_Item_PostFrame");	
	RegisterHam(Ham_Weapon_Reload, weapon_thanatos7, "fw_Weapon_Reload");
	RegisterHam(Ham_Weapon_Reload, weapon_thanatos7, "fw_Weapon_Reload_Post", 1);	
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_thanatos7, "fw_Weapon_WeaponIdle_Post", 1);
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	cs_register_custom_item("Thanatos-7", 9000, 6, "GiveThanatos7", "thanatos7")
}

public fw_PrecacheEvent_Post(type, const name[])
	if(equal("events/m249.sc", name)) g_Event = get_orig_retval()	
	

public GiveThanatos7(id)
{
	if(!is_user_alive(id)) return
	
	drop_weapons(id, 1)
	
	Set_BitVar(g_HadWpn, id)
	UnSet_BitVar(g_Attack, id)
	
	fm_give_item(id, weapon_thanatos7)
	
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_THANATOS7)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, 120)
}
public fw_Remove_Item(id, itemid, slot)
	if(slot==0)UnSet_BitVar(g_HadWpn, id)
public Hook_Weapon(id) 
{
	engclient_cmd(id, weapon_thanatos7)
	return PLUGIN_HANDLED
}
public message_DeathMsg()
{
	// get value data
	static killer, weapon[32]
	killer = get_msg_arg_int(1)
	get_msg_arg_string(4, weapon, charsmax(weapon))
	
	if((Get_BitVar(g_HadWpn, killer) && equal(weapon, "m249")) || equal(weapon, SCYTHE_NAME))
		set_msg_arg_string(4, "thanatos7")
		
	return PLUGIN_CONTINUE
}
public fw_TraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_user_connected(Attacker))
		return HAM_IGNORED	
	if(get_user_weapon(Attacker) != CSW_THANATOS7 || !Get_BitVar(g_HadWpn, Attacker))
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
	
	if(equal(model, "models/w_m249.mdl"))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_thanatos7, entity)
		if(Get_BitVar(g_HadWpn, iOwner) && pev_valid(weapon))
		{
			set_pev(weapon, pev_impulse, 2038) 
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			set_pev(entity, pev_body, 9)
			
			UnSet_BitVar(g_HadWpn,iOwner)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_THANATOS7 || !Get_BitVar(g_HadWpn, id))
		return FMRES_IGNORED
		
	static PressedButton, Ent
	PressedButton = get_uc(uc_handle, UC_Buttons)
	Ent = get_pdata_cbase(id, 373)
	if(!pev_valid(Ent)) return FMRES_IGNORED
	
	if(PressedButton & IN_ATTACK2 && !pev(Ent, pev_iuser3))
	{
		if(get_pdata_float(id, 83, 5) > 0.0)
			return FMRES_IGNORED
		
		PressedButton &= ~IN_ATTACK2
		set_uc(uc_handle, UC_Buttons, PressedButton)

		if(pev(Ent, pev_iuser4) == 0)
		{
			set_pdata_float(id, 83, 2.75, 5)
			Set_WeaponIdleTime(id, CSW_THANATOS7, 2.75)
			
			set_pev(Ent, pev_iuser3, 1)
			set_pev(Ent, pev_fuser1, get_gametime() + 2.75)
			
			Set_WeaponAnim(id, 10)
		} else {
			Shoot_Scythe(id)
			set_pev(Ent, pev_iuser4, 0)
		}
	}	
	return FMRES_HANDLED
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
		if(pev(iEnt, pev_iuser4) == 1) Set_WeaponAnim(Id, random_num(1,2))
		else Set_WeaponAnim(Id, 0)
		
		set_pdata_float(iEnt, 48, 20.0, 4)
	}	
}
public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2038)
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
	
	if(pev(ent, pev_iuser3) == 1 && pev(ent, pev_fuser1) <= get_gametime())
	{
		set_pev(ent, pev_iuser4, 1)
		set_pev(ent, pev_iuser3, 0)
	}
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_THANATOS7)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(120 - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_THANATOS7, bpammo - temp1)		
		
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
	
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_THANATOS7)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0)
		return HAM_SUPERCEDE
	if(iClip >= 120)
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
			
		set_pdata_int(ent, 51, pev(ent, pev_iuser1), 4)
		set_pdata_float(id, 83, 3.0, 5)
		Set_WeaponAnim(id, pev(ent, pev_iuser4) ? 8 : 7)
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
		
	Set_WeaponAnim(Id, pev(Ent, pev_iuser4) ? 12 : 11)
	set_pev(Id, pev_viewmodel2, V_MODEL)
	set_pev(Id, pev_weaponmodel2, P_MODEL)
	set_pev(Ent, pev_iuser3, 0)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_THANATOS7 && Get_BitVar(g_HadWpn, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_THANATOS7 || !Get_BitVar(g_HadWpn, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event)
		return FMRES_IGNORED
	
	new Ent = get_pdata_cbase(invoker, 373)
	if(!pev_valid(Ent)) return FMRES_IGNORED
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	Set_WeaponAnim(invoker, pev(Ent, pev_iuser4) ? 4 : 3)
	emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.6, 0, PITCH_NORM)

	return FMRES_SUPERCEDE
}
public fw_Touch(iPtr, iPtd)
{
	if(!pev_valid(iPtr)) return
	
	new szClassname[64]
	pev(iPtr, pev_classname, szClassname, 63)
	if(equal(szClassname, SCYTHE_NAME))
	{
		set_pev(iPtr, pev_movetype, MOVETYPE_NONE)
		set_pev(iPtr, pev_solid, SOLID_NOT);
		set_pev(iPtr, pev_velocity, Float:{0.0, 0.0, 0.0})
	}
	
}
public fw_Think(iEnt)
{
	if(!pev_valid(iEnt)) return
	
	new szClassname[64]
	pev(iEnt, pev_classname, szClassname, 63)
	if(equal(szClassname, SCYTHE_NAME))
	{
		Scythe_Think(iEnt)
	}
}
public Shoot_Scythe(id)
{
	emit_sound(id, CHAN_WEAPON, WeaponSounds[1], 1.0, 0.67, 0, PITCH_NORM)
	
	Set_WeaponAnim(id, 9)
	
	set_pdata_float(id, 83, 4.0, 5)
	Set_WeaponIdleTime(id, CSW_THANATOS7, 4.0)
	
	Create_Scythe(id)
}

public Create_Scythe(id)
{
	new iEnt = create_entity("info_target")
	
	static Float:Origin[3], Float:Angles[3], Float:Velocity[3]
	
	get_position(id, 5.0, 0.0, -2.0, Origin)
	
	pev(id, pev_v_angle, Angles)
	Angles[0] *= -1.0

	// set info for ent
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	entity_set_string(iEnt, EV_SZ_classname, SCYTHE_NAME)
	engfunc(EngFunc_SetModel, iEnt, S_MODEL)
	
	set_pev(iEnt, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(iEnt, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(iEnt, pev_origin, Origin)
	set_pev(iEnt, pev_angles, Angles)
	set_pev(iEnt, pev_solid, SOLID_BBOX)
	set_pev(iEnt, pev_owner, id)	
	set_pev(iEnt, pev_fuser1, get_gametime() + 8.0)

	velocity_by_aim(id, 2000, Velocity)
	set_pev(iEnt, pev_velocity, Velocity)	
	
	set_pev(iEnt, pev_nextthink, get_gametime())
	
	// Animation
	set_pev(iEnt, pev_animtime, get_gametime())
	set_pev(iEnt, pev_framerate, 2.0)
	set_pev(iEnt, pev_sequence, 0)
}

public Scythe_Think(Ent)
{
	static Float:vecOrigin[3];
	pev(Ent, pev_origin, vecOrigin);
	
	new Attacker = pev(Ent, pev_owner);
	
	static Float:Time; pev(Ent, pev_fuser1, Time)
	if(get_gametime() >= Time || cs_zb_is_zombie(Attacker) || !is_user_connected(Attacker))
	{
		engfunc(EngFunc_RemoveEntity, Ent);
		return;
	}
	
	Stock_RangeDamage(Attacker, Ent, vecOrigin, 60.0, 60.0)
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1);
}
stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
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

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
	
	return 1;
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

stock Stock_RangeDamage(pevAttacker, pevInflictor, Float:vecOrigin[3], Float:flDamage, Float:flRadius)
{
	if(!is_valid_ent(pevAttacker)) pevAttacker = pevInflictor;
	
	new szClassname[64]
	new iVictim = -1
	while((iVictim = find_ent_in_sphere(iVictim, vecOrigin, flRadius)) != 0)
	{
		if(!is_valid_ent(iVictim) || pevAttacker == iVictim) continue;
		
		pev(iVictim, pev_classname, szClassname, charsmax(szClassname))
		if((equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable")) && (pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY))
			continue;
			
		if(pev(iVictim, pev_flags) & FL_MONSTER) flDamage *= 3.0;
		Stock_TakeDamage(pevAttacker, pevInflictor, iVictim, flDamage, DMG_CLUB)
	}
	
}

stock Stock_TakeDamage(pevAttacker, pevInflictor, iVictim, Float:flDamage, bitsDamageType)
{
	if(!is_valid_ent(iVictim) || flDamage <= 0.0) return;
	else if(!is_valid_ent(pevAttacker)) pevAttacker = iVictim;
	else if(!is_valid_ent(pevInflictor)) pevInflictor = pevAttacker;
	
	if(entity_get_float(iVictim, EV_FL_health) > 0.0 && entity_get_float(iVictim, EV_FL_takedamage) > 0.0)
	{
		new teamA=get_user_team(pevAttacker);
		new teamB=get_user_team(iVictim);
		new team1=pev(pevAttacker, pev_iuser2);
		new team2=pev(iVictim, pev_iuser2);
		if(!get_cvar_num("mp_friendlyfire")) 
		{
			if(teamA==teamB && (is_user_connected(pevAttacker) && is_user_connected(iVictim))) return;
			if(team1==team2 && (!is_user_connected(pevAttacker) && !is_user_connected(iVictim))) return;
			if(teamA==team2 && (is_user_connected(pevAttacker) && !is_user_connected(iVictim))) return;
			if(team1==teamB && (!is_user_connected(pevAttacker) && is_user_connected(iVictim))) return;
		}
		
		if(flDamage > 0.0) ExecuteHamB(Ham_TakeDamage, iVictim, pevInflictor, pevAttacker, flDamage, bitsDamageType);
	}
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

stock Set_WeaponIdleTime(id, WeaponId ,Float:TimeIdle)
{
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, 4)
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
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
