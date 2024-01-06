#include <amxmodx>
#include <csm>
#include <zombiemodlimited>
#include <fakemeta>

new Float:g_flSkillTime[33], g_iSkillStat[33], g_Classid, g_Hud
new const zombie_pain_sound[][] = { "zombi/zombi_hurt_female_01.wav ", "zombi/zombi_hurt_female_02.wav" }
new const zombie_die_sound[][] = { "zombi/zombi_death_female_01.wav ", "zombi/zombi_death_female_02.wav" }


public plugin_precache() 
{
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_speed/zbz_speed.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_knife_speed.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_zombibomb_speed.mdl")
	
	engfunc(EngFunc_PrecacheSound, "zombi/zombi_pressure_female.wav")
	
	for(new i = 0; i<2; i++) 
	{
		engfunc(EngFunc_PrecacheSound, zombie_pain_sound[i])
		engfunc(EngFunc_PrecacheSound, zombie_die_sound[i])
	}
	
}
public plugin_init() 
{
	register_plugin("[Zombie Z] Class Light", "1.0", "csbtedhan");
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_EmitSound, "fw_EmitSound")
	
	g_Hud = CreateHudSyncObj()
	
	g_Classid = cs_zb_register_class("Light Zombie", "speed", "zbz_speed", "speed", 0.8, 310.0, 0.7, 1, 5, 1);
}

public client_command(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return PLUGIN_CONTINUE
	
	new arg[13]
	if (read_argv(0, arg, 12) > 11) return PLUGIN_CONTINUE 
	if(g_iSkillStat[id] == 0 && g_flSkillTime[id] <= get_gametime())
	{
		if(equali(arg, "drop"))
		{
			g_iSkillStat[id] = 1
			set_pdata_int(id, 363, 110);
			set_pev(id, pev_maxspeed, 240.0);
			fm_set_rendering(id, kRenderFxNone, 255, 255, 255, kRenderTransAlpha, 30)
			
			engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "zombi/zombi_pressure_female.wav", 1.0, 0.8, 0, 100);
			g_flSkillTime[id] = get_gametime() + 8.0;
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

public fw_CSHUD(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 0.0, 0.2, 0.0, 0.0);
	ShowSyncHudMsg(id, g_Hud, "[G]Invisible: %s [R]Gravity: %s", (g_flSkillTime[id] <= get_gametime() && g_iSkillStat[id] == 0) ? "Ready" : "Cooldown",  (g_flSkillTime[id] <= get_gametime()&& g_iSkillStat[id] == 0) ? "Ready" : "Cooldown");
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	static CurButton;CurButton = get_uc(uc_handle, UC_Buttons)
	if(CurButton & IN_RELOAD)
	{
		CurButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, CurButton)
		if(g_flSkillTime[id] <= get_gametime() && g_iSkillStat[id] == 0)
		{
			g_iSkillStat[id] = 1
			play_sound(id, "zombi/speedup.wav")
			set_pev(id, pev_gravity, 0.45);
			fm_set_rendering(id, kRenderFxGlowShell, 100, 100, 100)
			g_flSkillTime[id] = get_gametime() + 7.0;
			
		}
	}
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
public fw_CSZB_Killed(id, attacker)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return
	
	g_iSkillStat[id] = 0
	set_pev(id, pev_gravity, 0.7)
	set_pev(id, pev_maxspeed, 310.0)
	fm_set_rendering(id);
}
public fw_CSZB_OnPreThink(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return

	if(g_flSkillTime[id] <= get_gametime() && g_iSkillStat[id])
	{
		g_iSkillStat[id] = 0
		set_pev(id, pev_gravity, 0.7)
		set_pev(id, pev_maxspeed, 310.0)
		fm_set_rendering(id);
		g_flSkillTime[id] = get_gametime() + 8.0;
	}
}
stock play_sound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
