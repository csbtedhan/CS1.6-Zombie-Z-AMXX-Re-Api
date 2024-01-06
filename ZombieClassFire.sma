
#include <amxmodx>
#include <csm>
#include <zombiemodlimited>
#include <fakemeta>
#include <xs>
#include <hamsandwich>

#define FLAME_MAX	100
#define FLAME_DAMAGE	10

new g_sFlame[] = "sprites/flame_puff01.spr"
new g_sSpit[] = "models/zbz/spit.mdl"
new szFlameSound[] = "weapons/flamethrower-1.wav"
new Float:g_flFlameDelay[2][33], g_iFlame[33], g_Hud, g_HudJ
new g_sModelindexSmoke, g_Classid, Float:g_flFlameTime[8912], Float:g_flLastLeap[2][33], Float:g_flLastHeal[33], Float:g_flLastSpit[33][2], g_iSpit[33], g_iLeapMana[33]

#define LEAP_SPEED		650.0
#define LEAP_MAXMANA		1000
#define LEAP_RECHARGERATE	10
#define LEAP_MANA		300
#define LEAP_MANA_ESCAPE		600
#define LEAP_RECHARGEINTERVAL	0.05
#define LEAP_INTERVAL		1.0

public plugin_precache() 
{
	engfunc(EngFunc_PrecacheModel, "models/player/zbz_fire/zbz_fire.mdl")
	
	engfunc(EngFunc_PrecacheModel, g_sFlame)
	engfunc(EngFunc_PrecacheModel, g_sSpit)
	engfunc(EngFunc_PrecacheSound, szFlameSound)
	engfunc(EngFunc_PrecacheSound, "zombi/firezombi_spit1.wav")
	engfunc(EngFunc_PrecacheSound, "zombi/firezombi_splat1.wav")
	engfunc(EngFunc_PrecacheSound, "zombi/firezombi_leap.wav")
	engfunc(EngFunc_PrecacheModel, "sprites/spr_boomer.spr");
	
	g_sModelindexSmoke = engfunc(EngFunc_PrecacheModel, "sprites/gas_smoke1.spr")
	
}
public plugin_init() 
{
	g_Hud = CreateHudSyncObj()
	g_HudJ = CreateHudSyncObj()
	
	register_forward(FM_Touch, "fw_Fire_Touch")
	register_forward(FM_Think, "fw_Fire_Think")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	RegisterHam(Ham_Think, "info_target", "SpitThink")
	RegisterHam(Ham_Touch, "info_target", "SpitImpact")
	g_Classid = cs_zb_register_class("Xenozio Harom Zombie", "fire", "zbz_fire", "tank", 0.8, 300.0, 0.8, 1, 30, 0);
}
public fw_CSPlayer_Spawn(id)
{
	g_iFlame[id] = 0
	g_iSpit[id] = 0
}
public fw_CSHUD(id)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	set_hudmessage(255, 255, 0, -1.0, 0.25, 0, 0.0, 0.2, 0.0, 0.0)
	ShowSyncHudMsg(id, g_Hud, "[E] Fire Amount: %i [G] Spit: %s [R] Self-Healing: %s", g_iFlame[id], g_flLastSpit[id][0] <= get_gametime() ? "Ready" : "Cooldown",g_flLastHeal[id] <= get_gametime() ? "Ready" : "Cooldown")
	
	new current_morale = clamp((((g_iLeapMana[id] ) * 10) / LEAP_MAXMANA), 0, 10)
	new message[256], PowerUp[32], PowerDown[32]
	for(new i = 0; i < current_morale; i++)
		formatex(PowerUp, sizeof(PowerUp), "%s||", PowerUp)
	for(new i = 10; i > current_morale; i--)
		formatex(PowerDown, sizeof(PowerDown), "%s==", PowerDown)
				
	new ManaNeed = cs_zb_is_escape_mode() ? LEAP_MANA_ESCAPE : LEAP_MANA
	format(message, 255, "LEAP ENERGY [%s] ^n[%s%s]", (g_iLeapMana[id] < ManaNeed) ? "NOT READY" : "READY" , PowerUp, PowerDown)
	set_hudmessage(255, 140, 0, 0.02, 0.88, 0, 0.0, 0.5, 0.0, 0.0)
	ShowSyncHudMsg(id, g_HudJ, "%s", message)
}

public client_command(id)
{
	if(!is_user_alive(id) || !cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid)
		return PLUGIN_CONTINUE
	
	new arg[13]
	if (read_argv(0, arg, 12) > 11) return PLUGIN_CONTINUE 
	if(g_flLastSpit[id][0] <= get_gametime() && get_user_weapon(id) == CSW_KNIFE)
	{
		if(equali(arg, "drop"))
		{
			g_iSpit[id] = 5
			Spit(id)
			Stock_SetPlayerAnim(id, "shoot_knife")
			set_pdata_float(id, 83, 0.75);
			engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, "zombi/firezombi_spit1.wav", 1.0, 0.8, 0, 100);
			g_flLastSpit[id][1] = get_gametime() + 0.05;
			g_flLastSpit[id][0] = get_gametime() + 8.0;
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}
public fw_CSZB_OnPreThink(id)
{
		
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return

	new ManaNeed = cs_zb_is_escape_mode() ? LEAP_MANA_ESCAPE : LEAP_MANA
		
	if(g_iSpit[id] > 0 && g_flLastSpit[id][1] <= get_gametime())
	{
		g_iSpit[id] --
		Spit(id)
		g_flLastSpit[id][1] = get_gametime() + 0.05;
	}
	
	if(g_flLastLeap[1][id] <= get_gametime())
	{
		g_iLeapMana[id] = min(LEAP_MAXMANA, g_iLeapMana[id] + LEAP_RECHARGERATE)
		g_flLastLeap[1][id] = get_gametime() + LEAP_RECHARGEINTERVAL
	}
		
	if (!(pev(id, pev_button) & (IN_JUMP | IN_DUCK) == (IN_JUMP | IN_DUCK)))
			return;
		
	static Float:velocity[3]
	pev(id, pev_velocity, velocity);
	
	if (!(pev(id, pev_flags) & FL_ONGROUND) || vector_length(velocity) < 80.0 || g_flLastLeap[0][id] > get_gametime() || g_iLeapMana[id] < ManaNeed)
		return;
		
	g_flLastLeap[0][id] = get_gametime() + LEAP_INTERVAL
	g_flLastLeap[1][id] = get_gametime() + LEAP_INTERVAL
	g_iLeapMana[id] = max(0, g_iLeapMana[id] - ManaNeed)
		
	engfunc(EngFunc_EmitSound, id, CHAN_VOICE, "zombi/firezombi_leap.wav", 1.0, 0.8, 0, 100);
	
	if(!(pev(id, pev_oldbuttons) & IN_FORWARD))
		Stock_SetNewVelocity(LEAP_SPEED+200.0, velocity, velocity)
	else velocity_by_aim(id, floatround(LEAP_SPEED), velocity)
	velocity[2] = 320.0
	set_pev(id, pev_velocity, velocity)
	
}
public fw_CmdStart(id, uc_handle, seed)
{
	if(!cs_zb_is_zombie(id) || cs_zb_get_zombie_class(id) != g_Classid || !is_user_alive(id))
		return
		
	static CurButton;CurButton = get_uc(uc_handle, UC_Buttons)
	new Float:flHp, Float:flMaxHp; flMaxHp = float(cs_zb_get_user_maxhealth(id))
	pev(id, pev_health, flHp);
		
	if(CurButton & IN_USE)
	{
		if(g_flFlameDelay[0][id] <= get_gametime() && g_iFlame[id] > 0)
		{
			g_iFlame[id] --
			g_flFlameDelay[0][id] = get_gametime() + 0.065;
			
			MakeFlame(id)
		}
		
		g_flFlameDelay[1][id]= get_gametime() + 5.0;
	} else {
		if(g_flFlameDelay[1][id] <= get_gametime() && g_iFlame[id] < FLAME_MAX)
		{
			g_iFlame[id] ++
			g_flFlameDelay[1][id] = get_gametime() + 0.5;
		}
	}
	if(CurButton & IN_RELOAD && g_flLastHeal[id] <= get_gametime() && flHp < flMaxHp * 0.8)
	{
		set_pev(id, pev_health, floatmin(flMaxHp, flHp + (flMaxHp * 0.25)));
		play_sound(id, "zombi/smallmedkit1.wav");
		ZHealEffect(id)
		
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
		
		g_flLastHeal[id] = get_gametime() + 10.0
	}
	if(is_user_bot(id) && find_closes_enemy(id))
	{
		if(g_flFlameDelay[0][id] <= get_gametime() && g_iFlame[id] > 0 && random(20) > 14)
		{
			g_iFlame[id] --
			g_flFlameDelay[0][id] = get_gametime() + 0.065;
			
			MakeFlame(id)
		}
		
		g_flFlameDelay[1][id]= get_gametime() + random_float(5.0, 15.0);
	}
}
public MakeFlame(id)
{
	new iEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(iEnt)) return
	
	static Float:vfAngle[3], Float:MyOrigin[3], Float:pVelocity[3]
	static Float:Origin[3], Float:Velocity[3]

	get_position(id, 20.0, 0.0, -2.0, Origin)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(10)
	write_byte(200)
	write_byte(140)
	write_byte(0)
	write_byte(4)
	write_byte(2)
	message_end()
	
	pev(id, pev_angles, vfAngle)
	pev(id, pev_origin, MyOrigin)
	pev(id, pev_velocity, pVelocity);
	vfAngle[2] = float(random(18) * 20)

	// set info for ent
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	set_pev(iEnt, pev_rendermode, kRenderTransAdd)
	set_pev(iEnt, pev_renderamt, 160.0)
	set_pev(iEnt, pev_scale, 0.25)
	set_pev(iEnt, pev_nextthink, get_gametime())
	
	g_flFlameTime[iEnt] = get_gametime() + 1.1
	set_pev(iEnt, pev_classname, "zombie_flame")
	engfunc(EngFunc_SetModel, iEnt, g_sFlame)
	set_pev(iEnt, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(iEnt, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(iEnt, pev_origin, Origin)
	set_pev(iEnt, pev_gravity, 0.01)
	set_pev(iEnt, pev_angles, vfAngle)
	set_pev(iEnt, pev_solid, SOLID_TRIGGER)
	set_pev(iEnt, pev_owner, id)	
	set_pev(iEnt, pev_frame, 0.0)
	
	vfAngle[0] = vfAngle[1] = 0.0
	vfAngle[2] = random_float(-200.0, 200.0)
	set_pev(iEnt, pev_avelocity, vfAngle);

	velocity_by_aim(id, 450, Velocity);
	xs_vec_add(Velocity, pVelocity, Velocity);
	set_pev(iEnt, pev_velocity, Velocity)
	
	engfunc(EngFunc_EmitSound, id, CHAN_WEAPON, szFlameSound, 1.0, 0.8, 0, 100);
}

public fw_Fire_Think(iEnt)
{
	if(!pev_valid(iEnt)) 
		return
		
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, sizeof(szClassname))
	if(!equal(szClassname, "zombie_flame")) return
	
	static Float:fFrame, Float:fScale
	pev(iEnt, pev_frame, fFrame)
	pev(iEnt, pev_scale, fScale)
	set_pev(iEnt, pev_renderamt, floatmin(160.0, floatmax(0.0, (g_flFlameTime[iEnt]-get_gametime())*160.0)))
	
	// effect exp
	if(pev(iEnt, pev_movetype) == MOVETYPE_NONE)
	{
		fFrame += 1.0
		fScale += 0.1
		fScale = floatmin(fScale, 1.75)

		if(fFrame > 21.0)
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}
		
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.025)
	} else {
		fFrame += 1.25
		fFrame = floatmin(21.0, fFrame)
		fScale += 0.15
		fScale = floatmin(fScale, 1.75)
		
		set_pev(iEnt, pev_nextthink, get_gametime() + 0.05)
	}

	
	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_scale, fScale)
	
	// time remove
	if (get_gametime() >= g_flFlameTime[iEnt])
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return;
	}
}

public fw_Fire_Touch(ent, id)
{
	if(!pev_valid(ent))
		return
	new szClassname[32]
	pev(ent, pev_classname, szClassname, sizeof(szClassname))
	if(!equal(szClassname, "zombie_flame") || id==pev(ent, pev_owner)) return
	
	static Float:origin[3];
	pev(ent, pev_origin, origin)
	Stock_CreateSmoke(origin, g_sModelindexSmoke, random_num(15, 25), random_num(15, 25));
	
	if(pev_valid(id))
	{
		static Classname2[32]
		pev(id, pev_classname, Classname2, sizeof(Classname2))
		
		if(pev(id, pev_takedamage) <= 0.0) return;
		
		if(equal(Classname2, "zombie_flame")) return
		else if(is_user_alive(id) && !cs_zb_is_zombie(id))
			ExecuteHamB(Ham_TakeDamage, id, ent, pev(ent, pev_owner), float(FLAME_DAMAGE), DMG_BURN)
		else if(!is_user_connected(id)) ExecuteHamB(Ham_TakeDamage, id, ent, ent, float(FLAME_DAMAGE), DMG_BULLET)
	}
		
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_solid, SOLID_NOT)
}
public Spit(id)
{
	new pEnt, Float:vOrigin[3], Float:vAngle[3], Float:pVelocity[3], Float:vVelocity[3];
	pev(id, pev_origin, vOrigin);
	
	pEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(pEnt, pev_origin, vOrigin);
	set_pev(pEnt, pev_classname, "firezombi_spit")
	engfunc(EngFunc_SetModel, pEnt, g_sSpit);
	set_pev(pEnt, pev_owner, id);
	set_pev(pEnt, pev_movetype, 6);
	set_pev(pEnt, pev_solid, SOLID_BBOX);
	set_pev(pEnt, pev_rendermode, kRenderTransAdd);
	set_pev(pEnt, pev_renderamt, 255.0);
	set_pev(pEnt, pev_mins, Float:{-1.0, -1.0, -1.0}, Float:{1.0, 1.0, 1.0})
		
	velocity_by_aim(id, 1400, vVelocity);
	pev(id, pev_velocity, pVelocity);
	
	vVelocity[0] += random_float(-80.0, 80.0);
	vVelocity[1] += random_float(-80.0, 80.0);
	vVelocity[2] += 170.0;
	xs_vec_add(vVelocity, pVelocity, vVelocity);
	set_pev(pEnt, pev_velocity, vVelocity);
	vector_to_angle(vVelocity, vAngle);
	set_pev(pEnt, pev_angles, vAngle);
		
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(pEnt)
	write_short(engfunc(EngFunc_ModelIndex, "sprites/laserbeam.spr"))
	write_byte(2)
	write_byte(1)
	write_byte(100)
	write_byte(255)
	write_byte(100)
	write_byte(255)
	message_end()
		
	set_pev(pEnt, pev_nextthink, get_gametime())
	
}
public SpitThink(Ent)
{
	if(!isSpit(Ent)) return;
	
	new Float:vVelocity[3], Float:vAngle[3];
	pev(Ent, pev_velocity, vVelocity);
	vector_to_angle(vVelocity, vAngle)
	set_pev(Ent, pev_angles, vAngle);
	
	set_pev(Ent, pev_nextthink, get_gametime()+0.01)
}
public SpitImpact(Ent, Id)
{
	if(!isSpit(Ent)) return;
	
	new Float:vOrigin[3], pevAttacker = pev(Ent, pev_owner);
	pev(Ent, pev_origin, vOrigin);
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_short(engfunc(EngFunc_ModelIndex, "sprites/spr_boomer.spr"))
	write_byte(random(4)+3)
	write_byte(30)
	write_byte(14)
	message_end()
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(104)
	engfunc(EngFunc_WriteCoord, vOrigin[0])
	engfunc(EngFunc_WriteCoord, vOrigin[1])
	engfunc(EngFunc_WriteCoord, vOrigin[2])
	write_byte(engfunc(EngFunc_DecalIndex, "{spit1"))
	write_short(pev_valid(Id) ? Id : 0)
	message_end()
	
	engfunc(EngFunc_EmitAmbientSound, 0, vOrigin, "zombi/firezombi_splat1.wav", 1.0, 0.8, 0, 100);
	DoRadiusDamage(pevAttacker, Ent, vOrigin, 170.0, 120.0);
	
	engfunc(EngFunc_RemoveEntity, Ent)
}
stock DoRadiusDamage(pevAttacker, pevInflictor, Float:vOrigin[3], Float:flMaxDamage, Float:flRadius)
{
	new Float:flDist, Float:flDamage, Float:pOrigin[3], pEnt = -1
	while((pEnt = engfunc(EngFunc_FindEntityInSphere, pEnt, vOrigin, flRadius)) != 0)
	{
		if(!pev_valid(pEnt) || pEnt == pevAttacker) continue;
		
		pev(pEnt, pev_origin, pOrigin);
		flDist = vector_distance(pOrigin, vOrigin)
		flDamage = flMaxDamage - floatmul(flMaxDamage, floatdiv(flDist, flRadius));
		
		if(!isClearLine(pOrigin, vOrigin)) flDamage *= 0.3;
		if(flDamage <= 0.0 && isBreakable(pEnt))
			flDamage = floatdiv(flMaxDamage, 2.0)
		
		if(flDamage > 0.0 && pev(pEnt, pev_health) > 0.0) ExecuteHamB(Ham_TakeDamage, pEnt, pevInflictor, pevAttacker, flDamage, isBreakable(pEnt) ? DMG_BLAST : DMG_CLUB)
	}
}
stock isSpit(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if (equal(szClassname, "firezombi_spit")) return 1;
	return 0;
}
stock isBreakable(iEnt)
{
	if (!pev_valid(iEnt)) return 0;
	
	new szClassname[32]
	pev(iEnt, pev_classname, szClassname, charsmax(szClassname))
	if(pev(iEnt, pev_spawnflags) & SF_BREAK_TRIGGER_ONLY) return 0;
	
	if (equal(szClassname, "func_breakable") || equal(szClassname, "func_pushable")) return 1;
	return 0;
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
stock Stock_SetNewVelocity(Float:flNewSpeed, Float:vecVelocity[3], Float:vecOut[3])
{
	static Float:vecVelocityCN[3], Float:flY, Float:flX
	vecVelocityCN = vecVelocity
	flY = xs_vec_dot(vecVelocityCN, vecVelocityCN);

	if(flY) flX = floatsqroot(flNewSpeed*flNewSpeed / flY)
	xs_vec_mul_scalar(vecVelocityCN, flX, vecVelocityCN);

	if(flNewSpeed<0.0) xs_vec_mul_scalar(vecVelocityCN, -1.0, vecVelocityCN)
	vecOut = vecVelocityCN
	
	return 1
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	xs_vec_sub(origin2, origin1, new_velocity)
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	xs_vec_mul_scalar(new_velocity, num, new_velocity)
	
	return 1;
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
stock Stock_CreateSmoke(Float:vecOrigin[3], iSprites, iSize, iFrame)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(5)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2])
	write_short(iSprites)
	write_byte(iSize)
	write_byte(iFrame)
	message_end()
}
stock isClearLine(Float:vOrigin1[3], Float:vOrigin2[3])
{
	new Float:flFraction;
	engfunc(EngFunc_TraceLine, vOrigin1, vOrigin2, IGNORE_MONSTERS|IGNORE_GLASS, 0, 0);
	get_tr2(0, TR_flFraction, flFraction)
	
	if (flFraction < 1.0) return 0;

	return 1;
}
stock play_sound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}

stock Stock_SetPlayerAnim(id, const AnimName[], Float:rate=1.0)
{
	static AnimNum, Float:FrameRate, Float:GroundSpeed, bool:Loops, Anim2[64]
	if(!(pev(id, pev_flags) & FL_DUCKING)) format(Anim2, 63, "ref_%s", AnimName)
	else format(Anim2, 63, "crouch_%s", AnimName)

	if ((AnimNum=lookup_sequence(id,Anim2,FrameRate,Loops,GroundSpeed))==-1) AnimNum=0
	
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
stock find_closes_enemy(ent)
{
	new enemy, Float:dist, Float:distmin, Float:origin[3], Float:originT[3]
	pev(ent, pev_origin, origin)
	
	for(new target = 0; target<get_maxplayers(); target++)
	{
		if (!is_user_alive(target) || get_user_team(ent) == get_user_team(target)) continue;
		
		pev(target, pev_origin, originT)
		dist = get_distance_f(origin, originT)
		if ((!distmin || dist <= distmin) && dist <= 350.0 && isClearLine(origin, originT))
		{
			distmin = dist
			enemy = target
		}
	}
	return enemy
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
