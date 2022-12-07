#' @export s3_create_bucket
s3_create_bucket <- function(client = NULL, bucket = NA, location_constraint = "us-east-2", ...) {
  
  response <-
    client$create_bucket(
      Bucket = bucket,
      CreateBucketConfiguration = list(LocationConstraint = location_constraint),
      ...
    )

  data.frame(
    Location = response$Location,
    RequestId = response$ResponseMetadata$RequestId,
    HostId = response$ResponseMetadata$HostId,
    HTTPStatusCode = response$ResponseMetadata$HTTPStatusCode,
    HTTPHeaders = response$ResponseMetadata$HTTPHeaders
  )
}
