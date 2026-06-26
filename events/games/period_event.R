# Deterministic period-ending process
period_event <-
  function(entity) {
    list(
      time_next = entity$last_time +
        (1200 - (entity$current$game_time_elapsed %% 1200)),
      event_type = "period_end"
    )
  }
