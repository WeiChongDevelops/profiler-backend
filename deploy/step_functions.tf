# Step Functions State Machine
resource "aws_sfn_state_machine" "instagram_workflow" {
  name     = "instagram-workflow"
  role_arn = aws_iam_role.step_functions_role.arn
  type     = "EXPRESS"

  definition = jsonencode({
    StartAt = "GetInstagramUserId",
    States  = {
      GetInstagramUserId = {
        Type       = "Task",
        Resource   = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:get_instagram_user_id",
        Next       = "GetUserPostIds",
        InputPath  = "$",
        ResultPath = "$.user_id"
      },
      GetUserPostIds = {
        Type       = "Task",
        Resource   = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:get_user_post_ids",
        Next       = "GetPostComments",
        ResultPath = "$.post_ids"
      },
      GetPostComments = {
        Type         = "Task",
        Resource     = "arn:aws:lambda:${var.aws_region}:${data.aws_caller_identity.current.account_id}:function:get_post_comments",
        End          = true,
        ResultPath   = "$.comments",
        OutputPath   = "$.comments"
      }
    }
  })
}