#if defined _csm_included
    #endinput
#endif

#define _csm_included

#if AMXX_VERSION_NUM >= 175
    #pragma reqlib csm
    #if !defined AMXMODX_NOAUTOLOAD
        #pragma loadlib csm
    #endif
#else
    #pragma library csm
#endif

#define CS_CMD_CONTINUE	0
#define CS_CMD_BLOCK	1

native cs_register_custom_item(const szName[], iCost, iSlot, const szHandler[], const szSysName[]);
native cs_set_user_exp(id, iAmount)
native cs_get_user_exp(id)
native cs_set_user_level(id, NewLevel)
native cs_get_user_level(id)
native cs_get_custom_itemid(const szName[])
native cs_force_buy_custom_item(id, itemid, check, admin)
native cs_remove_item(id, itemid, slot)
native cs_set_data_wpn(id, cswpnid, const newname[])
native cs_reset_data_wpn(id, cswpnid)
native cs_show_custom_ammo(id, cswpnid, show, const szName[])
native cs_set_custom_ammo(id, cswpnid, amount)
native cs_weapon_is_attacking(id)
native cs_weapon_set_attacking(id, attack)
native cs_is_round_freeze()
native cs_set_block_dgrenade(id, block)
native cs_get_user_dgrenade(id, type)
native cs_give_user_dgrenade(id, type)
native cs_get_user_dgrenade_mode(id, type)
native cs_give_item(id, const szItem[])
native cs_get_custom_item_slot(itemid)
native cs_get_current_wpndata(id, szString[], len)
native cs_forward_weapon_touch(Enable)
native cs_set_ammo_display(id, wpnid, active, bpammo)
native cs_user_has_weapon(id, szWpn[])
native cs_set_user_step(index, iDisable)
native cs_is_map_param(index)
native cs_misc_add_menuitem(const szTitle[], const szCmd[])
native cs_vgui_ffa_mode(enable)
native cs_set_custom_potrait(id, const szPotrait[])

forward fw_CSHUD(id)
forward fw_CSPlayer_Kill(victim, attacker)
forward fw_CSPlayer_Spawn(id)
forward fw_Remove_Item(id, itemid, slot)
forward fw_CSClient_Command(id, const szCmd[])
forward fw_CSNew_Round()
forward fw_CSRoundStart()
forward fw_CSWpn_Touch(id, iWpnid)
forward fw_WpnInspect(iEnt, id)

native cs_user_firebullets3( id, Float:source[3], Float:dirShooting[3], Float:spread, Float:distance, penetration, bulletType, damage, Float:rangerModifier, attacker, bool:isPistol, sharedRand )
native cs_user_firebullets( id, cShots, Float:vecSrc[3],  Float:vecDirShooting[3], Float:vecSpread[3], Float:flDistance, iBulletType, iTracerFreq, iDamage, pevAttacker) 
