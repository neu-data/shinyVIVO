# shinyVIVO 0.1.0

* First release, built on the Neudata R package template.
* `launch_app()` opens the workbench: upload a `.csv` or `.xlsx` file, pick
  the text and metric columns, code the text against your themes with a
  local Ollama model, and plot the metric by theme presence. The app uses
  the Neudata Shiny template's look.
* `ollama_code_text()` codes one text, using a JSON schema so the model
  must return one boolean per theme. `code_dataframe()` codes every row;
  failed calls give `NA`, never a silent `FALSE`.
* `summarise_theme_metric()` and `plot_theme_metric()` compare a numeric
  metric between rows with and without each theme.
* `vivo_sample_data()` provides a small feedback dataset for trying the app.
