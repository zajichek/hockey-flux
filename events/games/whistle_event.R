# Generative whistle process (icing, offsides, penalty, injury)
whistle_event <-
  function(entity) {
    list(
      time_next = entity$last_time + rexp(1, rate = 50 / 3600),
      event_type = sample(
        x = c("icing", "offsides", "penalty", "injury"),
        size = 1,
        prob = c(.30, .50, .15, .05)
      )
    )
  }
