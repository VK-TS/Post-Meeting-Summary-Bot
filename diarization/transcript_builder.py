def build_speaker_transcript(speaker_segments):
    return [
        {"speaker": item["speaker"], "text": item["text"].strip()}
        for item in speaker_segments
        if item.get("text", "").strip()
    ]
