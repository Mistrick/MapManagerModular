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

enum IgnoreFlags (<<=1) {
    IGNORE_DISABLED = 0,
    IGNORE_TIMER_CHECK = 1 << 0,
    IGNORE_ROUND_CHECK,
    IGNORE_FRAGS_CHECK
};

enum LastRoundState {
    LRS_Not, // Not last round
    LRS_Last, // Last round, round that can be played after voting
    LRS_Final // Final round, one more round after the last one if the last one ended in a draw
}

/**
 * Get ignore flags for starting vote.
 *
 * @return                      Ignore flags
 */
native IgnoreFlags:map_scheduler_get_ignore_check();

/**
 * Set ignore flags for starting vote.
 * 
 * @param flags                 Flags from IgnoreFlags enum
 *
 * @noreturn
 */
native map_scheduler_set_ignore_check(IgnoreFlags:flags);

/**
 * Start vote by scheduler, work with own cvars.
 * 
 * @param type                  Type of vote, used const VOTE_BY_*
 *
 * @noreturn
 */
native map_scheduler_start_vote(type);

/**
 * Extend current map time.
 * 
 * @param count                 Extend time param, bonus time = count * cvarnum(extend_time)
 *
 * @noreturn
 */
native map_scheduler_extend_map(count = 1);

/**
 * Returns true if vote will in next round.
 *
 * @return                      true/false
 */
native bool:is_vote_will_in_next_round();

/**
 * Returns state of last round.
 *
 * @return                      LastRoundState value
 */
native LastRoundState:get_last_round_state();

/**
 * Returns true if one map mode active.
 *
 * @return                      true/false
 */
native bool:is_one_map_mode();
