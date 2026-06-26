# Retrieve observations about the game throughout simulation
game_observe <-
  function(entity, event) {
    # Extract a snapshot of the entity
    s <- entity$snapshot()
    tibble::tibble(
      time = entity$last_time,
      event = event$event_type
    ) |>
      dplyr::bind_cols(
        dplyr::bind_cols(s)
      )
  }
