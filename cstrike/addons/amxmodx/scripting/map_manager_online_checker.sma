#include <amxmodx>
#include <map_manager>
#include <map_manager_scheduler>

#define PLUGIN "Map Manager: Online checker"
#define VERSION "1.0.0"
#define AUTHOR "Sergey Shorokhov"

#pragma semicolon 1

#define get_num(%0) get_pcvar_num(g_pCvars[%0])
#define get_float(%0) get_pcvar_float(g_pCvars[%0])

enum Cvars {
    CHECK_INTERVAL,
    CHECKS_COUNT,
    CHECK_TIMEOUT
};

new g_sPrefix[48];
new g_pCvars[Cvars];

new g_CurrentMap[MapStruct];
new g_Warnings;

public plugin_init() {
    register_plugin(PLUGIN, VERSION + VERSION_HASH, AUTHOR);

    g_pCvars[CHECK_INTERVAL] = register_cvar("mapm_online_check_interval", "30");
    g_pCvars[CHECKS_COUNT] = register_cvar("mapm_online_check_count", "3");
    g_pCvars[CHECK_TIMEOUT] = register_cvar("mapm_online_check_timeout", "120");

    set_task(get_float(CHECK_INTERVAL), "task_check_online", .flags = "b");
}

public plugin_cfg() {
    mapm_get_prefix(g_sPrefix, charsmax(g_sPrefix));
}

public task_check_online() {
    new current_online = get_players_num();
    if(current_online != 0 && get_float(CHECK_TIMEOUT) > get_gametime()) {
        return;
    }

    new bool: is_online_incorrect = (current_online < g_CurrentMap[MinPlayers] || current_online > g_CurrentMap[MaxPlayers]);

    g_Warnings = clamp(is_online_incorrect ? ++g_Warnings : --g_Warnings, 0, get_num(CHECKS_COUNT));
    if(g_Warnings != get_num(CHECKS_COUNT)) {
        return;
    }

    client_print_color(0, print_team_default, "%s^1 %L", g_sPrefix, LANG_PLAYER, "MAPM_RTV_START_VOTE");

    const VOTE_BY_INCORRECT_ONLINE = 1337;
    map_scheduler_start_vote(VOTE_BY_INCORRECT_ONLINE);
}

public mapm_maplist_loaded(Array: maplist, const nextmap[]) {
    get_mapname(g_CurrentMap[Map], charsmax(g_CurrentMap[Map]));

    new map_info[MapStruct];
    for(new i, size = ArraySize(maplist); i < size; i++) {
        ArrayGetArray(maplist, i, map_info);

        if(strcmp(g_CurrentMap[Map], map_info[Map]) != 0)
            continue;

        g_CurrentMap[MinPlayers] = map_info[MinPlayers];
        g_CurrentMap[MaxPlayers] = map_info[MaxPlayers];

        return;
    }

    set_fail_state("Map '%s' not found in 'maps.ini'", g_CurrentMap[Map]);
}

public mapm_can_be_extended(type) {
    if(g_Warnings == get_num(CHECKS_COUNT)) {
        return EXTEND_BLOCKED;
    }

    return EXTEND_ALLOWED;
}
