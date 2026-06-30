# Defines derived game schema states
game_derived_vars <-
  function() {
    period_at_time <- function(game_time_elapsed) {
      max(1, ceiling(game_time_elapsed / 1200))
    }

    period_time_at_time <- function(game_time_elapsed) {
      period <- period_at_time(game_time_elapsed)
      game_time_elapsed - ((period - 1) * 1200)
    }

    list(
      # Period the game is in
      period = function(entity, j, t) {
        period_at_time(entity$current$game_time_elapsed)
      },

      # Time elapsed in the period
      period_time_elapsed = function(entity, j, t) {
        period_time_at_time(entity$current$game_time_elapsed)
      },

      # Time remaining in the period
      period_time_remaining = function(entity, j, t) {
        1200 - period_time_at_time(entity$current$game_time_elapsed)
      },

      # Time left on the game clock
      game_clock = function(entity, j, t) {
        # Extract period time remaining (in seconds)
        period_time_remaining <- 1200 -
          period_time_at_time(entity$current$game_time_elapsed)
        period_time_remaining <- ceiling(period_time_remaining)

        # Format as time
        sprintf(
          "%02d:%02d",
          period_time_remaining %/% 60,
          period_time_remaining %% 60
        )
      },

      # Is the game in overtime?
      in_overtime = function(entity, j, t) {
        period_at_time(entity$current$game_time_elapsed) >= 4
      }
    )
  }
