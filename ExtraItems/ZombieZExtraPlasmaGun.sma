#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <csm>
#include <fakemeta_util>
#include <hamsandwich>

#define V_MODEL "models/zbz/wpn/v_plasmagun6.mdl"
#define P_MODEL "models/zbz/wpn/p_plasmagun6.mdl"
#define W_MODEL "models/zbz/wpn/w_primgroup1.mdl"


#define CSW_PLASMAGUN 	CSW_AUG
#define weapon_plasmagun 	"weapon_aug"

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn, g_Attack, g_Muzzleflash_Ent, g_Muzzleflash
new g_sModelindexExplo
new const szPlasmaBullet[] = "sprites/plasmaball6.spr"

#define PLASMA_BALL		"plasmaball"

new const WeaponSounds[][] =
{
	"weapons/plasmagun-1.wav",
	"weapons/plasmagun_exp.wav"
}


public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	
	g_sModelindexExplo = engfunc(EngFunc_PrecacheModel, "sprites/plasmabomb6.spr")
	engfunc(EngFunc_PrecacheModel, szPlasmaBullet)
	
	g_Muzzleflash_Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	set_pev(g_Muzzleflash_Ent, pev_scale, 0.1)
	engfunc(EngFunc_SetModel, g_Muzzleflash_Ent, szPlasmaBullet);
	
	set_pev(g_Muzzleflash_Ent, pev_rendermode, kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent, pev_renderamt, 0.0)
	
	for(new i=0;i<2;i++)
		precache_sound(WeaponSounds[i])
}
public plugin_init()
{
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData,"fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	register_forward(FM_CheckVisibility, "fw_CheckVisibility")
	register_forward(FM_Touch, "fw_Touch")
	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_plasmagun, "fw_PrimaryAttack");
	RegisterHam(Ham_Item_Deploy, weapon_plasmagun, "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Item_AddToPlayer, weapon_plasmagun, "fw_Item_AddToPlayer_Post", 1);
	RegisterHam(Ham_Item_PostFrame, weapon_plasmagun, "fw_Item_PostFrame");	
	RegisterHam(Ham_Weapon_Reload, weapon_plasmagun, "fw_Weapon_Reload");
	RegisterHam(Ham_Weapon_Reload, weapon_plasmagun, "fw_Weapon_Reload_Post", 1);	
	
	cs_register_custom_item("Plasma Gun (+6)", 6250, 4, "GivePlasma", "plasmagun")
}
public fw_Remove_Item(id, itemid, slot)
{
	if(slot == 0) UnSet_BitVar(g_HadWpn,id)
}
public GivePlasma(id)
{
	if(!is_user_alive(id)) return;
	
	drop_weapons(id, 1)
	
	Set_BitVar(g_HadWpn,id)
	UnSet_BitVar(g_Attack,id)
	fm_give_item(id, "weapon_aug")
	
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_AUG)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, 65)
}
public fw_AddToFullPack_Post(esState, iE, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	if(iEnt == g_Muzzleflash_Ent)
	{
		if(Get_BitVar(g_Muzzleflash, iHost))
		{
			set_es(esState, ES_Frame, float(random_num(0, 1)))
				
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, 255.0)
			
			UnSet_BitVar(g_Muzzleflash, iHost)
		}
			
		set_es(esState, ES_Skin, iHost)
		set_es(esState, ES_Body, 1)
		set_es(esState, ES_AimEnt, iHost)
		set_es(esState, ES_MoveType, MOVETYPE_FOLLOW)
	}
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
	
	if(equal(model, "models/w_aug.mdl"))
	{
		static weapon; weapon = find_ent_by_owner(-1, weapon_plasmagun, entity)
		if(Get_BitVar(g_HadWpn, iOwner) && pev_valid(weapon))
		{
			set_pev(weapon, pev_impulse, 2005) 
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			set_pev(entity, pev_body, 8)
			UnSet_BitVar(g_HadWpn,iOwner)
			UnSet_BitVar(g_Attack,iOwner)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_Touch(iEnt, id)
{
	if(!pev_valid(iEnt)) return;
	
	new classname[32]
	pev(iEnt, pev_classname, classname, 31)
	if(equal(classname, PLASMA_BALL))
	{
		PlasmaBomb(iEnt)
		engfunc(EngFunc_RemoveEntity, iEnt)
	}
}
public fw_CheckVisibility(iEntity, pSet)
{
	if(iEntity == g_Muzzleflash_Ent)
	{
		forward_return(FMV_CELL, 1)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
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
		return HAM_SUPERCEDE;
	
	if(get_pdata_float(Ent, 46, 4) > 0.0)
		return HAM_SUPERCEDE;
		
	new Float:recoil[3]; recoil[0] = random_float(-2.0, 1.0)
	set_pev(Id, pev_punchangle, recoil);
	
	set_pdata_float(Ent, 46, 0.15, 5)
	
	Set_BitVar(g_Muzzleflash, Id)
	
	set_pdata_int(Ent, 51, get_pdata_int(Ent, 51)-1, 4)
	CreatePlasma(Id)
	Set_WeaponAnim(Id, random_num(3,4));
	engfunc(EngFunc_EmitSound, Id, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.6, 0, 100);
	
	return HAM_SUPERCEDE;
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2005)
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
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_AUG)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(65 - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_AUG, bpammo - temp1)		
		
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
		
	set_pev(ent, pev_iuser4, -1)
	
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_AUG)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0)
		return HAM_SUPERCEDE
	if(iClip >= 65)
		return HAM_SUPERCEDE			
	
	set_pev(ent, pev_iuser4, iClip)
	
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
		if(pev(ent, pev_iuser4) == -1)
			return HAM_IGNORED
		
		set_pdata_int(ent, 51, pev(ent, pev_iuser4), 4)
		
		set_pdata_float(id, 83, 3.0, 5)
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
		
	UnSet_BitVar(g_Attack,Id)
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
	
	set_pdata_string(Id, (492) * 4, "carbine", -1 , 20)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_AUG && Get_BitVar(g_HadWpn, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public CreatePlasma(id)
{
	new iEnt = create_entity("info_target")
	
	static Float:Origin[3], Float:Velocity[3]
	
	get_position(id, 0.0, 0.0, -1.0, Origin)
	
	set_pev(iEnt, pev_classname, PLASMA_BALL)
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	engfunc(EngFunc_SetModel, iEnt, szPlasmaBullet)
	
	entity_set_size(iEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
	set_pev(iEnt, pev_origin, Origin)
	set_pev(iEnt, pev_gravity, 0.6)
	
	set_pev(iEnt, pev_solid, SOLID_BBOX)
	set_pev(iEnt, pev_owner, id)
	set_pev(iEnt, pev_iuser1, 5002)
	
	velocity_by_aim(id, 1850, Velocity)
	set_pev(iEnt, pev_velocity, Velocity)	
	
	static Float:Angle[3]; Angle[2] = random_float(-90.0, 90.0);
	set_pev(iEnt, pev_angles, Angle);
	set_pev(iEnt, pev_scale, 0.2);
	set_pev(iEnt, pev_rendermode, kRenderTransAdd)
	set_pev(iEnt, pev_renderamt, 255.0)
}
public PlasmaBomb(Ent)
{
	static Float:vecOrigin[3];
	pev(Ent, pev_origin, vecOrigin);
	
	Stock_CreateExplosion(vecOrigin, g_sModelindexExplo, 4, 8, 14);
	engfunc(EngFunc_EmitAmbientSound, Ent, vecOrigin, WeaponSounds[1], 1.0, 0.6, 0, 100);
	
	static pevAttacker; pevAttacker = pev(Ent, pev_owner)
	Stock_RadiusDamage(pevAttacker, Ent, vecOrigin, 180.0, 120.0);
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

stock Stock_CreateExplosion(Float:vecOrigin[3], iSprites, iScale, iFrame, iFlags)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(iSprites)
	write_byte(iScale)
	write_byte(iFrame)
	write_byte(iFlags)
	message_end()
	
}
stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
	
	return 1;
}
stock Stock_RadiusDamage(pevAttacker, pevInflictor, Float:vecOrigin[3], Float:flMaxDamage, Float:flRadius)
{
	if(!is_valid_ent(pevAttacker)) pevAttacker = pevInflictor;
	
	new Float:fDamage, Float:fDistance, Float:vOrigin[3]
	new szClassname[64]
	
	new iVictim = -1
	while((iVictim = find_ent_in_sphere(iVictim, vecOrigin, flRadius)) != 0)
	{
		if(!is_valid_ent(iVictim)) continue;
		
		entity_get_vector(iVictim, EV_VEC_origin, vOrigin);
		fDistance = get_distance_f(vecOrigin, vOrigin);
		fDamage = flMaxDamage - floatmul(flMaxDamage, floatdiv(fDistance, flRadius));
		
		pev(iVictim, pev_classname, szClassname, 63);
		if(equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable"))
		{
			if(fDamage <= 0.0) fDamage = floatdiv(flMaxDamage, 2.0);
			// Break This
			if(entity_get_float(iVictim, EV_FL_health) > 0.0 && !(pev(iVictim, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY))
				ExecuteHamB(Ham_TakeDamage, iVictim, pevInflictor, pevAttacker, fDamage, DMG_BLAST);
		}
		
		if(get_entity_flags(iVictim) & FL_MONSTER) fDamage *= 4.5;
		Stock_TakeDamage(pevAttacker, pevInflictor, iVictim, fDamage, DMG_CLUB)
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
