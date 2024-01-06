#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <csm>
#include <fakemeta_util>
#include <hamsandwich>

#define V_MODEL "models/zbz/wpn/v_starchasersr.mdl"
#define P_MODEL "models/zbz/wpn/p_starchasersr.mdl"
#define W_MODEL "models/zbz/wpn/w_primgroup1.mdl"

#define CSW_STARCHASERSR CSW_G3SG1
#define weapon_starchasersr "weapon_g3sg1"

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn

new const WeaponSounds[][] = {
	"weapons/starchasersr-1.wav",
	"weapons/starchasersr_exp.wav"
}
public plugin_precache()
{
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	
	precache_model("sprites/ef_starchasersr_line.spr")
	precache_model("sprites/ef_starchasersr_explosion.spr")
	precache_model("sprites/ef_starchasersr_star.spr")
	
	for(new x = 0; x<sizeof(WeaponSounds); x++)
		precache_sound(WeaponSounds[x])
}
public plugin_init()
{
	register_plugin("[Zombie Z] Star Chaser SR", "1.0", "csbtedhan");
	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post", 1)
	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_starchasersr, "fw_PrimaryAttack");
	RegisterHam(Ham_Item_Deploy, weapon_starchasersr, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, weapon_starchasersr, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Item_PostFrame, weapon_starchasersr, "fw_Item_PostFrame");	
	RegisterHam(Ham_Weapon_Reload, weapon_starchasersr, "fw_Weapon_Reload");
	RegisterHam(Ham_Weapon_Reload, weapon_starchasersr, "fw_Weapon_Reload_Post", 1);	
	
	register_message(get_user_msgid("DeathMsg"), "message_DeathMsg")
	
	cs_register_custom_item("Star Chaser SR", 6500, 5, "GiveBUFFSG552", "starchasersr")
}

	
public GiveBUFFSG552(id)
{
	if(!is_user_alive(id)) return;
	
	drop_weapons(id, 1)
	
	Set_BitVar(g_HadWpn,id)
	fm_give_item(id, "weapon_g3sg1")
	
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_STARCHASERSR)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, 20)
}
public fw_Remove_Item(id, itemid, slot)
{
	if(slot == 0)
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
	
	if(Get_BitVar(g_HadWpn, killer) && equal(weapon, "g3sg1"))
		set_msg_arg_string(4, "starchasersr")
		
	return PLUGIN_CONTINUE
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
	
	if(equal(model, "models/w_g3sg1.mdl"))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_starchasersr, entity)
		if(Get_BitVar(g_HadWpn, iOwner) && pev_valid(weapon))
		{
			set_pev(weapon, pev_impulse, 2026) 
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			UnSet_BitVar(g_HadWpn,iOwner)
			set_pev(entity, pev_body, 18);
			
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
	if(!Get_BitVar(g_HadWpn, Id) || get_pdata_int(Ent, 51, 4) <= 0)
		return HAM_IGNORED
			
	
	static Float:Push[3]
	pev(Id, pev_punchangle, Push)
	Push[0] -= 5.0;
	set_pev(Id, pev_punchangle, Push)
		
	set_pdata_float(Ent, 46, 0.75, 4);
	set_pdata_float(Ent, 47, 0.75, 4);
	set_pdata_float(Ent, 48, 1.75, 4);
	
	Set_WeaponAnim(Id, random_num(1,2))
	ShootStar(Id)
	set_pdata_int(Ent, 51, get_pdata_int(Ent, 51, 4) -1, 4);
	engfunc(EngFunc_EmitSound, Id, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.8, 0, 100);
	
	return HAM_SUPERCEDE
}
public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2026)
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
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_STARCHASERSR)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(20 - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)	
		cs_set_user_bpammo(id, CSW_STARCHASERSR, bpammo - temp1)
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
	
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_STARCHASERSR)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0)
		return HAM_SUPERCEDE
	if(iClip >= 20)
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
		set_pdata_float(id, 83, 2.6, 5)
		set_pdata_float(ent, 46, 3.0, 4)
		set_pdata_float(ent, 47, 3.0, 4)
		set_pdata_float(ent, 48, 3.5, 4)
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
	if(!Get_BitVar(g_HadWpn, Id))
		return
	set_pev(Id, pev_viewmodel2, V_MODEL)
	set_pev(Id, pev_weaponmodel2, P_MODEL)
	
	Set_WeaponAnim(Id, 4)
}
public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_STARCHASERSR && Get_BitVar(g_HadWpn, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}


public ShootStar(id)
{
	static Float:vOrigin[3], Float:vTarget[3], Float:vAngle[3], Float:vFor[3];
	Stock_Get_Postion(id, 0.0, 3.0, -1.0, vOrigin);
	pev(id, pev_v_angle, vAngle);
	engfunc(EngFunc_MakeVectors, vAngle);
	global_get(glb_v_forward, vFor);
	xs_vec_mul_scalar(vFor, 8192.0, vFor);
	xs_vec_add(vOrigin, vFor, vTarget);
	
	engfunc(EngFunc_TraceLine, vOrigin, vTarget, 0, id, 0);
	get_tr2(0, TR_vecEndPos, vTarget);
	
	static Float:flAlpha, Float:flDist, Float:flCurrentDist, Float:flPDist; flDist = vector_distance(vOrigin, vTarget);
	static Float:pOrigin[3]; pOrigin = vOrigin
	
	flCurrentDist = flPDist = 0.0
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vTarget[0])
	engfunc(EngFunc_WriteCoord, vTarget[1])
	engfunc(EngFunc_WriteCoord, vTarget[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/ef_starchasersr_explosion.spr"))
	write_byte(10)
	write_byte(20)
	write_byte(14)
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPRITETRAIL)
	engfunc(EngFunc_WriteCoord, vTarget[0])
	engfunc(EngFunc_WriteCoord, vTarget[1])
	engfunc(EngFunc_WriteCoord, vTarget[2])
	engfunc(EngFunc_WriteCoord, vTarget[0])
	engfunc(EngFunc_WriteCoord, vTarget[1])
	engfunc(EngFunc_WriteCoord, vTarget[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/ef_starchasersr_star.spr"))
	write_byte(5)
	write_byte(1)
	write_byte(1)
	write_byte(200)
	write_byte(100)
	message_end()
	
		
	engfunc(EngFunc_EmitAmbientSound, 0, vTarget, WeaponSounds[1], 1.0, 0.6, 0, 100);
	Damaging(id, vTarget, 180.0, 500.0)
	
	while(flCurrentDist < flDist)
	{
		engfunc(EngFunc_MakeVectors, vAngle);
		global_get(glb_v_forward, vFor);
		xs_vec_mul_scalar(vFor, flPDist, vFor);
		xs_vec_add(vOrigin, vFor, pOrigin);
		
		flPDist += 70.0
		flCurrentDist = vector_distance(vOrigin, pOrigin);
		
		flAlpha = floatdiv(flCurrentDist * 255.0, flDist) 
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_SPRITE)
		engfunc(EngFunc_WriteCoord, pOrigin[0])
		engfunc(EngFunc_WriteCoord, pOrigin[1])
		engfunc(EngFunc_WriteCoord, pOrigin[2])
		write_short(engfunc(EngFunc_ModelIndex, "sprites/ef_starchasersr_line.spr"))
		write_byte(1)
		write_byte(clamp(floatround(flAlpha), 100, 255))
		message_end()
	}
}
public Damaging(pevAttacker, Float:vOrigin[3], Float:flRadius, Float:flDamage)
{
	static Float:pOrigin[3], pEnt; pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, flRadius)) != 0)
	{
		if(!pev_valid(pEnt)) continue;
		
		pev(pEnt, pev_origin, pOrigin)
		if(!isClearLine(pOrigin, vOrigin)) flDamage *= 0.6;
		
		if(pev(pEnt, pev_health) > 0.0 && pev(pEnt, pev_takedamage) > 0.0)
			ExecuteHamB(Ham_TakeDamage, pEnt, pevAttacker, pevAttacker, flDamage, isBreakable(pEnt) ? DMG_BLAST : DMG_CLUB);
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
stock isBreakable(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	static szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (pev(iEnt, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY) return 0;
	if (equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable")) return 1;
	return 0;
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
