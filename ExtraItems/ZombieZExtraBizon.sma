#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombiemodlimited>
#include <csm>

#define V_MODEL "models/zbz/wpn/v_bizon.mdl"
#define P_MODEL "models/zbz/wpn/p_bizon.mdl"
#define W_MODEL "models/zbz/wpn/w_bizon.mdl"


#define CSW_BIZON CSW_MP5NAVY
#define weapon_bizon "weapon_mp5navy"


#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn, g_Attack, g_Event, g_HamBot

new const CAN_DAMAGE_ENTITY[][]={ "info_target", "func_breakable" , "func_pushable" , "hostage_entity" }
new const TRACER_ENTITY[][]={ "info_target", "func_breakable", "func_pushable", "func_wall", "func_wall_toggle", "func_door", "func_door_rotating", "weaponbox",
		"func_button", "func_conveyor", "hostage_entity", "func_tank", "func_tankmortar", "func_tanklaser", "func_tankrocket", "button_target"  , "func_train" , "func_tracktrain"}
		
new const WeaponSounds[][] = 
{
	"weapons/bizon-1.wav",
	"weapons/bizon-1-distant.wav",
	"weapons/bizon_draw.wav",
	"weapons/bizon_clipin.wav",
	"weapons/bizon_clipout.wav",
	"weapons/bizon_boltback.wav",
	"weapons/bizon_boltforward.wav"
}
public plugin_precache()
{
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
}
public plugin_init()
{
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	
	RegisterHam(Ham_TraceAttack, "player", "HamF_TakeDamage")
	for(new i=0; i<sizeof(CAN_DAMAGE_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, CAN_DAMAGE_ENTITY[i], "HamF_TakeDamage")
		
	RegisterHam(Ham_TraceAttack, "worldspawn", "HamF_TraceAttack")
	for(new i=0; i<sizeof(TRACER_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, TRACER_ENTITY[i], "HamF_TraceAttack")
		
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_bizon, "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_bizon, "fw_PrimaryAttack_Post", 1);
	RegisterHam(Ham_Item_Deploy, weapon_bizon, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, weapon_bizon, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Item_PostFrame, weapon_bizon, "fw_Item_PostFrame");	
	RegisterHam(Ham_Weapon_Reload, weapon_bizon, "fw_Weapon_Reload");
	RegisterHam(Ham_Weapon_Reload, weapon_bizon, "fw_Weapon_Reload_Post", 1);	
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	cs_register_custom_item("PP-19 Bizon", 1700, 3, "GiveBizon", "bizon")
}
public fw_PrecacheEvent_Post(type, const name[])
	if(equal("events/mp5n.sc", name)) g_Event = get_orig_retval()

public GiveBizon(id)
{
	if(!is_user_alive(id) || cs_zb_is_zombie(id)) return PLUGIN_HANDLED;
	
	drop_weapons(id, 1)
	
	Set_BitVar(g_HadWpn,id)
	UnSet_BitVar(g_Attack,id)
	fm_give_item(id, "weapon_mp5navy")
	
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_BIZON)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, 64)
	cs_set_user_bpammo(id, CSW_BIZON, 250)
	return PLUGIN_HANDLED;
}
public RemoveBizon(id)
{
	UnSet_BitVar(g_HadWpn,id)
	UnSet_BitVar(g_Attack,id)
}
public fw_Remove_Item(id, itemid, slot)
{
	if(slot ==0) RemoveBizon(id)
}
public message_DeathMsg()
{
	// get value data
	static killer, weapon[32]
	killer = get_msg_arg_int(1)
	get_msg_arg_string(4, weapon, charsmax(weapon))
	
	if(Get_BitVar(g_HadWpn, killer) && equal(weapon, "mp5navy"))
		set_msg_arg_string(4, "bizon")
		
	return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
	if(is_user_bot(id) && !g_HamBot)
	{
		set_task(0.5, "RegHamBots", id)
	}
}
public RegHamBots(id)
{
	g_HamBot = 1
	RegisterHamFromEntity(Ham_TraceAttack, id, "HamF_TakeDamage")
}
public HamF_TraceAttack(iVictim, iAttacker, Float:fDamage, Float:vDir[3], iTr, iDamageType)
{
	if(!is_user_connected(iAttacker) || !Get_BitVar(g_HadWpn, iAttacker) || get_user_weapon(iAttacker) != CSW_BIZON) 
		return HAM_IGNORED;
		
	new Float:end[3], szName[16]
	get_tr2(iTr, TR_vecEndPos, end)

	if(point_contents(end) == CONTENTS_SKY)
		return HAM_IGNORED;
		
	format(szName, 15, "{shot%i", random_num(1,5));
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(109)
	engfunc(EngFunc_WriteCoord, end[0])
	engfunc(EngFunc_WriteCoord, end[1])
	engfunc(EngFunc_WriteCoord, end[2])
	write_short(iVictim)
	write_byte(get_decal_index(szName))
	message_end()
	return HAM_IGNORED;
}
public HamF_TakeDamage(iVictim, iAttacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{	
	if(!is_user_connected(iAttacker) || !Get_BitVar(g_HadWpn, iAttacker) || get_user_weapon(iAttacker) != CSW_BIZON) 
		return HAM_IGNORED;
	
	if(Get_BitVar(g_Attack, iAttacker) && pev_valid(iVictim) && is_user_alive(iVictim) && cs_zb_is_zombie(iVictim))
	{	
		new Float:vecVel[3]
		new ducking = pev(iVictim, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)
		
		pev(iVictim, pev_velocity, vecVel);
		xs_vec_mul_scalar(Direction, 3.0, Direction)
		if (ducking) xs_vec_mul_scalar(Direction, 0.25, Direction)
		xs_vec_add(vecVel, Direction, vecVel)
		Direction[2] = vecVel[2]
	
		set_pev(iVictim, pev_velocity, vecVel)
	}
		
	return HAM_IGNORED;
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
	
	if(equal(model, "models/w_mp5.mdl"))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_bizon, entity)
		if(Get_BitVar(g_HadWpn, iOwner) && pev_valid(weapon))
		{
			set_pev(weapon, pev_impulse, 2034) 
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

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2034)
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
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_BIZON)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(64 - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_BIZON, bpammo - temp1)		
		
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
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_BIZON)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0)
		return HAM_SUPERCEDE
	if(iClip >= 64)
		return HAM_SUPERCEDE			
	
	set_pev(ent, pev_iuser1, iClip)
	return HAM_HANDLED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(get_pdata_int(ent, 54, 4) != 1)
		return HAM_IGNORED	
		
	if(Get_BitVar(g_HadWpn, id))
	{ // Reload
		if(pev(ent, pev_iuser1) == -1)
			return HAM_IGNORED;
			
		set_pdata_int(ent, 51, pev(ent, pev_iuser1), 4)
		set_pdata_float(id, 83, 1.4, 5)
		set_pdata_float(ent, 46, 2.5, 5)
		set_pdata_float(ent, 47, 2.5, 5)
		set_pdata_float(ent, 48, 3.5, 5)
		Set_WeaponAnim(id, 1)
	} else {
		set_pdata_float(id, 83, 1.1, 5)
		set_pdata_float(ent, 46, 2.5, 5)
		set_pdata_float(ent, 47, 2.5, 5)
		set_pdata_float(ent, 48, 3.5, 5)
		Set_WeaponAnim(id, 1)
	}
		
	
	return HAM_HANDLED
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
		
	new Float:fRecoil[3]
	pev(Id, pev_punchangle, fRecoil)
	xs_vec_mul_scalar(fRecoil, 0.65, fRecoil)
	set_pev(Id, pev_punchangle, fRecoil)
	
	UnSet_BitVar(g_Attack,Id)
}
public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(Get_BitVar(g_HadWpn, Id))
	{
		set_pev(Id, pev_viewmodel2, V_MODEL)
		set_pev(Id, pev_weaponmodel2, P_MODEL)
		
		set_pdata_string(Id, (492) * 4, "mp5", -1 , 20)
	} else set_pdata_string(Id, (492) * 4, "carbine", -1 , 20)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_MP5NAVY && Get_BitVar(g_HadWpn, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_MP5NAVY || !Get_BitVar(g_HadWpn, invoker))
		return FMRES_IGNORED
	if(eventid != g_Event)
		return FMRES_IGNORED
	
	engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
	
	new Float:origin[3]; pev(invoker, pev_origin, origin)
	emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.7, 0, PITCH_NORM)
	engfunc(EngFunc_EmitAmbientSound, invoker, origin, WeaponSounds[1], 0.45, 0.2, 0, 100);
	Set_WeaponAnim(invoker, random_num(3,4))
	
	Eject_Shell(invoker)
	
	return FMRES_SUPERCEDE
}

stock Stock_GetPosition(id, Float:vForward, Float:vSide, Float:vUp, Float:RetValue[3])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForwards[3], Float:vRight[3], Float:vUps[3]
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUps);
	xs_vec_add(vOrigin,vUps,vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_AngleVectors, vAngle, vForwards, vRight, vUps);
	
	RetValue[0] = vOrigin[0] + vForwards[0] * vForward + vRight[0] * vSide + vUps[0] * vUp
	RetValue[1] = vOrigin[1] + vForwards[1] * vForward + vRight[1] * vSide + vUps[1] * vUp
	RetValue[2] = vOrigin[2] + vForwards[2] * vForward + vRight[2] * vSide + vUps[2] * vUp
}
public Eject_Shell(iEnt)
{
	static Float:vVelocity[3], Float:vOrigin[3], Float:vPVelocity[3];
	Stock_GetPosition(iEnt, 13.0, 6.0, -2.0, vOrigin)
	Stock_GetPosition(iEnt, 12.0, 8.5, -1.0, vVelocity)
	
	Stock_DirectedVector(vVelocity, vOrigin, vVelocity);
	xs_vec_mul_scalar(vVelocity, 150.0, vVelocity);
	
	pev(iEnt, pev_velocity, vPVelocity);
	xs_vec_add(vVelocity, vPVelocity, vVelocity);
	vVelocity[2] += random_float(-20.0, 20.0)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(106)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	engfunc(EngFunc_WriteCoord, vVelocity[0])
	engfunc(EngFunc_WriteCoord, vVelocity[1])
	engfunc(EngFunc_WriteCoord, vVelocity[2])
	write_angle(random(360))
	write_short(engfunc(EngFunc_ModelIndex, "models/pshell.mdl"))
	write_byte(1)
	write_byte(20)
	message_end()
}
stock Stock_DirectedVector(Float:vStart[3],Float:vEnd[3],Float:vOut[3])
{	
	xs_vec_sub(vStart, vEnd, vOut)
	xs_vec_normalize(vOut, vOut)
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
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
