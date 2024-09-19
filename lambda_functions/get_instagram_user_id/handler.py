import asyncio
from layer_module import layer_string, get_bye_string, get_test_key, get_async_client


def lambda_handler(event, context):
    return asyncio.run(process_event(event))


async def process_event(event):
    username = event.get("username")

    print(f"{layer_string} get_instagram_user_id")

    bye_string = get_bye_string()
    print(bye_string)

    test_key = get_test_key()
    print(f"Found test key: {test_key}")

    async_client = get_async_client()
    user_id = await get_instagram_user_id(async_client, username)
    # user_id = "test_user_id"

    print("Getting user ID for Instagram username...")
    print(f"User ID for {username}: {user_id}")

    return {"user_id": user_id}


# Async function to fetch Instagram user ID
async def get_instagram_user_id(async_client, username):
    user = await async_client.user_by_username_v1(username)
    return user["pk"]
