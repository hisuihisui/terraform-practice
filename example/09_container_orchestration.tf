# ECS

# ECSをプライベートネットワークに配置し、nginxコンテナを起動

# ECSクラスタ
# コンテナを実行するホストサーバーを論理的に束ねる
resource "aws_ecs_cluster" "example" {
  name = "example"
}

# タスク定義：コンテナ実行時の設定
# タスク：コンテナの実行単位
resource "aws_ecs_task_definition" "example" {
  # ファミリー：タスク定義名のプレフィックス
  # タスク定義名＝ファミリー：リビジョン番号
  # 例）example:1
  family = "example"
  # cpuとmemory
  # 設定できる値の組み合わせは決まっている
  cpu = "256"
  memory = "512"
  # Fargateの場合は、awsvpc を指定
  network_mode = "awsvpc"
  # 起動タイプ
  requires_compatibilities = [ "FARGATE" ]
  # コンテナ定義
  container_definitions = file("./container_definitions.json")
  # ログを送れるように権限追加
  execution_role_arn = module.ecs_task_execution_role.iam_role_arn
}

# ECSサービス
# 指定した数のタスクを維持する
# ALBとコンテナの橋渡しをする
resource "aws_ecs_service" "example" {
  name = "example"
  # ECSクラスタ
  cluster = aws_ecs_cluster.example.arn
  # タスク定義
  task_definition = aws_ecs_task_definition.example.arn
  # 維持するタスク数
  desired_count = 2
  # 起動タイプ
  launch_type = "FARGATE"
  # プラットフォームバージョン
  # デフォルトは LATEST だが、最新版でないことがある
  # なので、バージョンを指定する
  platform_version = "1.3.0"
  # タスク起動時のヘルスチェック猶予時間
  # デフォルトは０だが、タスクの起動に時間がかかる場合タスク起動と終了がループする
  # ０以上の値にしておく
  health_check_grace_period_seconds = 60

  # サブネットとセキュリティグループを設定
  network_configuration {
    # パブリックIPアドレスを割り当てるか
    assign_public_ip = false
    security_groups =  [
      module.nginx_sg.security_group_id
    ]
    subnets = [
      aws_subnet.private_0.id,
      aws_subnet.private_1.id,
    ]
  }

  # ロードバランサーとの関連付け
  # 複数コンテナがある場合はロードバランサーからリクエストを受け取るコンテナを指定
  load_balancer {
    target_group_arn = aws_lb_target_group.example.arn
    # コンテナ定義のnameと対応
    container_name = "example"
    # コンテナ定義のportMappings.containerPort に対応
    container_port = 80
  }

  # ライフサイクル
  lifecycle {
    # リソースの初回作成時を除き、タスク定義の更新を無視する
    # Fargateの場合、デプロイのたびにタスク定義が更新され、plan時に差分が出るため
    ignore_changes = [
      task_definition
    ]
  }
}

module "nginx_sg" {
  source = "./security_group"
  name = "nginx-sg"
  vpc_id = aws_vpc.example.id
  port = 80
  cidr_block = [ aws_vpc.example.cidr_block ]
}

# Fargateのロギング
# Fargeteではホストサーバーにログインできない → ログを確認できない
#  → CloudWatch Logs に送るようにする
resource "aws_cloudwatch_log_group" "for_ecs" {
  name = "/ecs/example"
  # ログの保持期間
  retention_in_days = 180
}

# ECSタスク実行IAMロール
# IAMポリシーデータソース
data "aws_iam_policy" "ecs_task_execution_role_policy" {
  # CloudWatchLogsや ECRの操作権限がある
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ポリシードキュメント
data "aws_iam_policy_document" "ecs_task_execution" {
  # ポリシーを継承
  source_policy_documents = [data.aws_iam_policy.ecs_task_execution_role_policy.policy]

  # SSMから環境変数を取得できる権限
  statement {
    effect = "Allow"
    actions = ["ssm:GetPatameters", "kms:Decrypt"]
  }
}

# IAMポリシーとIAMロールの作成
module "ecs_task_execution_role" {
  source = "./iam_role"
  name = "ecs-task-execution"
  identifier = "ecs-tasks.amazonaws.com"
  policy = data.aws_iam_policy_document.ecs_task_execution.json
}
