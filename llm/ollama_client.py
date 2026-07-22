import asyncio
import os
import requests
from dotenv import load_dotenv
from .prompt_loader import load_prompt

load_dotenv()

OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434/api/generate")
MODEL = os.getenv("OLLAMA_MODEL", "llama3.2:3b")
TIMEOUT = int(os.getenv("OLLAMA_TIMEOUT", "1800"))

def generate(prompt: str):
    response = requests.post(
        OLLAMA_URL,
        json={
            "model" : MODEL,
            "prompt" : prompt,
            "stream" : False
        },
        timeout=TIMEOUT,
    )

    response.raise_for_status()
    return response.json()["response"]

def summarize(transcript: str)->str:
    prompt = load_prompt(
        "summary.txt",
        transcript = transcript 
    )
    return generate(prompt)

async def coach(transcript: str) -> str:
    prompt = load_prompt(
        "coaching.txt",
        transcript=transcript 
    )
    return await asyncio.to_thread(generate, prompt)
