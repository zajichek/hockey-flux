# Deterministic event that starts a scheduled game
puck_drop_event <-
  function(entity) {
    can_drop_puck <-
      entity$current$game_status %in% c("scheduled", "intermission") ||
      (
        entity$current$game_status == "in_progress" &&
          !entity$current$play_active
      )

    if (!can_drop_puck) {
      return(NULL)
    }

    time_next <- if (entity$current$game_status == "scheduled") {
      entity$last_time
    } else if (entity$current$game_status == "intermission") {
      entity$last_time + runif(1, min = 15 * 60, max = 20 * 60)
    } else {
      entity$last_time + runif(1, min = 30, max = 2 * 60)
    }

    list(
      time_next = time_next,
      event_type = "puck_drop"
    )
  }
