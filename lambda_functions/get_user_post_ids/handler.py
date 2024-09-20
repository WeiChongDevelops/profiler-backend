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

    print(f"Found {len(post_ids)} post IDs for user {user_id}: {post_ids}")
    return post_ids


async def get_user_post_ids(async_client, user_id):
    post_ids = []
    page_id = None  # Start with no page ID to get the first page
    page_count = 0
    page_limit = 1

    while page_count < page_limit:
        posts = await async_client.user_medias_v2(user_id, page_id)
        print("Below is raw post/error output.")
        print(posts)

        # Extract post IDs from the current page
        current_post_ids = [
            item.get("pk")
            for item in posts["response"].get("items", [])
            if "pk" in item
        ]
        post_ids.extend(current_post_ids)  # Append the post IDs from this page

        if not posts["response"].get("more_available"):
            break

        print(
            f"Below are the {len(current_post_ids)} post IDs found on page {page_count + 1}"
        )
        print(current_post_ids)

        page_count += 1

    return post_ids
