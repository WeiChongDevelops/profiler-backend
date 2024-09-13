import json


def hello_world(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Success: get_instagram_user_id"}),
    }


def another_function(event, context):
    # Handle another event
    pass
