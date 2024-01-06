#include <amxmodx>
#include <xs>
#include <zombiemodlimited>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <csm>
#include <reapi>

new Float:g_flSkillTime[33], g_iSkillStat[33], Float:g_flHealTime[33], Float:flBotTime[33], g_Classid, g_Classid2
new g_iDropped[33], g_Hud, g_BoltFw, g_FwResult, g_fwStuckRedraw

new const szWeaponName[][] = { "weapon_p228", "weaponbox", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_deimos/zbz_deimos.mdl")
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_deimos2/zbz_deimos2.mdl")
	
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_knife_deimos.mdl")
	engfunc(EngFunc_PrecacheModel, "models/zbz/v_zombibomb_deimos.mdl")
	
	engfunc(EngFunc_PrecacheSound, "zombi/deimos_skill_start.wav");
	engfunc(EngFunc_PrecacheSound, "zombi/deimos_dash.wav");
}
public plugin_init()
{
	register_plugin("[Zombie Z] Class Deimos & Ganymede", "1.0", "csbtedhan");
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	RegisterHam(Ham_Touch, "info_target", "BoltImpact");
	
	g_Hud = CreateHudSyncObj()
	
	for(new x=0;x<sizeof(szWeaponName);x++)
		RegisterHam(Ham_Touch, szWeaponName[x], "DropStripWeaponBox");
	
	g_BoltFw = CreateMultiForward("fw_CSZB_BoltImpact", ET_CONTINUE, FP_CELL)
	g_fwStuckRedraw = CreateMultiForward("fw_CSZB_StuckRedraw", ET_IGNORE, FP_CELL)
	
	g_Classid = cs_zb_register_class("Deimos Zombie", "deimos", "zbz_deimos", "deimos", 0.8, 290.0, 1.0, 1, 21, 0);
	g_Classid2 = cs_zb_register_class("Ganymede Zombie", "deimos2", "zbz_deimos2", "deimos", 0.8, 290.0, 1.0, 1, 17, 0);
}

public fw_CSHUD(id)
{
	if(!cs_zb_is_zombie(id) || !is_user_alive(id))
		return
		
	set_hudmessage(255, 255, 255, -1.0, 0.25, 0, 0.0, 0.2, 0.0, 0.0);
	
	if(cs_zb_get_zombie_class(id) == g_Classid)
		ShowSyncHudMsg(id, g_Hud, "[G]Bolt: %s [R]Self Healing: %s", (g_flSkillTime[id] <= get_gametime() && g_iSkillStat[id]==0) ? "Ready" : "Cooldown",  (g_flHealTime[id] <= get_gametime()) ? "Ready" : "Cooldown");
	else if(cs_zb_get_zombie_class(id) == g_Classid2)
		ShowSyncHudMsg(id, g_Hud, "[G]Mahadash: %s [R]Hardening: %s", (g_flSkillTime[id] <= get_gametime() && g_iSkillStat[id]==0) ? "Ready" : "Cooldown",  (g_flHealTime[id] <= get_gametime()) ? "Ready" : "Cooldown");
}
public client_command(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	
	new arg[32]
	read_argv(0, arg, 31)
	if(g_iDropped[id] && !cs_zb_is_zombie(id) && (contain(arg, "weapon_") != -1 || equal(arg, "lastinv")))
		return PLUGIN_HANDLED
		
	if(!cs_zb_is_zombie(id) || !(cs_zb_get_zombie_class(id) == g_Classid || cs_zb_get_zombie_class(id) == g_Classid2)) 
		return PLUGIN_CONTINUE
	if(g_flSkillTime[id] <= get_gametime())
	{
		if(equali(arg, "drop") && g_iSkillStat[id] == 0 && get_user_weapon(id) == CSW_KNIFE)
		{
			if(cs_zb_get_zombie_class(id) == g_Classid)
			{
				Set_WeaponAnim(id, 8);
				SetPlayerAnimation(id, IsDucking(id) ? "skill_crouch_idle" : "skill");
				
				g_iSkillStat[id] = 1
				engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, "zombi/deimos_skill_start.wav", 1.0, 0.8, 0, 100);
				
				set_pdata_float(id, 83, 1.0);
				g_flSkillTime[id] = get_gametime() + 0.75;
			} else {
				g_iSkillStat[id] = 1
				set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
				set_pdata_float(id, 83, 2.0);
				engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, "zombi/deimos_dash.wav", 1.0, 0.8, 0, 100);
				g_flSkillTime[id] = get_gametime() + 0.75;
			}
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!cs_zb_is_zombie(id) || !(cs_zb_get_zombie_class(id) == g_Classid || cs_zb_get_zombie_class(id) == g_Classid2) || !is_user_alive(id))
		return
		
	static Float:hp, CurButton;CurButton = get_uc(uc_handle, UC_Buttons)
	if(CurButton & IN_RELOAD)
	{
		CurButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, CurButton)
		if(g_flHealTime[id] <= get_gametime())
		{
			play_sound(id, "zombi/smallmedkit1.wav")
			
			if(cs_zb_get_zombie_class(id) == g_Classid)
			{
				pev(id, pev_health, hp);
				set_pev(id, pev_health,floatmin(float(cs_zb_get_user_maxhealth(id)), hp+(75.0 * float(cs_zb_get_level(id)))))
			} else {
				set_pev(id, pev_armorvalue, pev(id, pev_armorvalue) + 600.0)
			}
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
	
	if(is_user_bot(id) && flBotTime[id] <= get_gametime() && cs_zb_get_zombie_class(id) == g_Classid)
	{
		if(random(10) > 7 && get_user_weapon(id) == CSW_KNIFE)
		{
			Set_WeaponAnim(id, 8);
			SetPlayerAnimation(id, IsDucking(id) ? "skill_crouch_idle" : "skill");
			g_iSkillStat[id] = 1
			engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, "zombi/deimos_skill_start.wav", 1.0, 0.8, 0, 100);
			
			set_pdata_float(id, 83, 1.0);
			g_flSkillTime[id] = get_gametime() + 0.75;
		}
		flBotTime[id] = get_gametime() + 8.0;
	}	
}
public fw_CSZB_Killed(victim, attacker) { g_iDropped[victim] = 0; g_iSkillStat[victim] = 0; }
public fw_CSZB_Infected(victim, attacker) { g_iDropped[victim] = 0; g_iSkillStat[victim] = 0; }
public fw_CSZB_OnSpawn(id) { g_iDropped[id] = 0; g_iSkillStat[id] = 0; }
public fw_CSZB_OnPreThink(id)
{
	if(g_iDropped[id] && get_pdata_float(id, 83) <= 0.0)
	{
		static szOldvModel[33], szOldpModel[33];
		pev(id, pev_noise, szOldvModel, 32);
		pev(id, pev_noise1, szOldpModel, 32);
		
		set_pev(id, pev_viewmodel2, szOldvModel, 32);
		set_pev(id, pev_weaponmodel2, szOldpModel, 32);
		ExecuteForward(g_fwStuckRedraw, g_FwResult, id)
		
		set_pev(id, pev_noise, "");
		set_pev(id, pev_noise1, "");
		
		g_iDropped[id] = 0
	}
	if(!cs_zb_is_zombie(id))
		return;
		
	if(cs_zb_get_zombie_class(id) == g_Classid)
	{
		if(g_iSkillStat[id] == 1 && g_flSkillTime[id] <= get_gametime())
		{
			MakeBolt(id)
			g_iSkillStat[id] = 0;
			g_flSkillTime[id] = get_gametime() + 6.0;
		}
	} else if(cs_zb_get_zombie_class(id) == g_Classid2) {
		if(g_iSkillStat[id] == 1 && g_flSkillTime[id] <= get_gametime() && pev(id, pev_flags) & FL_ONGROUND)
		{
			static Float:velocity[3]
			pev(id, pev_velocity, velocity);
			
			Set_WeaponAnim(id, 5);
			
			g_iSkillStat[id] = 0;
			g_flSkillTime[id] = get_gametime() + 6.0;
			
			velocity_by_aim(id, 1350, velocity)
					
			velocity[2] = 320.0
			set_pev(id, pev_velocity, velocity)
		}
	}
}
public DropStripWeaponBox(Ent, id)
{
	if(isHuman(id) && g_iDropped[id])
		return HAM_SUPERCEDE;
		
	return HAM_IGNORED
}
public MakeBolt(id)
{
	static pEnt, Float:vOrigin[3], Float:vUps[3];
	pev(id, pev_origin, vOrigin);
	pev(id, pev_view_ofs, vUps);
	xs_vec_add(vOrigin, vUps, vOrigin);
	vOrigin[2] -= 3.0;
	
	pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(pEnt, pev_origin, vOrigin);
	set_pev(pEnt, pev_movetype, MOVETYPE_FLY);
	set_pev(pEnt, pev_owner, id);
	set_pev(pEnt, pev_classname, "deimoszombibolt");
	
	engfunc(EngFunc_SetModel, pEnt, "models/grenade.mdl");
	engfunc(EngFunc_SetSize, pEnt, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0});
	
	set_pev(pEnt, pev_rendermode, kRenderTransTexture);
	set_pev(pEnt, pev_renderamt, 0.0);
	
	set_pev(pEnt, pev_solid, SOLID_BBOX);
	
	static Float:vecVelo[3];
	velocity_by_aim(id, 1750, vecVelo);
	set_pev(pEnt, pev_velocity, vecVelo);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(pEnt)
	write_short(engfunc(EngFunc_ModelIndex, "sprites/laserbeam.spr"));
	write_byte(15)
	write_byte(1)
	write_byte(255)
	write_byte(255)
	write_byte(0)
	write_byte(255)
	message_end()
}
public BoltImpact(Ent, id)
{
	if(!isBolt(Ent))
		return;
	
	static Float:vecOrigin[3], Float:vOrigin[3]; pev(Ent, pev_origin, vecOrigin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte( TE_EXPLOSION );
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/zombiebomb_exp.spr"))
	write_byte(30);
	write_byte(30);
	write_byte( 14 );
	message_end();
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(122)
	engfunc(EngFunc_WriteCoord, vecOrigin[0]);
	engfunc(EngFunc_WriteCoord, vecOrigin[1]);
	engfunc(EngFunc_WriteCoord, vecOrigin[2]);
	write_short(150)
	write_byte(111)
	write_byte(5)
	message_end()
	
	engfunc(EngFunc_EmitAmbientSound, 0, vecOrigin, "zombi/zombi_bomb_exp.wav", 1.0, 0.6, 0, 100);
	
	for(new victim = 0; victim < 32; victim++)
	{
		if(!isHuman(victim)) continue;

		pev(victim,pev_origin,vOrigin);
		if(vector_distance(vOrigin, vecOrigin) <= 80.0 && isClearLine(vOrigin, vecOrigin))
		{
			ExecuteForward(g_BoltFw, g_FwResult, victim)
		
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenShake"), _, victim)
			write_short((1<<12)*4)
			write_short((1<<12)*2)
			write_short((1<<12)*10)
			message_end()
			if(!g_FwResult)
			{
				if(!rg_drop_items_by_slot(id, PRIMARY_WEAPON_SLOT))
					rg_drop_items_by_slot(id, PISTOL_SLOT)
				
				set_pdata_float(victim, 83, 3.0);
				
				static szOldvModel[33], szOldpModel[33];
				pev(victim, pev_viewmodel2, szOldvModel, 32);
				pev(victim, pev_weaponmodel2, szOldpModel, 32);
				
				g_iDropped[victim] = 1;
				
				set_pev(victim, pev_noise, szOldvModel);
				set_pev(victim, pev_noise1, szOldpModel);
				
				set_pev(victim, pev_viewmodel2, "");
				set_pev(victim, pev_weaponmodel2, "");
			}
		}
	}
	
	engfunc(EngFunc_RemoveEntity, Ent);
}

stock isClearLine(Float:vOrigin1[3], Float:vOrigin2[3])
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vOrigin1, vOrigin2, IGNORE_MONSTERS, 0, 0);
	get_tr2(0, TR_flFraction, flFraction)
	
	if (flFraction < 1.0) return 0;

	return 1;
}
stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(0)
	message_end()
}
stock play_sound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}
stock isHuman(Ent)
{
	if (pev_valid(Ent) && !cs_zb_is_zombie(Ent) && is_user_alive(Ent))
		return 1;
	return 0;
}
stock isBolt(Ent)
{
	if(!pev_valid(Ent)) return 0;
	
	static szClassName[32]; pev(Ent, pev_classname,szClassName, 31);
	return (equal(szClassName, "deimoszombibolt"))
}
stock IsDucking(id)
{
	return (pev(id, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND))
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
