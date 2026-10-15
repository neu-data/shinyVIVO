# shinyVIVO workbench, built on neu-data/shiny-app-template.
# Files in R/ are sourced automatically by Shiny (theme.R).

library(shiny)
library(bslib)
library(shinyVIVO)

APP_NAME <- "shinyVIVO"

# --- UI ----------------------------------------------------------------------
ui <- page_navbar(
  title = neudata_brand(APP_NAME),
  window_title = paste(APP_NAME, "· Neudata"),
  theme = neudata_bs_theme(),
  navbar_options = navbar_options(bg = neudata_cols[["navy"]], theme = "dark"),
  fillable = FALSE,
  header = tags$head(
    tags$link(rel = "stylesheet", href = "neudata.css"),
    tags$link(rel = "icon", href = "neudata-logo.png")
  ),
  footer = neudata_footer(),

  sidebar = sidebar(
    width = 320,
    title = "Configuration",

    fileInput("upload_file", "1. Upload data (.csv, .xlsx)",
              accept = c(".csv", ".xlsx", ".xls")),
    actionLink("use_sample", "or load the sample dataset"),
    uiOutput("column_pickers"),
    hr(),

    textInput("ollama_url", "2. Ollama endpoint", value = "http://localhost:11434"),
    selectizeInput("ollama_model", "Model", choices = "llama3", selected = "llama3",
                   options = list(create = TRUE)),
    actionLink("refresh_models", "Refresh model list"),
    textInput("target_codes", "3. Themes (comma separated)",
              value = "Frustration, Bug Report, Praise"),
    hr(),

    actionButton("run_ai_coding", "Run local AI coding",
                 class = "btn-primary w-100", icon = icon("robot"))
  ),

  nav_panel(
    "Raw data",
    icon = bsicons::bs_icon("table"),
    card(
      full_screen = TRUE,
      card_header("Uploaded dataset"),
      DT::DTOutput("raw_data_table")
    )
  ),

  nav_panel(
    "Coding matrix",
    icon = bsicons::bs_icon("tags"),
    card(
      full_screen = TRUE,
      card_header(
        class = "d-flex justify-content-between align-items-center",
        "Themes coded by the model (NA = model call failed)",
        downloadButton("download_coded", "Download .csv", class = "btn-sm btn-outline-primary")
      ),
      DT::DTOutput("coded_data_table")
    )
  ),

  nav_panel(
    "Mixed-methods plot",
    icon = bsicons::bs_icon("bar-chart"),
    layout_column_wrap(
      width = 1 / 3,
      fill = FALSE,
      value_box(
        title = "Rows coded",
        value = textOutput("kpi_coded"),
        showcase = bsicons::bs_icon("check2-square"),
        theme = value_box_theme(bg = neudata_cols[["teal"]], fg = "#fff")
      ),
      value_box(
        title = "Rows failed",
        value = textOutput("kpi_failed"),
        showcase = bsicons::bs_icon("exclamation-triangle"),
        theme = value_box_theme(bg = neudata_cols[["blue"]], fg = "#fff")
      ),
      value_box(
        title = "Themes",
        value = textOutput("kpi_themes"),
        showcase = bsicons::bs_icon("tags"),
        theme = value_box_theme(bg = neudata_cols[["navy"]], fg = "#fff")
      )
    ),
    layout_columns(
      col_widths = c(7, 5),
      card(
        full_screen = TRUE,
        card_header("Metric by theme presence"),
        plotOutput("matrix_interaction_plot", height = "450px")
      ),
      card(
        full_screen = TRUE,
        card_header("Summary"),
        DT::DTOutput("summary_table")
      )
    )
  ),

  nav_panel(
    "About",
    icon = bsicons::bs_icon("info-circle"),
    card(
      card_header("About shinyVIVO"),
      p("shinyVIVO codes qualitative text against your themes with a large language model ",
        "running locally in ", tags$a(href = "https://ollama.com", target = "_blank", "Ollama"),
        ", then compares a quantitative metric between texts with and without each theme. ",
        "The text is sent only to the Ollama endpoint you set, which by default is your own machine."),
      p("Treat the codes as a first pass. Check a sample against a human coder before ",
        "reporting results, and read the differences as associations, not causes."),
      p(
        "Built by ",
        tags$a(href = "https://www.neu-data.com", target = "_blank", "Neudata Consulting Ltd"),
        " — data science, biostatistics and research analytics."
      )
    )
  ),

  nav_spacer(),
  nav_item(tags$a(href = "https://www.neu-data.com", target = "_blank", bsicons::bs_icon("globe"), "neu-data.com"))
)

# --- Server ------------------------------------------------------------------
server <- function(input, output, session) {

  data_source <- reactiveVal(NULL)

  observeEvent(input$upload_file, {
    path <- input$upload_file$datapath
    ext <- tolower(tools::file_ext(input$upload_file$name))
    df <- tryCatch(
      if (ext %in% c("xlsx", "xls")) as.data.frame(readxl::read_excel(path))
      else utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
      error = function(e) {
        showNotification(paste("Could not read file:", conditionMessage(e)),
                         type = "error")
        NULL
      }
    )
    data_source(df)
  })

  observeEvent(input$use_sample, data_source(vivo_sample_data()))

  refresh_models <- function() {
    models <- ollama_models(input$ollama_url)
    if (length(models)) {
      current <- input$ollama_model
      updateSelectizeInput(session, "ollama_model", choices = models,
                           selected = if (current %in% models) current else models[1])
    } else {
      showNotification("No models found. Is Ollama running at that endpoint?",
                       type = "warning")
    }
  }
  observeEvent(input$refresh_models, refresh_models())
  session$onFlushed(function() isolate(refresh_models()), once = TRUE)

  output$column_pickers <- renderUI({
    df <- req(data_source())
    chr_cols <- names(df)[vapply(df, is.character, logical(1))]
    num_cols <- names(df)[vapply(df, is.numeric, logical(1))]
    tagList(
      selectInput("text_col", "Text column", choices = names(df),
                  selected = if ("text" %in% chr_cols) "text" else chr_cols[1]),
      selectInput("metric_col", "Metric column", choices = num_cols,
                  selected = if ("metric" %in% num_cols) "metric" else num_cols[1])
    )
  })

  output$raw_data_table <- DT::renderDT({
    DT::datatable(req(data_source()), rownames = FALSE,
                  options = list(pageLength = 10, dom = "ftip"))
  })

  coded <- reactiveVal(NULL)

  observeEvent(input$run_ai_coding, {
    df <- data_source()
    themes <- parse_themes(input$target_codes)
    if (is.null(df)) {
      showNotification("Upload a dataset first.", type = "warning"); return()
    }
    if (!length(themes)) {
      showNotification("Enter at least one theme.", type = "warning"); return()
    }
    if (!length(ollama_models(input$ollama_url))) {
      showNotification(paste("Cannot reach Ollama at", input$ollama_url,
                             "(or no models are pulled). Start it with `ollama serve`."),
                       type = "error", duration = NULL)
      return()
    }

    res <- withProgress(message = "Coding with Ollama...", value = 0, {
      code_dataframe(
        df, input$text_col, themes,
        model = input$ollama_model, url = input$ollama_url,
        progress = function(i, n) incProgress(1 / n, detail = paste("Row", i, "of", n))
      )
    })

    failed <- sum(!stats::complete.cases(res[themes]))
    if (failed == nrow(res)) {
      showNotification("Every row failed. Check that Ollama is running and the model is pulled.",
                       type = "error", duration = NULL)
    } else if (failed > 0) {
      showNotification(sprintf("%d of %d rows could not be coded (shown as NA).",
                               failed, nrow(res)), type = "warning")
    }
    coded(list(df = res, themes = themes, failed = failed))
  })

  output$coded_data_table <- DT::renderDT({
    DT::datatable(req(coded())$df, rownames = FALSE,
                  options = list(pageLength = 10, dom = "ftip"))
  })

  output$download_coded <- downloadHandler(
    filename = function() paste0("shinyVIVO_coded_", Sys.Date(), ".csv"),
    content = function(file) utils::write.csv(req(coded())$df, file, row.names = FALSE)
  )

  output$kpi_coded <- renderText({
    res <- req(coded())
    nrow(res$df) - res$failed
  })
  output$kpi_failed <- renderText(req(coded())$failed)
  output$kpi_themes <- renderText(length(req(coded())$themes))

  output$matrix_interaction_plot <- renderPlot({
    res <- req(coded())
    validate(need(isTruthy(input$metric_col),
                  "The dataset has no numeric column to compare against."))
    plot_theme_metric(res$df, res$themes, input$metric_col)
  }, res = 96)

  output$summary_table <- DT::renderDT({
    res <- req(coded())
    req(input$metric_col)
    s <- summarise_theme_metric(res$df, res$themes, input$metric_col)
    s$mean <- round(s$mean, 2)
    DT::datatable(s, rownames = FALSE, options = list(dom = "t"))
  })
}

shinyApp(ui, server)
