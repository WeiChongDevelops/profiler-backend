import asyncio
import json
from layer_module import get_async_client


def lambda_handler(event, context):
    return asyncio.run(process_event(event))


async def process_event(event):
    print("Received event: " + json.dumps(event, indent=2))
    username = event.get("username")

    async_client = get_async_client()
    user_info = await get_instagram_user_info(async_client, username)

    print("Getting user info from Instagram username...")
    print(f"User info for {username}: {user_info}")

    return user_info


async def get_instagram_user_info(async_client, username):
    user_info = await async_client.user_by_username_v1(username)
    print("Below is raw user/error output.")
    print(user_info)
    return user_info
