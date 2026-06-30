# Deterministic expiration processes for active two-minute minor penalties
penalty_expiration_events <-
  function(entity) {
    penalty_slots <- c(
      home_penalty_1 = entity$current$home_penalty_1_expires,
      home_penalty_2 = entity$current$home_penalty_2_expires,
      away_penalty_1 = entity$current$away_penalty_1_expires,
      away_penalty_2 = entity$current$away_penalty_2_expires
    )
    active_slots <- penalty_slots[!is.na(penalty_slots)]

    lapply(names(active_slots), function(process_id) {
      list(
        time_next = entity$last_time +
          max(0, active_slots[[process_id]] -
            entity$current$game_time_elapsed),
        event_type = paste0("penalty_expired_", process_id)
      )
    }) |>
      stats::setNames(names(active_slots))
  }
