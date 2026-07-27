resource "aws_iam_role" "lambda_notifications" {
  name = "${var.project_name}-notifications-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_notifications.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Permite à Lambda consumir as filas SQS (trigger)
resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda_notifications.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_lambda_function" "notifications" {
  function_name = "notifications-function"
  role          = aws_iam_role.lambda_notifications.arn

  runtime = "nodejs20.x"
  handler = "index.handler"

  filename         = "${path.module}/../../Lambdas/NotificationsFunction/function.zip"
  source_code_hash = filebase64sha256("${path.module}/../../Lambdas/NotificationsFunction/function.zip")

  timeout = 15
}

resource "aws_lambda_event_source_mapping" "user_created" {
  function_name    = aws_lambda_function.notifications.arn
  event_source_arn = aws_sqs_queue.queues["user-created-event"].arn
  batch_size       = 10
}

resource "aws_lambda_event_source_mapping" "payment_processed" {
  function_name    = aws_lambda_function.notifications.arn
  event_source_arn = aws_sqs_queue.queues["payment-processed-event"].arn
  batch_size       = 10
}
