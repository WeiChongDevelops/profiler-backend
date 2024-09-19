import json

try:
    import layer_module
except ImportError:
    layer_module = None


def lambda_handler(event, context):
    post_ids = event["post_ids"]
    comments = {
        "post1": ["comment1", "comment2"],
        "post2": ["comment3", "comment4"],
        "post3": ["comment5", "comment6"],
    }

    if layer_module is not None:
        print(f"{layer_module.layer_string} get_post_comments")
    else:
        print("Layer module not available in local environment.")

    print(f"Comments for post IDs {post_ids}: {comments}")
    return {"comments": comments}
