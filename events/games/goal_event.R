# Generative goal process based on game situation
goal_rates <-
  function(
    entity,
    base_goal_rate = 6 / 3600,
    home_goal_share = 0.52,
    power_play_multiplier = 2
  ) {
    rates <- c(
      goal_home = base_goal_rate * home_goal_share,
      goal_away = base_goal_rate * (1 - home_goal_share)
    )

    if (
      entity$current$home_skaters_on_ice >
        entity$current$away_skaters_on_ice
    ) {
      rates[["goal_home"]] <-
        rates[["goal_home"]] * power_play_multiplier
    } else if (
      entity$current$away_skaters_on_ice >
        entity$current$home_skaters_on_ice
    ) {
      rates[["goal_away"]] <-
        rates[["goal_away"]] * power_play_multiplier
    }

    rates
  }

goal_event <-
  function(entity) {
    rates <- goal_rates(entity)

    list(
      time_next = entity$last_time + rexp(1, rate = sum(rates)),
      event_type = sample(
        x = names(rates),
        size = 1,
        prob = rates
      ),
      home_goal_rate = unname(rates[["goal_home"]]),
      away_goal_rate = unname(rates[["goal_away"]])
    )
  }
