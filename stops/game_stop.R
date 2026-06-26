# Criteria for stopping the game
game_stop <-
  function(entity, event) {
    entity$current$game_status == "final"
  }
