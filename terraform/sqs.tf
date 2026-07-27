locals {
  sqs_queues = [
    "user-created-event",
    "payment-processed-event",
    "payment-processed-catalog",
  ]
}

resource "aws_sqs_queue" "queues" {
  for_each = toset(local.sqs_queues)

  name = each.value
}
