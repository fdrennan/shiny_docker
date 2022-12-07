#' @export
create_instance <- function(ImageId = "ami-097a2df4ac947655f",
                            InstanceType = "t2.medium",
                            InstanceStorage = 10,
                            user_data = NULL,
                            KeyName = NULL,
                            GroupId = NULL,
                            DryRun = FALSE,
                            DeviceName = "/dev/sda1",
                            aws_credentials) {
  box::use(. / client[client])
  box::use(. / client[resource])
  ec2 <- client("ec2", aws_credentials = aws_credentials)
  ec2Res <- resource("ec2", aws_credentials = aws_credentials)

  response <-
    response <-
    ec2$run_instances(
      ImageId = ImageId,
      InstanceType = InstanceType,
      MinCount = as.integer(1),
      MaxCount = as.integer(1),
      UserData = user_data,
      KeyName = KeyName,
      SecurityGroupIds = list(GroupId),
      BlockDeviceMappings = list(
        list(
          Ebs = list(
            VolumeSize = as.integer(InstanceStorage)
          ),
          DeviceName = DeviceName
        )
      )
    )

  instance <- response$Instances[[1]]
  # InstanceId <- instance_data$Instances[[1]]$InstanceId
}

#' @export
describe_instances <- function(aws_credentials) {
  box::use(purrr)
  box::use(. / client[client])

  ec2 <- client("ec2", aws_credentials = aws_credentials)
  instances <- ec2$describe_instances()
  instances <- purrr$map_dfr(
    instances$Reservations, ~ {
      instance <- .[["Instances"]][[1]]
      #
      df <- as.data.frame(purrr$keep(instance, is.character))
      df$state <- instance$State$Name
      df
    }
  )
}

#' @export
instance_state <- function(InstanceId, aws_credentials) {
  box::use(. / instance[describe_instances])
  instances <- describe_instances(aws_credentials = aws_credentials)
  state <- instances[instances$InstanceId == InstanceId, ]$state
  state
}
