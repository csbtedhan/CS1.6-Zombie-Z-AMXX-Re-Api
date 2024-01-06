#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <cstrike>
#include <csm>
#include <zombiemodlimited>
#include <fakemeta_util>
#include <hamsandwich>

new const szVModels[][] = 
{
	"models/v_knife.mdl",
	"models/zbz/melee/v_bayonet.mdl",
	"models/zbz/melee/v_gut.mdl",
	"models/zbz/melee/v_huntsman.mdl",
	"models/zbz/melee/v_butterfly.mdl",
	"models/zbz/melee/v_m9.mdl",
	"models/zbz/melee/v_karambit.mdl",
	"models/zbz/melee/v_flip.mdl",
	"models/zbz/melee/v_classic.mdl",
	"models/zbz/melee/v_widow.mdl"
}

new const CAN_DAMAGE_ENTITY[][]={ "info_target", "func_breakable" , "func_pushable" , "hostage_entity" }

new Float:flKnifeDmg[] = { 526.0 , 529.0 , 527.0 , 530.0 , 531.0, 532.0, 537.0 , 527.0 , 530.5 , 532.0 }
new g_HadKnife[33], g_Stab[33], g_Attack[33], g_HamBot


public plugin_precache()
{
	for(new i=0;i<10;i++)
	{
		if(i!= 0)engfunc(EngFunc_PrecacheModel, szVModels[i])
	}
}

public plugin_init()
{
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "fw_Item_Deploy_Post", 1);
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_Attack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_Attack_Post", 1);
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Stab");
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_Stab_Post", 1);
	
	RegisterHam(Ham_TraceAttack, "player", "HamF_TakeDamage")
	for(new i=0; i<sizeof(CAN_DAMAGE_ENTITY); i++)
		RegisterHam(Ham_TraceAttack, CAN_DAMAGE_ENTITY[i], "HamF_TakeDamage")
	
	register_concmd("seal", "GiveMelee", -1)
	
	cs_register_custom_item("Bayonet", 0, 8, "GiveBayonet", "bayonet")
	cs_register_custom_item("Gutter", 0, 8, "GiveGutter", "gut")
	cs_register_custom_item("Hunts Man", 0, 8, "GiveHuntsman", "huntsman")
	cs_register_custom_item("Butterfly", 0, 8, "GiveButterfly", "butterfly")
	cs_register_custom_item("M9 Bayonet", 0, 8, "GiveM9", "m9")
	cs_register_custom_item("Karambit", 0, 8, "GiveKarambit", "karambit")
	cs_register_custom_item("Flipped", 0, 8, "GiveFlip", "flip")
	cs_register_custom_item("Classic", 0, 8, "GiveClassic", "classic")
	cs_register_custom_item("Talon", 0, 8, "GiveTalon", "widow")
	
	register_clcmd("inspect", "InspectKnife")
}

public GiveBayonet(id)
	GiveKnife(id, 1)
public GiveGutter(id)
	GiveKnife(id, 2)
public GiveHuntsman(id)
	GiveKnife(id, 3)
public GiveButterfly(id)
	GiveKnife(id, 4)
public GiveM9(id)
	GiveKnife(id, 5)
public GiveKarambit(id)
	GiveKnife(id, 6)
public GiveFlip(id)
	GiveKnife(id, 7)
public GiveClassic(id)
	GiveKnife(id, 8)
public GiveTalon(id)
	GiveKnife(id, 9)
public GiveMelee(id)
	GiveKnife(id, 0)

public GiveKnife(id, type)
{
	if(!is_user_alive(id)) return

	cs_remove_item(id, -1, 2)
	if(!user_has_weapon(id, CSW_KNIFE)) fm_give_item(id, "weapon_knife")
	
	g_Attack[id] =0
	g_HadKnife[id] = type
	if(get_user_weapon(id) == CSW_KNIFE)
	{
		set_pev(id, pev_viewmodel2, szVModels[g_HadKnife[id]])
		
		Set_WeaponAnim(id, 3)
		set_pdata_float(id, 83, 1.0)
	}
}
public InspectKnife(id)
{
	if(!is_user_alive(id) || cs_zb_is_zombie(id)) 
		return
	
	if(get_user_weapon(id) != CSW_KNIFE || !g_HadKnife[id])
		return;
		
	new pEnt = get_pdata_cbase(id, 373)
	if(!pev_valid(pEnt)) return;
	
	WpnInspect(pEnt, id)
}
public fw_Remove_Item(id, itemid, slot)
{
	if(slot == 2)
	{
		g_HadKnife[id] = 0
		g_Attack[id] = 0
	}
}
public fw_CSZB_StuckRedraw(id)
{
	if(get_user_weapon(id) == CSW_KNIFE && g_HadKnife[id])
	{
		ReDeploy_Knife(id)
	}
}
public ReDeploy_Knife(id)
{
	if(get_user_weapon(id) == CSW_KNIFE && g_HadKnife[id])
	{
		set_pev(id, pev_viewmodel2, szVModels[g_HadKnife[id]])
		
		Set_WeaponAnim(id, 3)
		set_pdata_float(id, 83, 1.0)
	}
}
public client_putinserver(id)
{
	if(is_user_bot(id) && !g_HamBot && get_cvar_num("bot_quota"))
	{
		set_task(0.5, "RegHamBots", id)
	}
}
public RegHamBots(id)
{
	g_HamBot = 1
	RegisterHamFromEntity(Ham_TraceAttack, id, "HamF_TakeDamage")
}
public HamF_TakeDamage(iVictim, iAttacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{	
	if(!is_user_connected(iAttacker) || get_user_weapon(iAttacker) != CSW_KNIFE || !g_HadKnife[iAttacker]) 
		return HAM_IGNORED;
	
	if(g_Attack[iAttacker])
	{	
		SetHamParamFloat(3, g_Stab[iAttacker] ? (flKnifeDmg[g_HadKnife[iAttacker]] * 4.0) : (flKnifeDmg[g_HadKnife[iAttacker]]))
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
	
}

public fw_Attack(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent || !g_HadKnife[Id])
		return
	
	g_Attack[Id] = 1
}

public fw_Attack_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent || !g_HadKnife[Id])
		return
	
	g_Attack[Id] = 0
}
public fw_Stab(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent || !g_HadKnife[Id])
		return
	
	g_Attack[Id] = 1
	g_Stab[Id] = 1
}

public fw_Stab_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent || !g_HadKnife[Id])
		return
	
	g_Attack[Id] = 0
	g_Stab[Id] = 0
}
public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent || !g_HadKnife[Id])
		return
		
	g_Stab[Id] = 0
	set_pev(Id, pev_viewmodel2, szVModels[g_HadKnife[Id]])
}
public WpnInspect(iEnt, id)
{
	if(get_user_weapon(id) != CSW_KNIFE) return;
	
	if(g_HadKnife[id] == 4 || g_HadKnife[id] == 5 || g_HadKnife[id] == 6 || g_HadKnife[id] == 7 || g_HadKnife[id] == 3 || g_HadKnife[id] == 1)
	{
		set_pdata_float(iEnt, 48, 10.0, 4);
		Set_WeaponAnim(id, random_num(8,10));
	}
	if(g_HadKnife[id] == 8 || g_HadKnife[id] == 9 || g_HadKnife[id] == 0 || g_HadKnife[id] == 2)
	{
		set_pdata_float(iEnt, 48, 10.0, 4);
		Set_WeaponAnim(id, random_num(8,9));
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
