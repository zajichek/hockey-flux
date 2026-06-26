# Creates the game model bundle
source(file = "events/game_events.R")
source(file = "transitions/game_transition.R")
source(file = "stops/game_stop.R")
source(file = "observations/game_observe.R")
game_bundle <-
  function() {
    list(
      time_spec = time_spec(unit = "seconds"),
      propose_events = game_events,
      transition = game_transition,
      stop = game_stop,
      observe = game_observe
    )
  }
