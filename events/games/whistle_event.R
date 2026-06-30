# Generative whistle process (icing, offsides, penalty, injury)
whistle_event <-
  function(entity) {
    event <- list(
      time_next = entity$last_time + rexp(1, rate = 50 / 3600),
      event_type = sample(
        x = c("icing", "offsides", "penalty", "injury"),
        size = 1,
        prob = c(.30, .50, .15, .05)
      )
    )

    if (event$event_type == "penalty") {
      eligible_teams <- character()

      if (
        entity$current$home_skaters_on_ice > 3 &&
          (
            is.na(entity$current$home_penalty_1_expires) ||
              is.na(entity$current$home_penalty_2_expires)
          )
      ) {
        eligible_teams <- c(eligible_teams, "home")
      }

      if (
        entity$current$away_skaters_on_ice > 3 &&
          (
            is.na(entity$current$away_penalty_1_expires) ||
              is.na(entity$current$away_penalty_2_expires)
          )
      ) {
        eligible_teams <- c(eligible_teams, "away")
      }

      if (length(eligible_teams) == 0) {
        event$event_type <- sample(
          c("icing", "offsides", "injury"),
          size = 1,
          prob = c(.30, .50, .05)
        )
      } else {
        event$penalized_team <- sample(eligible_teams, size = 1)
      }
    }

    event
  }
