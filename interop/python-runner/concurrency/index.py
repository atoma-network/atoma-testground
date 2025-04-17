from atoma_sdk import AtomaSDK
import asyncio
import os
import random
import time
from dotenv import load_dotenv
from datetime import datetime

load_dotenv()

def get_random_sleep_time(base_time: float, deviation: float = 0.2) -> float:
    """Get a random sleep time with deviation."""
    return base_time + (random.random() * 2 - 1) * deviation * base_time

async def single_request(atoma_sdk: AtomaSDK, prompt: str, request_num: int) -> int:
    """Make a single request to the Atoma API."""
    try:
        start_time = time.time()
        start_datetime = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        print(f"\nRequest {request_num} started at: {start_datetime}")

        response = await atoma_sdk.chat.create_async(
            model='TinyLlama/TinyLlama-1.1B-Chat-v1.0',
            messages=[
                {
                    'role': 'user',
                    'content': prompt,
                },
            ],
        )
        end_time = time.time()
        time_taken = end_time - start_time
        print(f"Request {request_num} completed in: {time_taken:.2f} seconds")
        print(f"Response tokens: {response.usage.total_tokens if response.usage else 0}")

        return response.usage.total_tokens if response.usage else 0
    except Exception as e:
        print(f"Error in request {request_num}: {str(e)}")
        return 0

async def process_batch(atoma_sdk: AtomaSDK, start_index: int, batch_size: int, sleep_time: float) -> int:
    """Process a batch of requests."""
    total_tokens = 0
    batch_start_time = time.time()
    print(f"\nStarting batch from index {start_index}")

    for i in range(start_index, min(start_index + batch_size, 10000)):
        try:
            prompt = "What is the capital of Jamaica?"
            tokens = await single_request(atoma_sdk, prompt, i)
            total_tokens += tokens

            # Sleep for random time before next request
            sleep_duration = get_random_sleep_time(sleep_time)
            print(f"Sleeping for {sleep_duration/1000:.2f} seconds before next request")
            await asyncio.sleep(sleep_duration / 1000)  # Convert to seconds
        except Exception as e:
            print(f"Error in batch processing at index {i}: {str(e)}")

    batch_time = time.time() - batch_start_time
    print(f"\nBatch from index {start_index} completed in {batch_time:.2f} seconds")
    return total_tokens

async def run(max_concurrency: int = 32, sleep_time: float = 5000):
    """Run multiple concurrent batches of API requests."""
    if not os.getenv('ATOMA_API_KEY'):
        raise ValueError("ATOMA_API_KEY not found in environment variables")
    if not os.getenv('ATOMA_SERVER_URL'):
        raise ValueError("ATOMA_SERVER_URL not found in environment variables")

    atoma_sdk = AtomaSDK(
        api_key=os.getenv('ATOMA_API_KEY'),
        server_url=os.getenv('ATOMA_SERVER_URL'),
    )

    start_time = time.time()
    start_datetime = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print(f"\nStarting concurrent requests at: {start_datetime}")

    total_requests = 10000
    batch_size = total_requests // max_concurrency + (1 if total_requests % max_concurrency else 0)

    print(f"Configuration:")
    print(f"- Total requests: {total_requests}")
    print(f"- Concurrent batches: {max_concurrency}")
    print(f"- Batch size: {batch_size}")
    print(f"- Base sleep time: {sleep_time/1000:.2f} seconds")

    # Create tasks for each batch
    tasks = [
        process_batch(atoma_sdk, i * batch_size, batch_size, sleep_time)
        for i in range(max_concurrency)
    ]

    # Run all batches concurrently
    results = await asyncio.gather(*tasks)
    total_tokens = sum(results)

    end_time = time.time()
    end_datetime = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    total_time = end_time - start_time

    print("\nExecution Summary:")
    print(f"- Start time: {start_datetime}")
    print(f"- End time: {end_datetime}")
    print(f"- Total execution time: {total_time:.2f} seconds")
    print(f"- Average time per request: {total_time/total_requests:.2f} seconds")
    print(f"- Total tokens: {total_tokens}")
    print(f"- Average tokens per request: {total_tokens/total_requests:.2f}")

if __name__ == "__main__":
    # Run 32 requests in parallel with 5 second sleep time
    asyncio.run(run(32, 5000))