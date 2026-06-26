# Instantiate a game
source(file = "schemas/game_schema.R")
source(file = "entities/game_derived_vars.R")
game_init <-
  function(game_id, location, home_team, away_team) {
    Entity$new(
      entity_type = "game",
      id = game_id,
      schema = game_schema(),
      init = list(
        location = location,
        home_team = home_team,
        away_team = away_team
      ),
      derived_vars = game_derived_vars(),
      time0 = 0
    )
  }
