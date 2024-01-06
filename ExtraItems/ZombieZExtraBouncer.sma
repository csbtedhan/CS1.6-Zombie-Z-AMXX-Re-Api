#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombiemodlimited>
#include <csm>
#include <reapi>

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn

#define P_MODEL	"models/zbz/wpn/p_bouncer.mdl"
#define V_MODEL	"models/zbz/wpn/v_bouncer.mdl"
#define W_MODEL	"models/zbz/wpn/w_primgroup1.mdl"
#define S_MODEL	"models/zbz/wpn/bouncer_bullet02.mdl"

new const WeaponSounds[][] =
{
	"weapons/bouncer-1.wav",
	"weapons/bouncer_draw.wav",
	"weapons/bouncer_reload_insert.wav",
	"weapons/bouncer_reload_after.wav"
}
public plugin_precache()
{
	for(new x = 0; x < sizeof(WeaponSounds); x++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[x])
		
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	engfunc(EngFunc_PrecacheModel, S_MODEL)
	
	engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr");
	engfunc(EngFunc_PrecacheModel, "models/zbz/wpn/bouncer_bullet01.mdl");
	
}
public plugin_init() 
{
	register_plugin("[Zombie Z] Bouncer", "1.0", "csbtedhan")
	
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post", 1)	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart");
	
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_m3", "fw_PrimaryAttack");
	RegisterHam(Ham_Item_PostFrame, "weapon_m3", "fw_Item_PostFrame");	
	RegisterHam(Ham_Item_Deploy, "weapon_m3", "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m3", "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_m3", "fw_Weapon_WeaponIdle")	
	RegisterHam(Ham_Weapon_WeaponIdle, "weapon_m3", "fw_Weapon_WeaponIdle_Post", 1)	
	
	RegisterHam(Ham_Touch, "info_target", "Bullet_Impact");
	
	server_cmd("sv_maxvelocity 9999")
	cs_register_custom_item("Bouncer", 6500, 2, "GiveBouncer", "bouncer")
}

public GiveBouncer(id)
{
	if(!is_user_alive(id)) return;
	
	drop_weapons(id, 1)
	
	Set_BitVar(g_HadWpn,id)
	fm_give_item(id, "weapon_m3")
	
	new iWpn = get_pdata_cbase(id, 373);
	if(pev_valid(iWpn) && get_pdata_int(iWpn, 43) == CSW_M3)
		set_pdata_int(iWpn, 51, 25, 4);
}
public RemoveBouncer(id) UnSet_BitVar(g_HadWpn,id)
public fw_Remove_Item(id, itemid, slot) 
{
	if(slot==0)RemoveBouncer(id)
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
	
	if(equal(model, "models/w_m3.mdl"))
	{
		static weapon; weapon = fm_find_ent_by_owner(-1, "weapon_m3", entity)
		if(pev_valid(weapon) && Get_BitVar(g_HadWpn, iOwner))
		{
			set_pev(weapon, pev_impulse, 2094) 
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			set_pev(entity, pev_body, 2)
			
			UnSet_BitVar(g_HadWpn,iOwner)
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}
public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2094)
	{
		Set_BitVar(g_HadWpn, id)
		set_pev(Ent, pev_impulse, 0)	
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
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_M3 || !Get_BitVar(g_HadWpn, id))
		return 
		
	new Ent = get_pdata_cbase(id, 373)
	if(!pev_valid(Ent)) return;
	static CurButton; CurButton = get_uc(uc_handle, UC_Buttons)
	if((CurButton & IN_RELOAD) && get_pdata_int(Ent, 51, 4) >= 25)
	{
		CurButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, CurButton)
	}	
}
public fw_Weapon_WeaponIdle( iEnt )
{
	if(pev_valid(iEnt) != 2)
		return HAM_IGNORED
	static id; id = get_pdata_cbase(iEnt, 41, 4)
	if(get_pdata_cbase(id, 373) != iEnt)
		return HAM_IGNORED
	if( get_pdata_float(iEnt, 48, 4) > 0.0 )
		return HAM_IGNORED
		
	if(!Get_BitVar(g_HadWpn, id))
		return HAM_IGNORED
	
	static iId ; iId = get_pdata_int(iEnt, 43, 4)
	static iMaxClip ; iMaxClip = 25

	static iClip ; iClip = get_pdata_int(iEnt, 51, 4)
	static fInSpecialReload ; fInSpecialReload = get_pdata_int(iEnt, 55, 4)

	if( !iClip && !fInSpecialReload )
		return HAM_IGNORED

	if( fInSpecialReload )
	{
		static iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, 5)

		if( iClip < iMaxClip && iBpAmmo )
		{
			Shotgun_Reload(iEnt, iId, iMaxClip, iClip, iBpAmmo, id)
			return HAM_SUPERCEDE
		}
		else if( iClip >= iMaxClip )
		{
			Set_WeaponAnim(id, 4)
				
			set_pdata_int(iEnt, 55, 0, 4)
			set_pdata_float(iEnt, 48, 1.5, 4)
		}
	}
	
	return HAM_IGNORED
}

public fw_Weapon_WeaponIdle_Post( iEnt )
{
	if(pev_valid(iEnt) != 2)
		return 
	static id; id = get_pdata_cbase(iEnt, 41, 4)
	if(get_pdata_cbase(id, 373) != iEnt)
		return

	if(!Get_BitVar(g_HadWpn, id))
		return
		
	static SpecialReload; SpecialReload = get_pdata_int(iEnt, 55, 4)
	if(!SpecialReload && get_pdata_float(iEnt, 48, 4) <= 0.25)
	{
		Set_WeaponAnim(id, 0)
		set_pdata_float(iEnt, 48, 20.0, 4)
	}	
}
public Shotgun_Reload(iEnt, iId, iMaxClip, iClip, iBpAmmo, id)
{
	if(iBpAmmo <= 0 || iClip == iMaxClip)
		return

	if(get_pdata_int(iEnt, 46, 4) > 0.0)
		return

	if(!Get_BitVar(g_HadWpn, id))
		return
		
	switch( get_pdata_int(iEnt, 55, 4) )
	{
		case 0:
		{
			Set_WeaponAnim(id, 5)
			 
			set_pdata_int(iEnt, 55, 1, 4)
			set_pdata_float(id, 83, 0.2, 5)
			set_pdata_float(iEnt, 48, 0.45, 4)
			set_pdata_float(iEnt, 46, 0.45, 4)
			set_pdata_float(iEnt, 47, 0.45, 4)
			return
		}
		case 1:
		{
			if( get_pdata_float(iEnt, 48, 4) > 0.0 )
				return
			set_pdata_int(iEnt, 55, 2, 4)
			set_pdata_float(iEnt, 48, 0.45, 4)
		}
		default:
		{
			Set_WeaponAnim(id, 3)
			set_pdata_int(iEnt, 51, iClip + 1, 4)
			set_pdata_int(id, 381, iBpAmmo-1, 5)
			set_pdata_int(iEnt, 55, 1, 4)
		}
	}
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
		
	if(get_user_weapon(id) == CSW_M3 && Get_BitVar(g_HadWpn, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}
public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_HadWpn, id))
		return HAM_IGNORED
		
	if(get_pdata_float(ent, 46, 4)-0.5<=0.0 && get_pdata_float(id, 83, 5) <= 0.0)
	{
		if(pev(ent, pev_iuser4) != 0)
		{
			Eject_Shell(id);
			set_pev(ent, pev_iuser4, 0);
		}
	}
	
	
	return HAM_IGNORED
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
	
	if(get_pdata_float(Ent, 46, 4) <= 0.0 && get_pdata_int(Ent, 51, 4) > 0)
	{
		Shoot_Bouncer(Id)
		set_pdata_int(Ent, 51, get_pdata_int(Ent, 51, 4) - 1, 4);
		Set_WeaponAnim(Id, random_num(1,2))
		set_pev(Ent, pev_iuser4, 1);
		set_pdata_float(Ent, 46, 1.0, 4);
		set_pdata_float(Id, 83, 1.0, 5);
		
		engfunc(EngFunc_EmitSound, Id, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.7, 0, 100);
		
		SetAnimation(Id, (pev(Id, pev_flags) & FL_DUCKING) ? "crouch_shoot_shotgun" : "ref_shoot_shotgun", 1.0);

		new Float:vPunch[3]; vPunch[0] -= 3.0
		set_pev(Id, pev_punchangle, vPunch);
	}
	
	return HAM_SUPERCEDE;
}

public Shoot_Bouncer(id)
{
	new Float:vecOrigin[3], Float:flSide = 2.0
	new Float:vecVelocity[3]
	
	static iEnt
	for( new x = 0; x < 7 ; x ++ )
	{
		Stock_GetPosition(id, 0.0, flSide, 0.0, vecOrigin)
		flSide -= 0.5
		iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		set_pev(iEnt, pev_origin, vecOrigin);
		
		set_pev(iEnt, pev_classname, "bouncer_bullet")
		set_pev(iEnt, pev_owner, id);
		set_pev(iEnt, pev_movetype, 10);
		set_pev(iEnt, pev_gravity, -0.1);
		set_pev(iEnt, pev_solid, SOLID_BBOX)
		set_pev(iEnt, pev_iuser1, 2)
		set_pev(iEnt, pev_iuser2, 75811)
		
		engfunc(EngFunc_SetModel, iEnt, S_MODEL);
		
		velocity_by_aim(id, 3500, vecVelocity);
		vecVelocity[0] += random_float(-150.0, 150.0)
		vecVelocity[1] += random_float(-150.0, 150.0)
		vecVelocity[2] += random_float(-150.0, 150.0)
		set_pev(iEnt, pev_velocity, vecVelocity);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(22)
		write_short(iEnt)
		write_short(engfunc(EngFunc_ModelIndex, "sprites/laserbeam.spr"))
		write_byte(1)
		write_byte(1)
		write_byte(10)
		write_byte(10)
		write_byte(255)
		write_byte(255)
		message_end()
	}
}
public Bullet_Impact(iEnt, pEnt)
{
	if(!pev_valid(iEnt)) 
		return;
	
	new szClass[32]; pev(iEnt, pev_classname, szClass, 31);
	if(!equal(szClass, "bouncer_bullet") || (pev_valid(pEnt) && pev(pEnt, pev_iuser2) == 75811))
		return;
		
	new Float:vDir[3], Float:vOrigin[3], Float:vEnd[3], Float:vVelocity[3], Float:flFraction, Float:vAngle[3];
	pev(iEnt, pev_origin, vOrigin);
	
	if(engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_SKY || cs_zb_is_zombie(pev(iEnt, pev_owner)))
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return;
	}
	
	pev(iEnt, pev_velocity, vVelocity);
	
	vector_to_angle(vVelocity, vAngle);
	engfunc(EngFunc_MakeVectors, vAngle);
	global_get(glb_v_forward, vDir);
	xs_vec_mul_scalar(vDir, 100.0, vVelocity);
	xs_vec_add(vOrigin, vVelocity, vEnd);
	
	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vOrigin, vEnd, 0, iEnt, tr);
	get_tr2(tr, TR_flFraction, flFraction);
	
	new pevAttacker = pev(iEnt, pev_owner)
	if(!is_user_connected(pevAttacker)) pevAttacker = iEnt
	
	if(flFraction < 1.0)
	{
		if(is_user_alive(pEnt))
		{
			if(cs_zb_is_zombie(pEnt))
			{
				rg_multidmg_clear()
				ExecuteHamB(Ham_TraceAttack, pEnt, pevAttacker, 70.5, vDir, tr, DMG_BULLET);
				rg_multidmg_apply(pevAttacker, pevAttacker)
			}
		} else {
			if(pev_valid(pEnt) && pev(pEnt, pev_takedamage) > 0.0)
				ExecuteHamB(Ham_TakeDamage, pEnt, iEnt, pevAttacker, 70.0, DMG_CLUB);
		}
	}
	free_tr2(tr)
	if(!pev_valid(pEnt) || (pev_valid(pEnt) && !is_user_alive(pEnt)))
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, vOrigin[0])
		engfunc(EngFunc_WriteCoord, vOrigin[1])
		engfunc(EngFunc_WriteCoord, vOrigin[2])
		write_short(pEnt)
		write_byte(engfunc(EngFunc_DecalIndex, "{shot1"))
		message_end()
	}
	if(pev(iEnt, pev_iuser1) <= 0 || engfunc(EngFunc_PointContents, vOrigin) == CONTENTS_SKY)
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return;
	}
	set_pev(iEnt, pev_iuser1, pev(iEnt, pev_iuser1) - 1)
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
	Stock_GetPosition(iEnt, 15.0, 6.0, -3.0, vOrigin)
	Stock_GetPosition(iEnt, 14.0, 8.0, -2.0, vVelocity)
	
	Stock_DirectedVector(vVelocity, vOrigin, vVelocity);
	xs_vec_mul_scalar(vVelocity, 210.0, vVelocity);
	
	pev(iEnt, pev_velocity, vPVelocity);
	xs_vec_add(vVelocity, vPVelocity, vVelocity);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(106)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	engfunc(EngFunc_WriteCoord, vVelocity[0]+random_float(-50.0, 50.0))
	engfunc(EngFunc_WriteCoord, vVelocity[1]+random_float(-50.0, 50.0))
	engfunc(EngFunc_WriteCoord, vVelocity[2]+random_float(-50.0, 50.0))
	write_angle(random(360))
	write_short(engfunc(EngFunc_ModelIndex, "models/zbz/wpn/bouncer_bullet01.mdl"))
	write_byte(2)
	write_byte(20)
	message_end()
}
stock Stock_DirectedVector(Float:vStart[3],Float:vEnd[3],Float:vOut[3])
{	
	xs_vec_sub(vStart, vEnd, vOut)
	xs_vec_normalize(vOut, vOut)
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
