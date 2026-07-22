from llm.prompt_loader import load_prompt
from llm.ollama_client import generate

def coaching_feedback(transcript, speaker=None):
    prompt = load_prompt(
        "coaching.txt",
        transcript=transcript,
        speaker=speaker or "speaker",
    )
    return generate(prompt)