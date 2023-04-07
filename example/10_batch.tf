# バッチ
# ECS Scheduled Tasks
# CloudWatchEventからタスクを起動する

# CloudWatchLogs
# バッチのログ
resource "aws_cloudwatch_log_group" "for_ecs_scheduled_tasks" {
  name = "/ecs-scheduled-tasks/example"
  retention_in_days = 180
}

# バッチ用タスク定義
resource "aws_ecs_task_definition" "example_batch" {
  family = "example-batch"
  cpu = "256"
  memory = "512"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = file("./batch_container_definitions.json")
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn
}

# CloudWatchEventがECSを起動できるIAMロール
module "ecs_events_role" {
  source = "./iam_role"
  name = "ecs-events"
  identifier = "events.amazonaws.com"
  policy = data.aws_iam_policy.ecs_events_role_policy.policy
}

# データソース
data "aws_iam_policy" "ecs_events_role_policy" {
  # タスクを実行＋タスクにIAMロールを渡す権限を付与するポリシーを参照
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceEventsRole"
}

# CloudWatchEventルール
resource "aws_cloudwatch_event_rule" "example_batch" {
  name = "example-batch"
  description = "とても重要なバッチです"
  # UTC
  schedule_expression = "cron(*/2 * * * ? *)"
}

# CloudWatchイベントターゲット
resource "aws_cloudwatch_event_target" "example_batch" {
  target_id = "example-batch"
  # CloudWatchEventルール
  rule = aws_cloudwatch_event_rule.example_batch.name
  role_arn = module.ecs_events_role.iam_role_arn
  arn = aws_ecs_cluster.example.arn

  # タスク実行時の設定
  ecs_target {
    launch_type = "FARGATE"
    task_count = 1
    platform_version = "1.3.0"
    task_definition_arn = aws_ecs_task_definition.example_batch.arn

    network_configuration {
      assign_public_ip = "false"
      subnets = [ aws_subnet.private_0.id ]
    }
  }
}
