import json
import boto3


def lambda_handler(event, context):
    try:
        comments = event.get("comments", [])
        print(f"Received comments: {comments}")

        if not comments:
            print("No comments provided in the input.")
            return {
                "statusCode": 400,
                "body": json.dumps({"error": "No comments provided in the input."}),
            }

        typescript_type_string = (
            "interface AlertMetricTotals { "
            "  isThreatening: number; "
            "  isHarassment: number; "
            "  isBullying: number; "
            "  isSexuallyInappropriate: number; "
            "  isExtremist: number; "
            "  isExplicitLanguage: number; "
            "  isEmotionallyHeated: number; "
            "  isToxic: number; "
            "  isHateSpeech: number; "
            "  isPositive: number; "
            "  isNeutralOrUnclearValence: number; "
            "  isNegative: number; "
            "}"
        )

        arguments = {
            "modelId": "anthropic.claude-3-sonnet-20240229-v1:0",
            "contentType": "application/json",
            "accept": "application/json",
            "body": json.dumps(
                {
                    "anthropic_version": "bedrock-2023-05-31",
                    "max_tokens": 3000,
                    "temperature": 0,
                    "system": (
                        "You are a JSON-only kiosk incapable of natural language. "
                        "Respond only with a single AlertMetrics object that totals the number of the given comments "
                        "that fit any of the sentiment metrics, based on the typescript definition "
                        "I will share shortly. Note that every comment must additionally add 1 to either [isPositive, "
                        "isNeutralOrUnclearValence or isNegative]. If you're not sure, just add 1 to isNeutralOrUnclearValence. "
                        "Note also that if a comment fits multiple categories, you must add 1 to ALL of those categories. "
                        "Here is the definition your response conforms to: \n"
                        + typescript_type_string
                    ),
                    "messages": [
                        {
                            "role": "user",
                            "content": "Here are the comments: " + json.dumps(comments),
                        },
                    ],
                }
            ).encode("utf-8"),
        }

        bedrock_runtime = boto3.client("bedrock-runtime")
        response = bedrock_runtime.invoke_model(**arguments)

        # Read and parse the response
        response_body = response["body"].read().decode("utf-8")
        response_json = json.loads(response_body)

        # Print the model output
        print(f"Model output: {response_json}")

        return {"statusCode": 200, "body": json.dumps(response_json)}

    except Exception as e:
        print(f"Error occurred: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps(
                {"error": "An error occurred while processing the request."}
            ),
        }
