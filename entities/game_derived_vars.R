# Defines derived game schema states
game_derived_vars <-
  function() {
    list(
      # Period the game is in
      period = function(entity, j, t) {
        floor(entity$current$game_time_elapsed / 1200) + 1
      },

      # Time elapsed in the period
      period_time_elapsed = function(entity, j, t) {
        entity$current$game_time_elapsed %% 1200
      },

      # Time remaining in the period
      period_time_remaining = function(entity, j, t) {
        1200 - (entity$current$game_time_elapsed %% 1200)
      },

      # Time left on the game clock
      game_clock = function(entity, j, t) {
        # Extract period time remaining (in seconds)
        period_time_remaining <- 1200 -
          (entity$current$game_time_elapsed %% 1200)
        period_time_remaining <- floor(period_time_remaining)

        # Format as time
        sprintf(
          "%02d:%02d",
          period_time_remaining %/% 60,
          period_time_remaining %% 60
        )
      },

      # Is the game in overtime?
      in_overtime = function(entity, j, t) {
        (floor(entity$current$game_time_elapsed / 1200) + 1) >= 4
      }
    )
  }
