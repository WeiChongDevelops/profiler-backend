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
    return post_ids


async def get_user_post_ids(async_client, user_id):
    post_ids = []
    page_id = None  # Start with no page ID to get the first page
    page_count = 0
    page_limit = 3

    while page_count < page_limit:
        posts = await async_client.user_medias_v2(user_id, page_id)
        print("Below is raw post/error output.")
        print(posts)

        # Extract post IDs from the current page
        current_post_ids = [
            item.get("pk") for item in posts["response"].get("items", []) if "pk" in item
        ]
        post_ids.extend(current_post_ids)  # Append the post IDs from this page

        # Check if there is a next page
        page_id = posts["response"].get("next_page_id")
        if not page_id:  # If there's no next page, break the loop
            break

        page_count += 1  # Increment page counter

    return post_ids