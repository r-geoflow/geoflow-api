# plumber.R - API Entrypoint
library(mime)
library(base64enc)
library(yaml)
library(jsonlite)
library(readxl)
library(writexl)
library(gsheet)
library(googledrive)
library(DBI)
library(rapiclient)
library(RMariaDB)
library(RPostgres)
library(RPostgreSQL)
library(RSQLite)
library(ocs4R)
library(zen4R)
library(atom4R)
library(rmarkdown)
library(dataverse)
library(geojsonsf)
library(svglite)
library(blastula)
library(gt)
library(plumber)
library(RFirmsGeo)
library(geoflow)

# Load and run the API
pr <- plumb("plumber_geoflow_api.R")

# Configure server
pr |>
  pr_run(
    host = "0.0.0.0",
    port = 8000,
    debug = TRUE
  )