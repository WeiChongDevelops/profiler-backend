import json

try:
    import layer_module
except ImportError:
    layer_module = None


def lambda_handler(event, context):
    user_id = event["user_id"]
    post_ids = ["post1", "post2", "post3"]

    if layer_module is not None:
        print(f"{layer_module.layer_string} get_user_post_ids")
    else:
        print("Layer module not available in local environment.")

    print(f"Post IDs for user {user_id}: {post_ids}")
    return {"post_ids": post_ids}
