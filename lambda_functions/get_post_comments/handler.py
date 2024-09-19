import json


def lambda_handler(event, context):
    post_ids = event["post_ids"]
    comments = {
        "post1": ["comment1", "comment2"],
        "post2": ["comment3", "comment4"],
        "post3": ["comment5", "comment6"],
    }
    print(f"Comments for post IDs {post_ids}: {comments}")
    return {"comments": comments}
