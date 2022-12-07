#' @export
client <- function(service = NULL) {
  box::use(reticulate[import])
  client <- import("boto3")$client
  client <- client(service)
}

#' @export
resource <- function(service = NULL) {
  box::use(reticulate[import])
  resource <- import("boto3")$resource
  resource <- resource(service)
}
