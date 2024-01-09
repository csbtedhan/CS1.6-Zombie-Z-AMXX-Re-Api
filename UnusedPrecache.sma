#include <amxmodx> 
#include <cstrike> 
#include <fakemeta> 

new const g_Sounds[][] = 
{ 
	"weapons/c4_beep1.wav", 
	"weapons/c4_beep2.wav", 
	"weapons/c4_beep3.wav", 
	"weapons/c4_beep4.wav", 
	"weapons/c4_beep5.wav", 
	"weapons/c4_explode1.wav", 
	"weapons/c4_plant.wav", 
	"weapons/c4_disarm.wav", 
	"weapons/c4_click.wav", 
	"weapons/c4_disarmed.wav", 
	"items/equip_nvg.wav",
	"weapons/p228-1.wav",
	"weapons/p228_clipin.wav",
	"weapons/p228_clipout.wav",
	"weapons/p228_slidepull.wav",
	"weapons/p228_sliderelease.wav",
	"weapons/pinpull.wav",
	"weapons/scout_fire-1.wav",
	"weapons/scout_bolt.wav",
	"weapons/scout_clipin.wav",
	"weapons/scout_clipout.wav",
	"weapons/sg550_clipout.wav",
	"weapons/sg550_boltpull.wav",
	"weapons/sg550_clipin.wav",
	"weapons/sg550_clipout.wav",
	"weapons/aug_boltpull.wav",
	"weapons/aug_boltslap.wav",
	"weapons/aug_forearm.wav",
	"weapons/aug_clipin.wav",
	"weapons/aug_clipout.wav",
	"weapons/p90_boltpull.wav",
	"weapons/p90_clipin.wav",
	"weapons/p90_clipout.wav",
	"weapons/p90_cliprelease.wav",
	"weapons/pinpull.wav",
	"weapons/fiveseven-1.wav",
	"weapons/fiveseven-2.wav",
	"weapons/fiveseven_clipin.wav",
	"weapons/fiveseven_clipout.wav",
	"weapons/fiveseven_slidepull.wav",
	"weapons/fiveseven_sliderelease.wav",
	"weapons/g3sg1_clipin.wav",
	"weapons/g3sg1_clipout.wav",
	"weapons/g3sg1_slide.wav",
	"weapons/sg552_boltpull.wav",
	"weapons/sg552_clipin.wav",
	"weapons/sg552_clipout.wav",
	"weapons/galil_boltpull.wav",
	"weapons/galil_clipin.wav",
	"weapons/galil_clipout.wav",
	"weapons/galil-1.wav",
	"weapons/galil-2.wav",
	"weapons/awp_clipin.wav",
	"weapons/awp_clipout.wav",
	"weapons/awp_deploy.wav",
	"weapons/tmp-1.wav",
	"weapons/tmp_clipin.wav",
	"weapons/tmp_clipout.wav",
	"weapons/flashbang-1.wav",
	"weapons/flashbang-2.wav",
	"weapons/hegrenade-1.wav",
	"weapons/hegrenade-2.wav",
	"weapons/famas-1.wav",
	"weapons/famas-2.wav",
	"weapons/famas-burst.wav",
	"weapons/famas_boltpull.wav",
	"weapons/famas_boltslap.wav",
	"weapons/famas_clipin.wav",
	"weapons/famas_clipout.wav",
	"weapons/famas_forearm.wav",
	"weapons/mac10-1.wav",
	"weapons/mac10_boltpull.wav",
	"weapons/mac10_clipin.wav",
	"weapons/mac10_clipout.wav",
	"weapons/ump45-1.wav",
	"weapons/ump45_boltslap.wav",
	"weapons/ump45_clipin.wav",
	"weapons/ump45_clipout.wav",
	"weapons/elite_reloadstart.wav",
	"weapons/elite_leftclipin.wav",
	"weapons/elite_clipout.wav",
	"weapons/elite_sliderelease.wav",
	"weapons/elite_rightclipin.wav",
	"weapons/elite_deploy.wav",
	"weapons/elite_fire.wav",
	"weapons/m249_boxout.wav",
	"weapons/m249_boxin.wav",
	"weapons/m249_chain.wav",
	"weapons/m249_coverup.wav",
	"weapons/m249_coverdown.wav",
	"weapons/m4a1_clipin.wav",
	"weapons/m4a1_clipout.wav",
	"weapons/m4a1_boltpull.wav",
	"weapons/m4a1_deploy.wav",
	"weapons/m4a1_silencer_on.wav",
	"weapons/m4a1_silencer_off.wav",
	"weapons/usp_clipout.wav",
	"weapons/usp_clipin.wav",
	"weapons/usp_silencer_on.wav",
	"weapons/usp_silencer_off.wav",
	"weapons/usp_sliderelease.wav",
	"weapons/usp_slideback.wav",
	"weapons/mp5_slideback.wav",
	"weapons/mp5_clipin.wav",
	"weapons/mp5_clipout.wav",
	"weapons/de_clipout.wav",
	"weapons/de_clipin.wav",
	"weapons/de_deploy.wav",
	"weapons/ak47_clipout.wav",
	"weapons/ak47_clipin.wav",
	"weapons/ak47_boltpull.wav",
	"weapons/g3sg1_slide.wav",
	"weapons/g3sg1_clipin.wav",
	"weapons/g3sg1_clipout.wav",
	"weapons/m3_pump.wav",
	"weapons/m3_insertshell.wav",
	"weapons/generic_reload.wav",
	"items/weapondrop1.wav",
	"radio/blow.wav",
	"radio/bombdef.wav",
	"radio/bombpl.wav",
	"radio/circleback.wav",
	"radio/clear.wav",
	"radio/com_followcom.wav",
	"radio/com_getinpos.wav",
	"radio/com_go.wav",
	"radio/com_reportin.wav",
	"radio/ct_affirm.wav",
	"radio/ct_backup.wav",
	"radio/ct_coverme.wav",
	"radio/ct_enemys.wav",
	"radio/ct_fireinhole.wav",
	"radio/ct_imhit.wav",
	"radio/ct_inpos.wav",
	"radio/ct_point.wav",
	"radio/ct_reportingin.wav",
	"radio/ctwin.wav",
	"radio/elim.wav",
	"radio/enemydown.wav",
	"radio/fallback.wav",
	"radio/fireassis.wav",
	"radio/flankthem.wav",
	"radio/followme.wav",
	"radio/getout.wav",
	"radio/hitassist.wav",
	"radio/hosdown.wav",
	"radio/letsgo.wav",
	"radio/locknload.wav",
	"radio/matedown.wav",
	"radio/meetme.wav",
	"radio/moveout.wav",
	"radio/negative.wav",
	"radio/position.wav",
	"radio/regroup.wav",
	"radio/rescued.wav",
	"radio/roger.wav",
	"radio/rounddraw.wav",
	"radio/sticktog.wav",
	"radio/stormfront.wav",
	"radio/takepoint.wav",
	"radio/takepoint.wav",
	"radio/terwin.wav",
	"radio/vip.wav",
	"hostage/hos1.wav",
	"hostage/hos2.wav",
	"hostage/hos3.wav",
	"hostage/hos4.wav",
	"hostage/hos5.wav",
	"hostage/hos1.wav",
	"items/tr_kevlar.wav",
	"player/breathe1.wav",
	"player/breathe2.wav",
	"player/pl_fallpain1.wav",
	"player/pl_fallpain2.wav",
	"player/pl_fallpain3.wav",
	"player/gasp1.wav",
	"player/gasp2.wav",
	"player/death6.wav",
	"player/die1.wav",
	"player/die2.wav",
	"player/die3.wav",
	"player/bhit_flesh-1.wav",
	"player/bhit_flesh-2.wav",
	"player/bhit_flesh-3.wav",
	"player/pl_die1.wav",
	"player/pl_shot1.wav",
	"player/pl_pain2.wav",	
	"player/pl_pain3.wav",
	"player/pl_pain4.wav",
	"player/pl_pain5.wav",
	"player/pl_pain6.wav",
	"player/pl_pain7.wav",
	"player/geiger1.wav",	
	"player/geiger2.wav",
	"player/geiger3.wav",
	"player/geiger4.wav",
	"player/geiger5.wav",
	"player/geiger6.wav",
	"common/bodydrop1.wav",
	"common/bodydrop2.wav",
	"common/bodydrop3.wav",
	"common/bodydrop4.wav",
	"common/npc_step1.wav",
	"common/npc_step2.wav",
	"common/npc_step3.wav",
	"common/npc_step4.wav",
	"common/wpn_select.wav",
	"common/wpn_hudon.wav",
	"common/wpn_hudoff.wav",
	"common/wpn_denyselect.wav",
	"common/wpn_moveselect.wav",
	"debris/flesh1.wav",
	"debris/flesh2.wav",
	"debris/flesh3.wav",
	"debris/flesh4.wav",
	"debris/flesh5.wav",
	"debris/flesh6.wav",
	"debris/flesh7.wav",
	"events/tutor_msg.wav",
	"events/enemy_died.wav",
	"events/friend_died.wav",
	"events/task_complete.wav",
	"items/tr_kevlar.wav",
	"plats/train_use1.wav",
	"plats/vehicle_ignition.wav",
	"items/ammopickup2.wav",
	"buttons/bell1.wav",
	"buttons/blip1.wav",
	"buttons/blip2.wav",
	"buttons/button11.wav",
	"buttons/latchunlocked2.wav",
	"ambience/quail1.wav",
	"items/suitchargeok1.wav",
	"common/bodydrop3.wav",
	"common/bodydrop4.wav"
} 
new const g_Models[][] = 
{ 
	"models/v_c4.mdl",
	"models/p_c4.mdl",
	"models/w_c4.mdl",
	"models/shield/p_shield_deagle.mdl",
	"models/shield/p_shield_fiveseven.mdl",
	"models/shield/p_shield_flashbang.mdl",
	"models/shield/p_shield_glock18.mdl",
	"models/shield/p_shield_hegrenade.mdl",
	"models/shield/p_shield_p228.mdl",
	"models/shield/p_shield_smokegrenade.mdl",
	"models/shield/p_shield_usp.mdl",
	"models/shield/v_shield_deagle.mdl",
	"models/shield/v_shield_fiveseven.mdl",
	"models/shield/v_shield_flashbang.mdl",
	"models/shield/v_shield_glock18.mdl",
	"models/shield/v_shield_hegrenade.mdl",
	"models/shield/v_shield_p228.mdl",
	"models/shield/v_shield_smokegrenade.mdl",
	"models/shield/v_shield_usp.mdl",
	"models/shield/v_shield_knife.mdl",
	"models/v_shield.mdl",
	"models/p_shield.mdl",
	"models/w_shield.mdl",
	"models/v_shield_r.mdl",
	"models/p_shield_r.mdl",
	"models/w_shield_r.mdl",
	"models/w_backpack.mdl",
	"models/w_thighpack.mdl",
	"models/w_antidote.mdl",
	"models/w_security.mdl",
	"models/agibs.mdl",
	
	"models/hostage01.mdl",
	"models/hostage02.mdl",
	"models/hostage03.mdl",
	"models/hostage04.mdl",
	"models/hostage05.mdl",
	"models/hostage06.mdl",
	"models/hostage07.mdl",
	"models/hostage08.mdl",
	"models/player/vip/vip.mdl",
	"sprites/b-tele.spr",
	"sprites/c-tele.spr",
	"sprites/ic4.spr",
	"sprites/c4.spr",
	"sprites/ic4.spr",
	"sprites/ihostage.spr",
	"sprites/iplayerc4.spr",
	"sprites/iplayervip.spr",
	"sprites/ibackpack.spr",
	"sprites/explode1.spr",
	
	"models/p_ump45.mdl",
	"models/v_ump45.mdl",
	"models/w_ump45.mdl",
	"models/p_tmp.mdl",
	"models/v_tmp.mdl",
	"models/w_tmp.mdl",
	"models/p_mac10.mdl",
	"models/v_mac10.mdl",
	"models/w_mac10.mdl",
	"models/p_p228.mdl",
	"models/v_p228.mdl",
	"models/w_p228.mdl",
	"models/p_fiveseven.mdl",
	"models/v_fiveseven.mdl",
	"models/w_fiveseven.mdl",
	"models/p_scout.mdl",
	"models/v_scout.mdl",
	"models/w_scout.mdl",
	"models/p_famas.mdl",
	"models/v_famas.mdl",
	"models/w_famas.mdl",
	"models/v_famas_r.mdl",
	"models/p_galil.mdl",
	"models/v_galil.mdl",
	"models/w_galil.mdl",
	"models/v_galil_r.mdl",
	"models/p_elite.mdl",
	"models/v_elite.mdl",
	"models/w_elite.mdl"
}
new const g_Generic[][] = 
{ 
	"sprites\weapon_awp.txt",
	"sprites\weapon_c4.txt",
	"sprites\weapon_elite.txt",
	"sprites\weapon_famas.txt",
	"sprites\weapon_fiveseven.txt",
	"sprites\weapon_flashbang.txt",
	"sprites\weapon_g3sg1.txt",
	"sprites\weapon_galil.txt",
	"sprites\weapon_mac10.txt",
	"sprites\weapon_p228.txt",
	"sprites\weapon_p90.txt",
	"sprites\weapon_scout.txt",
	"sprites\weapon_sg552.txt",
	"sprites\weapon_shield.txt",
	"sprites\weapon_shieldgun.txt",
	"sprites\weapon_smokegrenade.txt",
	"sprites\weapon_tmp.txt",
	"sprites\weapon_ump45.txt",
	"sprites\weapon_xm1014.txt",
	"sprites\weapon_ak47.txt",
	"sprites\weapon_m4a1.txt",
	"sprites\weapon_aug.txt",
	"sprites\weapon_m249.txt",
	"sprites\weapon_g3sg1.txt",
	"sprites\weapon_sg550.txt",
	"sprites\weapon_deagle.txt",
	"sprites\weapon_usp.txt",
	"sprites\weapon_glock18.txt",
	"sprites\weapon_m3.txt",
	"sprites\scope_arc.tga",
	"sprites\scope_arc_nw.tga",
	"sprites\scope_arc_ne.tga",
	"sprites\scope_arc_sw.tga",
	"gfx\vgui\ak47.tga",
	"gfx\vgui\aug.tga",
	"gfx\vgui\awp.tga",
	"gfx\vgui\defuser.tga",
	"gfx\vgui\deserteagle.tga",
	"gfx\vgui\elites.tga",
	"gfx\vgui\famas.tga",
	"gfx\vgui\fiveseven.tga",
	"gfx\vgui\flashbang.tga",
	"gfx\vgui\g3sg1.tga",
	"gfx\vgui\galil.tga",
	"gfx\vgui\gign.tga",
	"gfx\vgui\glock18.tga",
	"gfx\vgui\hegrenade.tga",
	"gfx\vgui\kevlar.tga",
	"gfx\vgui\kevlar_helmet.tga",
	"gfx\vgui\leet.tga",
	"gfx\vgui\m249.tga",
	"gfx\vgui\m3.tga",
	"gfx\vgui\m4a1.tga",
	"gfx\vgui\mac10.tga",
	"gfx\vgui\mp5.tga",
	"gfx\vgui\nightvision.tga",
	"gfx\vgui\not_available.tga",
	"gfx\vgui\p228.tga",
	"gfx\vgui\p90.tga",
	"gfx\vgui\sas.tga",
	"gfx\vgui\scout.tga",
	"gfx\vgui\sg550.tga",
	"gfx\vgui\sg552.tga",
	"gfx\vgui\shield.tga",
	"gfx\vgui\smokegrenade.tga",
	"gfx\vgui\tmp.tga",
	"gfx\vgui\ump45.tga",
	"gfx\vgui\urban.tga",
	"gfx\vgui\usp45.tga",
	"gfx\vgui\vip.tga",
	"gfx\vgui\xm1014.tga"
}
public plugin_precache() 
{ 
	register_forward(FM_PrecacheModel, "PrecacheModel") 
	register_forward(FM_PrecacheGeneric, "PrecacheGeneric") 
	register_forward(FM_PrecacheSound, "PrecacheSound") 
} 
public PrecacheModel(const szModel[]) 
{ 
	for(new i = 0; i < sizeof(g_Models); i++) 
	{ 
		if(containi(szModel, g_Models[i]) != -1 ) 
		{ 
			forward_return(FMV_CELL, 0) 
			return FMRES_SUPERCEDE 
		} 
	} 
	return FMRES_IGNORED 
} 

public PrecacheSound(const szSound[]) 
{ 
	if (equal(szSound, "hostage", 7))
		return FMRES_SUPERCEDE;
		
	for(new i = 0; i < sizeof(g_Sounds); i++) 
	{ 
		if(containi(szSound, g_Sounds[i]) != -1 ) 
		{ 
			forward_return(FMV_CELL, 0) 
			return FMRES_SUPERCEDE 
		} 
	} 
	return FMRES_IGNORED 
}
public PrecacheGeneric(const szGeneric[]) 
{ 
	for(new i = 0; i < sizeof(g_Generic); i++) 
	{ 
		if(containi(szGeneric, g_Generic[i]) != -1 ) 
		{ 
			forward_return(FMV_CELL, 0) 
			return FMRES_SUPERCEDE 
		} 
	} 
	return FMRES_IGNORED 
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/