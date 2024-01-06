#include <amxmodx>
#include <zombiemodlimited>
#include <fakemeta>
#include <csm>
#include <hamsandwich>

new Float:g_flSkillTime[33], g_iSkillStat[33], Float:g_flHealTime[33]
new Float:g_flSmokeTime[8192], Float:flBotTime[33], g_Classid, g_Hud

public plugin_precache()
{
	engfunc(EngFunc_PrecacheSound, "zombi/zombi_smoke.wav")
	
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_pc/zbz_pc.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_knife_pc.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_zombibomb_pc.mdl")
	
}
public plugin_init() 
{
	register_plugin("[Zombie Z] Class Psycho", "1.0", "csbtedhan");
	
	RegisterHam(Ham_Think, "info_target", "SmokeThink");
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_AddToFullPack, "fw_addToFullPack", 1)
	
	g_Hud = CreateHudSyncObj()
	
	g_Classid =  cs_zb_register_class("Psycho Zombie", "pc", "zbz_pc", "pc", 0.8, 260.0, 1.0, 1, 7, 0);
}

public fw_CSHUD(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 0.0, 0.2, 0.0, 0.0, 12);
	ShowSyncHudMsg(id, g_Hud, "[G]Smoke Screen: %s [R]Self Healing: %s", (g_flSkillTime[id] <= get_gametime()) ? "Ready" : "Cooldown",  (g_flHealTime[id] <= get_gametime()) ? "Ready" : "Cooldown");
}
public fw_CSNew_Round()
{
	new pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityByString, pEnt, "classname", "pczombismoke")) != 0)
	{
		if(pev_valid(pEnt)) engfunc(EngFunc_RemoveEntity, pEnt)
	}
}

public client_command(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return PLUGIN_CONTINUE
	
	new arg[13]
	if (read_argv(0, arg, 12) > 11) return PLUGIN_CONTINUE 
	if(g_flSkillTime[id] <= get_gametime() && g_iSkillStat[id] == 0)
	{
		if(equali(arg, "drop"))
		{
			MakeSmokeGroup(id)
			engfunc(EngFunc_EmitSound, id, CHAN_STATIC, "zombi/zombi_smoke.wav", 1.0, 0.8, 0, 100);
			
			set_pev(id, pev_maxspeed, 150.0);
			g_iSkillStat[id] = 5
			g_flSkillTime[id] = get_gametime() + 1.0;
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}
public fw_addToFullPack(es, e, ent, host, hostflags, player, pSet)
{
	if(!pev_valid(host))
		return FMRES_IGNORED;
		
	new id = pev(host, pev_iuser2)
	if(!pev_valid(id) || !(pev_valid(id) && pev(host, pev_iuser1) == 4)) id = host
	
	if(isSmoke(ent))
	{
		new iOwner = pev(ent, pev_owner)
		if(id == iOwner || cs_zb_is_zombie(id))
		{
			set_es(es, ES_RenderAmt, 10.0);
			set_es(es, ES_RenderColor, Float:{224.0, 224.0, 255.0})
			set_es(es, ES_RenderMode, kRenderTransAlpha);
		}
		
	}
	return FMRES_IGNORED;
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
		if(g_flHealTime[id] <= get_gametime())
		{
			play_sound(id, "zombi/smallmedkit1.wav")
			set_pev(id, pev_health, pev(id, pev_health) + random_float(400.0, 500.0))
			g_flHealTime[id] = get_gametime() + 7.0;
			
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
	}
	
	if(is_user_bot(id) && flBotTime[id] <= get_gametime())
	{
		if(random(10) > 7) 
		{
			MakeSmokeGroup(id)
			engfunc(EngFunc_EmitSound, id, CHAN_STATIC, "zombi/zombi_smoke.wav", 1.0, 0.8, 0, 100);
			
			set_pev(id, pev_maxspeed, 150.0);
			g_iSkillStat[id] = 5
			g_flSkillTime[id] = get_gametime() + 1.0;
		}
		flBotTime[id] = get_gametime() + 10.0;
	}	
}
public fw_CSZB_OnSpawn(id)
{
	g_iSkillStat[id] = 0;
}	
public fw_CSZB_OnPostThink(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return 
		
	if(g_iSkillStat[id] > 0 && g_flSkillTime[id] <= get_gametime())
	{
		g_iSkillStat[id] --
		if(g_iSkillStat[id] <= 0)
		{
			set_pev(id, pev_maxspeed, 260.0);
			g_flSkillTime[id] = get_gametime() + 8.0;
			return;
		}
		set_pev(id, pev_maxspeed, 150.0);
		MakeSmokeGroup(id)
		g_flSkillTime[id] = get_gametime() + 1.0;
	}
}
public MakeSmokeGroup(id)
{
	new Float:vOrigin[3];
	pev(id, pev_origin, vOrigin);
	
	new Float:flYaw = 0.0;
	
	MakeSmoke(id, vOrigin, 1.0);
	new Float:pOrigin[3]; 
	for(new x = 0; x < 14; x ++ )
	{
		get_spherical_coord(vOrigin, 40.0, flYaw, 0.0, pOrigin);
		MakeSmoke(id, pOrigin, 1.0);
		get_spherical_coord(vOrigin, 70.0, flYaw, 0.0, pOrigin);
		MakeSmoke(id, pOrigin, 1.0);
		flYaw += 25.7
	}
}
public MakeSmoke(id, Float:vOrigin[3], Float:flTime)
{
	static pEnt; pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	set_pev(pEnt, pev_origin, vOrigin);
	set_pev(pEnt, pev_classname, "pczombismoke");
	engfunc(EngFunc_SetModel, pEnt, "sprites/gas_puff_01.spr")
	set_pev(pEnt, pev_rendermode, kRenderTransAlpha);
	set_pev(pEnt, pev_rendercolor, Float:{5.0, 5.0, 5.0})
	set_pev(pEnt, pev_renderamt, 255.0);
	set_pev(pEnt, pev_iuser1, 0);
	set_pev(pEnt, pev_owner, id)
	set_pev(pEnt, pev_frame, 1.0);
	
	set_pev(pEnt, pev_scale, 0.1);
	set_pev(pEnt, pev_fuser1, get_gametime());
	set_pev(pEnt, pev_nextthink, get_gametime())
	
	g_flSmokeTime[pEnt] = get_gametime() + flTime
	static Float:vAngle[3]; vAngle[2] = random_float(-90.0, 90.0)
	set_pev(pEnt, pev_angles, vAngle);
}
public SmokeThink(Ent)
{
	if(!isSmoke(Ent))
		return;
		
	set_pev(Ent, pev_nextthink, get_gametime())
	static iOwner; iOwner = pev(Ent, pev_owner)
	if((!is_user_alive(iOwner) || !pev_valid(iOwner) || !cs_zb_is_zombie(iOwner)) && pev(Ent, pev_iuser1) != 1)
	{
		set_pev(Ent, pev_iuser1, 1)
		g_flSmokeTime[Ent] = get_gametime() + 0.5;
		return;
	}
	new Float:flTemp, Float:flScale;
	pev(Ent, pev_scale, flScale);
	pev(Ent, pev_fuser1, flTemp);
	set_pev(Ent, pev_scale, floatmin(3.1, flScale + floatabs(flTemp - get_gametime())));
	
	if(g_flSmokeTime[Ent] <= get_gametime())
	{
		if(pev(Ent, pev_iuser1) != 1)
		{
			set_pev(Ent, pev_iuser1, 1)
			g_flSmokeTime[Ent] = get_gametime() + 0.5;
		} else {
			engfunc(EngFunc_RemoveEntity, Ent);
			return;
		}
	}
	if(pev(Ent, pev_iuser1) == 1) set_pev(Ent, pev_renderamt, floatmin(255.0, floatmax(0.0, (g_flSmokeTime[Ent]-get_gametime())*255.0)))
	
}
stock get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length  = redius * floatcos(vertical_angle, degrees)
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
}
stock play_sound(id, const sound[])
{
	client_cmd(id, "spk ^"%s^"", sound)
}
stock isSmoke(Ent)
{
	if(!pev_valid(Ent)) return 0;
	
	static szClassName[32]; pev(Ent, pev_classname,szClassName, 31);
	return (equal(szClassName, "pczombismoke"))
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
