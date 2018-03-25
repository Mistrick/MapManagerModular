#if defined _map_manager_scheduler_included
  #endinput
#endif
#define _map_manager_scheduler_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib map_manager_scheduler
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib map_manager_scheduler
	#endif
#else
	#pragma library map_manager_scheduler
#endif

/**
 * TODO: write this.
 * 
 * @noreturn
 */
native map_scheduler_start_vote(type);
