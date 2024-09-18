import json


def lambda_handler(event, context):
    user_id = event["user_id"]
    post_ids = ["post1", "post2", "post3"]
    print(f"Post IDs for user {user_id}: {post_ids}")
    return {"post_ids": post_ids}
