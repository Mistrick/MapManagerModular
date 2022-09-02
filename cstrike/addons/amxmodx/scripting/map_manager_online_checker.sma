#include <amxmodx>
#include <amxmisc>
#include <map_manager>
#include <map_manager_scheduler>

new g_Prefix[48];
new g_CurrentMap[MapStruct];
new g_Warnings;

new Float: mapm_online_check_interval, mapm_online_check_count,
    Float: mapm_online_check_timeout;

public stock const PluginName[] = "Map Manager: Online checker";
public stock const PluginVersion[] = "1.0.0";
public stock const PluginAuthor[] = "Sergey Shorokhov";

public plugin_init() {
  register_plugin(PluginName, PluginVersion, PluginAuthor);

  bind_pcvar_float(
    create_cvar("mapm_online_check_interval", "30.0"),
    mapm_online_check_interval
  );

  bind_pcvar_num(
    create_cvar("mapm_online_check_count", "3"),
    mapm_online_check_count
  );

  bind_pcvar_float(
    create_cvar("mapm_online_check_timeout", "120.0"),
    mapm_online_check_timeout
  );

  mapm_get_prefix(g_Prefix, charsmax(g_Prefix));

  set_task_ex(mapm_online_check_interval, "OnlineCheck", .flags = SetTask_Repeat);
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

public OnlineCheck() {
  new current_online = get_playersnum_ex(GetPlayers_ExcludeBots | GetPlayers_ExcludeHLTV | GetPlayers_IncludeConnecting);
  if(current_online != 0 && mapm_online_check_timeout > get_gametime()) {
    return;
  }

  new bool: IsOnlineIncorrect = (current_online < g_CurrentMap[MinPlayers] || current_online > g_CurrentMap[MaxPlayers]);

  g_Warnings = clamp(IsOnlineIncorrect ? ++g_Warnings : --g_Warnings, 0, mapm_online_check_count);
  if(g_Warnings != mapm_online_check_count) {
    return;
  }

  client_print_color(0, print_team_default, "%s\1 %L", g_Prefix, LANG_PLAYER, "MAPM_RTV_START_VOTE");


  const VOTE_BY_INCORRECT_ONLINE = 1337;
  map_scheduler_start_vote(VOTE_BY_INCORRECT_ONLINE);
}

public mapm_can_be_extended(type) {
  if(g_Warnings == mapm_online_check_count) {
    return EXTEND_BLOCKED;
  }

  return EXTEND_ALLOWED;
}
