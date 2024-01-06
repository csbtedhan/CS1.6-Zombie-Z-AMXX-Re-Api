#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <reapi>
#include <zombiemodlimited>
#include <csm>

#define CSW_DSPS 	CSW_KNIFE
#define weapon_dsps 	"weapon_knife"

#define V_MODEL	"models/zbz/wpn/v_dualsword.mdl"
#define P_MODEL	"models/zbz/wpn/p_dualsword_a.mdl"
#define P_MODEL2	"models/zbz/wpn/p_dualsword_b.mdl"

#define ProjectileClassname	"DualSwordFX"

new const WeaponSounds[][] =
{
	"weapons/dualsword_stab1.wav",				
	"weapons/dualsword_stab2.wav",				
	"weapons/dualsword_stab1_hit.wav",			
	"weapons/dualsword_stab2_hit.wav",			
	"weapons/katanad_hitwall.wav",				
	"weapons/dualsword_slash_1.wav",			
	"weapons/dualsword_slash_2.wav",			
	"weapons/dualsword_slash_3.wav",			
	"weapons/dualsword_slash_4.wav",			
	"weapons/dualsword_hit1.wav",				
	"weapons/dualsword_hit2.wav",				
	"weapons/dualsword_hit3.wav",				
	"weapons/dualsword_slash_4_1.wav",			
	"weapons/dualsword_slash_4_2.wav",			
	"weapons/dualsword_skill_end.wav",			
	"weapons/dualsword_fly1.wav",				
	"weapons/dualsword_fly2.wav",				
	"weapons/dualsword_fly3.wav",				
	"weapons/dualsword_fly4.wav",				
	"weapons/dualsword_fly5.wav",
	"weapons/dualsword_skill_start.wav"
	
}

//Hit
#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_WORLD			2

enum _:WpnAnim
{
	ANIM_IDLEA = 0,
	ANIM_SLASH1,
	ANIM_SLASH2,
	ANIM_SLASH3,
	ANIM_SLASH4,
	ANIM_SLASHEND,
	ANIM_DRAWA,
	ANIM_IDLEB,
	ANIM_STAB1,
	ANIM_STAB2,
	ANIM_STABEND,
	ANIM_DRAWB
}


new g_HadWpn, g_iMode, g_iSlashEnd, g_iCheck[33]
new g_sModelindexEffects[4]

new Float:flDamageSlash[4] = { 400.0, 320.0, 340.0, 360.0 }
new Float:flDamageStab[2] = { 2420.0, 650.0 }

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

public plugin_init() 
{
	register_plugin("[Zombie Z] CSO Dual Sword Phantom Slayer", "1.3R", "Asdian")
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	register_forward(FM_AddToFullPack, "Fw_AddToFullPack_Post", 1);
	register_forward(FM_Touch, "fw_DPSEnt_Touch")
	
	RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1)
	
	register_forward(FM_Think, "fw_Think")
	RegisterHam(Ham_Item_PostFrame, weapon_dsps, "fw_Item_PostFrame")

	cs_register_custom_item("Dual Sword Phantom Slayer", 0, 8, "GiveDSPS", "dualsword")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL2)
	
	for(new i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/wpn/dualswordfx.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/wpn/dualsword_skill.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/wpn/dualsword_skillfx1.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/wpn/dualsword_skillfx2.mdl")
	
	g_sModelindexEffects[0] = engfunc(EngFunc_PrecacheModel, "sprites/leaf01_dualsword.spr")
	g_sModelindexEffects[1] = engfunc(EngFunc_PrecacheModel, "sprites/leaf02_dualsword.spr")
	g_sModelindexEffects[2] = engfunc(EngFunc_PrecacheModel, "sprites/petal01_dualsword.spr")
	g_sModelindexEffects[3] = engfunc(EngFunc_PrecacheModel, "sprites/petal02_dualsword.spr")
}

	
public GiveDSPS(id)
{
	if (!is_user_alive(id) || cs_zb_is_zombie(id))
		return

	Set_BitVar(g_HadWpn,id)
	UnSet_BitVar(g_iMode,id)
	UnSet_BitVar(g_iSlashEnd,id)
	g_iCheck[id] = 0
	fm_give_item(id, weapon_dsps)
	Event_CurWeapon(id)
}
public fw_Spawn_Post(id)
{
	remove_entity_name(ProjectileClassname)
	RemoveDsps(id)
}
public fw_Remove_Item(id, itemid, slot)
{
	if(slot == 2) RemoveDsps(id)
}
public fw_CSZB_BoltImpact(id)
{
	if(get_user_weapon(id) != CSW_DSPS)
		return
	if(!Get_BitVar(g_HadWpn, id))
		return
		
	static iEnt; iEnt = fm_get_user_weapon_entity(id, CSW_DSPS)
	if(!pev_valid(iEnt)) return
	
	set_pev(iEnt, pev_iuser1, 0)
	set_pev(iEnt, pev_iuser2, 0)
	set_pev(iEnt, pev_iuser3, 0)
	set_pev(iEnt, pev_iuser4, 0)
	set_pev(iEnt, pev_fuser1, 0.0)
		
	UnSet_BitVar(g_iSlashEnd,id)
	g_iCheck[id] = 0
	
}
public fw_CSZB_StuckRedraw(id)
{
	if(get_user_weapon(id) != CSW_DSPS)
		return
	if(!Get_BitVar(g_HadWpn, id))
		return

	Event_CurWeapon(id)	
}
public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_DSPS)
		return
	if(!Get_BitVar(g_HadWpn, id))
		return
		
	set_pev(id, pev_viewmodel2, V_MODEL)
	set_pev(id, pev_weaponmodel2, Get_BitVar(g_iMode,id) ? P_MODEL2:P_MODEL)
	
	Set_WeaponAnim(id, Get_BitVar(g_iMode,id)?ANIM_DRAWA:ANIM_DRAWB)
	
	static iEnt; iEnt = fm_get_user_weapon_entity(id, CSW_DSPS)
	if(!pev_valid(iEnt)) return
	
	set_pev(iEnt, pev_iuser1, 0)
	set_pev(iEnt, pev_iuser2, 0)
	set_pev(iEnt, pev_iuser3, 0)
	set_pev(iEnt, pev_iuser4, 0)
	set_pev(iEnt, pev_fuser1, 0.0)
		
	UnSet_BitVar(g_iSlashEnd,id)
	g_iCheck[id] = 0
	
	set_pdata_string(id, (492) * 4, "katana", -1 , 20)
	
	set_pdata_float(id, 83, 0.23)
	set_pdata_float(iEnt, 46, 0.25);
	set_pdata_float(iEnt, 47, 0.25);
	set_pdata_float(iEnt, 48, 0.25);
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "knife"))
		return PLUGIN_CONTINUE

	new iEntity = get_pdata_cbase(get_msg_arg_int(1), 373)
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_DSPS || !Get_BitVar(g_HadWpn, get_msg_arg_int(1)))
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "dualsword")
	return PLUGIN_CONTINUE
}
public Fw_AddToFullPack_Post(esState, iE, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	if (!pev_valid(iEnt))
		return;
	if (pev(iEnt, pev_flags) & FL_KILLME) 
		return;

	new classname[32], iOwner;
	pev(iEnt, pev_classname, classname, 31);
	iOwner = pev(iEnt, pev_owner)
	
	if (equal(classname,ProjectileClassname))
	{
		if(pev(iEnt, pev_iuser3) == 0)
		{
			if (iHost != iOwner || cs_zb_get_user_thirdperson(iOwner)) set_es(esState, ES_Effects, (get_es(esState, ES_Effects) | EF_NODRAW));
		}
	}
}
public fw_DPSEnt_Touch(iEnt, pEntity)
{
	if(!pev_valid(iEnt)) return HAM_IGNORED;
	
	new szClass[32]; pev(iEnt, pev_classname, szClass, 31);
	if(!equal(szClass, ProjectileClassname))
		return HAM_IGNORED;
		
	if(pev(iEnt, pev_iuser1) == 2)
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return FMRES_IGNORED;
	}
	return HAM_IGNORED;
}
public fw_Think(iEnt)
{
	if(!pev_valid(iEnt)) return
	
	new szClassname[64]
	pev(iEnt, pev_classname, szClassname, 63)
	if(equal(szClassname, ProjectileClassname))
		DualSwordFX_Think(iEnt)
}
public DualSwordFX_Think(iEnt)
{
	new iOwner
	iOwner = pev(iEnt, pev_owner)
	
	if(!is_user_alive(iOwner) || !is_user_connected(iOwner))
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return
	}
	
	if(!Get_Entity_Mode(iEnt))
	{
		new iWpn,iState,Float:vecOrigin[3], Float:vecAngle[3];
		iWpn = pev(iEnt, pev_iuser1)
		iState = pev(iWpn, pev_iuser4)
		Stock_Get_Postion(iOwner, 0.0, 0.0, 0.0, vecOrigin);
		
		pev(iOwner, pev_v_angle, vecAngle);
		vecAngle[0] = -vecAngle[0];
		
		if(!iState || get_user_weapon(iOwner) != CSW_DSPS)
		{
			if (pev(iEnt, pev_dmgtime) <= get_gametime())
			{
				engfunc(EngFunc_RemoveEntity, iEnt);
				return;
			}
		}
		set_pev(iEnt, pev_renderamt, floatmin(255.0, floatmax(0.0, (pev(iEnt, pev_dmgtime)-get_gametime())*255.0)));
		
		set_pev(iEnt, pev_origin, vecOrigin);
		set_pev(iEnt, pev_angles, vecAngle);
	}
	
	if(Get_Entity_Mode(iEnt) == 1)
	{
		set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	
		static Float:Origin[3]; pev(iOwner, pev_origin, Origin)
		Origin[2] -= 25.0
		
		if(pev(iEnt, pev_fuser1) < get_gametime() || !IsAlive(iOwner))
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
			return
		}
		set_pev(iEnt, pev_origin, Origin);
	}
	
	if(Get_Entity_Mode(iEnt) == 2)
	{
		new Float:vecOrigin[3]
		Stock_Get_Postion(iOwner, 0.0, 0.0, 0.0, vecOrigin);
		
		new Float:fOldOrigin[3];
		pev(iEnt, pev_oldorigin, fOldOrigin);
		
		new Float:vecNewOrigin[3];
		pev(iEnt, pev_origin, vecNewOrigin);
		
		new Float:vecfff[3];
		xs_vec_sub(vecOrigin, fOldOrigin, vecfff);
		xs_vec_add(vecNewOrigin, vecfff, vecNewOrigin);
		
		if(pev(iEnt, pev_iuser1) == 1)
		{
			set_pev(iEnt, pev_origin, vecNewOrigin);
			set_pev(iEnt, pev_oldorigin, vecOrigin);
		}
		
		if (pev(iEnt, pev_iuser1) == 2)
		{
			new Float:vecDef[3]; pev(iEnt, pev_vuser1, vecDef);
			set_pev(iEnt, pev_velocity, vecDef);
			new Float:fDist = get_distance_f(vecOrigin, vecNewOrigin);
			if (fDist > 175.0 * 0.5)
			{
				engfunc(EngFunc_RemoveEntity, iEnt);
				return;
			}
		}
		
		new Float:fTimeDmg;
		pev(iEnt, pev_fuser2, fTimeDmg);
		
		if (fTimeDmg && fTimeDmg < get_gametime() && pev(iEnt, pev_iuser1))
		{
			set_pev(iEnt, pev_fuser2, 0.0);
			KnifeAttack_Global(iOwner, false, 220.0, 360.0, 365.0, 1.5)
			set_pev(iEnt, pev_fuser2, get_gametime()+0.5);
		}
		
		new Float:fTimeTest;
		pev(iEnt, pev_fuser3, fTimeTest);
		
		if (fTimeTest && fTimeTest < get_gametime() && pev(iEnt, pev_iuser1))
		{
			new Float:vOrigin[3]; pev(iOwner, pev_origin, vOrigin);
			set_pev(iEnt, pev_fuser3, 0.0);
			engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, WeaponSounds[random_num(15,19)], 1.0, 0.7, 0, 100)
			set_pev(iEnt, pev_fuser3, get_gametime()+0.5);
		}
	}
	set_pev(iEnt, pev_nextthink, get_gametime())
	
	if(Get_Entity_Mode(iEnt) == 2)
	{
		new Float:fTimeLast;
		pev(iEnt, pev_fuser1, fTimeLast);
		
		if (fTimeLast < get_gametime() || pev(pev(iEnt, pev_iuser2), pev_fuser1) < get_gametime())
		{
			engfunc(EngFunc_RemoveEntity, iEnt);
		}
	}
}

public fw_Item_PostFrame(ent)
{
	if(!pev_valid(ent)) 
		return HAM_IGNORED
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(get_user_weapon(id) != CSW_DSPS || !Get_BitVar(g_HadWpn,id))
		return HAM_IGNORED

	if(get_pdata_float(ent, 48, 4) <= 0.01 && (!pev(ent, pev_iuser2) || !Get_BitVar(g_iSlashEnd,id)))
	{
		if(g_iCheck[id] < 6) g_iCheck[id] = 0
		set_pev(ent, pev_iuser3, 0)
		Set_WeaponAnim(id, Get_BitVar(g_iMode,id)?ANIM_IDLEA:ANIM_IDLEB)
		set_pdata_float(ent, 48, 4.03, 4)
	}
	
	new iButton = pev(id,pev_button)
	return DualSwordSpecial(id, ent, iButton)
}

public DualSwordSpecial(id, iEnt, iButton)
{
	new iState = pev(iEnt, pev_iuser3)
	new iState2 = pev(iEnt, pev_iuser2)
	new iSlash = pev(iEnt, pev_iuser4)
	new Float:fSound; pev(iEnt, pev_fuser1, fSound)
	
	if(!(iButton & IN_ATTACK) && get_pdata_float(iEnt, 46,4) <= 0.0 && iState2)
	{
		if(!iState || iState == 1)
		{
			Set_WeaponAnim(id, ANIM_STABEND)
			set_pev(iEnt, pev_iuser2, 0)
			set_pdata_float(iEnt, 48, 1.45,4)
		}
	}
	
	if(!(iButton & IN_ATTACK2) && get_pdata_float(iEnt, 47,4) <= 0.0 && Get_BitVar(g_iSlashEnd,id))
	{
		Set_WeaponAnim(id, ANIM_SLASHEND)
		set_pdata_float(iEnt, 48, 2.03,4)
		UnSet_BitVar(g_iSlashEnd,id)
	}
	
	if (get_pdata_float(id, 83) <= 0.0 && pev(iEnt, pev_iuser1))
	{
		new Float:fRange = Get_BitVar(g_iMode,id) ? 95.0 : 150.0
		new Float:fAngle = Get_BitVar(g_iMode,id) ? 120.0 : 90.0
		new Float:fDamage = Get_BitVar(g_iMode,id) ? flDamageSlash[iSlash] : flDamageStab[iState]
		
		if(!(pev(id, pev_flags) & FL_DUCKING)) SetAnimation(id, "ref_shoot_katana", 1.0)
		else SetAnimation(id, "crouch_shoot_katana", 1.0)
			
		new iHitResult = KnifeAttack_Global(id, true, fRange, fAngle, fDamage, 2.0)
		switch (iHitResult)
		{
			case RESULT_HIT_PLAYER : SendSound(id, CHAN_ITEM, WeaponSounds[Get_BitVar(g_iMode,id)?random_num(9,11):iState+2])
			case RESULT_HIT_WORLD : client_cmd(id, "spk %s", WeaponSounds[4])
		}
		set_pev(iEnt, pev_iuser1, 0);
	}
	
	if(get_pdata_float(iEnt, 47,4) <= 0.0 && iSlash && iSlash < 4)
	{
		set_pev(iEnt, pev_iuser1, 1)
		set_pev(iEnt, pev_iuser4, 1 + iSlash)
		set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
		
		set_pdata_float(id, 83, 0.06)
		set_pdata_float(iEnt, 46, iSlash == 3?(g_iCheck[id]==5?0.43:0.7):0.14,4);
		
		set_pdata_float(iEnt, 47, iSlash == 3?(g_iCheck[id]==5?0.43:0.7):0.14,4);
		set_pdata_float(iEnt, 48, 1.0,4);
		  
		Set_WeaponAnim(id, 1+iSlash)
		SendSound(id, CHAN_WEAPON, WeaponSounds[5 + iSlash])
		
		Create_Slash(id,iEnt,iSlash)
		
		if(iSlash == 3) 
		{
			Set_BitVar(g_iSlashEnd,id)
			
			set_pev(iEnt, pev_fuser1, get_gametime() + (g_iCheck[id]==5?0.43:0.5))
			set_pev(iEnt, pev_iuser4, 0)
		}
	}
	
	if(fSound && fSound < get_gametime())
	{
		SendSound(id,CHAN_VOICE,WeaponSounds[g_iCheck[id]==5?13:12])
		set_pev(iEnt, pev_fuser1, 0.0)
		
		if(g_iCheck[id]==5) 
		{
			Set_WeaponAnim(id, 14)
			g_iCheck[id] = 6
			
			set_pdata_float(iEnt, 46, 1.03,4)
			set_pdata_float(iEnt, 47, 1.03,4)
			set_pdata_float(iEnt, 48, 1.03,4)
			
			set_pev(iEnt, pev_fuser4, get_gametime()+0.5);
			DPS_Special(id, 0, 1.66)
			SendSound(id, CHAN_WEAPON, WeaponSounds[20])
		}
	}
	
	if(g_iCheck[id] == 6 && get_pdata_float(iEnt, 46,4) <= 0.0)
	{
		set_pdata_float(iEnt, 46, 11.36,4)
		set_pdata_float(iEnt, 47, 11.36,4)
		set_pdata_float(iEnt, 48, 11.36,4)
		
		g_iCheck[id] = 7
		set_pev(iEnt, pev_fuser1, get_gametime() + 10.6)
		Set_WeaponAnim(id, 15)
	}
	
	if(g_iCheck[id] == 7 && fSound && fSound < get_gametime())
	{
		SendSound(id,CHAN_VOICE,WeaponSounds[14])
		set_pev(iEnt, pev_fuser1, 0.0)
		g_iCheck[id] = 0
		
		DPS_Special(id, 1, 1.46)
	}
	
	DPS_RealSpecial(id, iEnt)
	
	if(iButton & IN_ATTACK && get_pdata_float(iEnt, 46,4) <= 0.0)
	{
		UnSet_BitVar(g_iMode,id)
		UnSet_BitVar(g_iSlashEnd,id)
		
		set_pev(iEnt, pev_iuser2, 1)
		set_pev(iEnt, pev_iuser4, 0)
		
		ExecuteHamB(Ham_Weapon_PrimaryAttack, iEnt)
		
		switch(iState)
		{
			case 0:
			{
				set_pdata_float(id, 83, 0.16)
				set_pdata_float(iEnt, 46, 0.5,4);
				set_pdata_float(iEnt, 47, 0.5,4);
				set_pdata_float(iEnt, 48, 1.0,4);
				
				set_pev(iEnt, pev_iuser1, 1)
				set_pev(iEnt, pev_iuser3, 1)
				set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
				
				Set_WeaponAnim(id, ANIM_STAB1)
				SendSound(id, CHAN_WEAPON, WeaponSounds[0])
				
				if(!g_iCheck[id]) g_iCheck[id] = 1
				else if(g_iCheck[id] == 2) g_iCheck[id] = 3
				else g_iCheck[id] = 0
			}
			case 1:
			{
				set_pdata_float(id, 83, 0.16)
				set_pdata_float(iEnt, 46, 0.65,4);
				set_pdata_float(iEnt, 47, 0.65,4);
				set_pdata_float(iEnt, 48, 1.5,4);
				
				set_pev(iEnt, pev_iuser1, 1)
				set_pev(iEnt, pev_iuser3, 0)
				set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
				
				Set_WeaponAnim(id, ANIM_STAB2)
				SendSound(id, CHAN_WEAPON, WeaponSounds[1])
				
				if(g_iCheck[id] == 3) g_iCheck[id] = 4
				else g_iCheck[id] = 0
			}
		}
	}
	
	if(iButton & IN_ATTACK2 && get_pdata_float(iEnt, 47) <= 0.0 && !iSlash)
	{
		Set_BitVar(g_iMode,id)
		
		ExecuteHamB(Ham_Weapon_SecondaryAttack, iEnt)
		
		set_pdata_float(id, 83, 0.06)
		set_pdata_float(iEnt, 46, 0.14,4);
		set_pdata_float(iEnt, 47, 0.14,4);
		set_pdata_float(iEnt, 48, 0.5,4);
		
		set_pev(iEnt, pev_iuser1, 1)
		set_pev(iEnt, pev_iuser2, 0)
		set_pev(iEnt, pev_iuser3, 0)
		set_pev(iEnt, pev_iuser4, 1)
		set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
		
		Set_WeaponAnim(id, ANIM_SLASH1)
		SendSound(id, CHAN_WEAPON, WeaponSounds[5])
		
		Create_Slash(id,iEnt,0)
		
		if(g_iCheck[id] == 1) g_iCheck[id] = 2
		else if(g_iCheck[id] == 4) g_iCheck[id] = 5
		else g_iCheck[id] = 0
	}
	
	iButton &= ~IN_ATTACK;
	iButton &= ~IN_ATTACK2;
	set_pev(id, pev_button, iButton);
	return HAM_IGNORED
}

stock Create_Slash(id,iEnt,seq)
{
	new Float:vecOrigin[3], Float:vecAngle[3];
	Stock_Get_Postion(id, 0.0, 0.0, 0.0 , vecOrigin);
	pev(id, pev_v_angle, vecAngle);
	vecAngle[0] = -vecAngle[0];
	
	new pEntity = DPS_Entites(id,"models/zbz/wpn/dualswordfx.mdl",vecOrigin,vecOrigin,1000.0,SOLID_NOT,seq)
		
	// Set info for ent	
	Set_Entity_Mode(pEntity, 0)
	set_pev(pEntity, pev_scale, 0.1);
	set_pev(pEntity, pev_iuser1, iEnt);
	set_pev(pEntity, pev_angles, vecAngle);
	set_pev(pEntity, pev_velocity, Float:{1.0, 1.0, 1.0})
	set_pev(pEntity, pev_nextthink, get_gametime()+0.01);
}

stock DPS_Special(id, seq, Float:fTime)
{
	new Float:VecOrig[3], Float:VecAng[3]
	pev(id, pev_origin, VecOrig)
	pev(id, pev_angles, VecAng)
	
	VecAng[0] = 0.0
	new iEfx = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(iEfx, pev_classname, ProjectileClassname);
	set_pev(iEfx, pev_origin, VecOrig)
	set_pev(iEfx, pev_frame, 0.0)
	set_pev(iEfx, pev_animtime, get_gametime())
	set_pev(iEfx, pev_framerate, 1.0)
	set_pev(iEfx, pev_velocity, Float:{1.0, 1.0, 1.0})
	set_pev(iEfx, pev_sequence, seq)
	engfunc(EngFunc_SetModel, iEfx, "models/zbz/wpn/dualsword_skill.mdl")
	dllfunc(DLLFunc_Spawn, iEfx)
	Set_Entity_Mode(iEfx, 1)
	set_pev(iEfx, pev_angles, VecAng)
	set_pev(iEfx, pev_solid, SOLID_NOT)
	set_pev(iEfx, pev_owner, id)
	set_pev(iEfx, pev_fuser1, get_gametime() + fTime)
	set_pev(iEfx, pev_nextthink, get_gametime() + 0.01)
}

stock DPS_RealSpecial(id, iEnt)
{
	new Float:fTimeEffect;
	pev(iEnt, pev_fuser4, fTimeEffect);
	
	if (g_iCheck[id] == 7 && fTimeEffect && fTimeEffect <= get_gametime())
	{
		set_pev(iEnt, pev_fuser4, get_gametime()+0.05);
		
		new Float:vecOrigin3[2][3],Float:vecOrigin[3]
		pev(id, pev_origin, vecOrigin);
		pev(id, pev_origin, vecOrigin3[0]);
		xs_vec_copy(vecOrigin3[0], vecOrigin3[1]);
		
		switch (random_num(0,3))
		{
			case 0:
			{
				vecOrigin3[0][0] += random_float(175.0*0.1, 175.0*0.5);
				vecOrigin3[0][1] += random_float(175.0*0.1, 175.0*0.5);
				new Float:fFloat = random_float(5.0, 15.0);
				vecOrigin3[0][2] += random_num(0,1) ? fFloat : -fFloat;
			}
			case 1:
			{
				vecOrigin3[0][0] += random_float(175.0*0.1, 175.0*0.5);
				vecOrigin3[0][1] -= random_float(175.0*0.1, 175.0*0.5);
				new Float:fFloat = random_float(5.0, 15.0);
				vecOrigin3[0][2] += random_num(0,1) ? fFloat : -fFloat;
			}
			case 2:
			{
				vecOrigin3[0][0] -= random_float(175.0*0.1, 175.0*0.5);
				vecOrigin3[0][1] += random_float(175.0*0.1, 175.0*0.5);
				new Float:fFloat = random_float(5.0, 15.0);
				vecOrigin3[0][2] += random_num(0,1) ? fFloat : -fFloat;
			}
			case 3:
			{
				vecOrigin3[0][0] -= random_float(175.0*0.1, 175.0*0.5);
				vecOrigin3[0][1] -= random_float(175.0*0.1, 175.0*0.5);
				new Float:fFloat = random_float(5.0, 15.0);
				vecOrigin3[0][2] += random_num(0,1) ? fFloat : -fFloat;
			}
		}
		
		switch (random_num(0,3))
		{
			case 0:
			{
				vecOrigin3[1][0] -= random_float(175.0*0.1, 175.0*0.5);
				vecOrigin3[1][1] -= random_float(175.0*0.1, 175.0*0.5);
				new Float:fFloat = random_float(5.0, 10.0);
				vecOrigin3[1][2] += random_num(0,1) ? fFloat : -fFloat;
			}
			case 1:
			{
				vecOrigin3[1][0] -= random_float(175.0*0.1, 175.0*0.5);
				vecOrigin3[1][1] += random_float(175.0*0.1, 175.0*0.5);
				new Float:fFloat = random_float(5.0, 10.0);
				vecOrigin3[1][2] += random_num(0,1) ? fFloat : -fFloat;
			}
			case 2:
			{
				vecOrigin3[1][0] += random_float(175.0*0.1, 175.0*0.5);
				vecOrigin3[1][1] -= random_float(175.0*0.1, 175.0*0.5);
				new Float:fFloat = random_float(5.0, 10.0);
				vecOrigin3[1][2] += random_num(0,1) ? fFloat : -fFloat;
			}
			case 3:
			{
				vecOrigin3[1][0] += random_float(175.0*0.1, 175.0*0.5);
				vecOrigin3[1][1] += random_float(175.0*0.1, 175.0*0.5);
				new Float:fFloat = random_float(5.0, 10.0);
				vecOrigin3[1][2] += random_num(0,1) ? fFloat : -fFloat;
			}
		}
		
		if (random_num(0,5) >= 3)
		{
			new Float:vecAngle2[3];
			vecAngle2[0] = random_num(0,1) ? random_float(-30.0, -15.0) : random_float(15.0, 30.0);
			vecAngle2[1] = random_num(0,1) ? random_float(-180.0, 0.0) : random_float(0.0, 180.0);
			
			new pEntity = DPS_Entites(id,"models/zbz/wpn/dualsword_skillfx1.mdl",vecOrigin3[0],vecOrigin3[0],0.01,SOLID_NOT,0)	
			set_pev(pEntity, pev_angles, vecAngle2);
			set_pev(pEntity, pev_iuser1, 1);
			set_pev(pEntity, pev_iuser2, iEnt);
			Set_Entity_Mode(pEntity, 2)
			set_pev(pEntity, pev_velocity, Float:{1.0, 1.0, 1.0})
			set_pev(pEntity, pev_fuser1, get_gametime()+0.5);
			set_pev(pEntity, pev_fuser2, get_gametime()+0.5);
			set_pev(pEntity, pev_fuser3, get_gametime()+0.3);
			set_pev(pEntity, pev_oldorigin, vecOrigin);
			set_pev(pEntity, pev_nextthink, get_gametime()+0.01);
		}
		
		new pEntity = DPS_Entites(id,"models/zbz/wpn/dualsword_skillfx2.mdl",vecOrigin3[0],vecOrigin3[1],1000.0,SOLID_TRIGGER,0)	
		set_pev(pEntity, pev_iuser1, 2);
		set_pev(pEntity, pev_iuser2, iEnt);
		Set_Entity_Mode(pEntity, 2)
		set_pev(pEntity, pev_oldorigin, vecOrigin);
		set_pev(pEntity, pev_fuser1, get_gametime()+0.5);
		set_pev(pEntity, pev_fuser2, get_gametime()+0.5);
		set_pev(pEntity, pev_fuser3, get_gametime()+0.3);
		set_pev(pEntity, pev_nextthink, get_gametime()+0.01);
	}
}

stock DPS_Entites(id, models[], Float:Start[3], Float:End[3], Float:speed, solid, seq)
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
		
	// Set info for ent	
	set_pev(pEntity, pev_movetype, MOVETYPE_FLY);
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, models);
	set_pev(pEntity, pev_classname, ProjectileClassname);
	set_pev(pEntity, pev_mins, Float:{-1.0, -1.0, -1.0});
	set_pev(pEntity, pev_maxs, Float:{1.0, 1.0, 1.0});
	set_pev(pEntity, pev_origin, Start);
	set_pev(pEntity, pev_gravity, 0.01);

	set_pev(pEntity, pev_solid, solid);
	
	static Float:Velocity[3];
	Stock_Get_Speed_Vector(Start, End, speed, Velocity);
	set_pev(pEntity, pev_velocity, Velocity);
	set_pev(pEntity, pev_vuser1, Velocity);
	
	new Float:vecVAngle[3]; pev(id, pev_v_angle, vecVAngle);
	vector_to_angle(Velocity, vecVAngle)
	
	if(vecVAngle[0] > 90.0) vecVAngle[0] = -(360.0 - vecVAngle[0]);
	set_pev(pEntity, pev_angles, vecVAngle);
	
	if(contain(models, "skillfx1")!=-1 || contain(models, "skillfx2")!=-1)
	{
		set_pev(pEntity, pev_movetype, MOVETYPE_FLY);
		set_pev(pEntity, pev_rendermode, kRenderTransAdd);
		set_pev(pEntity, pev_renderamt, 255.0);
	}
	else if(contain(models, "dualswordfx")!=-1)
	{
		set_pev(pEntity, pev_rendermode, kRenderTransAdd);
		set_pev(pEntity, pev_renderamt, 255.0);
		set_pev(pEntity, pev_dmgtime, get_gametime() + 2.0);
	}
	set_pev(pEntity, pev_sequence, seq)
	set_pev(pEntity, pev_animtime, get_gametime());
	set_pev(pEntity, pev_framerate, 1.0)
	return pEntity;
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
stock Set_Entity_Mode(iEnt, mode) set_pev(iEnt, pev_iuser3, mode)
stock Get_Entity_Mode(iEnt) return pev(iEnt,pev_iuser3)
stock SendSound(id, chan, sample[]) emit_sound(id, chan, sample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
stock Stock_Get_Speed_Vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}

stock KnifeAttack_Global(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
{
	new iHitResult
	if(fAngle > 0.0) iHitResult = RangedKnifeAttack(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
	else iHitResult = SingleKnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack)

	return iHitResult
}

stock SingleKnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bitsDamageType = DMG_BULLET)
{
	if(cs_zb_is_zombie(id))
		return RESULT_HIT_NONE;
		
	new Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	GetGunPosition(id, vecSrc);

	pev(id, pev_v_angle, v_angle);
	engfunc(EngFunc_MakeVectors, v_angle);

	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, flRange, vecForward);
	xs_vec_add(vecSrc, vecForward, vecEnd);

	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);

	new Float:flFraction; get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);
	
	get_tr2(tr, TR_flFraction, flFraction);

	new iHitResult = RESULT_HIT_NONE;
	
	if (flFraction < 1.0)
	{
		new pEntity = get_tr2(tr, TR_pHit);
		iHitResult = RESULT_HIT_WORLD;
		
		if (pev_valid(pEntity) && (IsPlayer(pEntity) || IsHostage(pEntity)))
		{
			if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
				flDamage *= 1.0;

			iHitResult = RESULT_HIT_PLAYER;
		}

		if (pev_valid(pEntity))
		{
			engfunc(EngFunc_MakeVectors, v_angle);
			global_get(glb_v_forward, vecForward);

			if (iHitgroup != -1)
				set_tr2(tr, TR_iHitgroup, iHitgroup);

			if (!(pev(pEntity, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY) && isEnemy(pEntity, id))
			{
				ClearMultiDamage()
				ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
				ApplyMultiDamage(id, id)
				if(is_user_alive(pEntity) && cs_zb_is_zombie(pEntity))Stock_Fake_KnockBack(id, pEntity, flKnockBack)
			}

			if (IsAlive(pEntity))
			{
				free_tr2(tr);
				return iHitResult;
			}
		}
	}
	free_tr2(tr);
	return iHitResult;
}

stock RangedKnifeAttack(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bNoTraceCheck = 0)
{
	if(cs_zb_is_zombie(id))
		return RESULT_HIT_NONE;
		
	new Float:vecOrigin[3], Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	pev(id, pev_origin, vecOrigin);

	new iHitResult = RESULT_HIT_NONE;
	GetGunPosition(id, vecSrc);

	pev(id, pev_v_angle, v_angle);
	if(fAngle >= 360.0) v_angle[0] = 0.0
	engfunc(EngFunc_MakeVectors, v_angle);

	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, flRange, vecForward);
	xs_vec_add(vecSrc, vecForward, vecEnd);

	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);
	
	new Float:EndPos2[3]
	get_tr2(tr, TR_vecEndPos, EndPos2)
	
	new Float:flFraction; get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction < 1.0) 
	{
		iHitResult = RESULT_HIT_WORLD;
		if(bStab) Stock_SakuraEffect(id, EndPos2)
	}
	
	new Float:vOrigin[3], Float:vecEndZ = vecEnd[2];
	
	new pEntity = -1;
	while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, flRange)) != 0)
	{
		if (!pev_valid(pEntity))
			continue;
		if (id == pEntity || !IsAlive(pEntity) || (fAngle < 360.0 && !CheckAngle(id, pEntity, fAngle)))
			continue;
		if (pev(pEntity, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY)
			continue;
		GetGunPosition(id, vecSrc);
		Stock_Get_Origin(pEntity, vecEnd);

		vecEnd[2] = vecSrc[2] + (vecEndZ - vecSrc[2]) * (get_distance_f(vecSrc, vecEnd) / flRange);

		xs_vec_sub(vecEnd, vecSrc, vecForward);
		xs_vec_normalize(vecForward, vecForward);
		xs_vec_mul_scalar(vecForward, flRange, vecForward);
		xs_vec_add(vecSrc, vecForward, vecEnd);

		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);
		get_tr2(tr, TR_flFraction, flFraction);

		if (flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, id, tr);
		get_tr2(tr, TR_flFraction, flFraction);

		if (flFraction < 1.0)
		{
			if (IsPlayer(pEntity) || IsHostage(pEntity))
			{
				iHitResult = RESULT_HIT_PLAYER;
				if(bStab) Stock_SakuraEffect(id, vecEnd)
				
				if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
					flDamage *= 1.0;
			}

			if (get_tr2(tr, TR_pHit) == pEntity || bNoTraceCheck)
			{
				engfunc(EngFunc_MakeVectors, v_angle);
				global_get(glb_v_forward, vecForward);

				if (iHitgroup != -1) set_tr2(tr, TR_iHitgroup, iHitgroup);

				ClearMultiDamage();
				ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, DMG_BULLET);
				ApplyMultiDamage(id, id);
				
				pev(pEntity, pev_origin, vOrigin);
				if(is_user_alive(pEntity) && cs_zb_is_zombie(pEntity))
					Stock_MakeKnockback(pEntity, vOrigin, vecOrigin, vector_distance(vOrigin, vecOrigin), flDamage * flKnockBack)
			}
		}
		free_tr2(tr);
	}
	return iHitResult;
}

stock isEnemy(iEnt, iPlayer)
{
	if (!pev_valid(iEnt)) return 0;
	
	if(is_user_alive(iEnt) || get_entity_flags(iEnt) & FL_MONSTER)
	{
		if (is_user_alive(iEnt) && get_user_team(iPlayer) != get_user_team(iEnt)) return 1;
		if (get_entity_flags(iEnt) & FL_MONSTER && pev(iEnt, pev_iuser2) != get_user_team(iPlayer)) return 1;
	} else return 1;
	
	return 0;
}
stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(0)
	message_end()
}
public RemoveDsps(id)
{
	UnSet_BitVar(g_HadWpn,id)
	UnSet_BitVar(g_iMode,id)
	UnSet_BitVar(g_iSlashEnd,id)
	g_iCheck[id] = 0
}
stock Stock_Set_Vis(iEnt, iVis = 1)
	set_pev(iEnt, pev_effects, iVis == 1 ? pev(iEnt, pev_effects) & ~EF_NODRAW : pev(iEnt, pev_effects) | EF_NODRAW)


stock Stock_Get_Postion(id,Float:forw,Float:right,Float:up,Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp)
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_AngleVectors, vAngle, vForward, vRight, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock IsPlayer(pEntity) return is_user_connected(pEntity)
stock IsHostage(pEntity)
{
	new classname[32]; pev(pEntity, pev_classname, classname, charsmax(classname))
	return ( equal(classname, "hostage_entity") || equal(classname, "monster_scientist") )
}
stock IsAlive(pEntity)
{
	if (pEntity < 1) return 0
	return (pev(pEntity, pev_deadflag) == DEAD_NO && pev(pEntity, pev_health) > 0)
}

stock GetGunPosition(id, Float:vecScr[3])
{
	new Float:vecViewOfs[3]
	pev(id, pev_origin, vecScr)
	pev(id, pev_view_ofs, vecViewOfs)
	xs_vec_add(vecScr, vecViewOfs, vecScr)
}

stock CheckBack(iEnemy,id)
{
	new Float:anglea[3], Float:anglev[3]
	pev(iEnemy, pev_v_angle, anglea)
	pev(id, pev_v_angle, anglev)
	new Float:angle = anglea[1] - anglev[1] 
	if (angle < -180.0) angle += 360.0
	if (angle <= 45.0 && angle >= -45.0) return 1
	return 0
}

stock CheckAngle(iAttacker, iVictim, Float:fAngle)
{
	static Float:vecOrigin[3], Float:vecTarget[3], Float:vecFor[3], Float:vecAng[3], Float:vecDir[3];
	pev(iAttacker, pev_origin, vecOrigin);
	Stock_Get_Origin(iVictim, vecTarget);
	
	xs_vec_sub(vecTarget, vecOrigin, vecDir);
	xs_vec_normalize(vecDir, vecDir);
	
	pev(iAttacker, pev_v_angle, vecAng);
	engfunc(EngFunc_MakeVectors, vecAng);
	global_get(glb_v_forward, vecFor);
	
	if(xs_vec_dot(vecFor, vecDir) >= floatcos(fAngle * M_PI/360.0))
		return 1;
	
	return 0
}
stock Stock_Get_Origin(id, Float:origin[3])
{
	new Float:maxs[3],Float:mins[3]
	if (pev(id, pev_solid) == SOLID_BSP)
	{
		pev(id,pev_maxs,maxs)
		pev(id,pev_mins,mins)
		origin[0] = (maxs[0] - mins[0]) / 2 + mins[0]
		origin[1] = (maxs[1] - mins[1]) / 2 + mins[1]
		origin[2] = (maxs[2] - mins[2]) / 2 + mins[2]
	} else pev(id, pev_origin, origin)
}

public Stock_Fake_KnockBack(id, iVic, Float:iKb)
{
	if(iVic > 32) return
	
	new Float:vAttacker[3], Float:vVictim[3], Float:vVelocity[3], flags
	pev(id, pev_origin, vAttacker)
	pev(iVic, pev_origin, vVictim)
	vAttacker[2] = vVictim[2] = 0.0
	flags = pev(id, pev_flags)
	
	xs_vec_sub(vVictim, vAttacker, vVictim)
	new Float:fDistance
	fDistance = xs_vec_len(vVictim)
	xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim)
	
	pev(iVic, pev_velocity, vVelocity)
	xs_vec_mul_scalar(vVictim, iKb, vVictim)
	xs_vec_mul_scalar(vVictim, 50.0, vVictim)
	vVictim[2] = xs_vec_len(vVictim) * 0.15
	
	if(flags &~ FL_ONGROUND)
	{
		xs_vec_mul_scalar(vVictim, 1.2, vVictim)
		vVictim[2] *= 0.4
	}
	if(xs_vec_len(vVictim) > xs_vec_len(vVelocity)) set_pev(iVic, pev_velocity, vVictim)
}	
stock Stock_MakeKnockback(iEnt, Float:fEntOrigin[3], Float:fPoint[3], Float:fDistance, Float:fDamage)
{
	new Float:fTime = floatdiv(fDistance, fDamage)
	new Float:fVelocity[3]
	fVelocity[0] = floatdiv((fEntOrigin[0] - fPoint[0]), fTime)
	fVelocity[1] = floatdiv((fEntOrigin[1] - fPoint[1]), fTime)
	fVelocity[2] = floatdiv((fEntOrigin[2] - fPoint[2]), fTime)
	set_pev(iEnt, pev_velocity, fVelocity)
	return 1
}
stock Float:Stock_Get_Body_Dmg(iBody)
{
	switch (iBody)
	{
		case HIT_GENERIC: return 0.75
		case 1: return 4.0
		case 2: return 1.0
		case 3: return 1.25
		case 4,5,6,7: return 0.75
		default: return 0.75
	}
	return 1.0
}

stock Stock_SakuraEffect(id, Float:vecOri[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOri)
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord,vecOri[0])
	engfunc(EngFunc_WriteCoord,vecOri[1])
	engfunc(EngFunc_WriteCoord,vecOri[2])
	write_short(g_sModelindexEffects[Get_BitVar(g_iMode,id)?2:0])
	write_short(g_sModelindexEffects[Get_BitVar(g_iMode,id)?3:1])
	write_byte(Get_BitVar(g_iMode,id)?178:128)
	write_byte(random_num(2,3))
	message_end()
}

stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
}
stock ClearMultiDamage() rg_multidmg_clear()
stock ApplyMultiDamage(inflictor, iAttacker) rg_multidmg_apply(inflictor, iAttacker);
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
