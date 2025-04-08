# type:ignore
from atoma_sdk import AtomaSDK
import asyncio
import os
import threading


def get_chat(model: str, query: str):
    completion = atoma_sdk.chat.create(
        model=model,
        messages=[
            {"role": "developer", "content": "You are a helpful assistant."},
            {"role": "user", "content": query},
        ],
    )
    return completion.choices[0].message.content


async def get_chat_async(model: str, query: str):
    completion = await atoma_sdk.chat.create_async(
        model=model,
        messages=[
            {"role": "developer", "content": "You are a helpful assistant."},
            {"role": "user", "content": query},
        ],
    )
    return completion.choices[0].message.content


def get_chat_confidential(model: str, query: str):
    completion = atoma_sdk.confidential_chat.create(
        model=model,
        messages=[
            {"role": "developer", "content": "You are a helpful assistant."},
            {"role": "user", "content": query},
        ],
    )
    return completion.choices[0].message.content


async def get_chat_confidential_async(model: str, query: str):
    completion = await atoma_sdk.confidential_chat.create_async(
        model=model,
        messages=[
            {"role": "developer", "content": "You are a helpful assistant."},
            {"role": "user", "content": query},
        ],
    )
    return completion.choices[0].message.content


def get_chat_stream(model: str, prompt: str):
    completion = atoma_sdk.chat.create_stream(
        model=model,
        messages=[
            {"role": "developer", "content": "You are a helpful assistant."},
            {"role": "user", "content": prompt},
        ],
    )
    s = ""
    for a in completion:
        print(a)
        if len(a.data.choices) > 0:
            s += a.data.choices[0].delta.content
    return s


async def get_chat_stream_async(model: str, prompt: str):
    completion = await atoma_sdk.chat.create_stream_async(
        model=model,
        messages=[
            {"role": "developer", "content": "You are a helpful assistant."},
            {"role": "user", "content": prompt},
        ],
    )
    s = ""
    async for a in completion:
        if len(a.data.choices) > 0:
            s += a.data.choices[0].delta.content
    return s


def get_chat_confidential_stream(model: str, prompt: str):
    completion = atoma_sdk.confidential_chat.create_stream(
        model=model,
        messages=[
            {"role": "developer", "content": "You are a helpful assistant."},
            {"role": "user", "content": prompt},
        ],
    )
    s = ""
    for a in completion:
        if len(a.data.choices) > 0:
            s += a.data.choices[0].delta.content
    return s


async def get_chat_confidential_stream_async(model: str, prompt: str):
    completion = await atoma_sdk.confidential_chat.create_stream_async(
        model=model,
        messages=[
            {"role": "developer", "content": "You are a helpful assistant."},
            {"role": "user", "content": prompt},
        ],
    )
    s = ""
    async for a in completion:
        if len(a.data.choices) > 0:
            s += a.data.choices[0].delta.content
    return s


model = "neuralmagic/Qwen2-72B-Instruct-FP8"

print_lock = asyncio.Lock()


with AtomaSDK(bearer_auth=api_token) as atoma_sdk:
    semaphore = asyncio.Semaphore(20)

    def fetch_fact(i):
        prompt = f"Tell me a random fact about number {i}"
        fn = [
            get_chat,
            get_chat_stream,
            get_chat_confidential,
            get_chat_confidential_stream,
        ][i % 4]
        response = fn(model, prompt)
        print_lock = threading.Lock()
        with print_lock:
            print(response)

    async def fetch_fact_async(i):
        prompt = f"Tell me a random fact about number {i}"
        fn = [
            get_chat_async,
            get_chat_stream_async,
            get_chat_confidential_async,
            get_chat_confidential_stream_async,
        ][i % 4]
        return await fn(model, prompt)

    async def fetch_fact_async_kill(i):
        async with semaphore:  # Acquire semaphore
            async with print_lock:
                print(i, "start")
            try:
                # res = await fetch_fact_async(i)
                res = await asyncio.wait_for(fetch_fact_async(i % 4), timeout=100)
            except Exception as e:
                res = f"Timeout {e}"
            async with print_lock:
                print(i, res)

    def single_test():
        for i in [1]:
            fetch_fact(i)

    # async def single_test_kill():
    #     for i in range(20):
    #         try:
    #             a = await asyncio.wait_for(fetch_fact_async(i), timeout=3)
    #             print(a)
    #         except Exception as e:
    #             print("Timeout", e)

    # asyncio.run(single_test_kill())
    # print(single_test())

    async def run_tests():
        tasks = [fetch_fact_async_kill(i) for i in range(100)]
        await asyncio.gather(*tasks)

    asyncio.run(run_tests())

    # threads = []
    # for i in range(100):
    #     thread = threading.Thread(target=fetch_fact_async_kill_wrapper, args=(i,))
    #     threads.append(thread)
    #     thread.start()

    # for thread in threads:
    #     thread.join()
