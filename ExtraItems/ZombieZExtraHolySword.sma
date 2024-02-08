
#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <reapi>
#include <zombiemodlimited>
#include <csm>

#define PLUGIN "CSO Holysword"
#define VERSION "1.0"
#define AUTHOR "Natasha"

#define CSW_HOLYSWORD CSW_KNIFE
#define weapon_holysword "weapon_knife"

#define v_model "models/zbz/wpn/v_holysword.mdl"
#define p_model "models/zbz/wpn/p_holysword.mdl"

new const weapon_sound[][] =
{
	"weapons/holysword_slash1.wav",				// 0
	"weapons/holysword_slash2.wav",				// 1
	"weapons/holysword_slash3.wav",				// 2
	"weapons/tomahawk_slash1_hit.wav",			// 3
	"weapons/tomahawk_slash2_hit.wav",			// 4
	"weapons/combatknife_wall.wav",				// 5
	
	// specials
	"weapons/holysword_cannon.wav",	// 6
	"weapons/holysword_cannon_exp.wav",	// 7
	"weapons/holysword_charge_loop.wav",	// 8
	"weapons/holysword_charge_slash.wav",	// 9
	"weapons/holysword_paring_slash.wav",	// 10
	"weapons/holysword_parryattack.wav"	// 11
	
}

new const entity_models[][] = 
{
	"models/zbz/wpn/ef_holysword_chargecannon.mdl",
	"models/zbz/wpn/ef_holysword_parryattack.mdl",
	"models/zbz/wpn/ef_holysword_parryattack2.mdl"
}

//SLASH
new Float:c_slash_angle
new Float:c_slash_damage
new Float:c_slash_range
new Float:c_slash_kb

#define SLASH_ANGLE			30.0
#define SLASH_DAMAGE			740.0
#define SLASH_RANGE			120.0
#define SLASH_KNOCKBACK 		1.0	
	
//STACK
new Float:c_stack_angle
new Float:c_stack_damage
new Float:c_stack_range
new Float:c_stack_kb

#define STACK_ANGLE			40.0
#define STACK_DAMAGE			700.0
#define STACK_RANGE			150.0
#define STACK_KNOCKBACK 		3.0		

//CHARGE
new Float:c_charge_damage
new Float:c_charge_range
new Float:c_charge_kb

#define CHARGE_DAMAGE		2010.0	
#define CHARGE_RADIUS		10.0
#define CHARGE_KNOCKBACK 		5.0				

//BLAST-DEF
new Float:c_blast_damage
new Float:c_blast_radius
new Float:c_blast_range
new Float:c_blast_kb

#define BLAST_DAMAGE			6550.0	
#define BLAST_RADIUS			360.0
#define BLAST_RANGE			120.0
#define BLAST_KNOCKBACK 		100.0	
			
new const Float:AttackDamage_Mul[3] =  { 1.0, 1.5, 2.0 }
	
//Hit
#define	RESULT_HIT_NONE 			0
#define	RESULT_HIT_PLAYER			1
#define	RESULT_HIT_WORLD			2

#define DMG_GC (DMG_CRUSH | DMG_FALL | DMG_BLAST | DMG_SONIC)// | DMG_CLUB)
#define DMG_SH (DMG_POISON | DMG_ACID | DMG_FREEZE | DMG_SLOWFREEZE | DMG_DROWN | DMG_SLOWBURN | DMG_NERVEGAS | DMG_RADIATION | DMG_SHOCK)
#define DMG_ALL (DMG_GC | DMG_SH)

enum _:iAnim
{
	ANIM_IDLE = 0,
	ANIM_DRAW,
	ANIM_SLASH1,
	ANIM_SLASH2,
	ANIM_SLASH3,
	ANIM_SLASH_CHARGE,
	ANIM_CHARGE_START,
	ANIM_CHARGE_LOOP,
	ANIM_CHARGE_SLASH1,
	ANIM_CHARGE_SLASH2,
	ANIM_PARING,
	ANIM_PARING_SLASH1,
	ANIM_PARING_SLASH2
}

new g_had_holysword[33], g_isStack[33], Float:g_fTimer[33], g_isDef[33]
new spr_blood_spray, spr_blood_drop, spr1, spr2

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	register_forward(FM_ClientCommand , "Fw_ClientCommand")
	
	RegisterHam(Ham_Item_PostFrame, weapon_holysword, "fw_Item_PostFrame")
	RegisterHam(Ham_Think, "info_target", "fw_MF_Think")
	RegisterHam(Ham_Touch, "info_target", "fw_HS_Touch")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	cs_register_custom_item("Holy Sword Divine Order", 0, 8, "get_hsword", "holysword")
}

public plugin_precache()
{
	precache_model(v_model)
	precache_model(p_model)
	
	new i
	for(i = 0; i < sizeof(weapon_sound); i++) precache_sound(weapon_sound[i])
	for(i = 0; i < sizeof(entity_models); i++) precache_model(entity_models[i])
	
	load_config()
	
	spr1 = precache_model("sprites/muzzleflash65.spr")
	spr2 = precache_model("sprites/muzzleflash78.spr")
	
	spr_blood_spray = precache_model("sprites/bloodspray.spr")
	spr_blood_drop = precache_model("sprites/blood.spr")
}

load_config()
{
	if(!file_exists("script/custom_item/weapon_holysword.txt"))
	{
		delete_file("script/custom_item/weapon_holysword.txt")
		new File = fopen("script/custom_item/weapon_holysword.txt", "a")
		
		fprintf(File, "// Config Generated by AMXX^n^n")
		fprintf(File, "SLASH_ANGLE %i^n", floatround(SLASH_ANGLE))
		fprintf(File, "SLASH_DAMAGE %i^n", floatround(SLASH_DAMAGE))
		fprintf(File, "SLASH_RANGE %i^n", floatround(SLASH_RANGE))
		fprintf(File, "SLASH_KNOCKBACK %i^n^n", floatround(SLASH_KNOCKBACK))
		fprintf(File, "STACK_ANGLE %i^n", floatround(STACK_ANGLE))
		fprintf(File, "STACK_DAMAGE %i^n", floatround(STACK_DAMAGE))
		fprintf(File, "STACK_RANGE %i^n", floatround(STACK_RANGE))
		fprintf(File, "STACK_KNOCKBACK %i^n^n", floatround(STACK_KNOCKBACK))
		fprintf(File, "CHARGE_DAMAGE %i^n", floatround(CHARGE_DAMAGE))
		fprintf(File, "CHARGE_RANGE %i^n", floatround(CHARGE_RADIUS))
		fprintf(File, "CHARGE_KNOCKBACK %i^n^n", floatround(CHARGE_KNOCKBACK))
		fprintf(File, "BLAST_RADIUS %i^n", floatround(BLAST_RADIUS))
		fprintf(File, "BLAST_DAMAGE %i^n", floatround(BLAST_DAMAGE))
		fprintf(File, "BLAST_RANGE %i^n", floatround(BLAST_RANGE))
		fprintf(File, "BLAST_KNOCKBACK %i^n^n", floatround(BLAST_KNOCKBACK))
		fclose(File)
	}
	new file, linedata[1024], key[512], value[64], extra[64]
	file = fopen("script/custom_item/weapon_holysword.txt", "rt")
		
	while (file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")
			
		if (!linedata[0] || linedata[0] == '/') continue;
			
		parse(linedata, key, 511, value, 63, extra, 63);
		if(equal(key, "SLASH_DAMAGE")) c_slash_damage = str_to_float(value)
		else if(equal(key, "SLASH_ANGLE")) c_slash_angle = str_to_float(value)
		else if(equal(key, "SLASH_RANGE")) c_slash_range = str_to_float(value)
		else if(equal(key, "SLASH_KNOCKBACK")) c_slash_kb = str_to_float(value)
		
		else if(equal(key, "STACK_DAMAGE")) c_stack_damage = str_to_float(value)
		else if(equal(key, "STACK_ANGLE")) c_stack_angle = str_to_float(value)
		else if(equal(key, "STACK_RANGE")) c_stack_range = str_to_float(value)
		else if(equal(key, "STACK_KNOCKBACK")) c_stack_kb = str_to_float(value)
		
		else if(equal(key, "CHARGE_DAMAGE")) c_charge_damage = str_to_float(value)
		else if(equal(key, "CHARGE_RANGE")) c_charge_range = str_to_float(value)
		else if(equal(key, "CHARGE_KNOCKBACK")) c_charge_kb = str_to_float(value)
		
		else if(equal(key, "BLAST_DAMAGE")) c_blast_damage = str_to_float(value)
		else if(equal(key, "BLAST_ANGLE")) c_blast_radius = str_to_float(value)
		else if(equal(key, "BLAST_RANGE")) c_blast_range = str_to_float(value)
		else if(equal(key, "BLAST_KNOCKBACK")) c_blast_kb = str_to_float(value)
		
	}
	fclose(file)
}


public plugin_natives()
	register_native("cs_zb_is_defending", "natives_defending", 1);
	
public natives_defending(id)
{
	if(!is_user_alive(id) || cs_zb_is_zombie(id) || get_user_weapon(id) != CSW_HOLYSWORD || !g_had_holysword[id])
		return 0
		
	return g_isDef[id]
}
public fw_CSZB_BoltImpact(id)
{
	if(get_user_weapon(id) != CSW_HOLYSWORD || !g_had_holysword[id])
		return 0
		
	if (g_isDef[id])
	{
		if (g_isDef[id] == 1)
		{
			g_isDef[id] = 2
		}
		return 2
	}
	return 0
}
public fw_CSZB_Infecting(id, attacker)
{
	if(get_user_weapon(id) != CSW_HOLYSWORD || !g_had_holysword[id])
		return 0
		
	if (g_isDef[id])
	{
		if (g_isDef[id] == 1)
		{
			g_isDef[id] = 2
		}
		return 2
	}
	return 0
}
public fw_CSZB_StuckRedraw(id)
{
	if(get_user_weapon(id) != CSW_HOLYSWORD || !g_had_holysword[id])
		return
		
	g_isStack[id] = 0
	g_isDef[id] = 0
	
	Event_CurWeapon(id)
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if (!is_user_alive(victim) || get_user_weapon(victim) != CSW_HOLYSWORD || !g_had_holysword[victim])
		return HAM_IGNORED;
	
	if (g_isDef[victim] && !(damage_type & DMG_ALL))
	{
		if (g_isDef[victim] == 1)
		{
			g_isDef[victim] = 2
		}
		if(damage_type & DMG_BULLET)
		{
			SetHamParamInteger(5, DMG_CLUB|DMG_NEVERGIB)
		}
		return HAM_HANDLED
	}
	return HAM_IGNORED
}
public Fw_ClientCommand(id)
{
	new sCmd[32]
	read_argv(0,sCmd,31)
	
	if(get_user_weapon(id) != CSW_HOLYSWORD || !g_had_holysword[id])
		return FMRES_IGNORED
	
	if(equal(sCmd,"lastinv") || equal(sCmd,"weapon_",7))
		if(g_isDef[id]) return FMRES_SUPERCEDE
	
	return FMRES_IGNORED
}

public get_hsword(id)
{
	if (!is_user_alive(id))
		return

	g_had_holysword[id] = 1
	g_isStack[id] = 0
	g_isDef[id] = 0
	
	if(!user_has_weapon(id, CSW_HOLYSWORD)) fm_give_item(id, "weapon_knife")
	if (get_user_weapon(id) == CSW_HOLYSWORD) Event_CurWeapon(id)
}

public fw_Remove_Item(id, itemid, slot)
{
	if(slot == 2) remove_crow9(id)
}
public remove_crow9(id)
{
	g_had_holysword[id] = 0
	g_isStack[id] = 0
	g_isDef[id] = 0
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return 1
	if(get_user_weapon(id) != CSW_HOLYSWORD || !g_had_holysword[id])
		return 1
	
	new IsSpec = (g_isStack[id] == 5)
	set_pev(id, pev_viewmodel2, v_model)
	set_pev(id, pev_weaponmodel2, p_model)
	
	set_pdata_string(id, (492) * 4, "katana", -1 , 20)
	
	Set_WeaponAnim(id, IsSpec?ANIM_DRAW+13:ANIM_DRAW)
	
	static iEnt; iEnt = fm_get_user_weapon_entity(id, CSW_HOLYSWORD)
	if(!pev_valid(iEnt)) return 1
	
	set_pdata_float(id, 83, 1.0)
	set_pdata_float(iEnt, 46, 1.03);
	set_pdata_float(iEnt, 47, 1.03);
	set_pdata_float(iEnt, 48, 1.03);
	
	g_isDef[id] = 0
	set_pev(iEnt, pev_iuser1, 0)
	set_pev(iEnt, pev_iuser2, 0)
	set_pev(iEnt, pev_iuser3, 0)
	set_pev(iEnt, pev_iuser4, 0)
	return 0
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "knife"))
		return PLUGIN_CONTINUE

	new iEntity = get_pdata_cbase(get_msg_arg_int(1), 373)
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_HOLYSWORD || !g_had_holysword[get_msg_arg_int(1)])
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "holysword")
	return PLUGIN_CONTINUE
}

public fw_Item_PostFrame(ent)
{
	new id = pev(ent, pev_owner)
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(get_user_weapon(id) != CSW_HOLYSWORD || !g_had_holysword[id])
		return HAM_IGNORED

	new iButton = pev(id,pev_button)
	new IsSpec = (g_isStack[id] == 5)
	
	if (get_pdata_float(ent, 48, 4) <= 0.0)
	{
		if(g_isDef[id] == 1) g_isDef[id] = 0
		set_pev(ent, pev_iuser4, 0)
		set_pev(id, pev_body, IsSpec)
		
		Set_WeaponAnim(id, IsSpec?ANIM_IDLE+13:ANIM_IDLE)
		set_pdata_float(ent, 48, 8.06,4);
	}
	
	return WeaponHandler(id, ent, iButton)
}

public Float:DmgAdjust(IsSpec,iSlash,iType)
{
	if(!iType) return (IsSpec)?c_stack_angle:c_slash_angle
	else if(iType == 1) return (IsSpec?c_stack_damage:c_slash_damage) * AttackDamage_Mul[iSlash]
	else if(iType == 2) return (IsSpec)?c_stack_kb:c_slash_kb
	else if(iType == 3) return (IsSpec)?c_stack_range:c_slash_range
	return 1.0
}

public WeaponHandler(id, iEnt, iButton)
{
	new bStab2 = pev(iEnt, pev_iuser2);
	new iState = pev(iEnt, pev_iuser3)
	new iHold = pev(iEnt, pev_iuser4)
	new IsSpec = (g_isStack[id] == 5)
	new Float:flCheck; pev(iEnt, pev_fuser1, flCheck)
	
	if(g_isDef[id] == 2)
	{
		Set_WeaponAnim(id, !IsSpec?ANIM_PARING_SLASH1:ANIM_PARING_SLASH1+13)
		g_isDef[id] = 3
		
		Gunkata_Blast(id, IsSpec)
		SendSound(id, CHAN_WEAPON, weapon_sound[11])
		client_cmd(id, "spk %s", weapon_sound[10])
		
		set_pdata_float(id, 83, 0.5)
		set_pdata_float(iEnt, 46, 2.03,4);
		set_pdata_float(iEnt, 47, 2.03,4);
		set_pdata_float(iEnt, 48, 2.03,4);
	}

	if(get_pdata_float(id, 83) <= 0.0 && g_isDef[id] == 3) 
	{
		KnifeAttack2(id, IsSpec, c_blast_range, c_blast_radius, c_blast_damage, c_blast_kb)
		
		g_isDef[id] = 4
		if(IsSpec) g_isStack[id] = 0
		set_pev(iEnt, pev_fuser1, get_gametime() + 2.03)
	}
	
	if(pev(iEnt, pev_fuser1) < get_gametime() && g_isDef[id] == 4)
	{
		set_pev(iEnt, pev_iuser4, 0)
		g_isDef[id] = 0
	}
	
	if (!(iButton & IN_ATTACK))
	{
		if (iState == 2)
		{
			set_pdata_float(id, 83, 0.7)
			set_pdata_float(iEnt, 46, 1.7,4);
			set_pdata_float(iEnt, 47, 1.7,4);
			set_pdata_float(iEnt, 48, 1.7,4);
			
			Set_WeaponAnim(id, IsSpec?ANIM_CHARGE_SLASH1+13:ANIM_CHARGE_SLASH1)
			SendSound(id, CHAN_WEAPON, weapon_sound[9])
			g_isStack[id] = 6
			
			set_pev(iEnt, pev_iuser1, 1)
			set_pev(iEnt, pev_iuser2, 0)
			set_pev(iEnt, pev_iuser3, 0)
			set_pev(iEnt, pev_iuser4, 0)
			
			set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
		}
		
		if (iState < 2)
		{
			if(g_fTimer[id] < get_gametime() && bStab2)
			{
				Set_WeaponAnim(id, ANIM_SLASH_CHARGE)
				set_pdata_float(iEnt, 48, 1.36,4);
				
				set_pev(iEnt, pev_iuser2, 0)
			}
			set_pev(iEnt, pev_iuser3, 0)
		}
	}
	
	if (get_pdata_float(id, 83) <= 0.0 && pev(iEnt, pev_iuser1) && !g_isDef[id])
	{
		// range angle dmg knockback
		new iHitResult
		iHitResult = KnifeAttack_Global(id, IsSpec, DmgAdjust(IsSpec,iHold,3),DmgAdjust(IsSpec,iHold,0),DmgAdjust(IsSpec,iHold,1),DmgAdjust(IsSpec,iHold,2))
		
		switch (iHitResult)
		{
			case RESULT_HIT_PLAYER : SendSound(id, CHAN_VOICE, weapon_sound[random_num(3, 4)])
			case RESULT_HIT_WORLD : SendSound(id, CHAN_VOICE, weapon_sound[5])
		}
		
		new Float:vecSrc[3], Float:vecEnd[3], Float:vecForward[3];
		GetGunPosition(id, vecSrc);

		global_get(glb_v_forward, vecForward);
		xs_vec_mul_scalar(vecForward, DmgAdjust(IsSpec,iHold,3), vecForward);
		xs_vec_add(vecSrc, vecForward, vecEnd);

		new tr = create_tr2();
		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, id, tr);

		new Float:EndPos2[3]
		get_tr2(tr, TR_vecEndPos, EndPos2)
		
		if(iHitResult != RESULT_HIT_NONE)
		{
			new Float:iVicOrig[3], pEntity = -1;
			new Float:realOrig[3]; pev(id, pev_origin, realOrig)
			
			if(iHitResult == RESULT_HIT_PLAYER)
			{
				while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, realOrig, DmgAdjust(IsSpec,iHold,3))) != 0)
				{
					if (!pev_valid(pEntity))
						continue;
					if (id == pEntity)
						continue;
					if (!IsAlive(pEntity))
						continue;
					if (!CheckAngle(id, pEntity, DmgAdjust(IsSpec,iHold,0)))
						continue;	
					
					if(g_isStack[id] < 6 && can_damage(id, pEntity))
					{
						if(g_isStack[id] < 5)
						{
							g_isStack[id]++ 
							if(g_isStack[id] == 5) set_pev(iEnt, pev_iuser2, 1)
						} else g_isStack[id] = 5
					}
					
					Stock_Get_Origin(pEntity, iVicOrig);
					
					iVicOrig[2] -= 15.0
					Make_EffSprite(iVicOrig,0)
				}
			} else Make_EffSprite(EndPos2,(g_isStack[id] == 6))
		} 
			
		if(iHold == 2) iHold = 0
		else iHold += 1
		
		if(g_isStack[id] == 6)
		{
			if(!(pev(id, pev_flags) & FL_DUCKING)) SetAnimation(id, "ref_shoot_katana", 1.0)
			else SetAnimation(id, "crouch_shoot_katana", 1.0)
		
			MakeMuzzleFlash(id)
			g_isStack[id] = 0
			iHold = 0
		}
		
		set_pev(iEnt, pev_iuser1, 0);
		set_pev(iEnt, pev_iuser4, iHold)
	}
	
	if(get_pdata_float(iEnt, 46, 4) > 0.0)
		return HAM_IGNORED
	
	if(iButton & IN_ATTACK)
	{
		if(!(pev(id, pev_flags) & FL_DUCKING)) SetAnimation(id, "ref_shoot_katana", 1.0)
		else SetAnimation(id, "crouch_shoot_katana", 1.0)
		
		switch(iState)
		{
			case 0:
			{
				if(iHold == 1)
				{
					set_pdata_float(id, 83, 0.16)
					set_pdata_float(iEnt, 46, 0.66,4);
					set_pdata_float(iEnt, 47, 0.66,4);
					set_pdata_float(iEnt, 48, 2.03,4);
					
					Set_WeaponAnim(id, !IsSpec?ANIM_SLASH2:ANIM_SLASH2+13)
					g_fTimer[id] = get_gametime() + 0.66
				} else {
					set_pdata_float(id, 83, 0.3)
					set_pdata_float(iEnt, 46, 0.76,4);
					set_pdata_float(iEnt, 47, 0.76,4);
					set_pdata_float(iEnt, 48, 2.03,4);
					
					Set_WeaponAnim(id, !IsSpec?(!iHold?ANIM_SLASH1:ANIM_SLASH3):(!iHold?ANIM_SLASH1+13:ANIM_SLASH3+13))
					g_fTimer[id] = get_gametime() + 0.76
				}
				SendSound(id, CHAN_WEAPON, weapon_sound[random(2)])
				
				set_pev(iEnt, pev_iuser1, 1)
				set_pev(iEnt, pev_iuser3, 1)
				set_pev(iEnt, pev_fuser4, get_gametime() + get_pdata_float(id, 83))
			}
			case 1:
			{
				set_pdata_float(iEnt, 46, 0.7,4);
				set_pdata_float(iEnt, 47, 0.7,4);
				set_pdata_float(iEnt, 48, 0.7,4);
		
				Set_WeaponAnim(id, !IsSpec?ANIM_CHARGE_START:ANIM_CHARGE_START+12)
				set_pev(iEnt, pev_iuser3, 2)
			}
			case 2:
			{
				set_pdata_float(iEnt, 46, 1.7,4);
				set_pdata_float(iEnt, 47, 1.7,4);
				set_pdata_float(iEnt, 48, 1.7,4);
				
				Set_WeaponAnim(id, !IsSpec?ANIM_CHARGE_LOOP:ANIM_CHARGE_LOOP+12)
				SendSound(id, CHAN_WEAPON, weapon_sound[8])
			}
		}
	}

	if(iButton & IN_ATTACK2)
	{
		set_pdata_float(iEnt, 46, 3.03,4);
		set_pdata_float(iEnt, 47, 3.03,4);
		set_pdata_float(iEnt, 48, 3.03,4);
		
		if(!(pev(id, pev_flags) & FL_DUCKING)) SetAnimation(id, "ref_parying_holysword", 1.0)
		else SetAnimation(id, "crouch_parying_holysword", 1.0)
		
		g_isDef[id] = 1
		Set_WeaponAnim(id, !IsSpec?ANIM_PARING:ANIM_PARING+12)
	}
	
	iButton &= ~IN_ATTACK;
	iButton &= ~IN_ATTACK2;
	set_pev(id, pev_button, iButton);
	return HAM_IGNORED
}

public fw_MF_Think(iEnt)
{
	if(!pev_valid(iEnt))
		return
	
	static Classname[32], iOwner, iStat
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	iOwner = pev(iEnt, pev_owner)
	iStat = pev(iEnt, pev_iuser1)
	
	if(equal(Classname, "hsword_special"))
	{
		if(!iStat)
		{
			if(entity_range(iEnt, iOwner) > 600.0)
			{
				HExplo(iEnt, iOwner)
				set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
				return;
			}
			set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
		} else if(iStat == 1) set_pev(iEnt, pev_flags, pev(iEnt, pev_flags) | FL_KILLME)
	}
}

public fw_HS_Touch(iPtr,iPtd)
{
	if(!pev_valid(iPtr))
		return
	
	static Classname[32], iOwner
	pev(iPtr, pev_classname, Classname, sizeof(Classname))
	iOwner = pev(iPtr, pev_owner)
	
	new Float:fOrigin[3]
	pev(iPtr, pev_origin, fOrigin)
	
	if(equal(Classname, "hsword_special"))
	{
		if(!iPtd || !is_user_alive(iPtd)) 
		{
			HExplo(iPtr, iOwner)
			set_pev(iPtr, pev_flags, pev(iPtr, pev_flags) | FL_KILLME)
		} else if(IsPlayer(iPtd))
		{
			if(iPtd == iOwner) return
			
			new pEntity = -1;
			while ((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, fOrigin, 30.0)) != 0)
			{
				if (!pev_valid(pEntity))
					continue;
				if (iOwner == pEntity)
					continue;
				if (!IsAlive(pEntity))
					continue;
				if (!CheckAngle(iOwner, pEntity, 179.0))
					continue;
					
				HExplo(iPtr, iOwner)
			}
		}
		set_pev(iPtr, pev_nextthink, get_gametime() + 0.01)
	}
}

public HExplo(iPtr, iOwner)
{
	new Float:fOrigin[3]
	pev(iPtr, pev_origin, fOrigin)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(spr1) 
	write_byte(6)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(spr2) 
	write_byte(9)
	write_byte(15)
	write_byte(TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND)
	message_end()
	
	SendSound(iPtr, CHAN_VOICE, weapon_sound[7])
	Stock_RadiusDamage(fOrigin, iPtr, iOwner, c_charge_damage, c_charge_range, c_charge_kb, DMG_CLUB)
}

stock Gunkata_Blast(id, IsSpec)
{
	new Float:origin[3]
	pev(id, pev_origin, origin)

	origin[2] -= 15.0
	
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(pEntity, pev_movetype, MOVETYPE_NONE);
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, entity_models[1+IsSpec]);
	set_pev(pEntity, pev_classname, "hsword_special");
	set_pev(pEntity, pev_solid, SOLID_NOT);
	set_pev(pEntity, pev_iuser1, 1)
	set_pev(pEntity, pev_origin, origin)
	set_pev(pEntity, pev_frame, 0.0)
	set_pev(pEntity, pev_animtime, get_gametime())
	set_pev(pEntity, pev_framerate, 1.0)
	set_pev(pEntity, pev_sequence, 1)
	engfunc(EngFunc_SetSize, pEntity, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	dllfunc(DLLFunc_Spawn, pEntity)
	set_pev(pEntity, pev_scale, 1.0);
	
	set_pev(pEntity, pev_nextthink, get_gametime() + 0.55)
}

public MakeMuzzleFlash(id)
{
	static Float:vAvel[3],Float:targetOri[3], Float:vAngle[3], Float:vVelocity[3],Float:fOrigin2[3], Float:vPlayerVelocity[3];
	pev(id, pev_origin, fOrigin2)
	pev(id, pev_v_angle, vAngle)
	pev(id, pev_velocity, vPlayerVelocity);
	fm_get_aim_origin(id, targetOri)
	
	new iFlame = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	Stock_GetSpeedVector(fOrigin2, targetOri, 1050.0, vVelocity);
	xs_vec_add(vVelocity, vPlayerVelocity, vVelocity);
	
	vector_to_angle(vVelocity, vAngle)
	if(vAngle[0] > 90.0) vAngle[0] = -(360.0 - vAngle[0]);
	
	dllfunc(DLLFunc_Spawn, iFlame)
	set_pev(iFlame, pev_classname, "hsword_special")
	set_pev(iFlame, pev_animtime, get_gametime())
	set_pev(iFlame, pev_framerate, 1.0)
	set_pev(iFlame ,pev_angles, vAngle)
	set_pev(iFlame, pev_movetype, MOVETYPE_FLY)		
	set_pev(iFlame, pev_frame, 1.0)
	set_pev(iFlame, pev_scale, 1.5)
	set_pev(iFlame, pev_rendermode, kRenderTransAdd)
	set_pev(iFlame, pev_renderamt, 255.0)
	engfunc(EngFunc_SetModel, iFlame, entity_models[0])
	engfunc(EngFunc_SetSize, iFlame, {2.0,2.0,2.0}, {2.0,2.0,2.0})
	set_pev(iFlame, pev_origin, fOrigin2)
	set_pev(iFlame, pev_iuser1, 0)
	
	vAvel[2] = random_float(-200.0, 200.0)
	set_pev(iFlame, pev_avelocity, vAvel)
	set_pev(iFlame, pev_velocity, vVelocity)
	set_pev(iFlame, pev_solid, SOLID_TRIGGER)
	set_pev(iFlame, pev_owner, id)
	set_pev(iFlame, pev_nextthink, get_gametime() + 0.01)
	
	client_cmd(id, "spk %s", weapon_sound[6])
}

stock Stock_GetSpeedVector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed * speed / (new_velocity[0] * new_velocity[0] + new_velocity[1] * new_velocity[1] + new_velocity[2] * new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}
stock Stock_Get_Velocity_Angle(entity, Float:output[3])
{
	static Float:velocity[3]
	pev(entity, pev_velocity, velocity)
	vector_to_angle(velocity, output)
	if( output[0] > 90.0 ) output[0] = -(360.0 - output[0])
}

stock SendSound(id, chan, sample[]) emit_sound(id, chan, sample, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

stock KnifeAttack_Global(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
{
	new iHitResult
	if(fAngle > 0.0) iHitResult = KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack)
	else iHitResult = KnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack)

	return iHitResult
}

stock KnifeAttack(id, bStab, Float:flRange, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bitsDamageType = DMG_NEVERGIB | DMG_CLUB)
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

	new Float:EndPos2[3]
	get_tr2(tr, TR_vecEndPos, EndPos2)
	
	new iHitResult = RESULT_HIT_NONE;
	
	if (flFraction < 1.0)
	{
		new pEntity = get_tr2(tr, TR_pHit);
		iHitResult = RESULT_HIT_WORLD;
		
		if (pev_valid(pEntity) && (IsPlayer(pEntity) || IsHostage(pEntity)))
		{
			if (CheckBack(id, pEntity) && bStab && iHitgroup == -1)
				flDamage *= 3.0;

			iHitResult = RESULT_HIT_PLAYER;
		}

		if (pev_valid(pEntity) && id != pEntity)
		{
			engfunc(EngFunc_MakeVectors, v_angle);
			global_get(glb_v_forward, vecForward);

			if (iHitgroup != -1)
				set_tr2(tr, TR_iHitgroup, iHitgroup);

			ClearMultiDamage();
			ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, bitsDamageType);
			ApplyMultiDamage(id, id);
			
			if(cs_zb_is_zombie(pEntity) && is_user_alive(pEntity))
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

stock KnifeAttack2(id, bStab, Float:flRange, Float:fAngle, Float:flDamage, Float:flKnockBack, iHitgroup = -1, bNoTraceCheck = 0)
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
		if (!CheckAngle(id, pEntity, fAngle) && fAngle < 360.0)
			continue;
		if(!can_damage(id, pEntity))
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

				ClearMultiDamage()
				ExecuteHamB(Ham_TraceAttack, pEntity, id, flDamage, vecForward, tr, DMG_NEVERGIB | DMG_CLUB);
				ApplyMultiDamage(id, id);
				
				if(cs_zb_is_zombie(pEntity) && is_user_alive(pEntity))
					Stock_Fake_KnockBack(id, pEntity, flKnockBack)
			}
		}
		free_tr2(tr);
	}
	return iHitResult;
}

stock Stock_RadiusDamage(Float:vecSrc[3], pevInflictor, pevAttacker, Float:flDamage, Float:flRadius, Float:fKnockBack, bitsDamageType, bool:bSkipAttacker=true, bool:bCheckTeam=false)
{
	if(cs_zb_is_zombie(pevAttacker))
		return RESULT_HIT_NONE;
		
	new pEntity = -1, tr = create_tr2(), Float:flAdjustedDamage, Float:falloff, iHitResult = RESULT_HIT_NONE

	falloff = flDamage / flRadius
	new bInWater = (engfunc(EngFunc_PointContents, vecSrc) == CONTENTS_WATER)
	vecSrc[2] += 1.0
	if(!pevAttacker) pevAttacker = pevInflictor
	
	while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecSrc, flRadius)) != 0)
	{
		if(pev(pEntity, pev_takedamage) == DAMAGE_NO)
			continue
		if(bInWater && !pev(pEntity, pev_waterlevel))
			continue
		if(!bInWater && pev(pEntity, pev_waterlevel) == 3)
			continue
		if(bCheckTeam && IsPlayer(pEntity) && pEntity != pevAttacker)
			if(!can_damage(pEntity, pevAttacker))
				continue
		if(bSkipAttacker && pEntity == pevAttacker)
			continue
		
		new Float:vecEnd[3]
		pev(pEntity, pev_origin, vecEnd)

		engfunc(EngFunc_TraceLine, vecSrc, vecEnd, 0, 0, tr)

		new Float:flFraction
		get_tr2(tr, TR_flFraction, flFraction)

		if(flFraction >= 1.0) engfunc(EngFunc_TraceHull, vecSrc, vecEnd, 0, 3, 0, tr)
		
		if(pev_valid(pEntity))
		{
			pev(pEntity, pev_origin, vecEnd)
			xs_vec_sub(vecEnd, vecSrc, vecEnd)

			new Float:fDistance = xs_vec_len(vecEnd)
			if(fDistance < 1.0) fDistance = 0.0

			flAdjustedDamage = fDistance * falloff
			
			if(get_tr2(tr, TR_pHit) != pEntity) flAdjustedDamage *= 0.3

			if(flAdjustedDamage <= 0)
				continue

			ClearMultiDamage();
			ExecuteHamB(Ham_TraceAttack, pEntity, pevAttacker, flAdjustedDamage, vecEnd, tr, bitsDamageType);
			ApplyMultiDamage(pevAttacker, pevAttacker);
			
			if(cs_zb_is_zombie(pEntity) && is_user_alive(pEntity))
				Stock_Fake_KnockBack(pevAttacker, pEntity, fKnockBack)
			
			iHitResult = RESULT_HIT_PLAYER
		}
	}
	free_tr2(tr)
	return iHitResult
}

stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
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

stock Set_PlayerNextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}

stock Make_EffSprite(Float:fOrigin[3],bStab)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, fOrigin[0])
	engfunc(EngFunc_WriteCoord, fOrigin[1])
	engfunc(EngFunc_WriteCoord, fOrigin[2])
	write_short(bStab?spr1:spr2) 
	write_byte(bStab?2:3)
	write_byte(40)
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
stock ClearMultiDamage() rg_multidmg_clear();
stock ApplyMultiDamage(inflictor, iAttacker) rg_multidmg_apply(inflictor, iAttacker);
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
stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
