{
  box::use(plumber)
  box::use(jsonlite)
  box::use(glue[glue])
  box::use(readr)
  box::use(httr)
}

#' cors
#' @export cors
cors <- function(req, res) {
  print(as.list(req$args))
  res$setHeader("Access-Control-Allow-Origin", "*")
  
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$setHeader("Access-Control-Allow-Methods", "*")
    res$setHeader("Access-Control-Allow-Headers", req$HTTP_ACCESS_CONTROL_REQUEST_HEADERS)
    res$status <- 200
    return(list())
  } else {
    plumber$forward()
  }
}

#* @filter cors
cors <- function(req, res) {
  message(glue("Within filter {Sys.time()}"))
  res$setHeader("Access-Control-Allow-Origin", "*")
  
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$setHeader("Access-Control-Allow-Methods", "*")
    res$setHeader(
      "Access-Control-Allow-Headers",
      req$HTTP_ACCESS_CONTROL_REQUEST_HEADERS
    )
    res$status <- 200
    return(list())
  } else {
    plumber$forward()
  }
}


#* @serializer unboxedJSON
#* @get /costs
#* @param from
#* @param to
function(from = Sys.Date() - 31, to = Sys.Date()) {
  
  # Build the response object (list will be serialized as JSON)
  response <- list(
    statusCode = 200,
    data = "",
    message = "Success!",
    metaData = list(
      args = list(),
      runtime = 0
    )
  )
  
  response <- tryCatch(
    {
      command_to_run <- glue(
        'aws ce get-cost-and-usage --time-period Start={from},End={to} --granularity MONTHLY --metrics "BlendedCost" "UnblendedCost" "UsageQuantity" >> ./currentcost.txt'
      )
      system(command_to_run)
 
      return(response)
    },
    error = function(err) {
      response$statusCode <- 400
      response$message <- paste(err)
      
      return(response)
    }
  )
  
  return(response)
}
