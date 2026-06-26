# Load package
library(fluxCore)

# 1. Make game schema
game_schema <-
  set_schema(
    vars = list(
      HomeTeamScore = "count",
      AwayTeamScore = "count"
    )
  )

derived_vars <-
  list(
    period = function(entity, j, t) {
      # Check game time (in seconds)
      if (t < 20 * 60) {
        1
      } else if (t < 40 * 60) {
        2
      } else if (t < 60 * 60) {
        3
      }
    },
    clock = function(entity, j, t) {
      # Game clock (only 20 minutes per period)
    }
  )

# Stop when game is over
stop <- function(entity, event) entity$last_time >= 3600
