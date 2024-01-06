#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <csm>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombiemodlimited>
#include <explosion>

#define V_MODEL	"models/zbz/wpn/v_holybomb.mdl"
#define W_MODEL	"models/zbz/wpn/w_nadegroup1.mdl"

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	engfunc(EngFunc_PrecacheModel, "sprites/holybomb_burn.spr")
	engfunc(EngFunc_PrecacheModel, "sprites/holybomb_exp.spr")
	
	engfunc(EngFunc_PrecacheSound, "weapons/holybomb_exp.wav")
}
public plugin_init()
{
	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Think, "grenade", "fw_Grenade_Think")
	RegisterHam(Ham_Touch, "grenade", "fw_Grenade_Touch")
	RegisterHam(Ham_Think, "info_target", "BurnThink")
	
	cs_register_custom_item("Holy Bomb", 300, 7, "GiveHolyShit", "holybomb")
}
public GiveHolyShit(id)
{
	cs_remove_item(id, -1, 3)
	Set_BitVar(g_HadWpn, id)
	if(!user_has_weapon(id, CSW_HEGRENADE))
		fm_give_item(id, "weapon_hegrenade")
}

public fw_Remove_Item(id, itemid, slot)
{
	if(slot == 3) UnSet_BitVar(g_HadWpn, id)
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
		set_pev(Id, pev_weaponmodel2, "")
	}
}
public fw_CSZB_HumanNade_Pre(Ent, Id)
{
	if(!Get_BitVar(g_HadWpn, Id))
		return 0;
		
	engfunc(EngFunc_SetModel, Ent, W_MODEL)
	set_pev(Ent, pev_impulse, 1775)
	set_pev(Ent, pev_body, 4);
	set_pev(Ent, pev_dmgtime, get_gametime() + 2.0);
	return 1;
}
public fw_Grenade_Think(Ent)
{
	if(!pev_valid(Ent) || pev(Ent, pev_impulse) != 1775) 
		return HAM_IGNORED;
		
		
	if(get_gametime() < pev(Ent, pev_dmgtime))
		return HAM_IGNORED;
		
	GrenadeExplode(Ent)
	engfunc(EngFunc_RemoveEntity, Ent)
	return HAM_SUPERCEDE;
}
public fw_Grenade_Touch(Ent, Id)
{
	if(!pev_valid(Ent) || pev(Ent, pev_impulse) != 1775) 
		return HAM_IGNORED;
		
	set_pev(Ent, pev_dmgtime, 0.0);
	return HAM_IGNORED;
}
public GrenadeExplode(Ent)
{
	static Float:vecVelocity[3], Float:vecOrigin[3]; pev(Ent, pev_origin, vecOrigin);
	static pevAttacker; pevAttacker = pev(Ent, pev_owner);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte( TE_EXPLOSION );
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/holybomb_exp.spr"))
	write_byte(30);
	write_byte(30);
	write_byte(14);
	message_end();
	
	pev(Ent, pev_velocity, vecVelocity)
	CSGrenadeExplosion(vecOrigin, 0, 1, vecVelocity)

	engfunc(EngFunc_EmitAmbientSound, 0, vecOrigin, "weapons/holybomb_exp.wav", 1.0, 0.6, 0, 100);
	
	static Float:vOrigin[3], Float:flDist, Float:flDamage, pEnt; pEnt= -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vecOrigin, 350.0)) != 0 )
	{
		if(!pev_valid(pEnt) || pEnt == pevAttacker)
			continue;
			
		pev(pEnt, pev_origin, vOrigin);
		flDist = vector_distance(vOrigin, vecOrigin);
		flDamage = 100.0 - floatmul(100.0, floatdiv(flDist, 350.0));
		
		if(isBreakable(pEnt) && flDamage <= 0.0) flDamage = floatdiv(100.0, 2.0)
		
		if(flDamage > 0.0 && pev(pEnt, pev_health) > 0.0 && pev(pEnt, pev_takedamage) > 0.0)
			ExecuteHamB(Ham_TakeDamage, pEnt, Ent, pevAttacker, flDamage, isBreakable(pEnt) ? DMG_BLAST : (1<<24));
			
		if(is_user_alive(pEnt) && cs_zb_is_zombie(pEnt))
			MakeBurn(pevAttacker, pEnt)
	}
}

public MakeBurn(pevAttacker, pevVictim)
{
	static Float:vOrigin[3], pEnt;
	pev(pevVictim, pev_origin, vOrigin);
	
	pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(pEnt, pev_origin, vOrigin);
	set_pev(pEnt, pev_owner, pevAttacker);
	set_pev(pEnt, pev_aiment, pevVictim);
	set_pev(pEnt, pev_enemy, pevVictim);
	set_pev(pEnt, pev_movetype, MOVETYPE_FOLLOW)
	engfunc(EngFunc_SetModel, pEnt, "sprites/holybomb_burn.spr")
	set_pev(pEnt, pev_renderamt, 255.0);
	set_pev(pEnt, pev_rendermode, kRenderTransAdd);
	set_pev(pEnt, pev_scale, 1.0);
	set_pev(pEnt, pev_frame, 0.0);
	set_pev(pEnt, pev_classname, "holyburn_holybomb")
	
	set_pev(pEnt, pev_nextthink, get_gametime())
	set_pev(pEnt, pev_dmgtime, get_gametime() + 3.0);
}
public BurnThink(Ent)
{
	if(!isBurn(Ent))
		return;
		
	new pevOwner = pev(Ent, pev_owner)
	new pevVictim = pev(Ent, pev_enemy)
	
	if(cs_zb_is_zombie(pevOwner) || !is_user_alive(pevOwner) || !is_user_connected(pevOwner) ||
		!is_user_alive(pevVictim) || !cs_zb_is_zombie(pevVictim))
	{
		engfunc(EngFunc_RemoveEntity, Ent)
		return;
	}
	
	new Float:flDmgTime, Float:flFrame; pev(Ent, pev_frame, flFrame)
	if(flFrame >= engfunc(EngFunc_ModelFrames, "sprites/holybomb_burn.spr")) flFrame = 0.0
	set_pev(Ent, pev_frame, flFrame + 0.5)
	
	pev(Ent, pev_fuser1, flDmgTime)
	if(get_gametime() >= flDmgTime)
	{
		ExecuteHamB(Ham_TakeDamage, pevVictim, Ent, pevOwner, 10.0, DMG_BURN);
		set_pev(Ent, pev_fuser1, get_gametime() + 1.0)
	}
	pev(Ent, pev_dmgtime, flDmgTime)
	if(get_gametime() >= flDmgTime)
	{
		engfunc(EngFunc_RemoveEntity, Ent)
		return;
	}
	set_pev(Ent, pev_nextthink, get_gametime())
}
stock isBurn(Ent)
{
	if(!pev_valid(Ent)) return 0;
	
	static szClassName[32]; pev(Ent, pev_classname,szClassName, 31);
	return (equal(szClassName, "holyburn_holybomb"))
}
stock isBreakable(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))

	if (equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable")) return 1;
	return 0;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
