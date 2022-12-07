
#' @export
list_buckets <- function() {
  box::use(utils[capture.output])
  box::use(sys)
  box::use(unix)
  box::use(jsonlite[toJSON, flatten])
  box::use(fpeek[peek_count_lines])
  box::use(uuid[UUIDgenerate])
  aws_path <- getOption("aws_path", "/usr/local/aws-cli/v2/current/bin/aws")
  params <- "--output json"
  user_info <- unix$user_info()
  std_out <- function(x) {
    writeLines(rawToChar(x), )
  }
  iam_users <- sys$exec_wait(aws_path, c("iam", "list-users", params), std_out = std_out)
  s3_ls <- capture.output(sys$exec_wait(aws_path, c("s3", "ls"), std_out = std_out))
  s3_ls <- s3_ls[nchar(s3_ls) > 0]
  # print(s3_ls)
  out <- list(
    id = UUIDgenerate(),
    CURRENT_TIME = as.character(Sys.time()),
    user_info = user_info,
    iam_users = iam_users,
    s3_ls = s3_ls
  )
  out <- toJSON(out, pretty = TRUE, auto_unbox = T)
  if (!dir.exists("logs/aws")) {
    dir.create("logs/aws", recursive = TRUE)
  }
  if (file.exists("logs/aws/dashboard.txt")) {
    n_lines <- peek_count_lines("logs/aws/dashboard.txt")
    if (n_lines > 3000) {
      file.remove("logs/aws/dashboard.txt")
    }
  }
  write(out, file = "logs/aws/dashboard.txt", append = TRUE)
  cat(out)
  out
}
