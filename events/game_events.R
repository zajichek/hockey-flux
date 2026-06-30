# Defines the event process proposals for games
source(file = "events/games/goal_event.R")
source(file = "events/games/period_event.R")
source(file = "events/games/puck_drop_event.R")
source(file = "events/games/whistle_event.R")
game_events <-
  function(entity) {
    if (
      entity$current$game_status %in% c("scheduled", "intermission") ||
        (
          entity$current$game_status == "in_progress" &&
            !entity$current$play_active
        )
    ) {
      return(list(puck_drop = puck_drop_event(entity)))
    }

    if (
      entity$current$game_status == "in_progress" &&
        entity$current$play_active
    ) {
      return(list(
        goal = goal_event(entity),
        period = period_event(entity),
        whistle = whistle_event(entity)
      ))
    }

    list()
  }
