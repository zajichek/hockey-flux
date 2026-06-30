library(testthat)
library(fluxCore)

test_directory <- getwd()
setwd(test_path(".."))
source("entities/game_init.R")
source("bundles/game_bundle.R")
setwd(test_directory)

test_that("puck drop starts a scheduled game", {
  set.seed(1)
  game <- game_init(1, "Simulation", "Home", "Away")
  result <- Engine$new(bundle = game_bundle())$run(game, max_events = 1)
  puck_drop <- subset(result$events, event_type == "puck_drop")

  expect_equal(nrow(puck_drop), 1)
  expect_equal(puck_drop$time[[1]], 0)
  expect_equal(game$current$game_status, "in_progress")
  expect_equal(game$current$game_time_elapsed, 0)
  expect_true(game$current$play_active)
})

test_that("period end enters intermission before the next puck drop", {
  set.seed(2)
  game <- game_init(2, "Simulation", "Home", "Away")
  engine <- Engine$new(bundle = game_bundle())

  engine$run(game, max_events = 1)
  game$update(
    time = 1200,
    event_type = "period_end",
    changes = list(
      game_status = "intermission",
      game_time_elapsed = 1200
    )
  )

  proposals <- game_events(game)

  expect_equal(names(proposals), "puck_drop")
  intermission_length <- proposals$puck_drop$time_next - 1200
  expect_gte(intermission_length, 15 * 60)
  expect_lte(intermission_length, 20 * 60)
})

test_that("period-start puck drop begins the next period", {
  set.seed(3)
  game <- game_init(3, "Simulation", "Home", "Away")
  game$update(
    time = 1200,
    event_type = "period_end",
    changes = list(
      game_status = "intermission",
      game_time_elapsed = 1200
    )
  )

  result <- Engine$new(bundle = game_bundle())$run(game, max_events = 1)
  puck_drop <- tail(result$events, 1)
  final <- game$snapshot()

  expect_equal(puck_drop$event_type[[1]], "puck_drop")
  expect_gte(puck_drop$time[[1]] - 1200, 15 * 60)
  expect_lte(puck_drop$time[[1]] - 1200, 20 * 60)
  expect_equal(final$game_time_elapsed, 1200)
  expect_equal(final$game_status, "in_progress")
  expect_true(final$play_active)
  expect_equal(final$period, 2)
  expect_equal(final$game_clock, "20:00")
})

test_that("a tied regulation game starts overtime with a puck drop", {
  set.seed(4)
  game <- game_init(4, "Simulation", "Home", "Away")
  game$update(
    time = 3600,
    event_type = "period_end",
    changes = list(
      game_status = "intermission",
      game_time_elapsed = 3600,
      home_score = 2,
      away_score = 2
    )
  )

  result <- Engine$new(bundle = game_bundle())$run(game, max_events = 1)
  final <- game$snapshot()

  expect_equal(tail(result$events$event_type, 1), "puck_drop")
  expect_gte(game$last_time - 3600, 15 * 60)
  expect_lte(game$last_time - 3600, 20 * 60)
  expect_equal(final$game_time_elapsed, 3600)
  expect_equal(final$game_status, "in_progress")
  expect_true(final$play_active)
  expect_equal(final$period, 4)
  expect_true(final$in_overtime)
})

test_that("final games do not propose another puck drop", {
  game <- game_init(5, "Simulation", "Home", "Away")
  game$update(
    time = 3600,
    event_type = "period_end",
    changes = list(
      game_status = "final",
      game_time_elapsed = 3600,
      home_score = 3,
      away_score = 2
    )
  )

  expect_length(game_events(game), 0)
})

test_that("a whistle stops play until a short-delay puck drop", {
  set.seed(6)
  game <- game_init(6, "Simulation", "Home", "Away")
  engine <- Engine$new(bundle = game_bundle())
  engine$run(game, max_events = 1)

  whistle <- list(event_type = "icing", time_next = 42)
  changes <- game_transition(game, whistle)
  game$update(
    time = whistle$time_next,
    event_type = whistle$event_type,
    changes = changes
  )

  expect_equal(game$current$game_status, "in_progress")
  expect_false(game$current$play_active)
  expect_equal(game$current$game_time_elapsed, 42)

  proposals <- game_events(game)
  expect_equal(names(proposals), "puck_drop")
  stoppage_length <- proposals$puck_drop$time_next - game$last_time
  expect_gte(stoppage_length, 30)
  expect_lte(stoppage_length, 120)

  restart <- proposals$puck_drop
  restart_changes <- game_transition(game, restart)
  game$update(
    time = restart$time_next,
    event_type = restart$event_type,
    changes = restart_changes
  )

  expect_true(game$current$play_active)
  expect_equal(game$current$game_status, "in_progress")
  expect_equal(game$current$game_time_elapsed, 42)
})

test_that("a regulation goal stops play and updates the score", {
  set.seed(7)
  game <- game_init(7, "Simulation", "Home", "Away")
  Engine$new(bundle = game_bundle())$run(game, max_events = 1)

  goal <- list(event_type = "goal_home", time_next = 25)
  changes <- game_transition(game, goal)
  game$update(
    time = goal$time_next,
    event_type = goal$event_type,
    changes = changes
  )

  expect_equal(game$current$home_score, 1)
  expect_equal(game$current$game_status, "in_progress")
  expect_false(game$current$play_active)
  expect_equal(names(game_events(game)), "puck_drop")
})

test_that("an overtime goal finalizes inactive play without a restart", {
  game <- game_init(8, "Simulation", "Home", "Away")
  game$update(
    time = 5000,
    event_type = "puck_drop",
    changes = list(
      game_status = "in_progress",
      game_time_elapsed = 3600,
      play_active = TRUE,
      home_score = 2,
      away_score = 2
    )
  )

  goal <- list(event_type = "goal_away", time_next = 5010)
  changes <- game_transition(game, goal)
  game$update(
    time = goal$time_next,
    event_type = goal$event_type,
    changes = changes
  )

  expect_equal(game$current$away_score, 3)
  expect_equal(game$current$game_status, "final")
  expect_false(game$current$play_active)
  expect_length(game_events(game), 0)
})
