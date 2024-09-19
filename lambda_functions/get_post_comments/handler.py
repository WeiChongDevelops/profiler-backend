import asyncio
import json
from typing import List
from layer_module import get_async_client


def lambda_handler(event, context):
    return asyncio.run(process_event(event))


async def process_event(event):
    print("Received event: " + json.dumps(event, indent=2))
    post_ids = event.get("post_ids")

    async_client = get_async_client()
    comments = await get_post_comments(async_client, post_ids)

    print(f"Comments for post IDs {post_ids}: {comments}")
    return {"comments": comments}


async def get_post_comments(async_client, post_ids: List[str]) -> List:
    all_comments = [
        await async_client.media_comments_v2(post_id) for post_id in post_ids
    ]
    print("Below is raw comment/error output.")
    print(all_comments)
    comments_filtered = [
        item["response"]["caption"]["text"]
        for item in all_comments
        if "caption" in item["response"]
    ] + [
        comment["text"]
        for item in all_comments
        for comment in item["response"].get("comments", [])
    ]
    return comments_filtered
