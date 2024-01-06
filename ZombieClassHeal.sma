#include <amxmodx>
#include <zombiemodlimited>
#include <fakemeta>
#include <csm>

new Float:g_flSkillTime[33], Float:g_flHealTime[33], Float:flBotTime[33], g_Classid
new g_Hud

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_heal/zbz_heal.mdl")
	
	engfunc(EngFunc_PrecacheSound, "zombi/td_heal.wav");
	engfunc(EngFunc_PrecacheModel, "sprites/zb_restore_health.spr");
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_knife_heal.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_zombibomb_heal.mdl")
	
}
public plugin_init() 
{
	register_plugin("[Zombie Z] Class Voddoo", "1.0", "csbtedhan");
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	g_Hud = CreateHudSyncObj()
	
	g_Classid = cs_zb_register_class("Heal Zombie", "heal", "heal_zombi", "heal", 0.8, 260.0, 1.1, 1, 6, 0);
}
public client_command(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return PLUGIN_CONTINUE
	
	new arg[13]
	if (read_argv(0, arg, 12) > 11) return PLUGIN_CONTINUE 
	if(g_flSkillTime[id] <= get_gametime())
	{
		if(equali(arg, "drop"))
		{
			DoHealParty(id)
			engfunc(EngFunc_EmitSound, id, CHAN_STATIC, "zombi/td_heal.wav", 1.0, 0.8, 0, 100);
			
			g_flSkillTime[id] = get_gametime() + 10.0;
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
	ShowSyncHudMsg(id, g_Hud, "[G]Heal Party: %s [R]Self Healing: %s", (g_flSkillTime[id] <= get_gametime()) ? "Ready" : "Cooldown",  (g_flSkillTime[id] <= get_gametime()) ? "Ready" : "Cooldown");
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	static Float:hp, CurButton;CurButton = get_uc(uc_handle, UC_Buttons)
	if(CurButton & IN_RELOAD)
	{
		CurButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, CurButton)
		if(g_flHealTime[id] <= get_gametime())
		{
			play_sound(id, "zombi/smallmedkit1.wav")
			pev(id, pev_health, hp);
			set_pev(id, pev_health,floatmin(float(cs_zb_get_user_maxhealth(id)), hp+(75.0 * float(cs_zb_get_level(id)))))
			g_flHealTime[id] = get_gametime() + 7.0;
			
			FadeHeal(id)
		}
	}
	
	if(is_user_bot(id) && flBotTime[id] <= get_gametime())
	{
		if(random(10) > 7) 
		{
			DoHealParty(id)
			engfunc(EngFunc_EmitSound, id, CHAN_STATIC, "zombi/td_heal.wav", 1.0, 0.8, 0, 100);
			
			g_flSkillTime[id] = get_gametime() + 10.0;
		}
		flBotTime[id] = get_gametime() + 10.0;
	}	
}
public DoHealParty(id)
{
	static Float:vOrigin[3];
	pev(id, pev_origin, vOrigin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte( TE_EXPLOSION );
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/zb_restore_health.spr"))
	write_byte(10);
	write_byte(10);
	write_byte( TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOPARTICLES | TE_EXPLFLAG_NOSOUND );
	message_end();
			
	static pEnt, Float:hp, level; pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, 350.0)) != 0)
	{
		if(!isFriend(pEnt)) continue;
		
		level = cs_zb_get_level(pEnt)
		pev(pEnt, pev_health, hp);
		play_sound(pEnt, "zombi/smallmedkit1.wav")
		set_pev(pEnt, pev_health, floatmin(float(cs_zb_get_user_maxhealth(pEnt)), hp + (50.0 * float(level))));
		
		FadeHeal(pEnt)
		
		ZHealEffect(pEnt);
	}
}
public ZHealEffect(id)
{
	static Float:vOrigin[3], Float:vUp[3];
	pev(id, pev_origin, vOrigin);
	pev(id, pev_view_ofs, vUp);
	vOrigin[2] += vUp[2];
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte( TE_SPRITE );
	engfunc(EngFunc_WriteCoord, vOrigin[0]);
	engfunc(EngFunc_WriteCoord, vOrigin[1]);
	engfunc(EngFunc_WriteCoord, vOrigin[2] + 5.0);
	write_short( engfunc(EngFunc_ModelIndex, "sprites/zombiheal_head.spr") )
	write_byte(10)
	write_byte(255)
	message_end()
}
stock FadeHeal(id)
{
	if(!cs_zb_is_using_nvgs(id))
	{	
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
		write_short(1<<9);
		write_short(0);
		write_short(0x0000);
		write_byte(0);//r
		write_byte(200);  //g
		write_byte(0);  //b
		write_byte(100);
		message_end();
	}
}
stock play_sound(id, const sound[])
{
	client_cmd(id, "spk ^"%s^"", sound)
}
stock isFriend(id)
{
	if(pev_valid(id) && is_user_alive(id) && cs_zb_is_zombie(id))
		return 1;
	return 0;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
