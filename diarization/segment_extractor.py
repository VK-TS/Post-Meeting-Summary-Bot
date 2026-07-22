from pathlib import Path

from pydub import AudioSegment


SEGMENT_DIR = "segments"


Path(SEGMENT_DIR).mkdir(
    exist_ok=True
)


def extract_segment(
    audio,
    stem,
    start,
    end,
    speaker,
    index
):
    start_ms = start * 1000
    end_ms = end * 1000

    segment = audio[start_ms:end_ms]

    output_path = f"{SEGMENT_DIR}/{stem}_{speaker}_{index}.wav"

    segment.export(
        output_path,
        format="wav"
    )

    return output_path
