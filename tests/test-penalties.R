library(testthat)
library(fluxCore)

test_directory <- getwd()
setwd(test_path(".."))
source("entities/game_init.R")
source("bundles/game_bundle.R")
setwd(test_directory)

apply_event <- function(game, event) {
  changes <- game_transition(game, event)
  game$update(
    time = event$time_next,
    event_type = event$event_type,
    changes = changes
  )
  invisible(changes)
}

start_test_game <- function(id = 1) {
  game <- game_init(id, "Simulation", "Home", "Away")
  Engine$new(bundle = game_bundle())$run(game, max_events = 1)
  game
}

test_that("games begin at five-on-five with empty penalty slots", {
  game <- start_test_game()

  expect_equal(game$current$home_skaters_on_ice, 5)
  expect_equal(game$current$away_skaters_on_ice, 5)
  expect_true(is.na(game$current$home_penalty_1_expires))
  expect_true(is.na(game$current$home_penalty_2_expires))
  expect_true(is.na(game$current$away_penalty_1_expires))
  expect_true(is.na(game$current$away_penalty_2_expires))
})

test_that("a penalty fills a slot and reduces skater strength", {
  game <- start_test_game()
  apply_event(
    game,
    list(
      event_type = "penalty",
      time_next = 30,
      penalized_team = "home"
    )
  )

  expect_equal(game$current$home_skaters_on_ice, 4)
  expect_equal(game$current$away_skaters_on_ice, 5)
  expect_equal(game$current$home_penalty_1_expires, 150)
  expect_true(is.na(game$current$home_penalty_2_expires))
  expect_false(game$current$play_active)
})

test_that("penalty expiration uses active game time and restores a skater", {
  game <- start_test_game()
  apply_event(
    game,
    list(
      event_type = "penalty",
      time_next = 30,
      penalized_team = "home"
    )
  )

  apply_event(
    game,
    list(event_type = "puck_drop", time_next = 90)
  )
  proposals <- game_events(game)

  expect_equal(proposals$home_penalty_1$time_next, 210)

  apply_event(game, proposals$home_penalty_1)

  expect_equal(game$current$game_time_elapsed, 150)
  expect_equal(game$current$home_skaters_on_ice, 5)
  expect_true(is.na(game$current$home_penalty_1_expires))
  expect_true(game$current$play_active)
})

test_that("two penalty slots allow strength to fall no lower than three", {
  game <- start_test_game()
  apply_event(
    game,
    list(
      event_type = "penalty",
      time_next = 10,
      penalized_team = "home"
    )
  )
  apply_event(game, list(event_type = "puck_drop", time_next = 50))
  apply_event(
    game,
    list(
      event_type = "penalty",
      time_next = 60,
      penalized_team = "home"
    )
  )

  expect_equal(game$current$home_skaters_on_ice, 3)
  expect_equal(game$current$home_penalty_1_expires, 130)
  expect_equal(game$current$home_penalty_2_expires, 140)
})

test_that("penalties persist through period end and intermission", {
  game <- start_test_game()
  game$update(
    time = 1000,
    event_type = "test_setup",
    changes = list(game_time_elapsed = 1150)
  )
  apply_event(
    game,
    list(
      event_type = "penalty",
      time_next = 1010,
      penalized_team = "away"
    )
  )
  apply_event(game, list(event_type = "puck_drop", time_next = 1060))
  apply_event(game, list(event_type = "period_end", time_next = 1100))

  expect_equal(game$current$game_time_elapsed, 1200)
  expect_equal(game$current$away_penalty_1_expires, 1280)
  expect_equal(game$current$away_skaters_on_ice, 4)
  expect_equal(game$current$game_status, "intermission")

  apply_event(game, list(event_type = "puck_drop", time_next = 2100))
  proposals <- game_events(game)

  expect_equal(proposals$away_penalty_1$time_next, 2180)
})

test_that("an opposing power-play goal releases the earliest minor", {
  game <- start_test_game()
  game$update(
    time = 100,
    event_type = "test_setup",
    changes = list(
      game_time_elapsed = 100,
      away_skaters_on_ice = 4,
      away_penalty_1_expires = 220
    )
  )

  apply_event(game, list(event_type = "goal_home", time_next = 110))

  expect_equal(game$current$home_score, 1)
  expect_equal(game$current$away_skaters_on_ice, 5)
  expect_true(is.na(game$current$away_penalty_1_expires))
})

test_that("an equal-strength goal does not release a minor", {
  game <- start_test_game()
  game$update(
    time = 100,
    event_type = "test_setup",
    changes = list(
      game_time_elapsed = 100,
      home_skaters_on_ice = 4,
      away_skaters_on_ice = 4,
      home_penalty_1_expires = 220,
      away_penalty_1_expires = 225
    )
  )

  apply_event(game, list(event_type = "goal_home", time_next = 110))

  expect_equal(game$current$away_skaters_on_ice, 4)
  expect_equal(game$current$away_penalty_1_expires, 225)
})
