#' @export
list_key_pair <- function(KeyName = NULL, delete = FALSE, aws_credentials) {
  box::use(purrr)
  box::use(. / client[client])
  box::use(purrr[map_chr])
  ec2 <- client("ec2", aws_credentials = aws_credentials)
  kp <- ec2$describe_key_pairs()
  purrr$map_chr(kp$KeyPairs, ~ .$KeyName)
}

#' @export
manage_key_pair <- function(KeyName = NULL, delete = FALSE, store = FALSE, aws_credentials) {
  box::use(purrr)
  box::use(glue)
  box::use(. / client[client])
  ec2 <- client("ec2", aws_credentials = aws_credentials)
  if (delete) {
    return(
      ec2$delete_key_pair(KeyName = KeyName)
    )
  }
  kp <- ec2$create_key_pair(KeyName = KeyName)
  if (store) {
    write(kp$KeyMaterial, file = glue$glue("{KeyName}.pem"))
    system(glue$glue("chmod 400 {KeyName}.pem"))
  }
  kp$KeyMaterial
}
