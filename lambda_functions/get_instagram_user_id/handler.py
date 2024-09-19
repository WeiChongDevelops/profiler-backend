import json


def lambda_handler(event, context):
    username = event.get("username")
    user_id = "sample_user_id"
    print("Getting user ID for Instagram username...")
    print(f"User ID for {username}: {user_id}")
    return {"user_id": user_id}
