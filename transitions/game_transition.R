# Transition the states throughout the game
game_transition <-
  function(entity, event) {
    s <- entity$snapshot()

    release_earliest_penalty <- function(team) {
      slot_names <- paste0(team, "_penalty_", 1:2, "_expires")
      expirations <- unlist(s[slot_names])
      active_slots <- which(!is.na(expirations))

      if (length(active_slots) == 0) {
        return(list())
      }

      slot_to_release <- active_slots[[which.min(expirations[active_slots])]]
      skater_state <- paste0(team, "_skaters_on_ice")

      stats::setNames(
        list(NA_real_, min(5, s[[skater_state]] + 1)),
        c(slot_names[[slot_to_release]], skater_state)
      )
    }

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
      changes <- list(
        game_status =
          if (game_time_elapsed > 3600) "final" else s$game_status,
        game_time_elapsed = game_time_elapsed,
        home_score = s$home_score + 1,
        play_active = FALSE
      )

      if (s$home_skaters_on_ice > s$away_skaters_on_ice) {
        changes <- c(changes, release_earliest_penalty("away"))
      }

      return(changes)
    }

    if (event$event_type == "goal_away") {
      changes <- list(
        game_status =
          if (game_time_elapsed > 3600) "final" else s$game_status,
        game_time_elapsed = game_time_elapsed,
        away_score = s$away_score + 1,
        play_active = FALSE
      )

      if (s$away_skaters_on_ice > s$home_skaters_on_ice) {
        changes <- c(changes, release_earliest_penalty("home"))
      }

      return(changes)
    }

    if (event$event_type == "penalty") {
      team <- event$penalized_team
      slot_names <- paste0(team, "_penalty_", 1:2, "_expires")
      available_slot <- which(is.na(unlist(s[slot_names])))[[1]]
      skater_state <- paste0(team, "_skaters_on_ice")

      penalty_changes <- stats::setNames(
        list(
          game_time_elapsed + 120,
          s[[skater_state]] - 1
        ),
        c(slot_names[[available_slot]], skater_state)
      )

      return(c(
        list(
          game_time_elapsed = game_time_elapsed,
          play_active = FALSE
        ),
        penalty_changes
      ))
    }

    if (startsWith(event$event_type, "penalty_expired_")) {
      penalty_id <- sub("^penalty_expired_", "", event$event_type)
      team <- sub("_penalty_[12]$", "", penalty_id)
      slot <- sub("^(home|away)_penalty_", "", penalty_id)
      slot_state <- paste0(team, "_penalty_", slot, "_expires")
      skater_state <- paste0(team, "_skaters_on_ice")

      return(stats::setNames(
        list(
          game_time_elapsed,
          NA_real_,
          min(5, s[[skater_state]] + 1)
        ),
        c("game_time_elapsed", slot_state, skater_state)
      ))
    }

    if (event$event_type %in% c("icing", "offsides", "injury")) {
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
