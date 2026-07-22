import asyncio
from utils.chunker import chunk_text
from .ollama_client import generate
from .prompt_loader import load_prompt

async def summarize_large_transcript(transcript: str) -> str:
    words = transcript.split()
    word_count = len(words)

    # Quick win: Skip chunking for short transcripts
    if word_count < 2000:
        prompt = load_prompt("summary.txt", transcript=transcript)
        return await asyncio.to_thread(generate, prompt)

    # Process chunks in parallel for longer transcripts
    chunks = chunk_text(transcript)
    
    async def summarize_chunk(chunk):
        prompt = load_prompt("summary.txt", transcript=chunk)
        return await asyncio.to_thread(generate, prompt)
    
    chunk_summaries = await asyncio.gather(*[summarize_chunk(chunk) for chunk in chunks])
    
    combined = "\n".join(chunk_summaries)
    
    final_prompt = load_prompt("summary.txt", transcript=combined)
    final_summary = await asyncio.to_thread(generate, final_prompt)
    return final_summary
