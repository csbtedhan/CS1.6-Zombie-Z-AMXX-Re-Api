#include <amxmodx>
#include <zombiemodlimited>
#include <fakemeta>
#include <xs>
#include <hamsandwich>
#include <cstrike>
#include <csm>

new g_Classid, Float:flLastGrenade[33], iSkillStat[33], Float:flLastFastRun[33], iFastrunStat[33], Float:flBombRemove[8192], g_Hud
new const zombie_pain_sound[][] = { "zombi/passzombie_hurt1.wav ", "zombi/passzombie_hurt2.wav" }
new const zombie_die_sound[][] = { "zombi/passzombie_death1.wav ", "zombi/passzombie_death2.wav" }

public plugin_precache()
{
	for(new i = 0; i<2; i++) 
	{
		engfunc(EngFunc_PrecacheSound, zombie_pain_sound[i])
		engfunc(EngFunc_PrecacheSound, zombie_die_sound[i])
	}
	
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_pass/zbz_pass.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_knife_pass.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_zombibomb_pass.mdl")
}

public plugin_init() 
{
	register_plugin("[Zombie Z] Class Blotter", "1.0", "csbtedhan");
	RegisterHam(Ham_Think, "info_target", "FrogBombThink");
	RegisterHam(Ham_Touch, "info_target", "FrogBombImpact");
	
	g_Hud = CreateHudSyncObj()
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	g_Classid = cs_zb_register_class("Blotter Zombie", "pass", "zbz_pass", "pass", 0.8, 300.0, 1.3, 1, 25, 1);
}

public fw_CSHUD(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 0.0, 0.2, 0.0, 0.0);
	ShowSyncHudMsg(id, g_Hud, "[G]Fastrun: %s [R]Frog Bomb: %s", (flLastFastRun[id] <= get_gametime() && iFastrunStat[id]==0) ? "Ready" : "Cooldown",  (flLastGrenade[id] <= get_gametime()) ? "Ready" : "Cooldown");
}
public client_command(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return PLUGIN_CONTINUE
	
	new arg[13]
	if (read_argv(0, arg, 12) > 11) return PLUGIN_CONTINUE 
	if(flLastFastRun[id] <= get_gametime() && iFastrunStat[id] == 0)
	{
		if(equali(arg, "drop"))
		{
			iFastrunStat[id] = 1;
			set_pdata_int(id, 363, 110);
			set_pev(id, pev_maxspeed, 450.0);
			fm_set_rendering(id, kRenderFxGlowShell, 255, 0, 0);
			engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "zombi/zombi_pressure.wav", 1.0, 0.8, 0, 100);
			flLastFastRun[id] = get_gametime() + 8.0;
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}
public fw_CSNew_Round()
{
	RemoveSpecificEntity("weaponbox_frogbomb")
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	static Model[64], CurButton;CurButton = get_uc(uc_handle, UC_Buttons)
	
	cs_get_user_model(id, Model, 63);
	if(CurButton & IN_RELOAD && iFastrunStat[id] == 0)
	{
		CurButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		if(flLastGrenade[id] <= get_gametime())
		{
			if(!user_has_weapon(id, CSW_HEGRENADE))
			{
				if(pev(id, pev_health) > 5000.0)
				{
					fm_give_item(id, "weapon_hegrenade");
					engclient_cmd(id, "weapon_hegrenade");
					set_pev(id, pev_viewmodel2, "models/zbz/v_zombibomb_pass.mdl")
					
					Set_WeaponAnim(id, 5);
					
					set_pdata_float(id, 83, 1.1);
					set_pev(id, pev_health, pev(id, pev_health) - 5000.0);
					flLastGrenade[id] = get_gametime() + 3.0;
				}
			} else {

				if(get_user_weapon(id) == CSW_HEGRENADE)
				{
					SetPlayerAnimation(id, "skill")
					Set_WeaponAnim(id, 4);
					set_pdata_float(id, 83, 1.1);
					
					iSkillStat[id] = 1
					flLastGrenade[id] = get_gametime() + 1.0;
				}
			}
		}
	}
	
	if(iSkillStat[id] == 1 && flLastGrenade[id] <= get_gametime() && iFastrunStat[id] == 0)
	{
		MakeFrogBomb(id)
		if(cs_get_user_bpammo(id, CSW_HEGRENADE) > 1)
			cs_set_user_bpammo(id, CSW_HEGRENADE, cs_get_user_bpammo(id, CSW_HEGRENADE) - 1)
		else ham_strip_weapon(id, "weapon_hegrenade");
		iSkillStat[id] = 0
		flLastGrenade[id] = get_gametime() + 8.0;
	}
}
public fw_CSZB_OnPreThink(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return;
		
	if(flLastFastRun[id] <= get_gametime())
	{
		if(iFastrunStat[id] == 1)
		{
			iFastrunStat[id] = 0;
			set_pev(id, pev_maxspeed, 270.0);
			fm_set_rendering(id);
			set_pdata_int(id, 363, 90);
			flLastFastRun[id] = get_gametime() + 6.0
		}
	}
	if(iFastrunStat[id] == 1) set_pev(id, pev_maxspeed, 450.0);
}
public MakeFrogBomb(id)
{
	static pEnt, Float:vOrigin[3];
	pev(id, pev_origin, vOrigin);
	
	pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(pEnt, pev_origin, vOrigin);
	set_pev(pEnt, pev_movetype, MOVETYPE_TOSS);
	set_pev(pEnt, pev_owner, id)
	set_pev(pEnt, pev_classname, "weaponbox_frogbomb");
	
	set_pev(pEnt, pev_sequence, 1);
	set_pev(pEnt, pev_iuser1, 0);
	
	engfunc(EngFunc_SetSize, pEnt, Float:{-5.0, -5.0, -5.0}, Float:{5.0, 5.0, 5.0})
	engfunc(EngFunc_SetModel, pEnt, "models/zbz/w_zombibomb.mdl")
	
	set_pev(pEnt, pev_solid, SOLID_BBOX);
	
	flBombRemove[pEnt] = get_gametime() + 20.0;
	
	set_pev(pEnt, pev_nextthink, get_gametime())
	set_pev(pEnt, pev_gravity, 0.65)
	static Float:vecVelo[3]
	velocity_by_aim(id, 650, vecVelo);
	set_pev(pEnt, pev_velocity, vecVelo);
	
}
public FrogBombThink(Ent)
{
	if(!isZBomb(Ent)) return;

	if(flBombRemove[Ent] <= get_gametime())
	{
		engfunc(EngFunc_RemoveEntity, Ent);
		return;
	}
		
	set_pev(Ent, pev_nextthink, get_gametime())
}
public FrogBombImpact(Ent, Id)
{
	if(!isZBomb(Ent) || !pev_valid(Id)) 
		return;
	
	if(!is_user_alive(Id) || !cs_zb_is_zombie(Id))
		return;
		
	if(user_has_weapon(Id, CSW_HEGRENADE))
		return;
		
	fm_give_item(Id, "weapon_hegrenade")
	engfunc(EngFunc_RemoveEntity, Ent);
}
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return FMRES_IGNORED
		
	if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
	{
		emit_sound(id, channel, zombie_pain_sound[random_num(0, 1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	// Zombie dies
	if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		emit_sound(id, channel, zombie_die_sound[random_num(0, 1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
		
	// Zombie falls off
	if (sample[10] == 'f' && sample[11] == 'a' && sample[12] == 'l' && sample[13] == 'l')
	{
		emit_sound(id, channel, zombie_pain_sound[random_num(0, 1)], volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED
}
stock fm_give_item(index, const item[]) 
{
	if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
		return 0;

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent))
		return 0;

	new Float:origin[3];
	pev(index, pev_origin, origin);
	set_pev(ent, pev_origin, origin);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);

	new save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, index);
	if (pev(ent, pev_solid) != save)
		return ent;

	engfunc(EngFunc_RemoveEntity, ent);

	return -1;
}
stock isZBomb(Ent)
{
	if(!pev_valid(Ent)) return 0;
	
	static szClassName[32]; pev(Ent, pev_classname,szClassName, 31);
	if (equal(szClassName, "weaponbox_frogbomb")) return 1
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
stock SetPlayerAnimation(id, const AnimName[], Float:rate=1.0)
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
stock ham_strip_weapon(id,weapon[])
{
	if(!equal(weapon,"weapon_",7)) return 0;
	
	new wId = get_weaponid(weapon);
	if(!wId) return 0;
	
	new wEnt;
	while((wEnt = engfunc(EngFunc_FindEntityByString, wEnt, "classname", weapon)) && pev(wEnt, pev_owner) != id) {}
	if(!wEnt) return 0;
	
	new iTmp;
	if(get_user_weapon(id, iTmp, iTmp) == wId) ExecuteHamB(Ham_Weapon_RetireWeapon, wEnt);
	
	if(!ExecuteHamB(Ham_RemovePlayerItem, id, any:wEnt)) return 0;
	
	ExecuteHamB(Ham_Item_Kill, wEnt);
	set_pev(id, pev_weapons, pev(id, pev_weapons) & ~(1<<wId));
	
	return 1;
}
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) 
{
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));

	return 1;
}
stock RemoveSpecificEntity(const szClassName[])
{
	new pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", szClassName)) != 0)
	{
		if(!pev_valid(pEnt)) continue;
		
		engfunc(EngFunc_RemoveEntity, pEnt)
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
