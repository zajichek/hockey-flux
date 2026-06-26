# Defines the event process proposals for games
source(file = "events/games/goal_event.R")
source(file = "events/games/period_event.R")
source(file = "events/games/whistle_event.R")
game_events <-
  function(entity) {
    list(
      goal = goal_event(entity),
      period = period_event(entity),
      whistle = whistle_event(entity)
    )
  }
