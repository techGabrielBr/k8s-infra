resource "aws_iam_user" "app" {
  name = "${var.project_name}-app"
}

resource "aws_iam_user_policy" "app" {
  name = "${var.project_name}-app-policy"
  user = aws_iam_user.app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SqsAccess"
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = [for queue in aws_sqs_queue.queues : queue.arn]
      }
    ]
  })
}
