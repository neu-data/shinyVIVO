## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Test environments

* local Windows 11, R 4.6.1
* GitHub Actions: windows-latest, macos-latest, ubuntu-latest (release), ubuntu-latest (oldrel-1)

## Notes

* Ollama is an external application for running language models locally.
  Examples that need a running Ollama server are wrapped in \dontrun{};
  the tests use a stand-in coder instead, so no server is needed.
