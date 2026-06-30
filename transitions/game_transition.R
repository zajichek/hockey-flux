# Transition the states throughout the game
game_transition <-
  function(entity, event) {
    s <- entity$snapshot()

    if (event$event_type == "puck_drop") {
      return(list(
        game_status = "in_progress",
        game_time_elapsed = s$game_time_elapsed,
        play_active = TRUE
      ))
    }

    game_time_elapsed <- s$game_time_elapsed +
      (event$time_next - entity$last_time)

    if (event$event_type == "goal_home") {
      return(list(
        game_status =
          if (game_time_elapsed > 3600) "final" else s$game_status,
        game_time_elapsed = game_time_elapsed,
        home_score = s$home_score + 1,
        play_active = FALSE
      ))
    }

    if (event$event_type == "goal_away") {
      return(list(
        game_status =
          if (game_time_elapsed > 3600) "final" else s$game_status,
        game_time_elapsed = game_time_elapsed,
        away_score = s$away_score + 1,
        play_active = FALSE
      ))
    }

    if (event$event_type %in% c("icing", "offsides", "penalty", "injury")) {
      return(list(
        game_time_elapsed = game_time_elapsed,
        play_active = FALSE
      ))
    }

    if (event$event_type == "period_end") {
      game_time_elapsed <- s$period * 1200

      return(if (s$period == 3 && s$home_score != s$away_score) {
        list(
          game_status = "final",
          game_time_elapsed = game_time_elapsed,
          play_active = FALSE
        )
      } else {
        list(
          game_status = "intermission",
          game_time_elapsed = game_time_elapsed,
          play_active = FALSE
        )
      })
    }

    list(game_time_elapsed = game_time_elapsed)
  }
