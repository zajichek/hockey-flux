library(testthat)

source(test_path("..", "events", "games", "goal_event.R"))

strength_entity <- function(home_skaters, away_skaters, last_time = 0) {
  list(
    last_time = last_time,
    current = list(
      home_skaters_on_ice = home_skaters,
      away_skaters_on_ice = away_skaters
    )
  )
}

test_that("all even-strength states use the baseline goal hazards", {
  five_on_five <- goal_rates(strength_entity(5, 5))
  four_on_four <- goal_rates(strength_entity(4, 4))
  three_on_three <- goal_rates(strength_entity(3, 3))

  expect_equal(five_on_five, four_on_four)
  expect_equal(five_on_five, three_on_three)
  expect_equal(sum(five_on_five), 6 / 3600)
  expect_equal(
    five_on_five,
    c(goal_home = 6 / 3600 * 0.52, goal_away = 6 / 3600 * 0.48)
  )
})

test_that("a home power play doubles only the home scoring hazard", {
  even <- goal_rates(strength_entity(5, 5))
  home_power_play <- goal_rates(strength_entity(5, 4))

  expect_equal(
    home_power_play[["goal_home"]],
    2 * even[["goal_home"]]
  )
  expect_equal(
    home_power_play[["goal_away"]],
    even[["goal_away"]]
  )
  expect_gt(sum(home_power_play), sum(even))
})

test_that("an away power play doubles only the away scoring hazard", {
  even <- goal_rates(strength_entity(5, 5))
  away_power_play <- goal_rates(strength_entity(4, 5))

  expect_equal(
    away_power_play[["goal_away"]],
    2 * even[["goal_away"]]
  )
  expect_equal(
    away_power_play[["goal_home"]],
    even[["goal_home"]]
  )
  expect_gt(sum(away_power_play), sum(even))
})

test_that("two-skater advantages use the same power-play multiplier", {
  expect_equal(
    goal_rates(strength_entity(5, 3)),
    goal_rates(strength_entity(5, 4))
  )
  expect_equal(
    goal_rates(strength_entity(3, 5)),
    goal_rates(strength_entity(4, 5))
  )
})

test_that("goal proposals expose the hazards used by the process", {
  set.seed(1)
  entity <- strength_entity(5, 4, last_time = 100)
  rates <- goal_rates(entity)
  proposal <- goal_event(entity)

  expect_gt(proposal$time_next, entity$last_time)
  expect_true(proposal$event_type %in% names(rates))
  expect_equal(proposal$home_goal_rate, unname(rates[["goal_home"]]))
  expect_equal(proposal$away_goal_rate, unname(rates[["goal_away"]]))
})
