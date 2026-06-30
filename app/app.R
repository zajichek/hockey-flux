library(shiny)
library(fluxCore)

# The model files currently use paths relative to the project root.
app_directory <- getwd()
project_root <- normalizePath(file.path(app_directory, ".."))
setwd(project_root)
source("entities/game_init.R")
source("bundles/game_bundle.R")
setwd(app_directory)

simulate_games <- function(n_games, seed) {
  set.seed(seed)
  engine <- Engine$new(bundle = game_bundle())
  games <- vector("list", n_games)
  events <- vector("list", n_games)

  for (game_id in seq_len(n_games)) {
    game <- game_init(
      game_id = game_id,
      location = "Simulation",
      home_team = "Home",
      away_team = "Away"
    )
    result <- engine$run(game)
    final <- game$snapshot()

    games[[game_id]] <- data.frame(
      game_id = game_id,
      home_score = final$home_score,
      away_score = final$away_score,
      winner = if (final$home_score > final$away_score) "Home" else "Away",
      simulation_time_seconds = game$last_time,
      playing_time_seconds = final$game_time_elapsed,
      periods_played = final$period,
      stringsAsFactors = FALSE
    )

    game_events <- as.data.frame(result$observations)
    names(game_events)[names(game_events) == "event"] <- "event_type"
    game_events$game_id <- game_id
    events[[game_id]] <- game_events
  }

  list(
    games = do.call(rbind, games),
    events = do.call(rbind, events)
  )
}

ui <- fluidPage(
  titlePanel("Hockey Flux"),
  sidebarLayout(
    sidebarPanel(
      numericInput(
        "n_games",
        "Games to simulate",
        value = 25,
        min = 1,
        max = 1000,
        step = 1
      ),
      numericInput(
        "seed",
        "Random seed",
        value = 1,
        min = 1,
        step = 1
      ),
      actionButton("run", "Run simulations", class = "btn-primary"),
      tags$hr(),
      verbatimTextOutput("simulation_summary")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel(
          "Game scores",
          tableOutput("game_scores")
        ),
        tabPanel(
          "Event distribution",
          plotOutput("event_distribution", height = "500px"),
          tableOutput("event_counts")
        ),
        tabPanel(
          "Event data",
          tableOutput("event_preview")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  results <- eventReactive(
    input$run,
    {
      n_games <- as.integer(input$n_games)
      seed <- as.integer(input$seed)

      validate(
        need(!is.na(n_games) && n_games >= 1, "Choose at least one game."),
        need(!is.na(seed), "Enter a random seed.")
      )

      withProgress(message = "Simulating hockey games", value = 0, {
        simulation <- simulate_games(n_games, seed)
        incProgress(1)
        simulation
      })
    },
    ignoreNULL = FALSE
  )

  output$simulation_summary <- renderText({
    games <- results()$games
    overtime_games <- sum(games$periods_played > 3)

    paste(
      sprintf("Games: %d", nrow(games)),
      sprintf("Home wins: %d", sum(games$winner == "Home")),
      sprintf("Away wins: %d", sum(games$winner == "Away")),
      sprintf("Overtime games: %d", overtime_games),
      sep = "\n"
    )
  })

  output$game_scores <- renderTable({
    results()$games
  }, striped = TRUE, hover = TRUE, spacing = "s")

  output$event_distribution <- renderPlot({
    events <- results()$events
    bin_width <- 300
    upper_limit <- max(
      3600,
      ceiling(max(events$game_time_elapsed) / bin_width) * bin_width
    )
    breaks <- seq(0, upper_limit, by = bin_width)
    events$time_bin <- cut(
      events$game_time_elapsed,
      breaks = breaks,
      include.lowest = TRUE,
      right = TRUE
    )
    counts <- xtabs(~ event_type + time_bin, data = events)

    barplot(
      counts,
      beside = FALSE,
      col = seq_len(nrow(counts)),
      border = NA,
      las = 2,
      cex.names = 0.75,
      xlab = "",
      ylab = "Number of events",
      main = "Events by five-minute game-time interval"
    )
    legend(
      "topright",
      legend = rownames(counts),
      fill = seq_len(nrow(counts)),
      bty = "n",
      cex = 0.8
    )
  })

  output$event_counts <- renderTable({
    events <- results()$events
    counts <- as.data.frame(table(events$event_type), stringsAsFactors = FALSE)
    names(counts) <- c("event_type", "count")
    counts$percent <- round(100 * counts$count / sum(counts$count), 1)
    counts[order(counts$count, decreasing = TRUE), ]
  }, striped = TRUE, spacing = "s")

  output$event_preview <- renderTable({
    events <- results()$events
    events <- events[order(events$game_id, events$time), ]
    head(events, 100)
  }, striped = TRUE, hover = TRUE, spacing = "xs")
}

shinyApp(ui, server)
