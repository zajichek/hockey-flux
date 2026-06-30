# Transition the states throughout the game
game_transition <-
  function(entity, event) {
    s <- entity$snapshot()

    if (event$event_type == "goal_home") {
      return(list(
        game_status = if (event$time_next > 3600) "final" else s$game_status,
        game_time_elapsed = event$time_next,
        home_score = s$home_score + 1
      ))
    }

    if (event$event_type == "goal_away") {
      return(list(
        game_status = if (event$time_next > 3600) "final" else s$game_status,
        game_time_elapsed = event$time_next,
        away_score = s$away_score + 1
      ))
    }

    if (event$event_type == "period_end" && entity$snapshot()$period == 3) {
      return(if (s$home_score == s$away_score) {
        list(game_time_elapsed = event$time_next)
      } else {
        list(
          game_status = "final",
          game_time_elapsed = event$time_next
        )
      })
    }

    list(game_time_elapsed = event$time_next)
  }
