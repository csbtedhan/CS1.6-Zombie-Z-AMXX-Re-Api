
#pragma compress 1

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <csm>
#include <zombiemodlimited>
#include <reapi>

#define PLUGIN "Twin Shadow Axes"
#define VERSION "2.0"
#define AUTHOR "Asdian DX"

#define CSW_DGAXE CSW_KNIFE

#define v_model "models/zbz/wpn/v_dgaxe.mdl"
#define v_model2 "models/zbz/wpn/v_dgaxe_2.mdl"
#define p_model "models/zbz/wpn/p_dgaxe_a.mdl"
#define p_model2 "models/zbz/wpn/p_dgaxe_b.mdl"

new const weapon_sound[][] =
{
	"weapons/dgaxe_combo.wav",
	
	"weapons/dgaxe_dualslash1.wav",		// 1
	"weapons/dgaxe_dualslash2.wav",	
	
	"weapons/dgaxe_ready.wav",	// 3
	
	"weapons/dgaxe_skill1.wav",	// 4
	"weapons/dgaxe_skill1_exp.wav",	
	"weapons/dgaxe_skill2.wav",	
	"weapons/dgaxe_skill2_exp.wav",	
	
	"weapons/dgaxe_slash_hit1.wav",	// 8
	"weapons/dgaxe_slash_hit2.wav",	
	"weapons/dgaxe_slash_hit3.wav",	
	
	"weapons/dgaxe_slash1.wav",	// 11
	"weapons/dgaxe_slash2.wav",	
	"weapons/dgaxe_slash3.wav",	
	"weapons/dgaxe_slash4.wav",	
	
	"weapons/dgaxe_wall_metal1.wav",	// 15
	"weapons/dgaxe_wall_metal2.wav",
	
	"weapons/dgaxe_wall_stone1.wav",	// 17
	"weapons/dgaxe_wall_stone2.wav"
}

//SLASH
#define	SLASH_ANGLE			120.0
#define SLASH_DAMAGE			random_float(300.0,350.0)
#define SLASH_RANGE			130.0
#define SLASH_KNOCKBACK 		1.0		

//CHARGE
#define CHARGE_DAMAGE			random_float(600.0,650.0)	
#define	CHARGE_RANGE			160.0
#define	CHARGE_ANGLE			150.0
#define CHARGE_KNOCKBACK 		300.0				

//EXPLO1
#define EXPLO1_DAMAGE			random_float(600.0,650.0)	
#define	EXPLO1_RANGE			160.0
#define EXPLO1_KNOCKBACK 		10.0				

//EXPLO2
#define EXPLO2_DAMAGE			random_float(100.0,250.0)	
#define	EXPLO2_RANGE			200.0
#define EXPLO2_KNOCKBACK 		1.0				

//Hit
#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_METAL			2
#define	RESULT_HIT_GENERIC			3

// sprites and models
#define SPR_EFX_SKILL "sprites/muzzleflash200.spr"
#define SPR_EFX_CHARGED "sprites/ef_dgaxe_change.spr"

#define SPR_EFX_STAB "sprites/muzzleflash201.spr"
#define SPR_EFX_PRESTAB1 "sprites/muzzleflash202.spr"

#define SPR_EFX_IDLE_L "sprites/muzzleflash203.spr"
#define SPR_EFX_IDLE_R "sprites/muzzleflash204.spr"

#define MODEL_BLAST "models/zbz/ef_scorpion_hole.mdl"
#define MODEL_SUMMON "models/zbz/wpn/dgaxe_summon.mdl"
#define SPR_SUMMON_SPAWN "sprites/ef_dgaxe_smoke.spr"
#define SPR_SUMMON_EXPLO "sprites/ef_dgaxe_explo.spr"

// entities
#define DGAXE_ENT_WITHLOOP "dgaxe_entloop"
#define DGAXE_ENT_WITHOUTLOOP "dgaxe_entnonloop"

#define DGAXE_IDLESPR_L		1
#define DGAXE_IDLESPR_R		2
#define DGAXE_SKILLSPR		3

new g_had_dgaxe[33], g_combo[33], g_flame[33], Float:g_SkillTimer[33], g_Ammo[33], g_ModeCheck[33], g_CoolingDown[33], g_Block[33]
new cache_summon_spawnspr, cache_summon_explospr, spr_blood_spray, spr_blood_drop

// cosmetics
new g_IdleAnim[33]

public plugin_init() 
{
	register_plugin("[Zombie Z] Twin Shadow Axes", "2.0", "Asdian DX")
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	register_forward(FM_Think, "fw_MF_Think")
	register_forward(FM_AddToFullPack, "Fw_AddToFullPack_Post", 1);
	register_forward(FM_ClientCommand , "fw_ClientCommand")
	
	RegisterHam(Ham_Item_PostFrame, "weapon_knife", "fw_Item_PostFrame")
	
	cs_register_custom_item("Twin Shadow Axes", 0, 8, "get_dgaxe", "dgaxe")
}

public plugin_precache()
{
	precache_model(v_model)
	precache_model(v_model2)
	precache_model(p_model)
	precache_model(p_model2)
	
	for(new i = 0; i < sizeof(weapon_sound); i++)
		precache_sound(weapon_sound[i])
	
	precache_model(MODEL_BLAST)
	precache_model(MODEL_SUMMON)
	
	cache_summon_spawnspr = precache_model(SPR_SUMMON_SPAWN)
	cache_summon_explospr = precache_model(SPR_SUMMON_EXPLO)
	
	precache_model(SPR_EFX_SKILL)
	precache_model(SPR_EFX_CHARGED)
	
	precache_model(SPR_EFX_STAB)
	precache_model(SPR_EFX_PRESTAB1)
	
	precache_model(SPR_EFX_IDLE_L)
	precache_model(SPR_EFX_IDLE_R)
	
	spr_blood_spray = precache_model("sprites/bloodspray.spr")
	spr_blood_drop = precache_model("sprites/blood.spr")
}

public fw_Remove_Item(id, itemid, slot) 
{
	if(slot==2)remove_crow9(id)
}
public get_dgaxe(id)
{
	if (!is_user_alive(id))
		return

	g_had_dgaxe[id] = 1
	
	ResetAttrib(id)
	RemoveAttachment(id)
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string("weapon_knife")
	write_byte(2)
	write_byte(100)
	write_byte(-1)
	write_byte(-1)
	write_byte(2)
	write_byte(1)
	write_byte(CSW_DGAXE)
	write_byte(0)
	message_end()
	
	if (get_user_weapon(id) == CSW_DGAXE) Event_CurWeapon(id)
}

public remove_crow9(id)
{
	g_had_dgaxe[id] = 0
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string("weapon_knife")
	write_byte(-1)
	write_byte(-1)
	write_byte(-1)
	write_byte(-1)
	write_byte(2)
	write_byte(1)
	write_byte(CSW_DGAXE)
	write_byte(0)
	message_end()
	
	RemoveAttachment(id)
	ResetAttrib(id)
}

public ResetAttrib(id)
{
	g_ModeCheck[id] = 0
	g_combo[id] = 0
	g_IdleAnim[id] = 0
	g_Ammo[id] = 0
	g_CoolingDown[id] = 0
	g_Block[id] = 0
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return 1
	if(get_user_weapon(id) != CSW_DGAXE)
		return 1
	if(!g_had_dgaxe[id])
		return 1
		
	set_pev(id, pev_viewmodel2, IsOn(id) ? v_model2 : v_model)
	set_pev(id, pev_weaponmodel2, p_model)
	set_pev(id, pev_skin, IsOn(id))
	
	Set_WeaponAnim(id, 2)
	
	static iEnt; iEnt = fm_get_user_weapon_entity(id, CSW_DGAXE)
	if(!pev_valid(iEnt)) return 1
	
	set_pdata_float(id, 83, 1.0)
	set_pdata_float(iEnt, 46, 1.03);
	set_pdata_float(iEnt, 47, 1.03);
	set_pdata_float(iEnt, 48, 1.03);
	
	set_pev(iEnt, pev_iuser1, 0)
	set_pev(iEnt, pev_iuser2, 0)
	set_pev(iEnt, pev_iuser3, 0)
	
	RemoveAttachment(id)
	
	if(IsOn(id) && !g_ModeCheck[id])
	{
		SendSound(id, CHAN_ITEM, weapon_sound[3])
		g_ModeCheck[id] = 1
	}
	
	return 0
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "knife"))
		return PLUGIN_CONTINUE

	new iEntity = get_pdata_cbase(get_msg_arg_int(1), 373)
	
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_DGAXE || !g_had_dgaxe[get_msg_arg_int(1)])
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "dgaxe")
	return PLUGIN_CONTINUE
}

public client_PostThink(id)
{
	if(!is_user_connected(id) || !is_user_alive(id) || cs_zb_is_zombie(id) || !g_had_dgaxe[id])
		return
	
	static Wpn; Wpn = get_pdata_cbase(id, 373)
	if(!pev_valid(Wpn)) return
	
	static Float:flLastCheckTime
	pev(Wpn, pev_fuser2, flLastCheckTime)
	
	if(flLastCheckTime < get_gametime())
	{
		if(g_Ammo[id] < 100)
		{
			g_Ammo[id]++
			
			if(get_user_weapon(id) == CSW_DGAXE)
			{
				DgAxe_UpdateAmmo(id)
				
				if(g_Ammo[id] == 50) 
				{
					set_pev(id, pev_viewmodel2, v_model2)
					set_pev(id, pev_skin, 1)
					
					SendSound(id, CHAN_ITEM, weapon_sound[3])
					g_ModeCheck[id] = 1
					
					if(pev(id, pev_weaponanim) == 1) return
					
					MakeMuzzleFlash(id, SPR_EFX_CHARGED, DGAXE_ENT_WITHOUTLOOP, 2, DGAXE_SKILLSPR, 0.08, 0.05)
					MakeMuzzleFlash(id, SPR_EFX_CHARGED, DGAXE_ENT_WITHOUTLOOP, 3, DGAXE_SKILLSPR, 0.08, 0.05)
				}
				
				if(!IsOn(id)) g_ModeCheck[id] = 0
			}
			
			set_pev(Wpn, pev_fuser2, get_gametime() + 0.3)
		}
	}
}

public fw_Item_PostFrame(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(get_user_weapon(id) != CSW_DGAXE || !g_had_dgaxe[id])
		return HAM_IGNORED

	if(get_pdata_float(ent, 48, 4) <= 0.0) 
	{
		Set_WeaponAnim(id, !(g_IdleAnim[id] % 5) ? (g_IdleAnim[id] < 2 ? random(1) : 1) : 0)
		
		if(!g_flame[id] && !(pev(id, pev_weaponanim)))
		{
			MakeMuzzleFlash(id, SPR_EFX_IDLE_L, DGAXE_ENT_WITHLOOP, 2, DGAXE_IDLESPR_L, 0.08)
			MakeMuzzleFlash(id, SPR_EFX_IDLE_R, DGAXE_ENT_WITHLOOP, 3, DGAXE_IDLESPR_R, 0.08)
			
			g_flame[id] = 1
		}
		
		if(pev(id, pev_weaponanim) == 1)
			RemoveAttachment(id)
		
		if(g_IdleAnim[id] >= 10) g_IdleAnim[id] = 0
		else g_IdleAnim[id]++
		
		g_combo[id] = 0
		set_pdata_float(ent, 48, 2.03, 4)
	}	
		
	new iButton = pev(id,pev_button)
	return WeaponSkill(id, ent, iButton)
}

public WeaponSkill(id, iEnt, iButton)
{
	new iState = pev(iEnt, pev_iuser1)
	new Float:fTimer; pev(iEnt, pev_fuser1, fTimer)
	
	if((iButton & IN_RELOAD) && IsOn(id))
	{
		g_CoolingDown[id] = 1
		
		if(((iButton & IN_ATTACK) || (!(iButton & IN_ATTACK) && IsAimingAtVictim(id))) && g_SkillTimer[id] < get_gametime())
		{
			g_Ammo[id] = g_Ammo[id] - 50
			DgAxe_UpdateAmmo(id)
			
			if(!IsOn(id))
			{
				set_pev(id, pev_viewmodel2, v_model)
				set_pev(id, pev_skin, 0)
			}
			
			RemoveAttachment(id)
			
			if(iButton & IN_ATTACK) Summon_GojoSatoru(id, 0, 1)
			else
			{
				MakeMuzzleFlash(id, SPR_EFX_SKILL, DGAXE_ENT_WITHOUTLOOP, 1, DGAXE_SKILLSPR, 0.3)
			
				static Target; Target = IsAimingAtVictim(id, 1)
				Summon_GojoSatoru(id, Target, 0)
			}
			
			Set_WeaponAnim(id, (iButton & IN_ATTACK) ? 11 : 10)
			g_SkillTimer[id] = get_gametime() + ((iButton & IN_ATTACK) ? 7.0 : 1.53)
			set_pdata_float(iEnt, 48, 1.53, 4)
		}
	}
	
	if (g_combo[id] == 2 && get_pdata_float(id, 83) <= 0.0 && iState == 1)
	{
		RemoveAttachment(id)
		Stock_SetPlayerAnim(id, "shoot_knife")
			
		new iHitResult = KnifeAttack_Main(id, 0, SLASH_RANGE, SLASH_ANGLE, SLASH_DAMAGE, SLASH_KNOCKBACK)
		switch (iHitResult)
		{
			case RESULT_HIT_PLAYER : SendSound(id, CHAN_VOICE, weapon_sound[random_num(8, 10)])
			case RESULT_HIT_METAL : SendSound(id, CHAN_VOICE, weapon_sound[random_num(15, 16)])
			case RESULT_HIT_GENERIC : SendSound(id, CHAN_VOICE, weapon_sound[random_num(17, 18)])
		}
		
		set_pev(iEnt, pev_iuser1, 0);
		set_pev(iEnt, pev_fuser1, get_gametime() + 0.15)
		
		g_combo[id] = 3
	}
	
	if(g_combo[id] == 3 && fTimer && fTimer < get_gametime())
	{
		RemoveAttachment(id)
		MakeMuzzleFlash(id, SPR_EFX_STAB, DGAXE_ENT_WITHOUTLOOP, 1, DGAXE_SKILLSPR, 0.3)
		Gunkata_Blast(id)
		
		g_combo[id] = 0
		g_Block[id] = 0
		
		set_pev(iEnt, pev_fuser1, 0.0)
		set_pev(id, pev_weaponmodel2, p_model)
	}
	
	if(get_pdata_float(iEnt, 46) > 0.0)
		return HAM_IGNORED
	
	if(iButton & IN_ATTACK)
	{
		RemoveAttachment(id)
		if(g_combo[id] < 2)
		{
			Stock_SetPlayerAnim(id, "shoot_knife")
			new iAnim = pev(iEnt, pev_iuser2)
			
			set_pdata_float(iEnt, 46, 0.9,4);
			set_pdata_float(iEnt, 47, 0.91,4);
			set_pdata_float(iEnt, 48, 1.03,4);
	
			Set_WeaponAnim(id, 8 - iAnim)
			SendSound(id, CHAN_WEAPON, weapon_sound[2 - iAnim])
			
			iAnim = 1 - iAnim
			set_pev(iEnt, pev_iuser2, iAnim)
			
			new iHitResult = KnifeAttack_Main(id, 0, SLASH_RANGE, SLASH_ANGLE, SLASH_DAMAGE, SLASH_KNOCKBACK)
			switch (iHitResult)
			{
				case RESULT_HIT_PLAYER : SendSound(id, CHAN_VOICE, weapon_sound[random_num(8, 10)])
				case RESULT_HIT_METAL : SendSound(id, CHAN_VOICE, weapon_sound[random_num(15, 16)])
				case RESULT_HIT_GENERIC : SendSound(id, CHAN_VOICE, weapon_sound[random_num(17, 18)])
			}
		} else {
			set_pdata_float(id, 83, 0.7)
			set_pdata_float(iEnt, 46, 1.5,4);
			set_pdata_float(iEnt, 47, 1.51,4);
			set_pdata_float(iEnt, 48, 2.03,4);
	
			set_pev(iEnt, pev_iuser1, 1)
			set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
			
			g_Block[id] = 1
			Set_WeaponAnim(id, 9)
			SendSound(id, CHAN_WEAPON, weapon_sound[0])
			
			set_pev(id, pev_weaponmodel2, p_model2)
			MakeMuzzleFlash(id, SPR_EFX_PRESTAB1, DGAXE_ENT_WITHOUTLOOP, 1, DGAXE_SKILLSPR, 0.3)
		}
		
		if(g_combo[id] == 1) g_combo[id] = 2
	}

	if(iButton & IN_ATTACK2)
	{
		Stock_SetPlayerAnim(id, "shoot_knife")
		RemoveAttachment(id)
		
		new iAnim = pev(iEnt, pev_iuser4)
		set_pdata_float(iEnt, 46, 0.15,4);
		set_pdata_float(iEnt, 47, 0.151,4);
		set_pdata_float(iEnt, 48, 1.03,4);
		
		Set_WeaponAnim(id, 3 + iAnim)
		SendSound(id, CHAN_WEAPON, weapon_sound[11 + iAnim])
		
		if(iAnim > 2) iAnim = 0
		else iAnim++
		set_pev(iEnt, pev_iuser4, iAnim)
		
		new iHitResult = KnifeAttack_Main(id, 0, SLASH_RANGE, SLASH_ANGLE, SLASH_DAMAGE, SLASH_KNOCKBACK)
		switch (iHitResult)
		{
			case RESULT_HIT_PLAYER : SendSound(id, CHAN_VOICE, weapon_sound[random_num(8, 10)])
			case RESULT_HIT_METAL : SendSound(id, CHAN_VOICE, weapon_sound[random_num(15, 16)])
			case RESULT_HIT_GENERIC : SendSound(id, CHAN_VOICE, weapon_sound[random_num(17, 18)])
		}
		
		g_combo[id] = 1
	}
	
	iButton &= ~IN_ATTACK;
	iButton &= ~IN_ATTACK2;
	iButton &= ~IN_RELOAD;
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

	if(equal(Classname, DGAXE_ENT_WITHOUTLOOP) || equal(Classname, DGAXE_ENT_WITHLOOP))
		if (iHost != pev(iEnt, pev_owner)) set_es(esState, ES_Effects, (get_es(esState, ES_Effects) | EF_NODRAW));
}

public fw_ClientCommand(id)
{
	new sCmd[32]
	read_argv(0, sCmd, 31)
	
	if(equal(sCmd, "lastinv") || equal(sCmd,"weapon_", 7))
		if(g_Block[id]) return FMRES_SUPERCEDE
		
	return FMRES_IGNORED
}

public fw_MF_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32], iOwner
	pev(ent, pev_classname, Classname, sizeof(Classname))
	iOwner = pev(ent, pev_owner)
	
	if(equal(Classname, DGAXE_ENT_WITHOUTLOOP) || equal(Classname, DGAXE_ENT_WITHLOOP))
	{
		if (IsLoopType(ent) && (!IsAlive(iOwner) || !IsPlayer(iOwner) || get_user_weapon(iOwner) != CSW_DGAXE))
		{
			set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
			return;
		}
		
		new Float:fFrameRate, Float:fFrame, Float:fFrameMax, Float:fNextThink
		pev(ent, pev_frame, fFrame)
		pev(ent, pev_fuser1, fFrameRate)
		pev(ent, pev_fuser2, fNextThink)
		
		if(IsLoopType(ent)) fFrameMax = float(engfunc(EngFunc_ModelFrames, pev(ent, pev_modelindex))) - 4.0
		else fFrameMax = float(engfunc(EngFunc_ModelFrames, pev(ent, pev_modelindex)))
		
		fFrame += fFrameRate
		if(fFrame >= fFrameMax)
		{
			if(IsLoopType(ent)) fFrame = 5.0
			else
			{
				engfunc(EngFunc_RemoveEntity, ent);
				return;
			}
		}
		
		set_pev(ent, pev_frame, fFrame)
		set_pev(ent, pev_nextthink, get_gametime() + fNextThink)
		return
	}
	
	if(equal(Classname, "dgaxe_gojo"))
	{
		set_pev(ent, pev_nextthink, get_gametime() + 0.05)
		
		static iAnim, iMode, Float:fTimeRemove, Float:fRenderMount, Float:fAnim; 
		pev(ent, pev_ltime, fTimeRemove)
		pev(ent, pev_renderamt, fRenderMount)
		pev(ent, pev_fuser1, fAnim)
		iAnim = pev(ent, pev_iuser1)
		iMode = pev(ent, pev_iuser2)
		
		static Float:fFrame, Float:vOrig[3]
		pev(ent, pev_frame, fFrame)
		pev(ent, pev_origin, vOrig)
		
		fFrame += 1.0
		set_pev(ent, pev_frame, fFrame)
		
		if(!iMode)
		{
			if(fAnim && fAnim < get_gametime())
			{
				if(!iAnim)
				{
					Stock_SetEntityAnim(ent, 1)
					
					set_pev(ent, pev_iuser1, 1)
					set_pev(ent, pev_fuser1, get_gametime() + 0.16)
				}
				
				if(iAnim == 1)
				{
					set_pev(ent, pev_iuser1, 2)
					
					new Float:vVicOrig[3]
					pev(ent, pev_vuser1, vVicOrig)
					
					engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vVicOrig, 0)
					write_byte(TE_EXPLOSION)
					engfunc(EngFunc_WriteCoord, vVicOrig[0])
					engfunc(EngFunc_WriteCoord, vVicOrig[1])
					engfunc(EngFunc_WriteCoord, vVicOrig[2] + 70.0)
					write_short(cache_summon_explospr) 
					write_byte(10)
					write_byte(30)
					write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
					message_end()
					
					Do_Damage(ent, iOwner, vVicOrig, EXPLO1_RANGE, EXPLO1_DAMAGE, EXPLO1_KNOCKBACK)
				}
			}
			
			fRenderMount -= 2.0
			set_pev(ent,pev_renderamt,fRenderMount)
			
			if(fRenderMount <= 0.0)
			{
				g_CoolingDown[iOwner] = 0
				
				set_pev(ent, pev_iuser1, 0)
				set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
				return
			}
		} else {
			if(fAnim && fAnim < get_gametime())
			{
				if(iAnim <= 2)
				{
					Stock_SetEntityAnim(ent, 3)
					Do_Damage(ent, iOwner, vOrig, EXPLO2_RANGE, EXPLO2_DAMAGE, EXPLO2_KNOCKBACK)
					
					set_pev(ent, pev_iuser1, (iAnim == 1) ? 2 : 1)
					set_pev(ent, pev_fuser1, get_gametime() + 0.3)
				}
				
				if(iAnim == 3)
				{
					Stock_SetEntityAnim(ent, 4)
					set_pev(ent, pev_ltime, get_gametime() + 0.01)
				}
				
				if(iAnim == 4) // fuckers
				{
					set_pev(ent, pev_rendermode, kRenderTransTexture)
					set_pev(ent, pev_renderamt, 255.0)
						
					fRenderMount -= 8.0
					set_pev(ent, pev_renderamt, fRenderMount)
					
					set_pev(ent, pev_iuser1, 4)
					set_pev(ent, pev_fuser1, get_gametime())
					
					if(fRenderMount <= 0.0)
					{
						g_CoolingDown[iOwner] = 0
						
						set_pev(ent, pev_iuser1, 0)
						set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME);
						return
					}
				}
			}
			
			if(get_gametime() >= fTimeRemove)
			{
				if(iAnim == 3) // rendering shit
				{
					set_pev(ent, pev_iuser1, 4)
					set_pev(ent, pev_fuser1, get_gametime() + 0.3)
				}
				
				if(iAnim < 3)
				{
					set_pev(ent, pev_iuser1, 3)
					set_pev(ent, pev_fuser1, get_gametime() + 0.01)
				}
			}
		}
		set_pev(ent, pev_nextthink, get_gametime())
	}
}

public Gunkata_Blast(id)
{
	new Float:origin[3]
	pev(id, pev_origin, origin)

	origin[2] -= 10.0
	
	new iEnt = Stock_CreateEntityBase(id, "info_target", 0, MODEL_BLAST, DGAXE_ENT_WITHOUTLOOP, SOLID_NOT,origin,0.01)
	set_pev(iEnt, pev_frame, 0.0)
	set_pev(iEnt, pev_animtime, get_gametime())
	set_pev(iEnt, pev_framerate, 1.0)
	set_pev(iEnt, pev_sequence, 1)
	set_pev(iEnt, pev_fuser1, 0.5)
	set_pev(iEnt, pev_fuser2, 0.05)
	engfunc(EngFunc_SetSize, iEnt, Float:{-0.1, -0.1, -0.1}, Float:{0.1, 0.1, 0.1})
	dllfunc(DLLFunc_Spawn, iEnt)
	set_pev(iEnt, pev_scale, 0.03);
}

stock MakeMuzzleFlash(id, model[], classname[], body, type, Float:fScale, Float:fNext = 0.035)
{
	new Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, model, classname, SOLID_NOT,fOrigin,0.01)
	set_pev(iMuz, pev_body, body)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, fScale)
	set_pev(iMuz, pev_frame, 0.0)
	set_pev(iMuz, pev_iuser1, type)
	set_pev(iMuz, pev_fuser1, 1.0)
	set_pev(iMuz, pev_fuser2, fNext)
	dllfunc(DLLFunc_Spawn, iMuz)
}

stock Summon_GojoSatoru(id, vic, mode = 0)
{
	client_cmd(id, "spk %s", weapon_sound[mode?7:5])
	
	new Float:fRes[3], Float:fVicOrig[3]
	pev(vic, pev_origin, fVicOrig)
	
	if(!mode)
	{
		new Float:fAtkOrig[3], Float:vDir[3] 
		pev(id, pev_origin, fAtkOrig)
		
		xs_vec_sub(fAtkOrig, fVicOrig, vDir)
		xs_vec_normalize(vDir, vDir)
		xs_vec_mul_scalar(vDir, 100.0, vDir)
		xs_vec_add(fVicOrig, vDir, fRes)
	} else fm_get_aim_origin(id, fRes)
	
	static Float:vAngle[3]
	pev(id, pev_v_angle, vAngle)
	
	vAngle[0] = 0.0
	
	new iEfx = Stock_CreateEntityBase(id, "info_target", MOVETYPE_TOSS, MODEL_SUMMON, "dgaxe_gojo", SOLID_NOT, fRes, 0.0)
	if(!mode) set_pev(iEfx, pev_rendermode, kRenderTransTexture)
	set_pev(iEfx, pev_renderamt, 255.0)
	set_pev(iEfx, pev_angles, vAngle);
	set_pev(iEfx, pev_iuser1, 0)
	set_pev(iEfx, pev_iuser2, mode)
	set_pev(iEfx, pev_animtime, get_gametime())
	set_pev(iEfx, pev_sequence, mode?2:0)
	set_pev(iEfx, pev_framerate, 1.0)
	if(mode) set_pev(iEfx, pev_ltime, get_gametime() + 5.0)
	set_pev(iEfx, pev_fuser1, get_gametime() + 0.3)
	if(!mode) set_pev(iEfx, pev_vuser1, fVicOrig)
	set_pev(iEfx, pev_nextthink, get_gametime())
	engfunc(EngFunc_SetSize, iEfx, Float:{-0.1, -0.1, -0.1}, Float:{0.1, 0.1, 0.1})
	drop_to_floor(iEfx)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fRes, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fRes[0])
	engfunc(EngFunc_WriteCoord, fRes[1])
	engfunc(EngFunc_WriteCoord, fRes[2] + 10.0)
	write_short(cache_summon_spawnspr) 
	write_byte(8)
	write_byte(30)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()
}

stock Stock_SetEntityAnim(iEnt, iSeq, Float:fRate = 1.0)
{
	set_pev(iEnt, pev_animtime, get_gametime())
	set_pev(iEnt, pev_framerate, fRate)
	set_pev(iEnt, pev_sequence, iSeq)
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

public RemoveAttachment(id)
{
	g_flame[id] = 0
	
	new ent = find_ent_by_class(id, DGAXE_ENT_WITHLOOP)
	if(!pev_valid(ent)) return
	
	new type = pev(ent, pev_iuser1)
	if(type == DGAXE_IDLESPR_L || type == DGAXE_IDLESPR_R)
	{
		set_pev(ent, pev_iuser1, 0)
		remove_entity_name(DGAXE_ENT_WITHLOOP)
		return
	}
}

stock IsAimingAtVictim(id, a=0)
{
	static Body, Target
	get_user_aiming(id, Target, Body)
	
	if(a == 0) return (IsAlive(Target) && IsPlayer(Target))
	
	return Target
}

public IsLoopType(ent)
{
	new iType = pev(ent, pev_iuser1)
	return (iType == DGAXE_IDLESPR_L || iType == DGAXE_IDLESPR_R)
}

public IsOn(id) return (g_Ammo[id] >= 50) ? 1 : 0

stock DgAxe_UpdateAmmo(id)
{
	if(!is_user_alive(id))
		return

	static weapon_ent; weapon_ent = fm_get_user_weapon_entity(id, CSW_DGAXE)
	if(!pev_valid(weapon_ent)) return
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_DGAXE)
	write_byte(-1)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(2)
	write_byte(g_Ammo[id])
	message_end()
}

public Do_Damage(Ent, pevAttacker, Float:vecOrigin[3], Float:fRadius, Float:flMaxDamage, Float:flKnock)
{
	static Float:vicOrigin[3], Float:flDist, Float:flDamage, pEnt; pEnt= -1
	while ((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vecOrigin, fRadius)) != 0)
	{
		if(!pev_valid(pEnt))
			continue;
		if (pevAttacker == pEnt || !can_damage(pevAttacker, pEnt))
			continue;
		
		pev(pEnt, pev_origin, vicOrigin);
		flDist = vector_distance(vicOrigin, vecOrigin);
		flDamage = flMaxDamage - floatmul(flMaxDamage, floatdiv(flDist, fRadius));
		
		if(isBreakable(pEnt) && flDamage <= 0.0) flDamage = floatdiv(flMaxDamage, 2.0)
		
		if(flDamage > 0.0 && pev(pEnt, pev_health) > 0.0 && pev(pEnt, pev_takedamage) > 0.0)
		{
			if(IsPlayer(pEnt)) Stock_BloodEffect(vicOrigin, 5)
			ExecuteHamB(Ham_TakeDamage, pEnt, pevAttacker, pevAttacker, flDamage, isBreakable(pEnt) ? DMG_BLAST : DMG_CLUB);
		}
		
		if(flKnock > 0.0) Stock_Fake_KnockBack(Ent, pEnt, flKnock)
	}
}

stock isBreakable(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))

	if (equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable")) return 1;
	return 0;
}

stock SendSound(id, chan, sample[]) emit_sound(id, chan, sample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

stock KnifeAttack_Main(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
{
	new iHitResult
	if(fAngle > 0.0) iHitResult = KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
	else iHitResult = KnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack)

	return iHitResult
}

stock KnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bitsDamageType = DMG_NEVERGIB | DMG_CLUB)
{
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
		new pEntity = get_tr2(tr, TR_pHit);
		
		new iTtextureType, pTextureName[64];
		engfunc(EngFunc_TraceTexture, 0, vecSrc, vecEnd, pTextureName, charsmax(pTextureName));
		iTtextureType = dllfunc(DLLFunc_PM_FindTextureType, pTextureName);
		
		if (iTtextureType == 'M') iHitResult = RESULT_HIT_METAL
		else iHitResult = RESULT_HIT_GENERIC;
		
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

			Stock_Fake_KnockBack(id, pEntity, flKnockBack)

			ClearMultiDamage();
			ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
			ApplyMultiDamage(id, id);
			
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

stock KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bNoTraceCheck = 0, bitsDamageType = DMG_NEVERGIB | DMG_CLUB)
{
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
	
	new Float:EndPos2[3]
	get_tr2(tr, TR_vecEndPos, EndPos2)
	
	new Float:flFraction; get_tr2(tr, TR_flFraction, flFraction);
	if (flFraction < 1.0) 
	{
		new iTtextureType, pTextureName[64];
		engfunc(EngFunc_TraceTexture, 0, vecSrc, vecEnd, pTextureName, charsmax(pTextureName));
		iTtextureType = dllfunc(DLLFunc_PM_FindTextureType, pTextureName);
		
		if (iTtextureType == 'M') iHitResult = RESULT_HIT_METAL
		else iHitResult = RESULT_HIT_GENERIC
	}
	
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

				Stock_Fake_KnockBack(id, pEntity, flKnockBack)

				ClearMultiDamage();
				ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
				ApplyMultiDamage(id, id);
			}
		}
		free_tr2(tr);
	}
	return iHitResult;
}

stock ClearMultiDamage() rg_multidmg_clear()
stock ApplyMultiDamage(inflictor, iAttacker) rg_multidmg_apply(inflictor, iAttacker);

stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
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

stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
