import json


def hello_world(event, context):
    return {
        "statusCode": 200,
        "body": json.dumps({"message": "Success: get_post_comments"}),
    }


def another_function(event, context):
    # Handle another event
    pass
