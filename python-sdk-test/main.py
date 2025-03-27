# type:ignore
from atoma_sdk import AtomaSDK
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


def get_chat_confidential(model: str, query: str):
    completion = atoma_sdk.confidential_chat.create(
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
        if len(a.choices) > 0:
            s += a.choices[0].delta.content
    return s


model = "Infermatic/Llama-3.3-70B-Instruct-FP8-Dynamic"

with AtomaSDK(bearer_auth=os.getenv("ATOMASDK_BEARER_AUTH", "")) as atoma_sdk:
    semaphore = threading.Semaphore(20)

    def fetch_fact(i):
        with semaphore:  # Acquire semaphore
            prompt = f"Tell me a random fact about number {i}"
            fn = [get_chat, get_chat_confidential_stream, get_chat_stream, get_chat_confidential][i % 4]
            response = fn(model, prompt)
            print_lock = threading.Lock()
            with print_lock:
                print(response)

    threads = []
    for i in range(500):
        thread = threading.Thread(target=fetch_fact, args=(i,))
        threads.append(thread)
        thread.start()

    for thread in threads:
        thread.join()
