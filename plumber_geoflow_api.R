# plumber_geoflow_api.R
# Plumber API wrapper for geoflow with file upload support

library(mime)
library(base64enc)
library(yaml)
library(jsonlite)
library(writexl)
library(readxl)
library(plumber)
library(geoflow)


# ============================================================================
# ENDPOINTS
# ============================================================================

#* @apiTitle Geoflow API
#* @apiDescription API for executing workflows with the R geoflow framework
#* @apiLicense MIT
#* @apiContact Emmanuel Blondel <eblondel.pro@@gmail.com>

#* Health check
#* @get /health
function() {
  list(
    status = "OK"
  )
}

#* Get workflow status and information
#* @get /capabilities
function() {
  list(
    api_version = "1.0.0",
    geoflow_version = as.character(packageVersion("geoflow")),
    session_info = yaml::yaml.load(yaml::as.yaml(sessionInfo()))
  )
}

#* Execute workflow with all components
#* @post /execute
#* @parser all
#* @parser json list(simplifyVector = FALSE)
#* @param config:file Geoflow configuration file (either JSON or YAML file)
#* @param env:file Environment variables properties file (either .txt or custom .env file)
#* @param metadata_entities:[file] Metadata entity local file(s)
#* @param metadata_contacts:[file] Metadata contact local files(s)
#* @param metadata_dictionary:[file] Metadata dictionary local file(s)
#* @param metadata_registers:[file] Metadata dictionary registers (R scripts)
#* @param data:[file] Data local file(s)
function(config, env = list(),
         metadata_entities = list(),
         metadata_contacts = list(),
         metadata_dictionary = list(),
         metadata_registers = list(),
         data = list()){
  
  # Create temporary working directory
  temp_dir <- tempdir()
  
  tryCatch({
    
    execute = FALSE

    geoflow_config_obj = NULL
    config_file = NULL
    env_file = NULL
    
    if(is.null(config)){
      stop("Geoflow configuration file is missing")
    }else{
      geoflow_config_obj = config[[1]]
      print(geoflow_config_obj)
      config_file = file.path(temp_dir, names(config))

      #inherit environment variables file
      if(length(env)>0){
        if(endsWith(names(env), ".env")){
          env_txt <- rawToChar(env[[1]])
          env_file = file.path(temp_dir, names(env))
          readr::write_lines(env_txt, env_file)
        }else if(endsWith(names(env), ".txt")){
          env_file = file.path(temp_dir, names(env))
          readr::write_lines(env[[1]], env_file)
        }
        
        if(is.null(geoflow_config_obj$profile$environment)){
          geoflow_config_obj$profile$environment = list()
        }
        geoflow_config_obj$profile$environment$file = env_file
      }else{
        #in case the configuration includes an environment profile and no environment file is provided, trigger an error
        if(!is.null(geoflow_config_obj$profile$environment$file)){
          stop("The Geoflow configuration includes a reference to an environment file, and no environment file has been specified")
        }
      }
      
      #metadata files (if any)
      if(!is.null(geoflow_config_obj$metadata$entities)) {
        if(any(sapply(geoflow_config_obj$metadata$entities, function(x){x$handler}) %in% c("csv", "excel"))){
          print(metadata_entities)
          if(length(metadata_entities) == 0){
            stop("At least one metadata entity source referenced as CSV or EXCEL, with no metadata entities local file uploaded")
          }else{
            print("Overwriting entities with metadata_entities local files")
            geoflow_config_obj$metadata$entities = lapply(names(metadata_entities), function(x){
              print(metadata_entities[[x]])
              handler = switch(mime::guess_type(x),
                "text/csv" = "csv",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "excel"
              )
              source_file = file.path(temp_dir, x)
              switch(mime::guess_type(x),
                "text/csv" = {
                  readr::write_csv(metadata_entities[[x]], source_file)
                },
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = {
                  writexl::write_xlsx(metadata_entities[[x]], source_file, )
                }
              )
              list(
                handler = handler,
                source = source_file
              )
            }) |> unname()
          }
        }
      }
      if(!is.null(geoflow_config_obj$metadata$contacts)){
        if(any(sapply(geoflow_config_obj$metadata$contacts, function(x){x$handler}) %in% c("csv", "excel"))){
          if(length(metadata_contacts) == 0){
            stop("At least one metadata contact source referenced as CSV or EXCEL, with no metadata contacts local file uploaded")
          }else{
            print("Overwriting contacts with metadata_contacts local files")
            geoflow_config_obj$metadata$contacts = lapply(names(metadata_contacts), function(x){
              handler = switch(mime::guess_type(x),
                               "text/csv" = "csv",
                               "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "excel"
              )
              source_file = file.path(temp_dir, x)
              switch(mime::guess_type(x),
                     "text/csv" = {
                       readr::write_csv(metadata_contacts[[x]], source_file)
                     },
                     "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = {
                       writexl::write_xlsx(metadata_contacts[[x]], source_file)
                     }                    
              )
              list(
                handler = handler,
                source = source_file
              )
            }) |> unname()
          }
        }
      }
      if(!is.null(geoflow_config_obj$metadata$dictionary)){
        if(any(sapply(geoflow_config_obj$metadata$dictionary, function(x){x$handler}) %in% c("csv", "excel"))){
          if(length(metadata_dictionary) == 0){
            stop("At least one metadata dictionary source referenced as CSV or EXCEL, with no metadata dictionary local file uploaded")
          }else{
            print("Overwriting dictionary with metadata_dictionary local files")
            print(metadata_dictionary[[1]])
            geoflow_config_obj$metadata$dictionary = lapply(names(metadata_dictionary), function(x){
              print(metadata_dictionary[[x]])
              handler = switch(mime::guess_type(x),
                               "text/csv" = "csv",
                               "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = "excel"
              )
              source_file = file.path(temp_dir, x)
              switch(mime::guess_type(x),
                     "text/csv" = {
                       readr::write_csv(metadata_dictionary[[x]], source_file)
                     },
                     "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = {
                       writexl::write_xlsx(metadata_dictionary[[x]], source_file)
                     }                    
              )
              list(
                handler = handler,
                source = source_file
              )
            }) |> unname()
          }
        }
      }
      #registers
      if(length(metadata_registers)>0){
        for(filename in names(metadata_registers)){
          reg_file = file.path(temp_dir, filename)
          if(!endsWith(filename, ".R")) next
          writeBin(metadata_registers[[filename]], reg_file)
        }
      }
      
      #datasets
      if(length(data)>0){
        print("Copying data files")
        for(filename in names(data)){
          print(data[[filename]])
          dat_file = file.path(temp_dir, filename)
          switch(mime::guess_type(filename),
            "text/csv" = {
              readr::write_csv(data[[filename]], dat_file)
            },
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" = {
              writexl::write_xlsx(data[[filename]], dat_file)
            },
            {
              if(is.raw(data[[filename]])){
                writeBin(data[[filename]], dat_file)
              }else{
                stop(sprintf("Mime type '%s' not manage for data processing"))
              }
            }      
          )
        }
      }
      
      #write back geoflow config
      switch(mime::guess_type(config_file),
        "application/json" = jsonlite::write_json(geoflow_config_obj, config_file, auto_unbox = TRUE),
        "application/yaml" = yaml::write_yaml(geoflow_config_obj, config_file)
      )
      
    }

    result = geoflow::executeWorkflow(config_file, dir = temp_dir)
    
    list(
      success = TRUE,
      message = "Successful workflow execution",
      inputs = list(
        config = config_file
      ),
      output = result
    )
    
  }, error = function(e) {
    list(
      success = FALSE,
      message = "Error during workflow execution",
      details = e$message
    )
  }, finally = {
    # Cleanup (optional - keep for debugging)
    # unlink(temp_dir, recursive = TRUE)
  })
}
