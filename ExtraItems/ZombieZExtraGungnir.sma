#include <amxmodx>
#include <engine>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <csm>
#include <zombiemodlimited>
#include <reapi>

#define PLUGIN "AMXX Gungnir"
#define VERSION "2.0"
#define AUTHOR "Asdian"

// Data Config
#define P_GUNGNIR "models/zbz/wpn/p_gungnira.mdl"
#define P_GUNGNIR2 "models/zbz/wpn/p_gungnirb.mdl"
#define V_GUNGNIR "models/zbz/wpn/v_gungnir.mdl"
#define W_GUNGNIR "models/zbz/wpn/w_primgroup2.mdl"

#define MF_W "sprites/muzzleflash81.spr"
#define MODEL_W_OLD "models/w_p90.mdl"
#define WEAPON_CODE 02062019

#define CSW_GUNGNIR CSW_P90
#define weapon_gungnir "weapon_p90"

enum _:NewAnim
{
	ANIM_IDLE = 0,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_SHOOT_START,
	ANIM_SHOOT_LOOP,
	ANIM_SHOOT_END,
	ANIM_SHOOT2,
	ANIM_SHOOT2_CHARGE,
	ANIM_SHOOT2_SHOTCHARGE,
	ANIM_CHARGE_LOOP
}

new const SOUND_FIRE[][] = 
{
	"weapons/gungnir_shoot_loop.wav",
	"weapons/gungnir_shoot_end.wav",
	"weapons/gungnir_shoot_b.wav",
	"weapons/gungnir_charge_shoot1.wav",
	
	// exps
	"weapons/gungnir_shoot_b_exp.wav",
	"weapons/gungnir_charge_shoot_exp.wav",
	"weapons/gungnir_charge_shoot_exp2.wav"
}

new const EXP_MODELS[][] = 
{
	"sprites/ef_gungnir_aexplo.spr",
	"sprites/ef_gungnir_bexplo.spr",
	"sprites/ef_gungnir_chargeexplo.spr",
	"sprites/ef_gungnir_lightline1.spr",
	"sprites/ef_gungnir_lightline2.spr",
	"sprites/ef_gungnir_missile.spr",
	"sprites/ef_gungnir_xbeam.spr",
	
	"models/zbz/wpn/gungnir_missile.mdl"
}

// Weapon Config
#define CLIP 50
#define BPAMMO 999
#define SPEED 0.113
#define RECOIL 0.5
#define RELOAD_TIME 2.03
new c_wpn_clip, Float:c_wpn_speed, Float:c_wpn_reloadtime


#define ELECTRO_DAMAGE 256.0
#define ELECTRO_RANGE 350.0
#define ELECTRO_KNOCKBACK 150.0 // the velocity of victim when got damage
new c_ele_damage, c_ele_range, c_ele_kb

// base damage
#define WDAMG_PLASMA 750.0
#define WDAMG_CHARGE 850.0
#define WDAMG_BEAM 6275.0
new c_dmg_plasma, c_dmg_charge, c_dmg_beam	

// range
#define WRANGE_PLASMA 210.0
#define WRANGE_CHARGE 250.0
#define WRANGE_BEAM 75.0
new c_range_plasma, c_range_charge, c_range_beam
	
// knockback
#define WKNOCK_CHARGE 25.0 // only charge
new c_charge_kb

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_cachde_mf, Float:g_cache_frame_mf, g_cache_light, g_cache_hit, g_cache_exp[2], g_cache_beam[2], g_SpraySpr, g_DropSpr
new g_Had_Base, g_Clip[33], g_OldWeapon[33], g_iVic[3], Float:g_VecVel[3]
	
// Safety
new g_HamBot
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Safety
	Register_SafetyFunc()
	
	// Event
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	// Forward
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_SetModel, "fw_SetModel")
	
	// Ham
	RegisterHam(Ham_Item_Deploy, weapon_gungnir, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_gungnir, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_gungnir, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_gungnir, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_gungnir, "fw_Weapon_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_gungnir, "fw_Weapon_PrimaryAttack")	
	RegisterHam(Ham_Think, "env_sprite", "fw_MF_Think")
	RegisterHam(Ham_Think, "info_target", "HamF_InfoTarget_Think")
	RegisterHam(Ham_Touch, "info_target", "HamF_InfoTarget_Touch")
	
	// Cache
	cs_register_custom_item("Gungnir", 6500, 9, "Get_Base", "gungnir")
}

public plugin_precache()
{
	precache_model(P_GUNGNIR)
	precache_model(P_GUNGNIR2)
	precache_model(V_GUNGNIR)
	precache_model(W_GUNGNIR)
	
	load_config()
	
	new i
	for(i = 0; i < sizeof SOUND_FIRE; i++) precache_sound(SOUND_FIRE[i])
	for(i = 0; i < sizeof EXP_MODELS; i++)
	{
		if(!i) g_cache_hit = precache_model(EXP_MODELS[i])
		else if(i == 1) g_cache_exp[0] = precache_model(EXP_MODELS[i])
		else if(i == 2) g_cache_exp[1] = precache_model(EXP_MODELS[i])
		else if(i == 3) g_cache_beam[0] = precache_model(EXP_MODELS[i])
		else if(i == 4) g_cache_beam[1] = precache_model(EXP_MODELS[i])
		else if(i == 6) g_cache_light = precache_model(EXP_MODELS[i])
		else precache_model(EXP_MODELS[i])
	}
	
	g_SpraySpr = precache_model("sprites/bloodspray.spr")
	g_DropSpr = precache_model("sprites/blood.spr")
	g_cachde_mf = precache_model(MF_W)
	g_cache_frame_mf = float(engfunc(EngFunc_ModelFrames, g_cachde_mf))
}
load_config()
{
	if(!file_exists("script/custom_item/weapon_gungnir.txt"))
	{
		delete_file("script/custom_item/weapon_gungnir.txt")
		new File = fopen("script/custom_item/weapon_gungnir.txt", "a")
		
		fprintf(File, "// Config Generated by AMXX^n^n")
		fprintf(File, "CLIP_SIZE %i^n", CLIP)
		fprintf(File, "FIRE_RATE %f^n", SPEED)
		fprintf(File, "RELOAD_RATE %f^n^n", RELOAD_TIME)
		
		fprintf(File, "ELECTRO_DAMAGE %i^n", floatround(ELECTRO_DAMAGE))
		fprintf(File, "ELECTRO_RANGE %i^n", floatround(ELECTRO_RANGE))
		fprintf(File, "ELECTRO_KNOCKBACK %i^n", floatround(ELECTRO_KNOCKBACK))
		
		fprintf(File, "DAMAGE_PLASMA %i^n", floatround(WDAMG_PLASMA))
		fprintf(File, "DAMAGE_CHARGE %i^n", floatround(WDAMG_CHARGE))
		fprintf(File, "DAMAGE_BEAM %i^n", floatround(WDAMG_BEAM))
		
		fprintf(File, "RANGE_PLASMA %i^n", floatround(WRANGE_PLASMA))
		fprintf(File, "RANGE_CHARGE %i^n", floatround(WRANGE_CHARGE))
		fprintf(File, "RANGE_BEAM %i^n", floatround(WRANGE_BEAM))
		
		fprintf(File, "KNOCKBACK_CHARGE %i^n", floatround(WKNOCK_CHARGE))
		
		fclose(File)
	}
	new file, linedata[1024], key[512], value[64]
	file = fopen("script/custom_item/weapon_gungnir.txt", "rt")
		
	while (file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata))
		replace(linedata, charsmax(linedata), "^n", "")
			
		if (!linedata[0] || linedata[0] == '/') continue;
			
		parse(linedata, key, 511, value, 63);
		if(equal(key, "CLIP_SIZE")) c_wpn_clip = str_to_num(value)
		else if(equal(key, "FIRE_RATE")) c_wpn_speed = str_to_float(value)
		else if(equal(key, "RELOAD_RATE")) c_wpn_reloadtime = str_to_float(value)
		
		else if(equal(key, "ELECTRO_DAMAGE")) c_ele_damage = str_to_num(value)
		else if(equal(key, "ELECTRO_RANGE")) c_ele_range = str_to_num(value)
		else if(equal(key, "ELECTRO_KNOCKBACK")) c_ele_kb = str_to_num(value)
		
		else if(equal(key, "DAMAGE_PLASMA")) c_dmg_plasma = str_to_num(value)
		else if(equal(key, "DAMAGE_CHARGE")) c_dmg_charge = str_to_num(value)
		else if(equal(key, "DAMAGE_BEAM")) c_dmg_beam = str_to_num(value)
		
		else if(equal(key, "RANGE_PLASMA")) c_range_plasma = str_to_num(value)
		else if(equal(key, "RANGE_CHARGE")) c_range_charge = str_to_num(value)
		else if(equal(key, "RANGE_BEAM")) c_range_beam = str_to_num(value)
		
		else if(equal(key, "KNOCKBACK_CHARGE")) c_charge_kb = str_to_num(value)
	}
	fclose(file)
}

public message_DeathMsg(msg_id, msg_dest, msg_ent)
{
	new szWeapon[64]
	get_msg_arg_string(4, szWeapon, charsmax(szWeapon))
	
	if (strcmp(szWeapon, "p90"))
		return PLUGIN_CONTINUE
	
	new id = get_msg_arg_int(1)
	new iEntity = get_pdata_cbase(id, 373)
	
	if (!pev_valid(iEntity) || get_pdata_int(iEntity, 43, 4) != CSW_GUNGNIR || !Get_BitVar(g_Had_Base, id))
		return PLUGIN_CONTINUE

	set_msg_arg_string(4, "gungnir")
	return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
        Safety_Connected(id)
	
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Register_HamBot", id)
	}
}
 
public Register_HamBot(id)
{
	Register_SafetyFuncBot(id)
}
public client_disconnected(id)
{
        Safety_Disconnected(id)
}
public fw_Remove_Item(id, itemid, slot)
{
	if(slot==0) Remove_Base(id)
}

public Get_Base(id)
{
	Set_BitVar(g_Had_Base, id)
	
	Stock_Drop_Slot(id, 1)
	fm_give_item(id, weapon_gungnir)
	
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_GUNGNIR)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, c_wpn_clip)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_GUNGNIR)
	write_byte(c_wpn_clip)
	message_end()
	
	ExecuteHamB(Ham_Item_Deploy, Ent)
}

public Remove_Base(id)
{
	UnSet_BitVar(g_Had_Base, id)
}

public Event_CurWeapon(id)
{
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_GUNGNIR && g_OldWeapon[id] != CSW_GUNGNIR) && Get_BitVar(g_Had_Base, id))
	{
		 Draw_NewWeapon(id, CSWID)
	} else if((CSWID == CSW_GUNGNIR && g_OldWeapon[id] == CSW_GUNGNIR) && Get_BitVar(g_Had_Base, id)) {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_GUNGNIR)
		if(!pev_valid(Ent))
		{
			g_OldWeapon[id] = get_user_weapon(id)
			return
		}
	} else if(CSWID != CSW_GUNGNIR && g_OldWeapon[id] == CSW_GUNGNIR) {
		Draw_NewWeapon(id, CSWID)
	}
	
	g_OldWeapon[id] = get_user_weapon(id)
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_GUNGNIR)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_GUNGNIR)
		
		if(pev_valid(ent) && Get_BitVar(g_Had_Base, id))
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW) 
	} else {
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_GUNGNIR)
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 			
	}
	
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_GUNGNIR && Get_BitVar(g_Had_Base, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
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
	
	if(equal(model, MODEL_W_OLD))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_gungnir, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_Base, iOwner))
		{
			set_pev(weapon, pev_impulse, WEAPON_CODE)
			engfunc(EngFunc_SetModel, entity, W_GUNGNIR)
			set_pev(entity, pev_body, 8);

			Remove_Base(iOwner)
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}
public fw_Weapon_PrimaryAttack(Ent)
{
	if(pev_valid(Ent) != 2)
		return HAM_IGNORED
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	
	if(get_pdata_cbase(Id, 373) != Ent)
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, Id))
		return HAM_IGNORED
		
	if(get_pdata_int(Ent, 51, 4) <= 0)
		return HAM_IGNORED
		
	set_pdata_int(Ent, 51, get_pdata_int(Ent, 51, 4) - 1, 4);
	return HAM_SUPERCEDE;
}
public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_Had_Base, Id))
		return
	
	set_pev(Id, pev_viewmodel2, V_GUNGNIR)
	set_pev(Id, pev_weaponmodel2, P_GUNGNIR)
	
	Set_WeaponAnim(Id, ANIM_DRAW)
	set_pdata_string(Id, (492 * 4), "m249", -1, 20)
	
	set_pdata_float(Ent, 46, 1.03, 4)
	set_pdata_float(Ent, 47, 1.03, 4)
	set_pdata_float(Ent, 48, 1.03, 4)
	
	set_pev(Ent, pev_iuser1, 0);
	set_pev(Ent, pev_iuser2, 0);
	
	static iClip
	iClip = get_pdata_int(Ent, 51, 4)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, Id)
	write_byte(1)
	write_byte(CSW_GUNGNIR)
	write_byte(iClip)
	message_end()
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == WEAPON_CODE)
	{
		Set_BitVar(g_Had_Base, id)
		set_pev(Ent, pev_impulse, 0)
	}
	
	return HAM_IGNORED	
}

public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_GUNGNIR)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(c_wpn_clip - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_GUNGNIR, bpammo - temp1)		
		
		fInReload = 0
		set_pdata_int(ent, 54, fInReload, 4)
		set_pdata_float(ent, 46, 0.01, 4)
	}		
	
	WE_GUNGNIR(id, ent, iClip,bpammo,pev(id, pev_button))
	return HAM_IGNORED
}

public WE_GUNGNIR(id,iEnt,iClip, bpammo,iButton)
{
	new Float:flNextPrimaryAttack, Float:fCurTime, iState, Float:fSound, iCharge
	global_get(glb_time, fCurTime)
	pev(iEnt, pev_fuser1, fSound)
	pev(iEnt, pev_fuser2, flNextPrimaryAttack)
	iCharge = pev(iEnt, pev_iuser1)
	iState = pev(iEnt, pev_iuser2)
	new pEntity = -1
				
	if(get_pdata_float(iEnt, 46, 4) > 0.0)
		return
	if((!(iButton & IN_ATTACK) || !iClip) && iState == 1)
	{
		Set_WeaponAnim(id, ANIM_SHOOT_END)
		
		set_pdata_float(iEnt, 46, 0.33, 4)
		set_pdata_float(iEnt, 48, 0.33, 4)
		set_pev(iEnt, pev_iuser2, 0)
		
		emit_sound(id, CHAN_WEAPON, SOUND_FIRE[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
	
	if(!(iButton & IN_ATTACK2) && 0 < iCharge < 3)
	{
		new bool:iMax = (iCharge == 2) ? true : false
		
		static Float:vOrigin[3], Float:vVAngles[3], Float:vVec[3],Float:vAngle[3],Float:vecEnd2[3]
		engfunc(EngFunc_GetAttachment, id, 1, vOrigin, vAngle)
		pev(id, pev_v_angle, vVAngles);
	
		Stock_Get_Aiming(id, vecEnd2)
		Stock_GetSpeedVector(vOrigin, vecEnd2, iMax?3500.0:2500.0, vVec)
		
		new pEntity = Stock_CreateEntityBase(id, "info_target", MOVETYPE_FLY, EXP_MODELS[iMax?7:5], "gungnir_plasma", iMax ? SOLID_TRIGGER : SOLID_BBOX, 0.01)
		engfunc(EngFunc_SetSize, pEntity, Float:{-0.5, -0.5, 0.5}, Float:{0.5, 0.5, 0.5})
		
		set_pev(pEntity, pev_origin, vOrigin);
		set_pev(pEntity, pev_gravity, 0.01);
		set_pev(pEntity, pev_owner, id);
		set_pev(pEntity, pev_velocity, vVec);
		set_pev(pEntity, pev_vuser3, vVec);
		set_pev(pEntity, pev_frame, 0.0)
		set_pev(pEntity, pev_framerate, 1.0)
		set_pev(pEntity, pev_iuser1, iMax?1:0)
		
		Stock_Get_Velocity_Angle(pEntity, vVAngles)
		set_pev(pEntity, pev_angles, vVAngles)
		
		if(!iMax) 
		{
			set_pev(pEntity, pev_renderamt, 255.0)
			set_pev(pEntity, pev_rendermode, kRenderTransAdd)
			set_pev(pEntity, pev_scale, 0.4)
		}
		
		xs_vec_copy(vVec, g_VecVel)
		
		if(iMax) 
		{
			set_pev(pEntity, pev_vuser1, vOrigin)
			set_pev(pEntity, pev_vuser2, vecEnd2)
		}
		
		Set_WeaponAnim(id, iMax?ANIM_SHOOT2_SHOTCHARGE:ANIM_SHOOT2)
		emit_sound(id, CHAN_WEAPON, SOUND_FIRE[iMax?3:2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		if(iClip >= 5) iClip -= 5
		else iClip = 0
		set_pdata_int(iEnt, 51, iClip, 4)
		
		set_pdata_float(iEnt, 46, iMax?3.13:0.5, 4)
		set_pdata_float(iEnt, 48, iMax?3.5:0.75, 4)
		
		Stock_SetPlayerAnim(id, iMax?"shoot_gungnir_b":"shoot_m249")
		set_pev(id, pev_weaponmodel2, "")
		set_pev(iEnt, pev_iuser1, iMax?3:0)
		
		if(iMax) set_pev(iEnt, pev_fuser3, fCurTime + 0.33)
	}
	
	if(iCharge == 3 && fSound < fCurTime)
	{
		set_pdata_string(id, (492 * 4), "m249", -1, 20)
		set_pev(id, pev_weaponmodel2, P_GUNGNIR)
		set_pev(iEnt, pev_iuser1, 0)
	}
	
	if(iButton & IN_ATTACK && iClip)
	{
		if(fSound < fCurTime)
		{
			emit_sound(id, CHAN_WEAPON, SOUND_FIRE[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			set_pev(iEnt, pev_fuser1, fCurTime + 1.0)
		}
		
		if(!iState)
		{
			Set_WeaponAnim(id, ANIM_SHOOT_START)
			
			set_pdata_float(iEnt, 46, 0.23, 4)
			set_pdata_float(iEnt, 48, 0.23, 4)
			set_pev(iEnt, pev_iuser2, 1)
		}
		
		if(iState == 1)
		{
			ExecuteHamB(Ham_Weapon_PrimaryAttack, iEnt);
			
			set_pdata_float(iEnt, 46, c_wpn_speed, 4)
			set_pdata_float(iEnt, 48, c_wpn_speed + 0.5, 4)
			
			MakeMuzzleFlash(id, iEnt)
			Set_WeaponAnim(id, ANIM_SHOOT_LOOP)
			Stock_SetPlayerAnim(id, "shoot_m249")
			
			if(flNextPrimaryAttack > fCurTime)
				return
	
			set_pev(iEnt, pev_fuser2, fCurTime + 0.01)
			
			new Float:fOrigin[3], Float:fEnd[3], Float:LOL[3][3]
			pev(id, pev_origin, fOrigin)
			Stock_Get_Postion(id, 128.0, 0.0, 0.0, fEnd)
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_BEAMENTPOINT)
			write_short(id | 0x1000)
			engfunc(EngFunc_WriteCoord, fEnd[0])
			engfunc(EngFunc_WriteCoord, fEnd[1])
			engfunc(EngFunc_WriteCoord, fEnd[2])
			write_short(g_cache_light)
			write_byte(0) // framerate
			write_byte(0) // framerate
			write_byte(1) // life
			write_byte(60)  // width
			write_byte(10)// noise
			write_byte(26)// r, g, b
			write_byte(164)// r, g, b
			write_byte(255)// r, g, b
			write_byte(255)	// brightness
			write_byte(255)	// speed
			message_end()
			
			new k
			for(k = 0; k < 3; k++)
			{
				while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, fOrigin, float(c_ele_range))) != 0)
				{
					if(pev(pEntity, pev_takedamage) == DAMAGE_NO) continue
					if(is_user_connected(pEntity) && pEntity != id)
						if(!can_damage(pEntity, id)) continue
					if(pEntity == id) continue
					if(k == 1 && pEntity == g_iVic[0])  continue
					if(k == 2 && (pEntity == g_iVic[0] || pEntity == g_iVic[1]))  continue
					
					if(pev_valid(pEntity))
					{
						new Float:tempOrigin[3]
						pev(pEntity, pev_origin, tempOrigin)
						
						if(get_distance_f(fOrigin, tempOrigin) < float(c_ele_range))
							g_iVic[k] = pEntity
					}
				}
				
				pev(g_iVic[k], pev_origin, LOL[k])
				
				if(is_user_alive(g_iVic[k]) && can_damage(id, g_iVic[k]) && entity_range(id, g_iVic[k]) < float(c_ele_range) && !Stock_Blah(fOrigin, LOL[k], id))
				{
					engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
					write_byte(TE_EXPLOSION)
					engfunc(EngFunc_WriteCoord, LOL[k][0])
					engfunc(EngFunc_WriteCoord, LOL[k][1])
					engfunc(EngFunc_WriteCoord, LOL[k][2] - 15.0)
					write_short(g_cache_hit)
					write_byte(2)
					write_byte(30)
					write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
					message_end()
					
					engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0)
					write_byte(TE_BEAMPOINTS)
					engfunc(EngFunc_WriteCoord, LOL[k][0])
					engfunc(EngFunc_WriteCoord, LOL[k][1])
					engfunc(EngFunc_WriteCoord, LOL[k][2])
					engfunc(EngFunc_WriteCoord, fEnd[0])
					engfunc(EngFunc_WriteCoord, fEnd[1])
					engfunc(EngFunc_WriteCoord, fEnd[2])
					write_short(g_cache_light)
					write_byte(0)		// byte (starting frame) 
					write_byte(10)		// byte (frame rate in 0.1's) 
					write_byte(1)		// byte (life in 0.1's) 
					write_byte(60)		// byte (line width in 0.1's) 
					write_byte(17)		// byte (noise amplitude in 0.01's) 
					write_byte(26)		// byte,byte,byte (color) (R)
					write_byte(164)		// (G)
					write_byte(255)		// (B)
					write_byte(255)		// byte (brightness)
					write_byte(10)		// byte (scroll speed in 0.1's)
					message_end()
					
					ExecuteHamB(Ham_TakeDamage, g_iVic[k], id, id, float(c_ele_damage), DMG_SHOCK)
					
					if(1 <= g_iVic[k] <= 32)
					{
						new Float:vAttacker[3], Float:vVictim[3]
						pev(id, pev_origin, vAttacker)
						pev(g_iVic[k], pev_origin, vVictim)
						xs_vec_sub(vVictim, vAttacker, vVictim)
						
						new Float:fDistance
						fDistance = xs_vec_len(vVictim)
						xs_vec_mul_scalar(vVictim, 1 / fDistance, vVictim)
						xs_vec_mul_scalar(vVictim, float(c_ele_kb), vVictim)
						set_pev(g_iVic[k], pev_velocity, vVictim)
						
						SpawnBlood(LOL[k], get_pdata_int(g_iVic[k],89), c_ele_damage)
					}
				}
			}
		}
	}
	
	if(iButton & IN_ATTACK2 && iClip)
	{
		if(flNextPrimaryAttack > fCurTime)
			return
		
		switch(iCharge)
		{
			case 0:
			{
				set_pdata_float(iEnt, 46, 0.3, 4)
				
				set_pev(iEnt, pev_fuser2, fCurTime + 0.3)
				set_pev(iEnt, pev_iuser1, 1)
			}
			case 1:
			{
				Set_WeaponAnim(id, ANIM_SHOOT2_CHARGE)
				set_pdata_float(iEnt, 46, 2.03, 4)
				
				set_pev(iEnt, pev_fuser2, fCurTime + 2.03)
				set_pev(iEnt, pev_iuser1, 2)
				set_pev(id, pev_weaponmodel2, P_GUNGNIR2)
				set_pdata_string(id, (492 * 4), "gungnir_b", -1, 20)
			}
			case 2:
			{
				Set_WeaponAnim(id, ANIM_CHARGE_LOOP)
				set_pdata_float(iEnt, 48, 2.03, 4)
				set_pev(iEnt, pev_fuser2, fCurTime + 2.03)
				set_pev(iEnt, pev_iuser1, 2)
			}
		}
	}
}

public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	

	g_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_GUNGNIR)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0 || iClip >= c_wpn_clip)
		return HAM_SUPERCEDE
			
	g_Clip[id] = iClip
	return HAM_IGNORED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_Base, id))
		return HAM_IGNORED	
	if(g_Clip[id] == -1)
		return HAM_IGNORED
		
	set_pdata_int(ent, 51, g_Clip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	
	Set_WeaponAnim(id, ANIM_RELOAD)
	Set_PlayerNextAttack(id, c_wpn_reloadtime)
	Set_WeaponIdleTime(id, CSW_GUNGNIR,c_wpn_reloadtime)
	Stock_SetPlayerAnim(id, "reload_m249")
	return HAM_IGNORED
}

/* ===============================
------------- ENTITIES --------
=================================*/
public fw_MF_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static Classname[32]
	pev(ent, pev_classname, Classname, sizeof(Classname))
	
	if(equal(Classname, "despe_mf"))
	{
		static Float:fFrame, Float:fFrameMax
		pev(ent, pev_frame, fFrame)
		
		fFrameMax = g_cache_frame_mf
		
		fFrame += 1.0
		set_pev(ent, pev_frame, fFrame)
		
		if(fFrame >= fFrameMax) 
		{
			set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
			return
		}
		set_pev(ent, pev_nextthink, get_gametime() + 0.01)
		return
	}
}

public HamF_InfoTarget_Think(iEnt)
{
	if(!pev_valid(iEnt))
		return
	
	static Classname[32]
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "gungnir_plasma"))
		return
		
	new iOwner, iState
	iOwner = pev(iEnt, pev_owner)
	iState = pev(iEnt, pev_iuser1)
	
	if(!iState)
	{
		static Float:fFrame
		pev(iEnt, pev_frame, fFrame)
		
		fFrame += 1.0
		if(fFrame >= 10.0) fFrame = 0.0
		
		set_pev(iEnt, pev_frame, fFrame)
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.01)
	}
	
	if(iState)
	{
		new Float:vecOri[3], Float:vEnd[3], Float:vecOrigin[3]
		pev(iEnt, pev_origin, vecOrigin);
		pev(iEnt, pev_vuser1, vecOri)
		pev(iEnt, (iState==2) ? pev_vuser2 : pev_origin, vEnd)
		
		if(iState == 2) set_pev(iEnt, pev_origin, vEnd)
		if(iState == 1 && pev(iEnt, pev_movetype) != MOVETYPE_NONE) 
		{
			new Float:NewVelo[3]
			pev(iEnt, pev_vuser3, NewVelo);
			set_pev(iEnt, pev_velocity, NewVelo);
			new pEntity =  -1
			while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOrigin, 50.0)) != 0)
			{
				if(!pev_valid(pEntity) || pEntity == iOwner)
					continue;
					
				if(cs_zb_is_zombie(pEntity) && is_user_alive(pEntity))
				{
					set_pev(pEntity, pev_velocity, NewVelo)
				}
			}
		}
		
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOri, 0)
		write_byte(TE_BEAMPOINTS)
		engfunc(EngFunc_WriteCoord, vEnd[0]) // end
		engfunc(EngFunc_WriteCoord, vEnd[1])
		engfunc(EngFunc_WriteCoord, vEnd[2])
		engfunc(EngFunc_WriteCoord, vecOri[0]) // start
		engfunc(EngFunc_WriteCoord, vecOri[1])
		engfunc(EngFunc_WriteCoord, vecOri[2])
		write_short(g_cache_beam[iState-1])
		write_byte(0)		// byte (starting frame) 
		write_byte(500)		// byte (frame rate in 0.1's) 
		write_byte(1)		// byte (life in 0.1's) 
		write_byte((iState==2)?150:50)		// byte (line width in 0.1's) 
		write_byte(0)		// byte (noise amplitude in 0.01's) 
		write_byte(200)		// byte,byte,byte (color) (R)
		write_byte(200)		// (G)
		write_byte(200)		// (B)
		write_byte(75)		// byte (brightness)
		write_byte((iState==2)?30:10)		// byte (scroll speed in 0.1's)
		message_end()
		
		static Float:vAngle[3]
		Stock_Get_Velocity_Angle(iEnt, vAngle)
		set_pev(iEnt, pev_angles, vAngle)
		
		static Float:fTimeRemove, Float:fDelay; 
		pev(iEnt, pev_ltime, fTimeRemove)
		pev(iEnt, pev_fuser4, fDelay)
		
		if(get_gametime() >= fDelay && pev(iEnt, pev_iuser4)) 
		{	
			static iBall
			iBall = Stock_CreateEntityBase(iOwner, "info_target", MOVETYPE_NONE, "models/w_usp.mdl", "gungnir_plasma", SOLID_NOT, 0.01)
			engfunc(EngFunc_SetSize, iBall, Float:{-50.0, -50.0, 0.0}, Float:{50.0, 50.0, 50.0})
			fm_set_rendering(iBall, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
			
			set_pev(iBall, pev_origin, vEnd)
			set_pev(iBall, pev_iuser1, 2)
			set_pev(iBall, pev_vuser1, vecOri)
			set_pev(iBall, pev_vuser2, vEnd)
			set_pev(iBall, pev_ltime, get_gametime() + 2.5)
			set_pev(iBall, pev_iuser3, 1)
		
			DoLineDamage(iOwner, vecOri, vEnd, float(c_dmg_beam))
			
			engfunc(EngFunc_EmitAmbientSound, 0, vecOri, SOUND_FIRE[6], 1.0, 0.4, 0, 100);
			
			set_pev(iEnt, pev_iuser4, 0)
		}
		
		set_pev(iEnt, pev_nextthink, get_gametime() + iState == 1 ? 0.0 : 0.01)
		
		if(get_gametime() >= fTimeRemove && pev(iEnt, pev_iuser3)) 
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}
	}
}

public HamF_InfoTarget_Touch(iEnt, iPtd)
{
	if(!pev_valid(iEnt))
		return HAM_IGNORED
	
	static Classname[32]
	pev(iEnt, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "gungnir_plasma"))
		return HAM_IGNORED
		
	new iOwner, Float:vecOri[3], Float:vStart[3], iState
	iOwner = pev(iEnt, pev_owner)
	iState = pev(iEnt, pev_iuser1)
	pev(iEnt, pev_origin, vecOri)
	pev(iEnt, pev_vuser1, vStart)
	
	if(iPtd == iOwner)
		return HAM_IGNORED
		
	if(iState == 1 && !(is_valid_ent(iPtd) && is_user_alive(iPtd) && cs_zb_is_zombie(iPtd)))
	{
		Do_SprDmg(iOwner, iState, vecOri)
				
		fm_set_rendering(iEnt, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
		set_pev(iEnt, pev_fuser4, get_gametime() + 1.0)
		set_pev(iEnt, pev_iuser4, 1)
		set_pev(iEnt, pev_movetype, MOVETYPE_NONE)
		set_pev(iEnt, pev_ltime, get_gametime() + 2.5)
		set_pev(iEnt, pev_iuser3, 1)
		set_pev(iEnt, pev_solid, SOLID_NOT);
		
		engfunc(EngFunc_EmitAmbientSound, 0, vStart, SOUND_FIRE[5], 1.0, 0.4, 0, 100);
		
		EntityTouchDamage(iEnt, iOwner, WDAMG_CHARGE)
		
		return HAM_IGNORED
	}
	
	if(!iState) 
	{
		Do_SprDmg(iOwner, iState, vecOri)
		engfunc(EngFunc_RemoveEntity, iEnt)
	}
	
	return HAM_IGNORED
}

public Do_SprDmg(iOwner, iState, Float:vecOri[3])
{
	static Float:fDmg, Float:fRng, Float:fKnc
	if(!iState)
	{
		fDmg = float(c_dmg_plasma)
		fRng = float(c_range_plasma)
		fKnc = 1.0
	} else if(iState == 1) {
		fDmg = float(c_dmg_charge)
		fRng = float(c_range_charge)
		fKnc = float(c_charge_kb)
	} else if(iState == 2) {
		fDmg = float(c_dmg_beam)
		fRng = float(c_range_beam)
		fKnc = 1.0
	}
	
	if(iState != 2)
	{
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOri, 0)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, vecOri[0])
		engfunc(EngFunc_WriteCoord, vecOri[1])
		engfunc(EngFunc_WriteCoord, vecOri[2])
		write_short(g_cache_exp[iState])
		write_byte(10)
		write_byte(30)
		write_byte(TE_EXPLFLAG_NODLIGHTS|TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES)
		message_end()
		
		if(!iState) engfunc(EngFunc_EmitAmbientSound, 0, vecOri, SOUND_FIRE[4], 1.0, 0.5, 0, 100);
	}
	
	new pEntity = -1
	while((pEntity = engfunc(EngFunc_FindEntityInSphere, pEntity, vecOri, fRng)) != 0)
	{
		if(pev(pEntity, pev_takedamage) == DAMAGE_NO) continue
		if(is_user_connected(pEntity) && pEntity != iOwner)
			if(!can_damage(pEntity, iOwner)) continue
		if(pEntity == iOwner) continue
		
		if(pev_valid(pEntity))
		{
			ExecuteHamB(Ham_TakeDamage, pEntity, iOwner, iOwner, fDmg, DMG_BULLET)
			
			Stock_Fake_KnockBack(iOwner, pEntity, fKnc)
			if(is_user_alive(pEntity)) SpawnBlood(vecOri, get_pdata_int(pEntity,89), floatround(fDmg/5.0))
		}
	}
}

stock EntityTouchDamage(pevInflictor, pevAttacker, Float:flDamage)
{
	new Float:vecOrigin[3], Float:vecVelocity[3], Float:vecDirection[3], Float:vecForward[3];
	pev(pevInflictor, pev_origin, vecOrigin);
	pev(pevInflictor, pev_velocity, vecVelocity);

	new Float:vecStart[3], Float:vecEnd[3];

	xs_vec_normalize(vecVelocity, vecDirection);
	xs_vec_mul_scalar(vecDirection, 100.0, vecForward);
	xs_vec_copy(vecOrigin, vecStart);
	xs_vec_add(vecOrigin, vecForward, vecEnd);

	new tr = create_tr2();

	engfunc(EngFunc_TraceLine, vecStart, vecEnd, 0, pevInflictor, tr);

	new pEntity = get_tr2(tr, TR_pHit);

	if (is_user_alive(pEntity))
	{
		rg_multidmg_clear()
		ExecuteHamB(Ham_TraceAttack, pEntity, pevAttacker, flDamage, vecForward, tr, DMG_BULLET);
		rg_multidmg_apply(pevInflictor, pevAttacker)
	}

	free_tr2(tr);
}

stock EntityTouchTraceTexture(pEntity)
{
	new Float:vecOrigin[3], Float:vecVelocity[3], Float:vecDirection[3], Float:vecForward[3];
	pev(pEntity, pev_origin, vecOrigin)
	pev(pEntity, pev_velocity, vecVelocity)

	new Float:vecStart[3], Float:vecEnd[3]
	xs_vec_normalize(vecVelocity, vecDirection)

	if(xs_vec_len(vecDirection) <= 0.0)
		return 1

	xs_vec_mul_scalar(vecDirection, 8196.0, vecForward)
	xs_vec_copy(vecOrigin, vecStart)
	xs_vec_add(vecOrigin, vecForward, vecEnd)

	new tr = create_tr2()
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, 0, pEntity, tr)

	new Float:flFraction
	get_tr2(tr, TR_flFraction, flFraction)

	new pHit = get_tr2(tr, TR_pHit)
	if(pev_valid(pHit) && is_user_alive(pHit)) 
		return 0
	return 1
}

stock Stock_is_aiming_wall(id, Float:fRange)
{
	new Float:vecStart[3], Float:vecTarget[3]
	new Float:vecViewOfs[3], trRes
	pev(id, pev_origin, vecStart) 
	pev(id, pev_view_ofs, vecViewOfs) 
	xs_vec_add(vecStart, vecViewOfs, vecStart) 
	
	new Float:angle[3], Float:Forw[3]
	pev(id, pev_v_angle, angle)
	engfunc(EngFunc_MakeVectors, angle)
	global_get(glb_v_forward, Forw)
	xs_vec_mul_scalar(Forw, fRange, Forw)
	
	xs_vec_add(vecStart, Forw, vecTarget)
	engfunc(EngFunc_TraceLine, vecStart, vecTarget, 0, id, trRes)
	
	new Float:flFraction
	get_tr2(trRes, TR_flFraction, flFraction)
	
	new pHit = get_tr2(trRes, TR_pHit)
	if(pev_valid(pHit))
	{
		if(!is_user_alive(pHit)) return 1
	} else if(flFraction < 1.0) return 1
	return 0
}

public MakeMuzzleFlash(id, iEnt)
{
	static iMuz
	iMuz = Stock_CreateEntityBase(id, "env_sprite", MOVETYPE_FOLLOW, MF_W, "despe_mf", SOLID_NOT,0.01)
	set_pev(iMuz, pev_body, 1)
	set_pev(iMuz, pev_rendermode, kRenderTransAdd)
	set_pev(iMuz, pev_renderamt, 255.0)
	set_pev(iMuz, pev_aiment, id)
	set_pev(iMuz, pev_scale, 0.04)
	set_pev(iMuz, pev_frame, 0.0)
	set_pev(iMuz, pev_animtime, get_gametime())
	dllfunc(DLLFunc_Spawn, iMuz)
}

stock Stock_CreateEntityBase(id, classtype[], mvtyp, mdl[], class[], solid, Float:fNext)
{
	new pEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, classtype))
	set_pev(pEntity, pev_movetype, mvtyp);
	set_pev(pEntity, pev_owner, id);
	engfunc(EngFunc_SetModel, pEntity, mdl);
	set_pev(pEntity, pev_classname, class);
	set_pev(pEntity, pev_solid, solid);
	set_pev(pEntity, pev_nextthink, get_gametime() + fNext)
	return pEntity
}

stock Stock_GetSpeedVector(const Float:origin1[3], const Float:origin2[3], Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
}

stock Stock_Get_Aiming(id, Float:end[3])
{
	new Float:start[3], Float:view_ofs[3]
	pev(id, pev_origin, start)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)

	pev(id, pev_v_angle, end)
	engfunc(EngFunc_MakeVectors, end)
	global_get(glb_v_forward, end)
	xs_vec_mul_scalar(end, 8192.0, end)
	xs_vec_add(start, end, end)
	new ptr = create_tr2();
	engfunc(EngFunc_TraceLine, start, end, DONT_IGNORE_MONSTERS, id, ptr)
	get_tr2(ptr, TR_vecEndPos, end)
	free_tr2(ptr)
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

stock Float:Stock_Blah(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()
	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return get_distance_f(end, EndPos)
} 
stock can_damage(id1, id2)
{
	if(id1 <= 0 || id1 >= 33 || id2 <= 0 || id2 >= 33)
		return 1
		
	// Check team
	return(get_pdata_int(id1, 114) != get_pdata_int(id2, 114))
}
stock Stock_Get_Velocity_Angle(entity, Float:output[3])
{
	static Float:velocity[3]
	pev(entity, pev_velocity, velocity)
	vector_to_angle(velocity, output)
	if( output[0] > 90.0 ) output[0] = -(360.0 - output[0])
}
////////////////////////////

/* ===============================
------------- SAFETY -------------
=================================*/
public Register_SafetyFunc()
{
	register_event("CurWeapon", "Safety_CurWeapon", "be", "1=1")
	
	RegisterHam(Ham_Spawn, "player", "fw_Safety_Spawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_Safety_Killed_Post", 1)
}

public Register_SafetyFuncBot(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Safety_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_Safety_Killed_Post", 1)
	RegisterHamFromEntity(Ham_Touch, id, "fw_VicTouch")
}

public Safety_Connected(id)
{
	Set_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_Disconnected(id)
{
	UnSet_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_CurWeapon(id)
{
	if(!is_alive(id))
		return
		
	static CSW; CSW = read_data(2)
	if(g_PlayerWeapon[id] != CSW) g_PlayerWeapon[id] = CSW
}

public fw_Safety_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_IsAlive, id)
}

public fw_Safety_Killed_Post(id)
{
	UnSet_BitVar(g_IsAlive, id)
}

public is_connected(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0

	return 1
}

public is_alive(id)
{
	if(!is_connected(id))
		return 0
	if(!Get_BitVar(g_IsAlive, id))
		return 0
		
	return 1
}

public get_player_weapon(id)
{
	if(!is_alive(id))
		return 0
	
	return g_PlayerWeapon[id]
}

/* ===============================
--------- END OF SAFETY  ---------
=================================*/
stock DoLineDamage(pevAttacker, Float:vStart[3], Float:vEnd[3], Float:flDamage)
{
	if(!is_user_connected(pevAttacker) || cs_zb_is_zombie(pevAttacker))
		return;
		
	new pEnt, Float:pOrigin[3], iVis, Float:vDir[3]; xs_vec_sub(vEnd, vStart, vDir);
	new Float:vExtend[3];
	
	xs_vec_normalize(vDir, vDir);
	xs_vec_mul_scalar(vDir, 350.0, vDir);
	xs_vec_add(vEnd, vDir, vExtend);
	
	pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vStart, 8192.0)) != 0)
	{
		if(!pev_valid(pEnt) || pEnt == pevAttacker)
			continue;
		
		pev(pEnt, pev_origin, pOrigin);
		if(GetDistFromLine(vStart, vExtend, pOrigin, iVis) <= 60.0)
		{
			ExecuteHamB(Ham_TakeDamage, pEnt, pevAttacker, pevAttacker, flDamage, DMG_BULLET)
			if(is_user_alive(pEnt) && cs_zb_is_zombie(pEnt)) SpawnBlood(pOrigin, get_pdata_int(pEnt,89), floatround(flDamage/5.0))
		}
	}
}
stock Float:GetDistFromLine(Float:start[3],Float:end[3],Float:origin[3],&visible)
{
	new Float:deltas[3]
	deltas[0] = (start[1] - end[1]) / (start[0] - end[0])
	deltas[1] = (start[2] - end[2]) / (start[1] - end[1])
	deltas[2] = (start[1] - end[1]) / (start[2] - end[2])

	static Float:origin2[3]
	origin2[2] = origin[2]
	origin2[1] = (deltas[2] * (origin2[2] - start[2])) + start[1]
	origin2[0] = ((deltas[0] * start[0]) + origin2[1] - start[1]) / deltas[0]

	static Float:hit[3]
	engfunc(EngFunc_TraceLine,origin,origin2,1,0,0)
	get_tr2(0,TR_vecEndPos,hit)
	if(hit[0]==origin2[0] && hit[1]==origin2[1] && hit[2]==origin2[2])
		visible = 1
	else
		visible = 0
		

	return get_distance_f(origin,origin2)
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
stock SpawnBlood(const Float:vecOrigin[3], iColor, iAmount)
{
	if(!iAmount)
		return
	
	iAmount *= 2
	if(iAmount > 255) iAmount = 255
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecOrigin)
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(g_SpraySpr)
	write_short(g_DropSpr)
	write_byte(iColor)
	write_byte(min(max(3, iAmount / 10), 16))
	message_end()
}
stock Set_WeaponAnim(id, anim, iCheck=0)
{
	if(iCheck && pev(id, pev_weaponanim) == anim)
		return;

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
	set_pdata_float(entwpn, 48, TimeIdle, 4)
}

stock Set_PlayerNextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}

stock Stock_Get_Postion(id,Float:forw, Float:right, Float:up, Float:vStart[])
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

stock Stock_Drop_Slot(id, iSlot) 
{
	new weapons[32], num = 0
	get_user_weapons(id, weapons, num)
	
	for(new i = 0; i < num; i++)
	{
		new slot = Stock_Get_Wpn_Slot(weapons[i])

		if(iSlot == slot)
		{
			static wname[32]
			get_weaponname(weapons[i], wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock Stock_Get_Wpn_Slot(iWpn)
{
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

	if(PRIMARY_WEAPONS_BIT_SUM & (1<<iWpn)) return 1
	else if(SECONDARY_WEAPONS_BIT_SUM & (1<<iWpn)) return 2
	else if(iWpn == CSW_KNIFE) return 3
	else if(iWpn == CSW_HEGRENADE) return 4
	else if(iWpn == CSW_C4) return 5
	return 6 //FLASHBANG SMOKEBANG
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
