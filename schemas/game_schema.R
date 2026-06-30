# Defines the schema for a hockey game
game_schema <-
  function() {
    # Create the flux schema
    set_schema(
      vars = list(
        ## Game-level attributes (unchanging)

        # Where the game is being played
        location = "string",

        ## Game play attributes

        # The current status of this game (assume playoff hockey)
        game_status = list(
          type = "categorical",
          levels = c(
            "scheduled",
            "in_progress",
            "intermission",
            "final"
          ),
          default = "scheduled"
        ),

        # Elapsed hockey game time in seconds
        game_time_elapsed = list(
          type = "nonnegative_numeric",
          default = 0
        ),

        # Is play actively happening? (only can be TRUE when game_status is in_progress or overtime)
        play_active = list(type = "logical", default = FALSE),

        # Where is the puck located? (only happens during active play)
        puck_location = list(
          type = "categorical",
          levels = c("neutral", "home_offensive", "away_offensive"),
          default = NA,
          allow_na = TRUE
        ),

        ## Team information

        # Home team name
        home_team = "nonempty_string",

        # Away team name
        away_team = "nonempty_string",

        # Number of goals by the home team
        home_score = list(type = "count", default = 0),

        # Number of goals by the away team
        away_score = list(type = "count", default = 0),

        # Number of home skaters on ice
        home_skaters_on_ice = list(
          type = "positive_integer",
          default = 5,
          allow_na = TRUE
        ),

        # Number of away skaters on ice
        away_skaters_on_ice = list(
          type = "positive_integer",
          default = 5,
          allow_na = TRUE
        ),

        # Game-clock expiration times for active two-minute minor penalties
        home_penalty_1_expires = list(
          type = "nonnegative_numeric",
          default = NA,
          allow_na = TRUE
        ),

        home_penalty_2_expires = list(
          type = "nonnegative_numeric",
          default = NA,
          allow_na = TRUE
        ),

        away_penalty_1_expires = list(
          type = "nonnegative_numeric",
          default = NA,
          allow_na = TRUE
        ),

        away_penalty_2_expires = list(
          type = "nonnegative_numeric",
          default = NA,
          allow_na = TRUE
        )
      )
    )
  }
