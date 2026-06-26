# Generative goal process based on game situation
goal_event <-
  function(entity) {
    list(
      time_next = entity$last_time + rexp(1, rate = 6 / 3600),
      event_type = sample(
        x = c("goal_home", "goal_away"),
        size = 1,
        prob = c(.52, .48)
      )
    )
  }
