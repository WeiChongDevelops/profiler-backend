import asyncio
import json
from layer_module import get_async_client


def lambda_handler(event, context):
    return asyncio.run(process_event(event))


async def process_event(event):
    print("Received event: " + json.dumps(event, indent=2))
    user_id = event.get("user_id")

    async_client = get_async_client()
    post_ids = await get_user_post_ids(async_client, user_id)

    print(f"Post IDs for user {user_id}: {post_ids}")
    return {"post_ids": post_ids}


async def get_user_post_ids(async_client, user_id):
    posts = await async_client.user_medias_v2(user_id)
    print("Below is raw post/error output.")
    print(posts)
    post_ids = [
        item.get("pk") for item in posts["response"].get("items", []) if "pk" in item
    ]
    return post_ids
