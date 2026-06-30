library(shiny)
library(bslib)
library(fluxCore)
library(plotly)

# The model files currently use paths relative to the project root.
app_directory <- getwd()
project_root <- normalizePath(file.path(app_directory, ".."))
setwd(project_root)
source("entities/game_init.R")
source("bundles/game_bundle.R")
setwd(app_directory)

nhl_teams <- c(
  "Anaheim Ducks",
  "Boston Bruins",
  "Buffalo Sabres",
  "Calgary Flames",
  "Carolina Hurricanes",
  "Chicago Blackhawks",
  "Colorado Avalanche",
  "Columbus Blue Jackets",
  "Dallas Stars",
  "Detroit Red Wings",
  "Edmonton Oilers",
  "Florida Panthers",
  "Los Angeles Kings",
  "Minnesota Wild",
  "Montréal Canadiens",
  "Nashville Predators",
  "New Jersey Devils",
  "New York Islanders",
  "New York Rangers",
  "Ottawa Senators",
  "Philadelphia Flyers",
  "Pittsburgh Penguins",
  "San Jose Sharks",
  "Seattle Kraken",
  "St. Louis Blues",
  "Tampa Bay Lightning",
  "Toronto Maple Leafs",
  "Utah Mammoth",
  "Vancouver Canucks",
  "Vegas Golden Knights",
  "Washington Capitals",
  "Winnipeg Jets"
)

simulate_games <- function(n_games, seed, home_team, away_team) {
  set.seed(seed)
  engine <- Engine$new(bundle = game_bundle())
  games <- vector("list", n_games)
  events <- vector("list", n_games)

  for (game_id in seq_len(n_games)) {
    game <- game_init(
      game_id = game_id,
      location = home_team,
      home_team = home_team,
      away_team = away_team
    )
    result <- engine$run(game)
    final <- game$snapshot()

    games[[game_id]] <- data.frame(
      game_id = game_id,
      home_team = final$home_team,
      away_team = final$away_team,
      home_score = final$home_score,
      away_score = final$away_score,
      winner =
        if (final$home_score > final$away_score) home_team else away_team,
      location = final$location,
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

app_theme <- bs_theme(
  version = 5,
  bg = "#07111f",
  fg = "#edf3f8",
  primary = "#e63946",
  secondary = "#4cc9f0",
  success = "#38b000",
  base_font = "Arial",
  heading_font = "Arial Narrow"
)

ui <- page_sidebar(
  theme = app_theme,
  title = div(
    class = "brand-lockup",
    span(class = "brand-mark", "HF"),
    div(
      span(class = "brand-title", "HOCKEY FLUX"),
      span(class = "brand-subtitle", "PLAYOFF SIMULATION LAB")
    )
  ),
  sidebar = sidebar(
    width = 330,
    title = "MATCHUP SETUP",
    div(
      class = "team-selectors",
      selectInput(
        "away_team",
        "AWAY TEAM",
        choices = nhl_teams,
        selected = "Florida Panthers"
      ),
      div(class = "matchup-divider", span("AT")),
      selectInput(
        "home_team",
        "HOME TEAM",
        choices = nhl_teams,
        selected = "Colorado Avalanche"
      )
    ),
    tags$hr(),
    layout_columns(
      numericInput(
        "n_games",
        "GAMES",
        value = 25,
        min = 1,
        max = 1000,
        step = 1
      ),
      numericInput(
        "seed",
        "SEED",
        value = 1,
        min = 1,
        step = 1
      ),
      col_widths = c(6, 6)
    ),
    actionButton(
      "run",
      "RUN SIMULATIONS",
      class = "btn-primary run-button",
      width = "100%"
    ),
    tags$hr(),
    uiOutput("simulation_summary")
  ),
  tags$style(HTML("
    .navbar, .bslib-page-title { letter-spacing: .04em; }
    .brand-lockup {
      display: flex;
      align-items: center;
      gap: .8rem;
    }
    .brand-mark {
      display: grid;
      place-items: center;
      width: 2.5rem;
      height: 2.5rem;
      border: 2px solid #4cc9f0;
      border-radius: 50%;
      color: #4cc9f0;
      font-weight: 900;
      font-style: italic;
    }
    .brand-title {
      display: block;
      font-weight: 900;
      letter-spacing: .08em;
      line-height: 1;
    }
    .brand-subtitle {
      display: block;
      margin-top: .25rem;
      color: #8da2b8;
      font-size: .68rem;
      letter-spacing: .16em;
    }
    .bslib-sidebar-layout > .sidebar {
      border-right: 1px solid #223248;
    }
    .team-selectors .form-label,
    .sidebar .form-label {
      color: #8da2b8;
      font-size: .72rem;
      font-weight: 800;
      letter-spacing: .12em;
    }
    .matchup-divider {
      position: relative;
      margin: -.25rem 0 .65rem;
      color: #4cc9f0;
      text-align: center;
      font-size: .7rem;
      font-weight: 900;
      letter-spacing: .15em;
    }
    .matchup-divider::before,
    .matchup-divider::after {
      content: '';
      position: absolute;
      top: 50%;
      width: 42%;
      height: 1px;
      background: #2b3d54;
    }
    .matchup-divider::before { left: 0; }
    .matchup-divider::after { right: 0; }
    .run-button {
      padding: .8rem 1rem;
      border: 0;
      border-radius: .3rem;
      font-weight: 900;
      letter-spacing: .1em;
      box-shadow: 0 .35rem 1rem rgba(230, 57, 70, .22);
    }
    .matchup-header {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 1rem;
      min-height: 5rem;
      margin-bottom: 1rem;
      padding: 1rem 1.5rem;
      border: 1px solid #223248;
      border-radius: .55rem;
      background: linear-gradient(110deg, #0d1b2d, #13243a);
      box-shadow: 0 .5rem 1.5rem rgba(0, 0, 0, .2);
      text-align: center;
    }
    .matchup-team {
      flex: 1;
      font-size: clamp(1rem, 2vw, 1.45rem);
      font-weight: 900;
      letter-spacing: .03em;
      text-transform: uppercase;
    }
    .matchup-at {
      color: #4cc9f0;
      font-size: .8rem;
      font-weight: 900;
      letter-spacing: .16em;
    }
    .summary-panel {
      color: #c5d1dd;
      font-size: .85rem;
      line-height: 1.8;
    }
    .summary-panel strong { color: #fff; }
    .card {
      border: 1px solid #223248;
      box-shadow: 0 .5rem 1.5rem rgba(0, 0, 0, .18);
    }
    .card-header {
      font-size: .76rem;
      font-weight: 900;
      letter-spacing: .12em;
    }
    .nav-tabs .nav-link {
      font-weight: 800;
      letter-spacing: .04em;
    }
    .table {
      --bs-table-bg: transparent;
      --bs-table-striped-bg: rgba(255,255,255,.035);
      --bs-table-hover-bg: rgba(76,201,240,.08);
      color: #dce6ef;
      font-size: .86rem;
    }
    .table thead th {
      color: #8da2b8;
      font-size: .7rem;
      letter-spacing: .08em;
      text-transform: uppercase;
    }
  ")),
  uiOutput("matchup_header"),
  navset_card_tab(
    nav_panel(
      "Game explorer",
      layout_columns(
        card(
          card_header("SELECT A SIMULATED GAME"),
          card_body(
            selectInput(
              "explorer_game",
              "GAME",
              choices = "1",
              selected = "1"
            ),
            uiOutput("selected_game_summary")
          )
        ),
        card(
          full_screen = TRUE,
          card_header("SIMULATION TIMELINE"),
          card_body(
            plotlyOutput("game_timeline", height = "430px")
          )
        ),
        col_widths = c(3, 9)
      )
    ),
    nav_panel(
      "Game scores",
      card(
        card_header("SIMULATED RESULTS"),
        card_body(tableOutput("game_scores"))
      )
    ),
    nav_panel(
      "Event distribution",
      layout_columns(
        card(
          full_screen = TRUE,
          card_header("EVENTS BY GAME TIME"),
          card_body(plotOutput("event_distribution", height = "480px"))
        ),
        card(
          card_header("EVENT MIX"),
          tableOutput("event_counts")
        ),
        col_widths = c(8, 4)
      )
    ),
    nav_panel(
      "Event data",
      card(
        card_header("EVENT LOG · FIRST 100 ROWS"),
        card_body(
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
      home_team <- input$home_team
      away_team <- input$away_team

      validate(
        need(!is.na(n_games) && n_games >= 1, "Choose at least one game."),
        need(!is.na(seed), "Enter a random seed."),
        need(home_team != away_team, "Choose two different teams.")
      )

      withProgress(message = "Simulating hockey games", value = 0, {
        simulation <- simulate_games(
          n_games = n_games,
          seed = seed,
          home_team = home_team,
          away_team = away_team
        )
        incProgress(1)
        simulation
      })
    },
    ignoreNULL = FALSE
  )

  observeEvent(results(), {
    games <- results()$games
    game_labels <- sprintf(
      "Game %d — %s %d @ %s %d",
      games$game_id,
      games$away_team,
      games$away_score,
      games$home_team,
      games$home_score
    )
    game_choices <- stats::setNames(as.character(games$game_id), game_labels)

    updateSelectInput(
      session,
      "explorer_game",
      choices = game_choices,
      selected = as.character(games$game_id[[1]])
    )
  })

  selected_game <- reactive({
    req(input$explorer_game)
    selected_id <- as.integer(input$explorer_game)
    games <- results()$games
    events <- results()$events

    list(
      game = games[games$game_id == selected_id, ],
      events = events[events$game_id == selected_id, ]
    )
  })

  output$matchup_header <- renderUI({
    games <- results()$games

    div(
      class = "matchup-header",
      div(class = "matchup-team", games$away_team[[1]]),
      div(class = "matchup-at", "AT"),
      div(class = "matchup-team", games$home_team[[1]])
    )
  })

  output$simulation_summary <- renderUI({
    games <- results()$games
    overtime_games <- sum(games$periods_played > 3)

    div(
      class = "summary-panel",
      div(strong("SIMULATION SUMMARY")),
      div(sprintf("Games played: %d", nrow(games))),
      div(
        sprintf(
          "%s wins: %d",
          games$home_team[[1]],
          sum(games$winner == games$home_team)
        )
      ),
      div(
        sprintf(
          "%s wins: %d",
          games$away_team[[1]],
          sum(games$winner == games$away_team)
        )
      ),
      div(sprintf("Overtime games: %d", overtime_games))
    )
  })

  output$selected_game_summary <- renderUI({
    game <- selected_game()$game
    game <- game[1, ]

    div(
      class = "summary-panel",
      div(strong(sprintf("%s %d", game$away_team, game$away_score))),
      div(strong(sprintf("%s %d", game$home_team, game$home_score))),
      tags$hr(),
      div(sprintf("Winner: %s", game$winner)),
      div(sprintf("Periods: %d", game$periods_played)),
      div(
        sprintf(
          "Simulation time: %.1f min",
          game$simulation_time_seconds / 60
        )
      ),
      div(
        sprintf(
          "Playing time: %.1f min",
          game$playing_time_seconds / 60
        )
      )
    )
  })

  output$game_timeline <- renderPlotly({
    selected <- selected_game()
    game <- selected$game[1, ]
    events <- selected$events
    events <- events[order(events$time), ]

    events$phase <- ifelse(
      events$game_status == "intermission",
      "Intermission",
      ifelse(
        events$game_status == "in_progress" & events$play_active,
        "Active play",
        ifelse(
          events$game_status == "in_progress",
          "Stoppage",
          "Final"
        )
      )
    )

    intervals <- events
    intervals$start <- intervals$time / 60
    intervals$end <- c(events$time[-1], tail(events$time, 1)) / 60
    intervals$duration <- intervals$end - intervals$start
    intervals <- subset(
      intervals,
      duration > 0 & phase %in% c("Active play", "Stoppage", "Intermission")
    )
    intervals$hover <- sprintf(
      "<b>%s</b><br>%.2f–%.2f simulation min<br>Duration: %.1f sec",
      intervals$phase,
      intervals$start,
      intervals$end,
      intervals$duration * 60
    )

    events$event_color <- ifelse(
      grepl("^goal_", events$event_type),
      "#f9c74f",
      ifelse(
        events$event_type == "period_end",
        "#4cc9f0",
        ifelse(events$event_type == "puck_drop", "#ffffff", "#e63946")
      )
    )
    events$hover <- sprintf(
      paste0(
        "<b>%s</b>",
        "<br>Simulation time: %.2f min",
        "<br>Period %d · %s",
        "<br>%s %d – %d %s",
        "<br>Status: %s"
      ),
      gsub("_", " ", events$event_type),
      events$time / 60,
      events$period,
      events$game_clock,
      game$away_team,
      events$away_score,
      events$home_score,
      game$home_team,
      ifelse(events$play_active, "Active play", events$game_status)
    )

    phase_colors <- c(
      "Active play" = "#2a9d8f",
      "Stoppage" = "#e63946",
      "Intermission" = "#f4a261"
    )

    timeline <- plot_ly()
    for (phase_name in names(phase_colors)) {
      phase_intervals <- subset(intervals, phase == phase_name)
      if (nrow(phase_intervals) > 0) {
        timeline <- add_bars(
          timeline,
          data = phase_intervals,
          x = ~duration,
          base = ~start,
          y = rep(0, nrow(phase_intervals)),
          width = 0.42,
          orientation = "h",
          name = phase_name,
          marker = list(
            color = unname(phase_colors[[phase_name]]),
            line = list(width = 0)
          ),
          text = ~hover,
          hoverinfo = "text"
        )
      }
    }

    timeline |>
      add_markers(
        data = events,
        x = ~time / 60,
        y = rep(0, nrow(events)),
        name = "Events",
        marker = list(
          color = events$event_color,
          size = 8,
          line = list(color = "#07111f", width = 1)
        ),
        text = ~hover,
        hoverinfo = "text"
      ) |>
      layout(
        barmode = "overlay",
        paper_bgcolor = "#101c2c",
        plot_bgcolor = "#101c2c",
        font = list(color = "#dce6ef"),
        margin = list(l = 25, r = 20, t = 20, b = 60),
        xaxis = list(
          title = "Simulation time (minutes)",
          gridcolor = "#26384d",
          zerolinecolor = "#4cc9f0"
        ),
        yaxis = list(
          title = "",
          tickvals = 0,
          ticktext = "",
          range = c(-0.55, 0.55),
          showgrid = FALSE,
          zeroline = FALSE
        ),
        legend = list(
          orientation = "h",
          x = 0,
          y = 1.12
        ),
        hoverlabel = list(
          bgcolor = "#07111f",
          bordercolor = "#4cc9f0",
          font = list(color = "#edf3f8")
        )
      ) |>
      config(
        displaylogo = FALSE,
        modeBarButtonsToRemove = c("lasso2d", "select2d")
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

    old_par <- par(
      bg = "#101c2c",
      fg = "#dce6ef",
      col.axis = "#aebdca",
      col.lab = "#dce6ef",
      col.main = "#edf3f8"
    )
    on.exit(par(old_par))

    event_colors <- c(
      "#e63946",
      "#4cc9f0",
      "#f4a261",
      "#8ac926",
      "#b5179e",
      "#577590",
      "#f9c74f",
      "#90be6d"
    )

    barplot(
      counts,
      beside = FALSE,
      col = rep(event_colors, length.out = nrow(counts)),
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
      fill = rep(event_colors, length.out = nrow(counts)),
      bty = "n",
      cex = 0.8,
      text.col = "#dce6ef"
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
