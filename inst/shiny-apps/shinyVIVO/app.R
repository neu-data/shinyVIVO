library(shiny)
library(bslib)
library(shinyVIVO)

# --- UI ----------------------------------------------------------------------
ui <- page_sidebar(
  title = "shinyVIVO — Mixed-Methods AI Workbench",
  theme = bs_theme(version = 5, bootswatch = "minty"),

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
    textInput("target_codes", "Themes (comma separated)",
              value = "Frustration, Bug Report, Praise"),
    hr(),

    actionButton("run_ai_coding", "Run local AI coding",
                 class = "btn-success w-100", icon = icon("robot"))
  ),

  navset_card_underline(
    nav_panel(
      "Raw data",
      DT::DTOutput("raw_data_table")
    ),
    nav_panel(
      "Coding matrix",
      div(class = "mb-2", downloadButton("download_coded", "Download coded data (.csv)")),
      DT::DTOutput("coded_data_table")
    ),
    nav_panel(
      "Mixed-methods plot",
      plotOutput("matrix_interaction_plot", height = "500px"),
      DT::DTOutput("summary_table")
    )
  )
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
    DT::datatable(req(data_source()), options = list(pageLength = 10),
                  class = "cell-border stripe")
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
    coded(list(df = res, themes = themes))
  })

  output$coded_data_table <- DT::renderDT({
    DT::datatable(req(coded())$df, options = list(pageLength = 10))
  })

  output$download_coded <- downloadHandler(
    filename = function() paste0("shinyVIVO_coded_", Sys.Date(), ".csv"),
    content = function(file) utils::write.csv(req(coded())$df, file, row.names = FALSE)
  )

  output$matrix_interaction_plot <- renderPlot({
    res <- req(coded())
    validate(need(isTruthy(input$metric_col),
                  "The dataset has no numeric column to compare against."))
    plot_theme_metric(res$df, res$themes, input$metric_col)
  })

  output$summary_table <- DT::renderDT({
    res <- req(coded())
    req(input$metric_col)
    s <- summarise_theme_metric(res$df, res$themes, input$metric_col)
    s$mean <- round(s$mean, 2)
    DT::datatable(s, rownames = FALSE, options = list(dom = "t"))
  })
}

shinyApp(ui = ui, server = server)
