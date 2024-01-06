#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <csm>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombiemodlimited>
#include <explosion>

#define V_MODEL	"models/zbz/wpn/v_chaingren.mdl"
#define W_MODEL	"models/zbz/wpn/w_nadegroup1.mdl"

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))
new g_HadWpn


public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
}
public plugin_init()
{
	RegisterHam(Ham_Item_Deploy, "weapon_hegrenade", "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Think, "grenade", "fw_Grenade_Think")
	
	cs_register_custom_item("Chain Grenade", 350, 7, "GiveHolyShit", "chaingren")
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
	set_pev(Ent, pev_impulse, 1776)
	set_pev(Ent, pev_body, 3);
	set_pev(Ent, pev_iuser2, 3);
	set_pev(Ent, pev_dmgtime, get_gametime() + 1.4);
	return 1;
}
public fw_Grenade_Think(Ent)
{
	if(!pev_valid(Ent) || pev(Ent, pev_impulse) != 1776) 
		return HAM_IGNORED;
		
		
	if(get_gametime() < pev(Ent, pev_dmgtime))
		return HAM_IGNORED;
	
	set_pev(Ent, pev_iuser2, pev(Ent, pev_iuser2) - 1)
	GrenadeExplode(Ent)
	set_pev(Ent, pev_dmgtime, get_gametime() + 1.0);
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1);
	
	if(pev(Ent, pev_iuser2) <= 0)
		engfunc(EngFunc_RemoveEntity, Ent)
		
	return HAM_SUPERCEDE;
}
public GrenadeExplode(Ent)
{
	static Float:vecVelocity[3], Float:vecOrigin[3]; pev(Ent, pev_origin, vecOrigin);
	static pevAttacker; pevAttacker = pev(Ent, pev_owner);
	
	pev(Ent, pev_velocity, vecVelocity)
	CSGrenadeExplosion(vecOrigin, 1, 1, vecVelocity)
	
	static Float:vOrigin[3], Float:flDist, Float:flDamage, pEnt; pEnt= -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vecOrigin, 350.0)) != 0 )
	{
		if(!pev_valid(pEnt))
			continue;
			
		pev(pEnt, pev_origin, vOrigin);
		flDist = vector_distance(vOrigin, vecOrigin);
		flDamage = 70.0 - floatmul(70.0, floatdiv(flDist, 350.0));
		
		if(isBreakable(pEnt) && flDamage <= 0.0) flDamage = floatdiv(70.0, 2.0)
		
		if(flDamage > 0.0 && pev(pEnt, pev_health) > 0.0 && pev(pEnt, pev_takedamage) > 0.0)
			ExecuteHamB(Ham_TakeDamage, pEnt, Ent, pevAttacker, flDamage, isBreakable(pEnt) ? DMG_BLAST : (1<<24));
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
