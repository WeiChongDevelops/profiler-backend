import asyncio
import anthropic
import json
import os

ANTHROPIC_MODEL = "claude-3-5-sonnet-20240620"


def lambda_handler(event, context):
    return asyncio.run(process_event(event))


async def process_event(event):
    print("Received event: " + json.dumps(event, indent=2))
    comments = event.get("comments")

    # Get the sentiment totals
    sentiment_metric_counts = await get_sentiment_metric_counts(comments)

    # Get the sentiment proportions
    sentiment_metric_proportions = await get_sentiment_metric_proportions(
        sentiment_metric_counts, comments.length
    )

    # Package the sentiment data together
    sentiment_data = {
        "sentiment_metric_counts": sentiment_metric_counts,
        "sentiment_metric_proportions": sentiment_metric_proportions,
    }

    print(f"Sentiment Data: {sentiment_data}")
    return {"sentiment_data": sentiment_data}


async def get_sentiment_metric_proportions(counts, total_tweets):
    fractions = {k: v / total_tweets for k, v in counts.items()}
    return fractions


async def get_sentiment_metric_counts(tweets):
    client = anthropic.Client(
        api_key=os.getenv("ANTHROPIC_API_KEY"),
    )

    typescriptTypeString = """
    export interface SentimentMetrics {
      isThreatening: boolean;
      isHarassment: boolean;
      isBullying: boolean;
      isSexuallyInappropriate: boolean;
      isExtremist: boolean;
      isExplicitLanguage: boolean;
      isEmotionallyHeated: boolean;
      isToxic: boolean;
      isHateSpeech: boolean;
      isPositive: boolean;
      isNeutralOrUnclearValence: boolean;
      isNegative: boolean;
    }

    export type AlertMetric = keyof SentimentMetrics;

    export interface SentimentMetricCounts {
      isThreatening: number;
      isHarassment: number;
      isBullying: number;
      isSexuallyInappropriate: number;
      isExtremist: number;
      isExplicitLanguage: number;
      isEmotionallyHeated: number;
      isToxic: number;
      isHateSpeech: number;
      isPositive: number;
      isNeutralOrUnclearValence: number;
      isNegative: number;
    }
    """

    prompt = (
        anthropic.HUMAN_PROMPT
        + "You are a JSON-only kiosk incapable of natural language. "
        "Respond only with a single SentimentMetricCounts object that totals the number of the given tweets "
        "that fit any of the sentiment metrics, based on the typescript definitions "
        "I will share shortly. Note that every tweet must also add 1 to either [isPositive, "
        "isNeutralOrUnclearValence or isNegative]. If you're not sure, just add 1 to isNeutralOrUnclearValence. Note also that if a tweet fits multiple "
        "categories, you must add 1 to all of those categories. Here is the typescript def: "
        + typescriptTypeString
        + "\nHere are the tweets: "
        + json.dumps(tweets)
        + anthropic.AI_PROMPT
    )

    def call_anthropic():
        completion = client.messages.create(
            model=ANTHROPIC_MODEL,
            max_tokens=4000,
            temperature=0,
            messages=[{"role": "user", "content": prompt}],
        )
        return completion

    # Run the synchronous API call in a separate thread
    response = await asyncio.to_thread(call_anthropic)

    # Parse the JSON response
    try:
        counts = json.loads(response["content"])
    except json.JSONDecodeError:
        counts = {}

    print(counts)

    return counts
