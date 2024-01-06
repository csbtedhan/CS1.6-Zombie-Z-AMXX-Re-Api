
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <csm>
#include <hamsandwich>
#include <zombiemodlimited>
#include <reapi>

#define PLUGIN "CSO Dreadnova"
#define VERSION "1.0"
#define AUTHOR "Asdian | Mellowzy"

#define CSW_RUNEBLADE CSW_KNIFE
#define weapon_runeblade "weapon_knife"

#define v_model "models/zbz/wpn/v_summonknife.mdl"
#define p_model "models/zbz/wpn/p_summonknife_a.mdl"
#define p_model2 "models/zbz/wpn/p_summonknife_b.mdl"
#define p_model3 "models/zbz/wpn/p_summonknife_charging.mdl"

#define MODEL_FLAME "sprites/muzzleflash97.spr"
#define MODEL_FLAME2 "sprites/muzzleflash98.spr"
#define MODEL_MFSTAB "sprites/muzzleflash99.spr"
#define MODEL_EFSTAB "sprites/ef_summon_stab1.spr"
#define MODEL_EFCHARGE "sprites/ef_summon_charging.spr"
#define MODEL_EFSTBATT "sprites/ef_summon_stab2.spr"
#define MODEL_EFSTBMF "sprites/muzzleflash100.spr"
#define MODEL_EFCHGLOOP "sprites/ef_summon_charging_loop.spr"

#define MODEL_EFSUMN_SMNING "models/zbz/wpn/ef_summoner_summoning.mdl"
#define MODEL_EFSUMN_SMNING1 "sprites/ef_summoner_summon01.spr"
#define MODEL_EFSUMN_SMNING2 "sprites/ef_summoner_summon02.spr"
#define MODEL_EFSUMN_UNSMNING1 "sprites/ef_summoner_unsummon01.spr"
#define MODEL_EFSUMN_UNSMNING2 "sprites/ef_summoner_unsummon02.spr"
#define MODEL_EFSUMN_SWING "models/zbz/wpn/ef_summoner_swing.mdl"

#define SUMMONER_MDL "models/zbz/wpn/summoner.mdl"
#define model_cannon "models/zbz/wpn/ef_summonknife_cannon.mdl"

new const weapon_sound[][] =
{
	"weapons/summonknife1.wav",				// 0
	"weapons/summonknife2.wav",				// 1
	"weapons/summonknife3.wav",				// 2
	"weapons/summonknife4.wav",				// 3
	
	"weapons/summonknife_stab.wav",				// 4
	
	"weapons/katanad_hit1.wav",				// 5
	"weapons/katanad_hit2.wav",				// 6
	"weapons/katanad_hitwall.wav",				// 7
	
	"weapons/summonknife_charging_loop.wav",		// 8
	"weapons/summonknife_charging_relese.wav"		// 9
}

new const summoner_sounds[][] = 
{
	"weapons/summon_unsummon.wav",
	"weapons/summon_summon.wav",
	"weapons/summoning_ready.wav",
	"weapons/summon_slash1.wav",
	"weapons/summon_slash2.wav",
	"weapons/summon_slash3.wav",
	"weapons/summon_slash4.wav",
	"weapons/summon_stab.wav",	// 7
	"weapons/summon_stab_fire.wav"
}

//SLASH
#define	SLASH_ANGLE			150.0
#define SLASH_DAMAGE			452.0
#define SLASH_RANGE			130.0
#define SLASH_KNOCKBACK 		1.0
		
//STAB
#define	STAB_ANGLE			180.0
#define STAB_DAMAGE			710.0
#define STAB_RANGE			200.0
#define STAB_KNOCKBACK 			21.0		

//CHARGE
#define CHARGE_DAMAGE			6150.0	
#define	CHARGE_RANGE			180.0
#define	CHARGE_ANGLE			102.0
#define CHARGE_KNOCKBACK 		23.0				

//SLASH SUMMONER
#define SMNERSLASH_DAMAGE		590.0			
#define SMNERSLASH_RANGE		120.0		
#define SMNERSLASH_ANGLE		150.0		
#define SMNERSLASH_KNOCKBACK		2.0			

//STAB SUMMONER
#define SMNERSTAB_DAMAGE		1290.0			
#define SMNERSTAB_RANGE		185.0		
#define SMNERSTAB_KNOCKBACK		20.0			

//Hit
#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_WORLD			2

new g_had_runeblade[33], Float:g_flInterval[33], Float:g_flEfxInterval[33], g_iState[33], g_iStat[33], g_iCheck[33]
new Float:g_SummonerTimer[33], g_iSummonerAttacking[33], g_iSpecialAmmo[33], Float:g_SummonerAttTimer[33], g_iSummonerAttackMod[33]
new spr_blood_spray, spr_blood_drop, g_Exp_SprId, g_LaserID, g_LaserEXP

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	RegisterHam(Ham_Item_PostFrame, weapon_runeblade, "fw_Item_PostFrame")
	
	register_forward(FM_Think, "fw_MF_Think")
	register_forward(FM_Touch, "fw_MF_Touch")
	register_forward(FM_AddToFullPack, "Fw_AddToFullPack_Post", 1);
	
	cs_register_custom_item("Dread Nova", 0, 8, "get_runeblade", "summonknife")
}

public client_connect(id) remove_crow9(id)
public client_disconnected(id) remove_crow9(id)

public plugin_precache()
{
	precache_model(v_model)
	precache_model(p_model)
	precache_model(p_model2)
	precache_model(p_model3)
	
	new i
	for(i = 0; i < sizeof(weapon_sound); i++) precache_sound(weapon_sound[i])
	for(i = 0; i < sizeof(summoner_sounds); i++) precache_sound(summoner_sounds[i])
	
	spr_blood_spray = precache_model("sprites/bloodspray.spr")
	spr_blood_drop = precache_model("sprites/blood.spr")
	g_Exp_SprId = precache_model("sprites/ef_summon_charging_exp.spr")
	g_LaserID = precache_model("sprites/laserbeam.spr")
	g_LaserEXP = precache_model("sprites/ef_summoner_stab1.spr")
	
	precache_model(MODEL_FLAME)
	precache_model(MODEL_FLAME2)
	precache_model(MODEL_MFSTAB)
	precache_model(MODEL_EFSTAB)
	precache_model(MODEL_EFCHARGE)
	precache_model(MODEL_EFSTBATT)
	precache_model(MODEL_EFSTBMF)
	precache_model(MODEL_EFCHGLOOP)
	
	precache_model(SUMMONER_MDL)
	precache_model(MODEL_EFSUMN_SMNING)
	precache_model(MODEL_EFSUMN_SMNING1)
	precache_model(MODEL_EFSUMN_SMNING2)
	precache_model(MODEL_EFSUMN_UNSMNING1)
	precache_model(MODEL_EFSUMN_UNSMNING2)
	precache_model(MODEL_EFSUMN_SWING)
	precache_model(model_cannon)
	
	
	precache_sound("weapons/plasmagun_exp.wav")
}

public fw_Remove_Item(id, itemid, slot)
	if(slot==2) remove_crow9(id)

public get_runeblade(id)
{
	if (!is_user_alive(id))
		return

	g_had_runeblade[id] = 1
	Reset_Values(id, 0, 1)
	
	if (get_user_weapon(id) == CSW_RUNEBLADE) Event_CurWeapon(id)
	else engclient_cmd(id,weapon_runeblade)
}

public remove_crow9(id)
{
	RemoveEntityByOwner(id, "summoner")
	RemoveEntityByOwner(id, "summoner_efx")
	g_had_runeblade[id] = 0
}

public fw_CSHUD(id)
{
	if(cs_zb_is_zombie(id) || !is_user_alive(id) || !g_had_runeblade[id] || get_user_weapon(id) != CSW_RUNEBLADE) 
		return;
		
	set_dhudmessage(100, 100, 255, 0.9, 0.95, 0, 0.0, 0.2, 0.0, 0.0);
	show_dhudmessage(id, "%i", g_iSpecialAmmo[id])
}
public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return 1
	if(get_user_weapon(id) != CSW_RUNEBLADE)
		return 1
	if(!g_had_runeblade[id])
		return 1
		
	static iEnt; iEnt = fm_get_user_weapon_entity(id, CSW_RUNEBLADE)
	if(!pev_valid(iEnt)) return 1
	
	new iMode = pev(iEnt, pev_iuser2)
	set_pev(id, pev_viewmodel2, v_model)
	set_pev(id, pev_weaponmodel2, iMode?p_model2:p_model)
	Set_WeaponAnim(id, iMode?11:6)
	
	set_pdata_string(id, (492) * 4, "katana", -1 , 20)
	
	set_pdata_float(id, 83, 1.0)
	set_pdata_float(iEnt, 46, 1.03);
	set_pdata_float(iEnt, 47, 1.03);
	set_pdata_float(iEnt, 48, 1.03);
	
	Reset_Values(id, iEnt)
	
	return 0
}


stock Reset_Values(id, iEnt2=0, totally=0)
{
	static iEnt
	if(!iEnt2) iEnt = fm_get_user_weapon_entity(id, CSW_RUNEBLADE)
	else iEnt = iEnt2
	
	if(!pev_valid(iEnt)) return 1
	
	set_pev(iEnt, pev_iuser1, 0)
	if(totally) set_pev(iEnt, pev_iuser2, 0)
	set_pev(iEnt, pev_iuser3, 0)
	set_pev(iEnt, pev_iuser4, 0)
	
	g_iStat[id] = 0
	g_iCheck[id] = 0
	
	g_flInterval[id] = 0.0
	g_flEfxInterval[id] = 0.0
	g_iState[id] = 0
	
	if(totally) g_iSpecialAmmo[id] = 0
	g_iSummonerAttacking[id] = 0
	g_iSummonerAttackMod[id] = 0
	g_SummonerAttTimer[id] = 0.0
	g_SummonerTimer[id] = 0.0
	return 0
}
public message_WeaponList(msg_id, msg_dest, id)
{
	if(!is_user_connected(id) || !is_user_alive(id) || !g_had_runeblade[id] || get_msg_arg_int(8) != CSW_RUNEBLADE) 
		return;
		
	set_msg_arg_int(2, get_msg_argtype(2), 1)
	set_msg_arg_int(3, get_msg_argtype(3), 100)
	
}
public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64], id
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	id = get_msg_arg_int(1)
	
	if(strcmp(szWeapon, "knife"))
		return PLUGIN_CONTINUE

	new iEntity = get_pdata_cbase(id, 373)
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_RUNEBLADE || !g_had_runeblade[id])
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "summonknife")
	return PLUGIN_CONTINUE
}

public client_PostThink(id)
{
	if(!is_user_connected(id))
		return 	
	if(!g_had_runeblade[id])
		return 
	
	static Wpn; Wpn = get_pdata_cbase(id, 373)
	if(!pev_valid(Wpn)) return
	
	static Float:flLastCheckTime, Float:flSaskehHit
	pev(Wpn, pev_fuser2, flLastCheckTime)
	pev(Wpn, pev_fuser3, flSaskehHit)
	
	if(!g_iSummonerAttacking[id] && flLastCheckTime < get_gametime())
	{
		if(g_iSpecialAmmo[id] == 100)
			Stock_ScreenFade(id)
		
		if(g_iSpecialAmmo[id] < 100)
		{
			g_iSpecialAmmo[id]++
			
			if(get_user_weapon(id) == CSW_RUNEBLADE)
			{
				DreadNova_UpdateAmmo(id)
				
				if(g_iSpecialAmmo[id] == 100)
				{
					Stock_ScreenFade(id,0,155,255, 40)
					SendSound2(id, summoner_sounds[2])
					
					set_pev(Wpn, pev_fuser2, get_gametime() + 2.25)
					return
				}
			}
			
			set_pev(Wpn, pev_fuser2, get_gametime() + 0.3)
		}
	}
	
	if(g_iSummonerAttacking[id] && g_iSpecialAmmo[id] >= 0 && flLastCheckTime < get_gametime())
	{
		if(g_iSpecialAmmo[id] > 0) g_iSpecialAmmo[id]--
		else g_iSpecialAmmo[id] = 0
		
		if(get_user_weapon(id) == CSW_RUNEBLADE)
			DreadNova_UpdateAmmo(id)
		 
		set_pev(Wpn, pev_fuser2, get_gametime() + 0.2)	
	}
	
	// must hold the weapon
	if(get_user_weapon(id) != CSW_RUNEBLADE)
		return
	
	if(g_flEfxInterval[id] && g_flEfxInterval[id] < get_gametime())
	{
		if(g_iState[id] == 2) 
		{
			MakeMuzzleFlash(id, "flame_efx", MODEL_EFSTBMF, 1, 0.2, 0.15, 0.75)
			DN_Shoot_Cannon(id)
		}
		else if(g_iState[id] == 1) MakeMuzzleFlash(id, "flame_efx2", MODEL_EFCHARGE, 2, 0.2, 0.150, 0.7)
		else if(g_iState[id] == 3) MakeMuzzleFlash(id, "flame_efx3", MODEL_EFCHGLOOP, 2, 0.1, 0.150, 3.0, 1)
		g_flEfxInterval[id] = 0.0
		if(g_iState[id] != 3) g_iState[id] = 0
	}
	
	if(g_iSummonerAttacking[id] && g_SummonerTimer[id] && g_SummonerTimer[id] < get_gametime())
	{
		RemoveEntityByOwner(id, "summoner")
		
		new Float:origin[3], Float:angles[3];
		pev(id, pev_origin, origin)
		pev(id, pev_angles, angles)
		MakeSummoner(id, "summoner", SUMMONER_MDL, origin, angles, 0, 0.0, 1)
		
		g_SummonerTimer[id] = 0.0
	}
	
	if(g_iSummonerAttacking[id] && flSaskehHit && flSaskehHit < get_gametime())
	{
		if(g_iSummonerAttackMod[id] == 5)
		{
			new pEnt = FindEntityByOwner(id, "summoner")
			if(!pev_valid(pEnt)) return
			
			new Float:vecStart[3], Float:vecEnd[3], Float:vecAngles[3]
			engfunc(EngFunc_GetAttachment, pEnt, 1, vecStart, vecAngles)
			fm_get_aim_origin(id, vecEnd)
			vecEnd[2] += 20.0
			
			for(new i = 0; i < 6; i++)
			{
				engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecStart, 0)
				write_byte(TE_BEAMPOINTS)
				engfunc(EngFunc_WriteCoord, vecStart[0]) // end
				engfunc(EngFunc_WriteCoord, vecStart[1])
				engfunc(EngFunc_WriteCoord, vecStart[2])
				engfunc(EngFunc_WriteCoord, vecEnd[0]) // start
				engfunc(EngFunc_WriteCoord, vecEnd[1])
				engfunc(EngFunc_WriteCoord, vecEnd[2])
				write_short(g_LaserID)
				write_byte(0)		// byte (starting frame) 
				write_byte(35)		// byte (frame rate in 0.1's) 
				write_byte(3)		// byte (life in 0.1's) 
				write_byte(75)		// byte (line width in 0.1's) 
				write_byte(0)		// byte (noise amplitude in 0.01's) 
				write_byte(0)		// byte,byte,byte (color) (R)
				write_byte(200)		// (G)
				write_byte(200)		// (B)
				write_byte(255)		// byte (brightness)
				write_byte(0)		// byte (scroll speed in 0.1's)
				message_end()
			}
			
			engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEnd, 0)
			write_byte(TE_EXPLOSION)
			engfunc(EngFunc_WriteCoord, vecEnd[0])
			engfunc(EngFunc_WriteCoord, vecEnd[1])
			engfunc(EngFunc_WriteCoord, vecEnd[2])
			write_short(g_LaserEXP)
			write_byte(15)//size
			write_byte(35)//framerate
			write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
			message_end()
			
			engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, summoner_sounds[8], 1.0, 0.6, 0, 100);
			
			new pEntity = -1
			while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecEnd, SMNERSTAB_RANGE)) != 0)
			{
				if(pev(pEntity, pev_takedamage) == DAMAGE_NO) continue
				if(is_user_connected(pEntity) && pEntity != id)
					if(!can_damage(pEntity, id)) continue
				if(pEntity == id) continue
				
				if(pev_valid(pEntity))
				{
					ExecuteHamB(Ham_TakeDamage, pEntity, id, id, SMNERSTAB_DAMAGE, DMG_BULLET)
						
					Stock_Fake_KnockBack(id, pEntity, SMNERSTAB_KNOCKBACK)
					if(is_user_alive(pEntity)) SpawnBlood(vecEnd, get_pdata_int(pEntity,89), floatround(SMNERSTAB_DAMAGE/5.0))
				}
			}
		} else KnifeAttack_Setting(id, true, SMNERSLASH_RANGE, SMNERSLASH_ANGLE, SMNERSLASH_DAMAGE, SMNERSLASH_KNOCKBACK)
		
		set_pev(Wpn, pev_fuser3, 0.0)
	}
}

stock DreadNova_UpdateAmmo(id)
{
	if(!is_user_alive(id))
		return

	static weapon_ent; weapon_ent = fm_get_user_weapon_entity(id, CSW_RUNEBLADE)
	if(!pev_valid(weapon_ent)) return
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_RUNEBLADE)
	write_byte(-1)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(g_iSpecialAmmo[id])
	message_end()
}

public fw_Item_PostFrame(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(get_user_weapon(id) != CSW_RUNEBLADE || !g_had_runeblade[id])
		return HAM_IGNORED
	
	new iMode = pev(ent, pev_iuser2)
	new iCheck = pev(ent, pev_iuser3)
	
	if(get_pdata_float(ent, 48, 4) <= 0.0)
	{
		g_iCheck[id] = 0
		Stock_ScreenFade(id)
		
		if(iMode && !iCheck)
		{
			set_pdata_float(ent, 48, 2.03,4);
			Set_WeaponAnim(id, 7)
		}
	}
	
	new iButton = pev(id,pev_button)
	return SpecialHandler(id, ent, iButton)
}

public SpecialHandler(id, iEnt, iButton)
{
	new iState = pev(iEnt, pev_iuser1)
	new iMode = pev(iEnt, pev_iuser2)
	new iState2 = pev(iEnt, pev_iuser4)
	
	if(!(iButton & IN_ATTACK2) && iMode)
	{
		RemoveEntityByOwner(id, "flame_efx2")
		
		if((g_iStat[id] == 1 || g_iStat[id] == 4) && g_flInterval[id] < get_gametime())
		{
			g_flInterval[id] = 0.0
			Set_WeaponAnim(id, 10)
			set_pdata_float(iEnt, 46, 0.07,4);
			set_pdata_float(iEnt, 47, 0.88,4);
			set_pdata_float(iEnt, 48, 0.88,4);
			
			set_pev(iEnt, pev_iuser3, 0)
			set_pev(iEnt, pev_iuser4, 0)
			
			g_iStat[id] = 0
		}
		
		if(g_iStat[id] == 2 || g_iStat[id] == 3)
		{
			if(g_iState[id])
				RemoveEntityByOwner(id, "flame_efx3")
			
			set_pev(id, pev_weaponmodel2, p_model2)
			Set_WeaponAnim(id, 14)
			SendSound(id, CHAN_WEAPON, weapon_sound[9])
			
			set_pdata_float(id, 83, 0.3, 5);
			set_pdata_float(iEnt, 46, 0.86,4);
			set_pdata_float(iEnt, 47, 1.76,4);
			set_pdata_float(iEnt, 48, 0.86,4);
			
			set_pev(iEnt, pev_iuser3, 1)
			set_pev(iEnt, pev_iuser4, 0)
			set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
			
			g_iStat[id] = 4
			g_flInterval[id] = get_gametime() + 0.86
			g_flEfxInterval[id] = get_gametime() + 0.33
			g_iState[id] = 2
			
			MakeMuzzleFlash(id, "flame_efx", MODEL_EFSTBATT, 1, 0.3, 0.3, 1.0)
		}
	}
	
	if(!(iButton & IN_ATTACK))
	{
		if(iState && get_pdata_float(iEnt, 48, 4) <= 0.0)
		{
			set_pev(iEnt, pev_iuser1, 0)
			
			set_pdata_float(iEnt, 48, 0.86,4);
			Set_WeaponAnim(id, 5)
		}
	}
	
	if (get_pdata_float(id, 83) <= 0.0 && pev(iEnt, pev_iuser3) == 1)
	{
		if(g_iStat[id] == 1)
		{
			MakeMuzzleFlash(id, "flame_efx", MODEL_EFSTAB, 4, 0.3, 0.01)
			MakeMuzzleFlash(id, "flame_efx", MODEL_MFSTAB, 1, 0.2, 0.15, 0.75)
		}
		
		new iHitResult = KnifeAttack_Setting(id, 0, STAB_RANGE, STAB_ANGLE, STAB_DAMAGE, STAB_KNOCKBACK)
		switch (iHitResult)
		{
			case RESULT_HIT_PLAYER : SendSound(id, CHAN_VOICE, weapon_sound[random_num(5,6)])
			case RESULT_HIT_WORLD : SendSound(id, CHAN_VOICE, weapon_sound[7])
		}
		set_pev(iEnt, pev_iuser3, 0)
	}
	
	if(get_pdata_float(iEnt, 46, 4) > 0.0)
		return HAM_IGNORED
	
	if(iButton & IN_ATTACK)
	{
		set_pev(id, pev_weaponmodel2, p_model)
		set_pev(iEnt, pev_iuser2, 0)
		
		if(g_iSummonerAttacking[id] && g_SummonerAttTimer[id] < get_gametime())
		{
			g_iSummonerAttackMod[id] = random_num(1, 4)
			RemoveEntityByOwner(id, "summoner")
		
			new Float:origin[3], Float:angles[3];
			pev(id, pev_origin, origin)
			pev(id, pev_angles, angles)
			MakeSummoner(id, "summoner", SUMMONER_MDL, origin, angles, g_iSummonerAttackMod[id], 0.0, 1, 255.0, 0, 0, 0.0, 0.0, g_iSummonerAttackMod[id] - 1)
			
			SendSound2(id, summoner_sounds[2 + g_iSummonerAttackMod[id]])
			set_pev(iEnt, pev_fuser3, get_gametime() + 0.3)
			
			g_SummonerAttTimer[id] = get_gametime() + 1.0
			g_SummonerTimer[id] = get_gametime() + 1.35 
		}
		
		if(g_iCheck[id] == 3 && g_iSpecialAmmo[id] == 100)
		{
			g_iCheck[id] = 0
			g_iSummonerAttacking[id] = 1
			Set_WeaponAnim(id, 15)
			Stock_ScreenFade(id,0,155,255, 40)
			
			set_pdata_float(iEnt, 46, 1.3,4);
			set_pdata_float(iEnt, 47, 1.5,4);
			set_pdata_float(iEnt, 48, 1.35,4);
			
			RemoveEntityByOwner(id, "summoner")
			g_SummonerTimer[id] = get_gametime() + 2.86
			g_SummonerAttTimer[id] = get_gametime() + 2.85
			SendSound2(id, summoner_sounds[1])
			
			new Float:origin[3], Float:angles[3];
			pev(id, pev_origin, origin)
			pev(id, pev_angles, angles)
			MakeSummoner(id, "summoner", SUMMONER_MDL, origin, angles, 6, 0.0, 1, 0.0, 0, 1)
			MakeSummoner(id, "summoner", MODEL_EFSUMN_SMNING, origin, angles, 0, 2.7, 1, 255.0, 1, 2, 0.01)
			
			new Float:origin2[3]
			Stock_Get_Postion(id, 0.0, 0.0, 50.0, origin2)
			MakeSummoner(id, "summoner_efx", MODEL_EFSUMN_SMNING1, origin2, angles, 0, 0.0, 1, 255.0, 0, 0, 0.5, 0.3)
			MakeSummoner(id, "summoner_efx", MODEL_EFSUMN_SMNING2, origin2, angles, 0, 0.0, 1, 255.0, 0, 0, 1.0, 0.5)
			
			KnifeAttack_Setting(id, true, 160.0, 180.0, 0.0, 50.0)
			return HAM_SUPERCEDE
		}
		
		switch(iState)
		{
			case 0,1:
			{
				Stock_SetPlayerAnim(id, "shoot_katana")
				
				set_pdata_float(iEnt, 46, 0.16,4);
				set_pdata_float(iEnt, 47, 0.16,4);
				set_pdata_float(iEnt, 48, 0.53,4);
		
				set_pev(iEnt, pev_iuser1, 2)
				Set_WeaponAnim(id, 1)
				SendSound(id, CHAN_WEAPON, weapon_sound[0])
				
				new iHitResult = KnifeAttack_Setting(id, 0, SLASH_RANGE, SLASH_ANGLE, SLASH_DAMAGE, 0.0)
				switch (iHitResult)
				{
					case RESULT_HIT_PLAYER : SendSound(id, CHAN_VOICE, weapon_sound[random_num(5,6)])
					case RESULT_HIT_WORLD : SendSound(id, CHAN_VOICE, weapon_sound[7])
				}
				
				if(!g_iCheck[id]) g_iCheck[id] = 1
				else g_iCheck[id] = 0
			}
			case 2:
			{
				Stock_SetPlayerAnim(id, "shoot_katana")
				
				set_pdata_float(iEnt, 46, 0.4,4);
				set_pdata_float(iEnt, 47, 0.4,4);
				set_pdata_float(iEnt, 48, 0.53,4);
		
				set_pev(iEnt, pev_iuser1, 3)
				Set_WeaponAnim(id, 2)
				SendSound(id, CHAN_WEAPON, weapon_sound[1])
				
				new iHitResult = KnifeAttack_Setting(id, 0, SLASH_RANGE, SLASH_ANGLE, SLASH_DAMAGE, 0.0)
				switch (iHitResult)
				{
					case RESULT_HIT_PLAYER : SendSound(id, CHAN_VOICE, weapon_sound[random_num(5,6)])
					case RESULT_HIT_WORLD : SendSound(id, CHAN_VOICE, weapon_sound[7])
				}
			}
			case 3:
			{
				Stock_SetPlayerAnim(id, "shoot_katana")
				
				set_pdata_float(iEnt, 46, 0.4,4);
				set_pdata_float(iEnt, 47, 0.4,4);
				set_pdata_float(iEnt, 48, 0.53,4);
		
				set_pev(iEnt, pev_iuser1, 1)
				
				if(!random_num(0,1))
				{
					Set_WeaponAnim(id, 3)
					SendSound(id, CHAN_WEAPON, weapon_sound[2])
					MakeMuzzleFlash(id, "flame_efx", MODEL_FLAME, 1, 0.3, 0.01)
				} else {
					Set_WeaponAnim(id, 4)
					SendSound(id, CHAN_WEAPON, weapon_sound[3])
					MakeMuzzleFlash(id, "flame_efx", MODEL_FLAME2, 1, 0.3, 0.01, 0.75)
				}
				
				new iHitResult = KnifeAttack_Setting(id, 0, SLASH_RANGE, SLASH_ANGLE, SLASH_DAMAGE, 0.0)
				switch (iHitResult)
				{
					case RESULT_HIT_PLAYER : SendSound(id, CHAN_VOICE, weapon_sound[random_num(5,6)])
					case RESULT_HIT_WORLD : SendSound(id, CHAN_VOICE, weapon_sound[7])
				}
			}
		}
	}
	
	if(iButton & IN_ATTACK2)
	{
		set_pev(iEnt, pev_iuser1, 0)
		set_pev(iEnt, pev_iuser2, 1)
		set_pev(iEnt, pev_iuser4, 0)
		
		if(g_iSummonerAttacking[id] && g_SummonerAttTimer[id] < get_gametime())
		{
			RemoveEntityByOwner(id, "summoner")
			g_iSummonerAttackMod[id] = 5
			
			new Float:origin[3], Float:angles[3];
			pev(id, pev_origin, origin)
			pev(id, pev_angles, angles)
			MakeSummoner(id, "summoner", SUMMONER_MDL, origin, angles, 5, 0.0, 1, 255.0)
			
			SendSound(id, CHAN_WEAPON, summoner_sounds[7])
			set_pev(iEnt, pev_fuser3, get_gametime() + 0.66)
			
			g_SummonerAttTimer[id] = get_gametime() + 0.72
			g_SummonerTimer[id] = get_gametime() + 2.03
		}
		
		switch (iState2)
		{
			case 0:
			{
				Stock_SetPlayerAnim(id, "shoot_katana")
				set_pev(id, pev_weaponmodel2, p_model2)
				
				SendSound(id, CHAN_WEAPON, weapon_sound[4])
				Set_WeaponAnim(id, iMode ? 9 : 8)
				set_pdata_float(id, 83, 0.3, 5);
				
				set_pev(iEnt, pev_iuser3, 1)
				set_pev(iEnt, pev_iuser4, 1)
				set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
				
				g_iStat[id] = 1
				g_flInterval[id] = get_gametime() + 0.68
				
				if(g_iCheck[id] == 1) g_iCheck[id] = 2
				else if(g_iCheck[id] == 2) g_iCheck[id] = 3
				else g_iCheck[id] = 0
				
				set_pdata_float(iEnt, 46, 0.88,4);
				set_pdata_float(iEnt, 47, 1.0,4);
				set_pdata_float(iEnt, 48, 0.88,4);
			}
			case 1:
			{
				g_flInterval[id] = get_gametime() + 0.1
				g_flEfxInterval[id] = get_gametime() + 0.66
				g_iState[id] = 1
				
				Set_WeaponAnim(id, 12)
				Stock_SetPlayerAnim(id, "aim_knife")
				set_pev(id, pev_weaponmodel2, p_model3)
				
				set_pdata_float(iEnt, 46, 1.16,4);
				set_pdata_float(iEnt, 47, 1.53,4);
				set_pdata_float(iEnt, 48, 1.33,4);
				
				set_pev(iEnt, pev_iuser4, 2)
			}
			case 2:
			{
				g_iStat[id] = 2
				set_pev(iEnt, pev_iuser4, 3)
				
				set_pdata_float(iEnt, 46, 0.37,4);
				set_pdata_float(iEnt, 47, 1.37,4);
				set_pdata_float(iEnt, 48, 0.37,4);
				
				if(g_iState[id] != 3)
				{
					g_iState[id] = 3
					g_flEfxInterval[id] = get_gametime() + 0.1
				}
			}
			case 3:
			{
				g_iStat[id] = 3
				set_pev(iEnt, pev_iuser4, 3)
				
				set_pdata_float(iEnt, 46, 1.33,4);
				set_pdata_float(iEnt, 47, 1.53,4);
				set_pdata_float(iEnt, 48, 1.33,4);
				
				Set_WeaponAnim(id, 13)
				SendSound(id, CHAN_WEAPON, weapon_sound[8])
			}
		}
	}
	
	iButton &= ~IN_ATTACK;
	iButton &= ~IN_ATTACK2;
	set_pev(id, pev_button, iButton);
	return HAM_IGNORED
}

public Fw_AddToFullPack_Post(esState, iE, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	if (!pev_valid(iEnt))
		return;
	if (pev(iEnt, pev_flags) & FL_KILLME) 
		return;

	new Classname[32];
	pev(iEnt, pev_classname, Classname, 31);

	if(equal(Classname, "flame_efx") || equal(Classname, "flame_efx3") || equal(Classname, "flame_efx2"))
	{
		if (iHost != pev(iEnt, pev_owner))
			set_es(esState, ES_Effects, (get_es(esState, ES_Effects) | EF_NODRAW));
	}
}

public fw_MF_Think(iEnt)
{
	if(!pev_valid(iEnt))
		return
	
	static Classname[32], iOwner, iStat
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	iOwner = pev(iEnt, pev_owner)
	iStat = pev(iEnt, pev_iuser1)
	
	if(equal(Classname, "summoner_slashefx"))
	{
		set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
		
		new Float:origin[3],Float:fOrigin[3], Float:vecAngle[3], iAttach
		iAttach = pev(iEnt, pev_iuser1)
		
		if(!pev_valid(iAttach))
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}
		
		pev(iEnt, pev_origin, fOrigin)
		pev(iAttach, pev_origin, origin)
		pev(iAttach, pev_v_angle, vecAngle);
		
		vecAngle[0] = 0.0;
		set_pev(iEnt, pev_v_angle, vecAngle);
		set_pev(iEnt, pev_angles, vecAngle);

		static Float:fSpeed
		fSpeed = floatmin(500.0, vector_distance(origin, fOrigin) * 9.0)
		Stock_Hook_Ent(iEnt, origin, fSpeed, 1)
		
		if(pev(iEnt, pev_ltime) < get_gametime() || get_user_weapon(iOwner) != CSW_RUNEBLADE || !ValidPlayer(iOwner) || !g_had_runeblade[iOwner])
		{
			new Float:fRender
			pev(iEnt, pev_renderamt, fRender)
			
			fRender -= 25.0
			set_pev(iEnt, pev_renderamt, fRender)
			
			if(!fRender)
			{
				engfunc(EngFunc_RemoveEntity, iEnt)
				return
			}
		}
	}
	
	if(equal(Classname, "summoner") || equal(Classname, "summoner_efx"))
	{
		set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
		
		new Float:origin[3],Float:fOrigin[3], Float:vecAngle[3]
		pev(iEnt, pev_origin, fOrigin)
		pev(iOwner, pev_origin, origin)
		pev(iOwner, pev_v_angle, vecAngle);
		
		if(equal(Classname, "summoner_efx"))
			origin[2] += 50.0
		
		vecAngle[0] = 0.0;
		set_pev(iEnt, pev_v_angle, vecAngle);
		set_pev(iEnt, pev_angles, vecAngle);

		static Float:fSpeed
		fSpeed = floatmin(500.0, vector_distance(origin, fOrigin) * 9.0)
		Stock_Hook_Ent(iEnt, origin, fSpeed, 1)

		if(equal(Classname, "summoner_efx"))
		{
			new Float:fFrameRate, Float:fFrame, Float:fFrameMax;
			pev(iEnt, pev_frame, fFrame)
			pev(iEnt, pev_fuser1, fFrameRate)
			fFrameMax = float(engfunc(EngFunc_ModelFrames, pev(iEnt,pev_modelindex)))
			fFrame += fFrameRate
			
			if(fFrame >= fFrameMax)
			{
				set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
				return
			}
			set_pev(iEnt, pev_frame, fFrame)
		} else {
			if(iStat == 1)
			{
				new Float:fRender
				pev(iEnt, pev_renderamt, fRender)
				
				fRender += 1.0
				set_pev(iEnt, pev_renderamt, fRender)
			}
			
			if(!iStat && (!g_iSpecialAmmo[iOwner] || get_user_weapon(iOwner) != CSW_RUNEBLADE || !IsAlive(iOwner) || !ValidPlayer(iOwner)))
			{
				new Float:fRender
				pev(iEnt, pev_renderamt, fRender)
				
				fRender -= 5.0
				set_pev(iEnt, pev_renderamt, fRender)
				
				if(fRender == 175.0)
				{
					g_iSummonerAttacking[iOwner] = 0
					g_iSummonerAttackMod[iOwner] = 0
					engfunc(EngFunc_RemoveEntity, iEnt)
					
					new Float:origin2[3], Float:angles[3]
					pev(iOwner, pev_origin, origin2)
					pev(iOwner, pev_angles, angles)
					MakeSummoner(iOwner, "summoner", SUMMONER_MDL, origin2, angles, 7, 1.0, 1, 175.0, 0, 3)
			
					Stock_Get_Postion(iOwner, 0.0, 0.0, 50.0, origin2)
					MakeSummoner(iOwner, "summoner_efx", MODEL_EFSUMN_UNSMNING1, origin2, angles, 0, 0.0, 1, 255.0, 0, 0, 0.5, 0.3)
					MakeSummoner(iOwner, "summoner_efx", MODEL_EFSUMN_UNSMNING2, origin2, angles, 0, 0.0, 1, 255.0, 0, 0, 0.5, 0.5)
					
					SendSound2(iOwner, summoner_sounds[0])
					Stock_ScreenFade(iOwner,0,155,255, 40)
					return
				}
			}
			
			if(iStat > 1 && (pev(iEnt, pev_ltime) < get_gametime() || get_user_weapon(iOwner) != CSW_RUNEBLADE || !IsAlive(iOwner) || !g_had_runeblade[iOwner]))
			{
				if(iStat == 2) 
				{
					engfunc(EngFunc_RemoveEntity, iEnt)
					return
				}
				
				new Float:fRender
				pev(iEnt, pev_renderamt, fRender)
				
				fRender -= 5.0
				set_pev(iEnt, pev_renderamt, fRender)
				
				if(!fRender)
				{
					if(iStat == 3 && is_user_connected(iOwner))
					{
						g_iSpecialAmmo[iOwner] = 0
						Stock_ScreenFade(iOwner)
					}
					engfunc(EngFunc_RemoveEntity, iEnt)
					return
				}
			}
		}
	}
	
	if(equal(Classname, "flame_efx") || equal(Classname, "flame_efx2"))
	{
		new Float:fFrameRate, Float:fFrame, Float:fFrameMax;
		pev(iEnt, pev_frame, fFrame)
		pev(iEnt, pev_fuser1, fFrameRate)
		fFrameMax = float(engfunc(EngFunc_ModelFrames, pev(iEnt,pev_modelindex)))

		fFrame += fFrameRate
		set_pev(iEnt, pev_frame, fFrame)
		set_pev(iEnt, pev_nextthink, 0.01);
		
		if (fFrame >= fFrameMax || get_user_weapon(iOwner) != CSW_RUNEBLADE || !ValidPlayer(iOwner) || cs_zb_is_zombie(iOwner))
		{
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME);
			return;
		}
		return
	}
	
	if(equal(Classname, "flame_efx3"))
	{
		new Float:fFrameRate, Float:fFrame, Float:fFrameMax
		pev(iEnt, pev_frame, fFrame)
		pev(iEnt, pev_fuser1, fFrameRate)
		fFrameMax = float(engfunc(EngFunc_ModelFrames, pev(iEnt,pev_modelindex)))
		
		fFrame += fFrameRate
		if(fFrame >= fFrameMax) 
			fFrame = 0.0
		
		set_pev(iEnt, pev_frame, fFrame)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.035)
		return
	}
	
	if(equal(Classname, "DN_Cannon"))
	{
		static iOwner;
		iOwner = pev(iEnt, pev_owner)
		if(entity_range(iEnt, iOwner) > 750.0)
		{
			Explosions(iEnt, iOwner)
			set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
			return;
		}
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
	}
}

public fw_MF_Touch(iEnt,iPtd)
{
	if(!pev_valid(iEnt))
		return HAM_IGNORED
	
	static Classname[32]
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "DN_Cannon"))
		return HAM_IGNORED
		
	new iOwner, Float:vecOri[3]
	iOwner = pev(iEnt, pev_owner)
	pev(iEnt, pev_origin, vecOri)
	
	if(iPtd == iOwner)
		return HAM_IGNORED
	
	new Float:fOrigin[3]
	pev(iEnt, pev_origin, fOrigin)

	Explosions(iEnt, iOwner)
	engfunc(EngFunc_RemoveEntity, iEnt)
	return HAM_IGNORED
}

public Explosions(iPtr, iOwner)
{
	new Float:fOrigin[3]
	pev(iPtr, pev_origin, fOrigin)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(g_Exp_SprId) 
	write_byte(7)
	write_byte(40)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()
	
	engfunc(EngFunc_EmitAmbientSound, 0, fOrigin, "weapons/plasmagun_exp.wav", 1.0, 0.6, 0, 100);
	
	new pEntity = -1
	while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, fOrigin, CHARGE_RANGE)) != 0)
	{
		if(pev(pEntity, pev_takedamage) == DAMAGE_NO) continue
		if(is_user_connected(pEntity) && pEntity != iOwner)
			if(!can_damage(pEntity, iOwner)) continue
		if(pEntity == iOwner) continue
		
		if(pev_valid(pEntity))
		{
			ExecuteHamB(Ham_TakeDamage, pEntity, iOwner, iOwner, CHARGE_DAMAGE, DMG_BULLET)
				
			Stock_Fake_KnockBack(iOwner, pEntity, CHARGE_KNOCKBACK)
			if(is_user_alive(pEntity)) SpawnBlood(fOrigin, get_pdata_int(pEntity,89), floatround(CHARGE_DAMAGE/5.0))
		}
	}
}
stock MakeMuzzleFlash(id, class[], model[], iBody, Float:fScale, Float:fNext, Float:fFrameRate = 1.0, iCheck = 0)
{
	new Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, model, class, SOLID_NOT,fOrigin,fNext)
	set_pev(iMuz, pev_body, iBody)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, fScale)
	set_pev(iMuz, pev_frame, 0.0)
	set_pev(iMuz, pev_fuser1, fFrameRate)
	if(iCheck) 
	{
		set_pev(iMuz, pev_animtime, get_gametime())
		set_pev(iMuz, pev_framerate, 1.0)
	}
	dllfunc(DLLFunc_Spawn, iMuz)
}

public DN_Shoot_Cannon(id)
{
	static Float:vAvel[3],Float:targetOri[3], Float:vAngle[3], Float:vVelocity[3],Float:fOrigin2[3], Float:vPlayerVelocity[3];
	pev(id, pev_origin, fOrigin2)
	pev(id, pev_v_angle, vAngle)
	pev(id, pev_velocity, vPlayerVelocity);
	fm_get_aim_origin(id, targetOri)
	
	Stock_GetSpeedVector(fOrigin2, targetOri, 1550.0, vVelocity);
	xs_vec_add(vVelocity, vPlayerVelocity, vVelocity);
	
	vector_to_angle(vVelocity, vAngle)
	if(vAngle[0] > 90.0) vAngle[0] = -(360.0 - vAngle[0]);
	
	new iFlame = Stock_CreateEntityBase(id, "info_target", MOVETYPE_FLY, model_cannon, "DN_Cannon", SOLID_BBOX, fOrigin2, 0.01)
	set_pev(iFlame, pev_animtime, get_gametime())
	set_pev(iFlame, pev_framerate, 1.0)
	set_pev(iFlame ,pev_angles, vAngle)		
	set_pev(iFlame, pev_frame, 1.0)
	set_pev(iFlame, pev_scale, 1.5)
	set_pev(iFlame, pev_rendermode, kRenderTransAdd)
	set_pev(iFlame, pev_renderamt, 255.0)
	engfunc(EngFunc_SetSize, iFlame, {1.0,1.0,1.0}, {1.0,1.0,1.0})
	
	vAvel[2] = random_float(-200.0, 200.0)
	set_pev(iFlame, pev_avelocity, vAvel)
	set_pev(iFlame, pev_velocity, vVelocity)
}

stock MakeSummoner(id, classname[], mdl[], Float:origin[3], Float:angles[3], seq, Float:fLife = 0.0, iRender=0, Float:fRender = 255.0, iDrop=0, stat=0, Float:fScales=0.0, Float:fFrmRate=0.0, iSlash=-1)
{
	new pEnt2 = Stock_CreateEntityBase(id, "info_target", MOVETYPE_FOLLOW, mdl, classname, SOLID_NOT, origin, 0.1)
	set_pev(pEnt2, pev_gravity, 0.1);
	set_pev(pEnt2, pev_angles, angles);
	if(fScales > 0.0) set_pev(pEnt2, pev_scale, fScales);
	engfunc(EngFunc_SetSize, pEnt2, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	set_pev(pEnt2, pev_frame, 0.0)
	set_pev(pEnt2, pev_animtime, get_gametime())
	set_pev(pEnt2, pev_framerate, 1.0)
	set_pev(pEnt2, pev_sequence, seq)
	set_pev(pEnt2, pev_iuser1, stat)
	if(fLife > 0.0) set_pev(pEnt2, pev_ltime, get_gametime() + fLife)
	if(iRender)
	{
		set_pev(pEnt2, pev_rendermode, kRenderTransAdd)
		set_pev(pEnt2, pev_renderamt, fRender)
	}
	if(fFrmRate > 0.0) set_pev(pEnt2, pev_fuser1, fFrmRate)
	if(iDrop) engfunc(EngFunc_DropToFloor, pEnt2)
	
	if(iSlash != -1) Summoner_Slash(id, pEnt2, origin, angles, iSlash, 0.5, 0.25)
}

stock Summoner_Slash(id, iEnt, Float:origin[3], Float:angles[3], seq, Float:fLife = 0.0, Float:fScales=0.0)
{
	new pEnt2 = Stock_CreateEntityBase(id, "info_target", MOVETYPE_FOLLOW, MODEL_EFSUMN_SWING, "summoner_slashefx", SOLID_NOT, origin, 0.1)
	set_pev(pEnt2, pev_gravity, 0.1);
	set_pev(pEnt2, pev_angles, angles);
	set_pev(pEnt2, pev_scale, fScales);
	engfunc(EngFunc_SetSize, pEnt2, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	set_pev(pEnt2, pev_frame, 0.0)
	set_pev(pEnt2, pev_animtime, get_gametime())
	set_pev(pEnt2, pev_framerate, 1.0)
	set_pev(pEnt2, pev_sequence, seq)
	set_pev(pEnt2, pev_iuser1, iEnt)
	set_pev(pEnt2, pev_ltime, get_gametime() + fLife)
	set_pev(pEnt2, pev_rendermode, kRenderTransAdd)
	set_pev(pEnt2, pev_renderamt, 255.0)
}

stock Stock_CreateEntityBase(id, classtype[], mvtyp, mdl[], class[], solid, Float:fOrigin[3], Float:fNext)
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classtype))
	set_pev(pEntity, pev_movetype, mvtyp);
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, mdl);
	set_pev(pEntity, pev_classname, class);
	set_pev(pEntity, pev_solid, solid);
	set_pev(pEntity, pev_origin, fOrigin);
	set_pev(pEntity, pev_nextthink, get_gametime() + fNext)
	return pEntity
}

stock Stock_ScreenFade(id,r=200,g=200,b=200,br=0)
{
	if(!is_user_alive(id))
		return
		
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), {0,0,0}, id)
	write_short((1<<12))//duration
	write_short((1<<12) * 1) //Hold
	write_short(0x0004) //Type
	write_byte(r) //R
	write_byte(g) //G
	write_byte(b) //B
	write_byte(br) //B
	message_end()
}

stock SendSound(id, chan, sample[]) emit_sound(id, chan, sample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
stock SendSound2(id, iSound[])
{
	if(!is_user_alive(id))
		return
		
	client_cmd(id, "spk %s", iSound)
}
stock FindEntityByOwner(iOwner, const szClassname[])
{
	new pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", szClassname)) != 0)
	{
		if(!pev_valid(pEnt) || pev(pEnt, pev_owner) != iOwner) continue;
	
		return pEnt
	}
	return -1;
}
stock RemoveEntityByOwner(iOwner, const szClassname[])
{
	new pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", szClassname)) != 0)
	{
		if(!pev_valid(pEnt) || pev(pEnt, pev_owner) != iOwner) continue;
	
		engfunc(EngFunc_RemoveEntity, pEnt)
	}
}
stock KnifeAttack_Setting(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
{
	new iHitResult
	if(fAngle > 0.0) iHitResult = KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
	else iHitResult = KnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack)

	return iHitResult
}

stock KnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bitsDamageType = DMG_NEVERGIB | DMG_CLUB)
{
	if( !ValidPlayer(id) )
		return 0;
	 
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

	new Float:EndPos2[3]
	get_tr2(tr, TR_vecEndPos, EndPos2)
	
	new iHitResult = RESULT_HIT_NONE;
	
	if (flFraction < 1.0)
	{
		iHitResult = RESULT_HIT_WORLD;
		
		new pEntity = get_tr2(tr, TR_pHit);
		if (pev_valid(pEntity) && (IsPlayer(pEntity) || IsHostage(pEntity)))
		{
			if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
				flDamage *= 3.0;
			
			iHitResult = RESULT_HIT_PLAYER;
		}

		if (pev_valid(pEntity))
		{
			engfunc(EngFunc_MakeVectors, v_angle);
			global_get(glb_v_forward, vecForward);

			if (iHitgroup != -1)
				set_tr2(tr, TR_iHitgroup, iHitgroup);

			rg_multidmg_clear();
			ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
			rg_multidmg_apply(id, id)
			
			if(is_user_alive(pEntity) && cs_zb_is_zombie(pEntity))
				Stock_Fake_KnockBack(id, pEntity, flKnockBack)
			
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

stock KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bitsDamageType = DMG_NEVERGIB | DMG_CLUB, bNoTraceCheck = 0)
{
	if( !ValidPlayer(id) )
		return 0;
		
	new Float:vecOrigin[3], Float:vecSrc[3], Float:vecEnd[3], Float:v_angle[3], Float:vecForward[3];
	pev(id, pev_origin, vecOrigin);

	new iHitResult = RESULT_HIT_NONE;
	GetGunPosition(id, vecSrc);

	pev(id, pev_v_angle, v_angle);
	engfunc(EngFunc_MakeVectors, v_angle);

	global_get(glb_v_forward, vecForward);
	xs_vec_mul_scalar(vecForward, flRange, vecForward);
	xs_vec_add(vecSrc, vecForward, vecEnd);

	new tr = create_tr2();
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);

	new Float:flFraction;
	get_tr2(tr, TR_flFraction, flFraction);

	if (flFraction < 1.0) iHitResult = RESULT_HIT_WORLD;

	new Float:vecEndZ = vecEnd[2];

	new pEntity = -1;
	while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, flRange)) != 0)
	{
		if (!pev_valid(pEntity))
			continue;
		if (id == pEntity)
			continue;
		if (!IsAlive(pEntity))
			continue;
		if (!CheckAngle(id, pEntity, fAngle))
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

				if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
					flDamage *= 3.0;
			}

			if (get_tr2(tr, TR_pHit) == pEntity || bNoTraceCheck)
			{
				engfunc(EngFunc_MakeVectors, v_angle);
				global_get(glb_v_forward, vecForward);

				if (iHitgroup != -1) set_tr2(tr, TR_iHitgroup, iHitgroup);

				rg_multidmg_clear();
				ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
				rg_multidmg_apply(id, id)

				if(is_user_alive(pEntity) && cs_zb_is_zombie(pEntity))
					Stock_Fake_KnockBack(id, pEntity, flKnockBack)
			}
		}
		free_tr2(tr);
	}
	return iHitResult;
}

stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock Stock_SetPlayerAnim(id, const AnimName[], Float:rate=1.0)
{
	static AnimNum, Float:FrameRate, Float:GroundSpeed, bool:Loops, Anim2[64]
	if(!(pev(id, pev_flags) & FL_DUCKING)) format(Anim2, 63, "ref_%s", AnimName)
	else format(Anim2, 63, "crouch_%s", AnimName)

	if ((AnimNum=lookup_sequence(id,Anim2,FrameRate,Loops,GroundSpeed))==-1) AnimNum=0
	
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

stock Make_EffSprite(Float:fOrigin[3],bStab)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(bStab?spr1:spr2) 
	write_byte(bStab?6:3)
	write_byte(40)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()
}

stock Make_EffSprite2(Float:fOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(spr3) 
	write_byte(2)
	write_byte(48)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()
}

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
	return equal(classname, "hostage_entity")
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

stock CheckAngle(iAttacker, iVictim, Float:fAngle)  return(Stock_CheckAngle(iAttacker, iVictim) > floatcos(fAngle,degrees))

stock Float:Stock_CheckAngle(id,iTarget)
{
	new Float:vOricross[2],Float:fRad,Float:vId_ori[3],Float:vTar_ori[3],Float:vId_ang[3],Float:fLength,Float:vForward[3]
	Stock_Get_Origin(id, vId_ori)
	Stock_Get_Origin(iTarget, vTar_ori)
	
	pev(id,pev_angles,vId_ang)
	for(new i=0;i<2;i++) vOricross[i] = vTar_ori[i] - vId_ori[i]
	
	fLength = floatsqroot(vOricross[0]*vOricross[0] + vOricross[1]*vOricross[1])
	
	if (fLength<=0.0)
	{
		vOricross[0]=0.0
		vOricross[1]=0.0
	} else {
		vOricross[0]=vOricross[0]*(1.0/fLength)
		vOricross[1]=vOricross[1]*(1.0/fLength)
	}
	
	engfunc(EngFunc_MakeVectors,vId_ang)
	global_get(glb_v_forward,vForward)
	
	fRad = vOricross[0]*vForward[0]+vOricross[1]*vForward[1]
	
	return fRad   //->   RAD 90' = 0.5rad
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

stock Stock_GetSpeedVector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}

stock SpawnBlood(const Float:vecOrigin[3], iColor, iAmount)
{
	if(iAmount == 0)
		return

	if (!iColor)
		return

	iAmount *= 2
	if(iAmount > 255) iAmount = 255
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin)
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(iColor)
	write_byte(min(max(3, iAmount / 10), 16))
	message_end()
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

stock Stock_BloodEffect(Float:vecOri[3], scale)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord,vecOri[0])
	engfunc(EngFunc_WriteCoord,vecOri[1])
	engfunc(EngFunc_WriteCoord,vecOri[2])
	write_short(spr_blood_spray)
	write_short(spr_blood_drop)
	write_byte(75)
	write_byte(scale)
	message_end()
}
stock ValidPlayer(id)
{
	return (is_user_alive(id) && is_user_connected(id) && !cs_zb_is_zombie(id))
}
stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
}
///////
stock Stock_Hook_Ent(ent, Float:TargetOrigin[3], Float:Speed, mode=0)
{
	static Float:fl_Velocity[3],Float:EntOrigin[3],Float:distance_f,Float:fl_Time
	pev(ent, pev_origin, EntOrigin)
	
	if(!mode)
	{
		distance_f = get_distance_f(EntOrigin, TargetOrigin)
		fl_Time = distance_f / Speed
			
		pev(ent, pev_velocity, fl_Velocity)
			
		fl_Velocity[0] = (TargetOrigin[0] - EntOrigin[0]) / fl_Time
		fl_Velocity[1] = (TargetOrigin[1] - EntOrigin[1]) / fl_Time
		fl_Velocity[2] = (TargetOrigin[2] - EntOrigin[2]) / fl_Time

		if(vector_length(fl_Velocity) > 1.0) set_pev(ent, pev_velocity, fl_Velocity)
		else set_pev(ent, pev_velocity, Float:{0.01, 0.01, 0.01})
	} else {
		static Float:fl_EntVelocity[3], Float:fl_Acc[3]
		Stock_Directed_Vector(TargetOrigin, EntOrigin, fl_Velocity)
		xs_vec_mul_scalar(fl_Velocity, Speed, fl_Velocity)
		
		for(new i =0; i<3; i++)
		{
			if(fl_Velocity[i] > fl_EntVelocity[i]) 
			{
				fl_Acc[i] = fl_Velocity[i]-fl_EntVelocity[i]
				fl_Acc[i] = floatmin(70.0, fl_Acc[i])
				fl_EntVelocity[i] += fl_Acc[i]
			}
			else if(fl_Velocity[i] < fl_EntVelocity[i])
			{
				fl_Acc[i] = fl_EntVelocity[i]-fl_Velocity[i]
				fl_Acc[i] = floatmin(70.0, fl_Acc[i])
				fl_EntVelocity[i] -= fl_Acc[i]
			}
		}
		set_pev(ent, pev_velocity, fl_EntVelocity)
	}
}
stock Stock_Directed_Vector(Float:start[3],Float:end[3],Float:reOri[3])
{	
	new Float:v3[3]
	v3[0]=start[0]-end[0]
	v3[1]=start[1]-end[1]
	v3[2]=start[2]-end[2]
	new Float:vl = vector_length(v3)
	reOri[0] = v3[0] / vl
	reOri[1] = v3[1] / vl
	reOri[2] = v3[2] / vl
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
