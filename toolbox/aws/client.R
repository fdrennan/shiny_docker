#' #' Access an AWS Client Service
#' #' @title client
#' #' @family client
#' #' @description Client Level Access to AWS Services
#' #'
#' #' @param service NULL An AWS Service like 'ec2' or 's3'
#' #' @param aws_access_key_id  NULL Your AWS ACCESS Key
#' #' @param aws_secret_access_key  NULL Your AWS Secret Key
#' #' @param region NULL Your preferred AWS Region, mine is us-east-2
#' #'
#' #' @importFrom reticulate import
#' #' @export client
#' client <- function(service = NULL,
#'                    aws_access_key_id  = getOption('AWS_ACCESS'),
#'                    aws_secret_access_key  = getOption("AWS_SECRET"),
#'                    region = getOption("AWS_REGION")) {
#'   box::use(reticulate[import])
#'   client <- import("boto3")$client
#'   client <- client(
#'     service,
#'     aws_access_key_id = aws_access_key_id ,
#'     aws_secret_access_key = aws_secret_access_key ,
#'     region_name = region
#'   )
#' }
