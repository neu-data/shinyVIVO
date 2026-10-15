# shinyVIVO

A point-and-click workbench for qualitative and mixed-methods research in R.
Upload a spreadsheet of text responses, code them against your themes with a
**local** LLM served by [Ollama](https://ollama.com), and see how each theme
relates to a quantitative metric. The text stays on your machine.

## Install

```r
# install.packages("devtools")
devtools::install_github("neu-data/shinyVIVO")
```

## Quick start

1. Install Ollama and pull a model:
   ```
   ollama pull llama3
   ```
   (Ollama runs in the background after install. If it doesn't, start it with `ollama serve`.)
2. Launch the app:
   ```r
   shinyVIVO::launch_app()
   ```
3. Upload a `.csv` or `.xlsx` file, or click **load the sample dataset**. Pick
   the text column and a numeric metric column, enter your themes, and click
   **Run local AI coding**.

The app has three tabs:

| Tab | Shows |
|---|---|
| Raw data | The uploaded dataset |
| Coding matrix | One `TRUE`/`FALSE` column per theme (`NA` where the model call failed), downloadable as CSV |
| Mixed-methods plot | Mean metric for rows with vs. without each theme, with group sizes |

## Using it from code

The pieces behind the app are exported, so you can script them too:

```r
library(shinyVIVO)

df <- vivo_sample_data()
coded <- code_dataframe(df, text_col = "text",
                        themes = c("Frustration", "Bug Report", "Praise"),
                        model = "llama3")
summarise_theme_metric(coded, c("Frustration", "Bug Report", "Praise"), "metric")
plot_theme_metric(coded, c("Frustration", "Bug Report", "Praise"), "metric")
```

`ollama_code_text()` codes a single string. It sends Ollama a JSON schema
that requires one boolean per theme, so the model's answers can be parsed
reliably.

## License

MIT
