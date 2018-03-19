#include <amxmodx>
#include <map_manager>

#if AMXX_VERSION_NUM < 183
#include <colorchat>
#endif

#define PLUGIN "Map Manager: Rtv"
#define VERSION "0.0.1"
#define AUTHOR "Mistrick"

#pragma semicolon 1

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say rtv", "ClCmd_Rtv");
	register_clcmd("say /rtv", "ClCmd_Rtv");
}

public ClCmd_Rtv(id)
{
	// TODO: rtv logic
	//if()
	{
		mapm_start_vote();
	}
}