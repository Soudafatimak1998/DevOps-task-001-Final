resource "aws_batch_compute_environment" "compute_env" {
  compute_environment_name = "batch_compute_env_${var.environment}"
  type                     = "MANAGED"

  compute_resources {
    max_vcpus        = 16
    subnets          = aws_subnet.subnet[*].id
    security_group_ids = [aws_security_group.sg.id]
    instance_types   = ["m4.large"]
    instance_role    = aws_iam_instance_profile.batch_instance_profile.arn
  }
  service_role = aws_iam_role.batch_service_role.arn
}

resource "aws_batch_job_queue" "job_queue" {
  name                 = "batch_job_queue_${var.environment}"
  state                = "ENABLED"
  priority             = 1
  compute_environments = [aws_batch_compute_environment.compute_env.arn]
}

resource "aws_batch_job_definition" "job_definition" {
  name        = "batch_job_definition_${var.environment}"
  type        = "container"
  container_properties = jsonencode({
    image      = "${aws_ecr_repository.repository.repository_url}:latest"
    vcpus      = 2
    memory     = 2048
    command    = ["echo", "hello world"]
    environment = [
      {
        name  = "ENV"
        value = var.environment
      }
    ]
  })
}
