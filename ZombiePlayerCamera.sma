
#include <amxmodx>
#include <amxmisc> 
#include <hamsandwich>
#include <engine>
#include <fakemeta>
#include <xs>

new g_view_ent[33];
new g_view_type[33];

public plugin_init()
{
	register_plugin("Player Camera", "1.0", "Martin");
	register_concmd("camera_menu", "show_menu_camera");
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink_Post", 1);
}

public plugin_natives()
{
	register_native("cs_zb_get_user_thirdperson", "native_get_tps", 1)
}
public native_get_tps(id)
{
	if(!is_user_alive(id) || !is_user_connected(id)) return 0;
	
	return g_view_type[id];
}
public client_connect(id)
{
	if (pev_valid(g_view_ent[id]))
	{
		engfunc(EngFunc_RemoveEntity, g_view_ent[id]);
	}
	g_view_ent[id] = 0;
	g_view_type[id] = 0;
	return 0;
}

public fw_PlayerPostThink_Post(id)
{
	if (!is_user_alive(id))return 0;
	if (!g_view_type[id])return 0;
	if (!pev_valid(g_view_ent[id]))return 0;

	static Float:makevectors[3];
	static Float:punchangle[3];
	static Float:v_angle[3];
	pev(id, pev_v_angle, v_angle);
	pev(id, pev_punchangle, punchangle);
	xs_vec_add(v_angle, punchangle, makevectors);
	engfunc(EngFunc_MakeVectors, makevectors);
	static Float:vecSrc[3];
	static Float:viewofs[3];
	static Float:origin[3];
	pev(id, pev_origin, origin);
	pev(id, pev_view_ofs, viewofs);
	xs_vec_add(origin, viewofs, vecSrc);
	static Float:vecAiming[3];
	global_get(glb_v_forward, vecAiming);
	static tr;
	switch (g_view_type[id])
	{
		case 1:
		{
			static Float:vecResult[3];
			xs_vec_mul_scalar(vecAiming, 128.00, vecAiming);
			xs_vec_sub(vecSrc, vecAiming, vecResult);
			engfunc(EngFunc_TraceLine, vecSrc, vecResult, 1, id, tr);
			new Float:ret[3];
			get_tr2(tr, TR_vecEndPos, ret);
			set_pev(g_view_ent[id], pev_origin, ret);
			static Float:angles[3];
			pev(id, pev_v_angle, angles);
			set_pev(g_view_ent[id], pev_angles, angles);
			engfunc(EngFunc_SetView, id, g_view_ent[id]);
		}
		case 2:
		{
			static Float:vecUp[3];
			static Float:vecRight[3];
			static Float:vecResult[3];
			global_get(glb_v_up, vecUp);
			global_get(glb_v_right, vecRight);
			xs_vec_mul_scalar(vecUp, 15.00, vecUp);
			xs_vec_mul_scalar(vecRight, 15.00, vecRight);
			xs_vec_add(vecUp, vecRight, vecUp);
			xs_vec_mul_scalar(vecAiming, 32.00, vecAiming);
			xs_vec_sub(vecAiming, vecUp, vecAiming);
			xs_vec_sub(vecSrc, vecAiming, vecResult);
			engfunc(EngFunc_TraceLine, vecSrc, vecResult, 1, id, tr);
			new Float:ret[3];
			get_tr2(tr, TR_vecEndPos, ret);
			set_pev(g_view_ent[id], pev_origin, ret);
			static Float:angles[3];
			pev(id, pev_v_angle, angles);
			set_pev(g_view_ent[id], pev_angles, angles);
			engfunc(EngFunc_SetView, id, g_view_ent[id]);
		}
		case 3:
		{
			new Float:vecAdd[3];
			vecAdd[0] = 740.0;
			xs_vec_add(vecSrc, vecAdd, vecAdd);
			engfunc(EngFunc_TraceLine, vecSrc, vecAdd, 1, id, tr);
			new Float:ret[3];
			get_tr2(tr, TR_vecEndPos, ret);
			ret[2] -= 40.00;
			set_pev(g_view_ent[id], pev_origin, ret);
			static Float:angles[3];
			pev(id, pev_v_angle, angles);
			angles[0] = 90.00/*1119092736*/;
			angles[2] = 0.0;
			set_pev(g_view_ent[id], pev_angles, angles);
			engfunc(EngFunc_SetView, id, g_view_ent[id]);
		}
	}
	return 0;
}

public show_menu_camera(id)
{
	static menuid;
	menuid = menu_create("Player Camera", "menu_camera", 0);
	menu_additem(menuid, "Normal 3rd Person", "", 0, -1);
	menu_additem(menuid, "Top Right 3rd Person", "", 0, -1);
	menu_additem(menuid, "Top Down", "", 0, -1);
	menu_additem(menuid, "First Person", "", 0, -1);
	
	set_pdata_int(id, 205, 0, 4)
	menu_display(id, menuid, 0);
	return 0;
}
	
public menu_camera(id, menuid, item)
{
	if (item == -3)
	{
		menu_destroy(menuid);
		return 1;
	}
	if (!is_user_alive(id))
	{
		menu_destroy(menuid);
		return 1;
	}
	switch (item)
	{
		case 0:fm_set_view(id, 1);
		case 1:fm_set_view(id, 2);
		case 2:fm_set_view(id, 3);
		case 3:fm_set_view(id, 0);
	}
	menu_destroy(menuid);
	return 1;
}

stock fm_set_view(id, type)
{
	if (!type)
	{
		engfunc(EngFunc_SetView, id, id);
		if (pev_valid(g_view_ent[id]))engfunc(EngFunc_RemoveEntity, g_view_ent[id]);
		
		g_view_type[id] = 0;
		g_view_ent[id] = 0;
		set_pev(id, pev_rendermode, 0);
		set_pev(id, pev_renderamt, 0);
		return 1;
	}
	if (g_view_type[id] == type) return 0;
	
	g_view_type[id] = type;
	if (pev_valid(g_view_ent[id])) engfunc(EngFunc_RemoveEntity, g_view_ent[id]);

	new camera = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"));
	set_pev(camera, pev_classname, "camera");
	engfunc(EngFunc_SetModel, camera, "models/w_hegrenade.mdl");
	set_pev(camera, pev_movetype, 8);
	set_pev(camera, pev_owner, id);
	set_pev(camera, pev_rendermode, 1);
	set_pev(camera, pev_renderamt, 0);
	engfunc(EngFunc_SetView, id, camera);
	g_view_ent[id] = camera;
	return 1;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1057\\ f0\\ fs16 \n\\ par }
*/
