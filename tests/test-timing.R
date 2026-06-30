# Load package
library(testthat)

# Import model components
source(test_path("..", "entities", "game_derived_vars.R"))
source(test_path("..", "events", "games", "period_event.R"))
source(test_path("..", "transitions", "game_transition.R"))
source(test_path("..", "stops", "game_stop.R"))

# Utility to extract clock calculations for points in the game
snapshot_at <- function(game_time_elapsed, game_status = "in_progress") {
  entity <- list(
    current = list(
      game_time_elapsed = game_time_elapsed,
      game_status = game_status
    )
  )

  # Extract derived variables
  derived <- game_derived_vars()

  # Compute period/game clock components
  list(
    period = derived$period(entity, NULL, game_time_elapsed),
    period_time_elapsed = derived$period_time_elapsed(
      entity,
      NULL,
      game_time_elapsed
    ),
    period_time_remaining = derived$period_time_remaining(
      entity,
      NULL,
      game_time_elapsed
    ),
    game_clock = derived$game_clock(entity, NULL, game_time_elapsed),
    in_overtime = derived$in_overtime(entity, NULL, game_time_elapsed)
  )
}

transition_entity <- function(
  period,
  home_score,
  away_score,
  game_status = "in_progress",
  in_overtime = FALSE,
  game_time_elapsed = 0,
  last_time = 0
) {
  list(
    last_time = last_time,
    snapshot = function() {
      list(
        period = period,
        home_score = home_score,
        away_score = away_score,
        game_status = game_status,
        in_overtime = in_overtime,
        game_time_elapsed = game_time_elapsed,
        home_skaters_on_ice = 5,
        away_skaters_on_ice = 5,
        home_penalty_1_expires = NA_real_,
        home_penalty_2_expires = NA_real_,
        away_penalty_1_expires = NA_real_,
        away_penalty_2_expires = NA_real_
      )
    }
  )
}

# The last second of a period is still attributed to that period
test_that("exact period boundaries belong to the period that just ended", {
  end_first <- snapshot_at(1200, "intermission")
  expect_equal(end_first$period, 1)
  expect_equal(end_first$period_time_elapsed, 1200)
  expect_equal(end_first$period_time_remaining, 0)
  expect_equal(end_first$game_clock, "00:00")

  end_regulation <- snapshot_at(3600, "final")
  expect_equal(end_regulation$period, 3)
  expect_equal(end_regulation$period_time_elapsed, 1200)
  expect_equal(end_regulation$period_time_remaining, 0)
  expect_equal(end_regulation$game_clock, "00:00")
  expect_false(end_regulation$in_overtime)
})

# The next period begins in the e.g., millisecond after the clock starts again
test_that("the next period begins immediately after its boundary", {
  epsilon <- 1e-8

  second_period <- snapshot_at(1200 + epsilon)
  expect_equal(second_period$period, 2)
  expect_equal(second_period$period_time_elapsed, epsilon, tolerance = 1e-7)
  expect_equal(second_period$game_clock, "20:00")

  overtime <- snapshot_at(3600 + epsilon)
  expect_equal(overtime$period, 4)
  expect_equal(overtime$period_time_elapsed, epsilon, tolerance = 1e-7)
  expect_equal(overtime$game_clock, "20:00")
  expect_true(overtime$in_overtime)
})

# The period end is a scheduled (deterministic) event process
test_that("period events are scheduled at 20-minute boundaries", {
  mid_period <- list(
    last_time = 1350,
    current = list(game_time_elapsed = 1350)
  )
  expect_equal(period_event(mid_period)$time_next, 2400)

  exact_boundary <- list(
    last_time = 1200,
    current = list(game_time_elapsed = 1200)
  )
  expect_equal(period_event(exact_boundary)$time_next, 2400)
})

# Ensure a game goes to over time (we're following playoff rules)
test_that("a tied game continues after regulation", {
  entity <- transition_entity(
    period = 3,
    home_score = 2,
    away_score = 2,
    game_time_elapsed = 3500,
    last_time = 5000
  )
  changes <- game_transition(
    entity,
    list(event_type = "period_end", time_next = 5100)
  )

  expect_equal(changes$game_time_elapsed, 3600)
  expect_equal(changes$game_status, "intermission")
})

# Game finalizes in regulation when the scores are not equal
test_that("a regulation lead finalizes the game at the period end", {
  entity <- transition_entity(
    period = 3,
    home_score = 3,
    away_score = 2,
    game_time_elapsed = 3500,
    last_time = 5000
  )
  changes <- game_transition(
    entity,
    list(event_type = "period_end", time_next = 5100)
  )

  expect_equal(changes$game_time_elapsed, 3600)
  expect_equal(changes$game_status, "final")
})

test_that("period ends normalize accumulated floating-point drift", {
  entity <- transition_entity(
    period = 2,
    home_score = 1,
    away_score = 1,
    game_time_elapsed = 2399.999999999,
    last_time = 4000
  )
  changes <- game_transition(
    entity,
    list(event_type = "period_end", time_next = 4000.000000001)
  )

  expect_equal(changes$game_time_elapsed, 2400)
  expect_equal(changes$game_status, "intermission")
})

# A goal event triggers the end of the game in sudden death over time
test_that("the first overtime goal finalizes the game at its event time", {
  entity <- transition_entity(
    period = 4,
    home_score = 2,
    away_score = 2,
    game_time_elapsed = 3600,
    last_time = 5500,
    in_overtime = TRUE
  )
  goal_time <- 5500 + 15.25
  changes <- game_transition(
    entity,
    list(event_type = "goal_home", time_next = goal_time)
  )

  expect_equal(changes$game_time_elapsed, 3615.25)
  expect_equal(changes$home_score, 3)
  expect_equal(changes$game_status, "final")
})

# The stopping rule is only handled by the game status being updated
test_that("the stopping rule depends only on final game status", {
  active <- list(current = list(game_status = "in_progress"))
  final <- list(current = list(game_status = "final"))

  expect_false(game_stop(active, NULL))
  expect_true(game_stop(final, NULL))
})
