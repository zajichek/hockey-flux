# Transition the states throughout the game
game_transition <-
  function(entity, event) {
    if (event$event_type == "period_end" && entity$snapshot()$period == 3) {
      return(list(game_status = "final"))
    }
    list(game_time_elapsed = entity$last_time)
  }
