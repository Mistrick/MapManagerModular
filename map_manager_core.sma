#include <amxmodx>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Map Manager: Core"
#define VERSION "0.0.1"
#define AUTHOR "Mistrick"

#pragma semicolon 1

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_cvar("mapm_version", VERSION, FCVAR_SERVER | FCVAR_SPONLY);
}

public plugin_natives()
{
	register_library("map_manager_core");

    register_native("mapm_start_vote", "native_start_vote");
    register_native("mapm_stop_vote", "native_stop_vote");
}

public native_start_vote(plugin, params)
{
    // TODO: call start vote func
}
public native_stop_vote(plugin, params)
{
    // TODO: call stop vote func
}