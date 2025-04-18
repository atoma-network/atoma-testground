import os
import time
from dotenv import load_dotenv
from atoma_sdk import AtomaSDK

load_dotenv()

def main():
    try:
        if not os.getenv('ATOMA_API_KEY'):
            raise ValueError("ATOMA_API_KEY not found in environment variables")

        if not os.getenv('ATOMA_SERVER_URL'):
            raise ValueError("ATOMA_SERVER_URL not found in environment variables")

        atoma_sdk = AtomaSDK(
            api_key=os.getenv('ATOMA_API_KEY'),
            server_url=os.getenv('ATOMA_SERVER_URL'),
        )

        print("Testing health check:")
        health_response = atoma_sdk.health.health()
        print(health_response)

        print("\nStarting chat:")
        start_time = time.time()
        response = atoma_sdk.confidential_chat.create(
            model='TinyLlama/TinyLlama-1.1B-Chat-v1.0',
            messages=[
                {
                    'role': 'user',
                    'content': 'What is the capital of Jamaica?',
                },
            ],
        )
        end_time = time.time()
        time_taken = end_time - start_time

        print(response)
        print(f"\nTotal time taken: {time_taken:.2f} seconds")

    except Exception as e:
        print(f"An error occurred: {str(e)}")

if __name__ == "__main__":
    main()
