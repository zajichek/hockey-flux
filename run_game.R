## Run a game simulation
library(fluxCore)

# Create a game entity
source(file = "entities/game_init.R")
game <- game_init(1, "WI", "COL", "FLA")

# Create an engine
source(file = "bundles/game_bundle.R")
eng <- Engine$new(bundle = game_bundle())

# Run a game through the engine
out <- eng$run(game, return_observations = TRUE)
