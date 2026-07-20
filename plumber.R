# plumber.R - API Entrypoint
library(mime)
library(base64enc)
library(yaml)
library(jsonlite)
library(writexl)
library(readxl)
library(geoflow)
library(plumber)

# Load and run the API
pr <- plumb("plumber_geoflow_api.R")

# Configure server
pr |>
  pr_run(
    host = "0.0.0.0",
    port = 8000,
    debug = TRUE
  )