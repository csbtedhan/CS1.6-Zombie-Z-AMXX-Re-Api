#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <csm>
#include <zombiemodlimited>
#include <fakemeta_util>
#include <hamsandwich>

new const szAnacondaModels[][] = { "models/zbz/wpn/p_dartpistol.mdl", "models/zbz/wpn/v_dartpistol.mdl", "models/zbz/wpn/w_secgroup1.mdl" , "models/zbz/wpn/s_dartpistol.mdl"}

	
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn

new const WeaponSounds[][] = 
{
	"weapons/dartpistol-1.wav",
	"weapons/taser_shoot.wav"
}

public plugin_precache()
{
	for(new i=0;i<4;i++)
	{
		engfunc(EngFunc_PrecacheModel, szAnacondaModels[i])
	}
	
	engfunc(EngFunc_PrecacheModel, "sprites/dart_explosion.spr")
	
	for(new i=0;i<2;i++)
		precache_sound(WeaponSounds[i])
}
public plugin_init()
{
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post", 1)	
	
	RegisterHam(Ham_Think, "info_target", "DartThink")
	RegisterHam(Ham_Touch, "info_target", "DartImpact")
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_deagle", "fw_PrimaryAttack");
	RegisterHam(Ham_Item_Deploy, "weapon_deagle", "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_deagle", "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Item_PostFrame, "weapon_deagle", "fw_Item_PostFrame");	
	RegisterHam(Ham_Weapon_Reload, "weapon_deagle", "fw_Weapon_Reload");
	RegisterHam(Ham_Weapon_Reload, "weapon_deagle", "fw_Weapon_Reload_Post", 1);	
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	cs_register_custom_item("Dart Pistol", 850, 1, "GiveAnaconda", "dartpistol")
}

public GiveAnaconda(id)
{
	if(!is_user_alive(id)) return;
	
	drop_weapons(id, 2)
	
	Set_BitVar(g_HadWpn,id)
	fm_give_item(id, "weapon_deagle")
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_DEAGLE)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, 5)
}

public fw_Remove_Item(id, itemid, slot)
{
	if(slot == 1)
	{
		UnSet_BitVar(g_HadWpn,id)
	}
}
public message_DeathMsg()
{
	// get value data
	static killer, weapon[32]
	killer = get_msg_arg_int(1)
	get_msg_arg_string(4, weapon, charsmax(weapon))
	
	if(equal(weapon, "deagle") && Get_BitVar(g_HadWpn, killer)) set_msg_arg_string(4, "dartpistol")
		
	return PLUGIN_CONTINUE
}
public fw_CSPlayer_Kill(victim, attacker)
{
	if(Get_BitVar(g_HadWpn, victim))
	{
		set_task(0.1, "fw_Remove_Weapon", victim + 2025)
	}
}
public fw_Remove_Weapon(id)
{
	id -= 2025
	UnSet_BitVar(g_HadWpn, id)
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
		static weapon; weapon = find_ent_by_owner(-1, "weapon_deagle", entity)
		if(pev_valid(weapon))
		{
			if(Get_BitVar(g_HadWpn, iOwner))
			{
				set_pev(weapon, pev_impulse, 2163) 
				engfunc(EngFunc_SetModel, entity, szAnacondaModels[2])
				set_pev(entity, pev_body, 1)
			}
			else return FMRES_IGNORED
			UnSet_BitVar(g_HadWpn,iOwner)
			
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
		
	if(get_pdata_int(Ent, 51, 4) <= 0)
	{
		Set_WeaponAnim(Id, 5)
		return HAM_SUPERCEDE
	}
	
	Set_WeaponAnim(Id, random_num(1,2))
	new Float:flRecoil[3]; pev(Id, pev_punchangle, flRecoil);
	flRecoil[0] -= 2.0
	set_pev(Id, pev_punchangle, flRecoil);
	
	set_pdata_int(Ent, 51, max(0, get_pdata_int(Ent, 51, 4) - 1), 4);
	
	engfunc(EngFunc_EmitSound, Id, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.8, 0, 100);
	ShootDart(Id)
	
	set_pdata_float(Ent, 46, 1.0, 4)
	set_pdata_float(Ent, 47, 1.0, 4)
	set_pdata_float(Ent, 48, 1.5, 4)
	
	if(!(pev(Id, pev_flags) & FL_DUCKING)) SetAnimation(Id, "ref_shoot_onehanded", 1.0)
	else SetAnimation(Id, "crouch_shoot_onehanded", 1.0)
	
	return HAM_SUPERCEDE
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2163)
	{
		Set_BitVar(g_HadWpn, id)
		set_pev(Ent, pev_impulse, 0)	
	}
	return HAM_HANDLED
}

public fw_Item_PostFrame(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_HadWpn, id))
		return HAM_IGNORED
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_DEAGLE)
	
	static iMaxClip; 
	iMaxClip = 5
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(iMaxClip - iClip, bpammo)
			
		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_DEAGLE, bpammo - temp1)		
		
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
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_DEAGLE)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static iMaxClip; 
	
	iMaxClip = 5
	
	set_pev(ent, pev_iuser1, -1)
	if(BPAmmo <= 0)
		return HAM_SUPERCEDE
	if(iClip >= iMaxClip)
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
			
		new Float:flTime = 1.5;
		
		set_pdata_float(id, 83, flTime, 5)
		set_pdata_float(ent, 46, flTime+0.5, 4)
		set_pdata_float(ent, 47, flTime+0.5, 4)
		set_pdata_float(ent, 48, flTime+1.9, 4)
		
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
	
	if(Get_BitVar(g_HadWpn, Id))
	{
		set_pev(Id, pev_viewmodel2, szAnacondaModels[1])
		set_pev(Id, pev_weaponmodel2, szAnacondaModels[0])
		Set_WeaponAnim(Id, 4)
	}
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_DEAGLE && Get_BitVar(g_HadWpn, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public ShootDart(id)
{
	static Float:vOrigin[3], Float:vUp[3], Float:vVelocity[3], Float:vAngle[3];
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp)
	xs_vec_add(vOrigin, vUp, vOrigin);
	
	pev(id, pev_v_angle, vAngle)
	vAngle[0] = 180.0 - vAngle[0]
	
	new pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(pEnt, pev_origin, vOrigin)
	set_pev(pEnt, pev_classname, "dart")
	engfunc(EngFunc_SetModel, pEnt, szAnacondaModels[3])
	set_pev(pEnt, pev_angles, vAngle)
	set_pev(pEnt, pev_owner, id)
	set_pev(pEnt, pev_movetype, 5)
	set_pev(pEnt, pev_solid, 2)
	set_pev(pEnt, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(pEnt, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(pEnt, pev_iuser1, 6)
	
	velocity_by_aim(id, 2000, vVelocity)
	set_pev(pEnt, pev_velocity, vVelocity)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(pEnt)
	write_short(engfunc(EngFunc_ModelIndex, "sprites/laserbeam.spr"))
	write_byte(1)
	write_byte(1)
	write_byte(155)
	write_byte(255)
	write_byte(218)
	write_byte(200)
	message_end()
	
}
public DartThink(Ent)
{
	if(!isDart(Ent))
		return;
		
	new pevOwner = pev(Ent, pev_owner)
	new Float:vOrigin[3]; pev(Ent, pev_origin, vOrigin)
	
	if(cs_zb_is_zombie(pevOwner) || !is_user_alive(pevOwner) || !is_user_connected(pevOwner))
	{
		engfunc(EngFunc_RemoveEntity, Ent)
		return;
	}
	
	if(pev(Ent, pev_iuser1) > 0)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, vOrigin[0])
		engfunc(EngFunc_WriteCoord, vOrigin[1])
		engfunc(EngFunc_WriteCoord, vOrigin[2])
		write_short(engfunc(EngFunc_ModelIndex, "sprites/dart_explosion.spr"))
		write_byte(1)
		write_byte(25)
		write_byte(14)
		message_end()
		
		DoElectricity(vOrigin, pevOwner, Ent)
		
		set_pev(Ent, pev_iuser1, pev(Ent, pev_iuser1) - 1)
		engfunc(EngFunc_EmitAmbientSound, Ent, vOrigin, WeaponSounds[1], 1.0, 0.8, 0, 100)
		
		if(pev(Ent, pev_iuser1) <= 0)
		{
			engfunc(EngFunc_RemoveEntity, Ent)
			return;
		}
		
	}
	set_pev(Ent, pev_nextthink, get_gametime() + 0.5)
}
public DartImpact(Ent, Id)
{
	if(!isDart(Ent))
		return;
		
	set_pev(Ent, pev_movetype, 0)
	set_pev(Ent, pev_velocity, Float:{0.0, 0.0, 0.0})
	set_pev(Ent, pev_solid, 0)
	set_pev(Ent, pev_nextthink, get_gametime())
}
stock DoElectricity(Float:vOrigin[3], pevAttacker, pevInflictor)
{
	new Float:pOrigin[3]
	for(new id = 0; id < get_maxplayers(); id ++)
	{
		if(!is_user_connected(id) || !is_user_alive(id) || !cs_zb_is_zombie(id))
			continue;
			
		pev(id, pev_origin, pOrigin)
		if(!isClearLine(pOrigin, vOrigin) || vector_distance(vOrigin, pOrigin) > 170.0)
			continue;
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, pOrigin[0])
		engfunc(EngFunc_WriteCoord, pOrigin[1])
		engfunc(EngFunc_WriteCoord, pOrigin[2])
		write_short(engfunc(EngFunc_ModelIndex, "sprites/dart_explosion.spr"))
		write_byte(1)
		write_byte(25)
		write_byte(14)
		message_end()
		
		ExecuteHamB(Ham_TakeDamage, id, pevInflictor, pevAttacker, 150.0, DMG_CLUB) 
	}
}
stock isClearLine(Float:vOrigin1[3], Float:vOrigin2[3])
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vOrigin1, vOrigin2, IGNORE_MONSTERS|IGNORE_GLASS, 0, 0);
	get_tr2(0, TR_flFraction, flFraction)
	
	if (flFraction < 1.0) return 0;

	return 1;
}

stock SetAnimation(id, const AnimName[], Float:rate=1.0)
{
	static AnimNum, Float:FrameRate, Float:GroundSpeed, bool:Loops
	if ((AnimNum=lookup_sequence(id,AnimName,FrameRate,Loops,GroundSpeed))==-1) AnimNum=0

	if (!Loops || (Loops && pev(id,pev_sequence)!=AnimNum))
	{
		set_pev(id, pev_gaitsequence, AnimNum)
		set_pev(id, pev_sequence, AnimNum)
		set_pev(id, pev_frame, 0.0)
		set_pev(id, pev_animtime, get_gametime())
	}
	set_pev(id, pev_framerate, rate)

	set_pdata_int(id, 40, Loops, 4)
	set_pdata_int(id, 39, 0, 4)

	set_pdata_float(id, 36, FrameRate, 4)
	set_pdata_float(id, 37, GroundSpeed, 4)
	set_pdata_float(id, 38, get_gametime(), 4)

	set_pdata_int(id, 73, 28, 5)
	set_pdata_int(id, 74, 28, 5)
	set_pdata_float(id, 220, get_gametime(), 5)
}
stock isDart(Ent)
{
	if(!pev_valid(Ent)) return 0;
	
	static szClassName[32]; pev(Ent, pev_classname,szClassName, 31);
	return (equal(szClassName, "dart"))
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

stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
