import json


def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Success: get_instagram_user_id"}),
    }
