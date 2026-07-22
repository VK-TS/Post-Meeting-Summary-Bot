import re


def transcript_to_text(transcript):

    lines = []

    for item in transcript:

        line = (
            f"{item['speaker']}:\n"
            f"  {item['text']}"
        )

        lines.append(line)

    return "\n\n".join(lines)


def format_generated_text(text):
    text = re.sub(r"\s*([*-]\s+)", r"\n\1", text.strip())
    text = re.sub(r"\s+((?:\d+|[A-Z])[\).]\s+)", r"\n\1", text)
    return text.strip()
