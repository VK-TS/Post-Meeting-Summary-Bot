import os
from pathlib import Path

NORMALIZED_DIR = "normalized"
FFMPEG_PATH = os.getenv(
    "FFMPEG_PATH",
    r"C:\Users\TS6207_VENKAT\Downloads\ffmpeg-8.1.1-essentials_build\ffmpeg-8.1.1-essentials_build\bin\ffmpeg.exe",
)
FFPROBE_PATH = os.getenv(
    "FFPROBE_PATH",
    r"C:\Users\TS6207_VENKAT\Downloads\ffmpeg-8.1.1-essentials_build\ffmpeg-8.1.1-essentials_build\bin\ffprobe.exe",
)

FFMPEG_DIR = str(Path(FFMPEG_PATH).parent)
os.environ["PATH"] = FFMPEG_DIR + os.pathsep + os.environ.get("PATH", "")

from pydub import AudioSegment

AudioSegment.converter = FFMPEG_PATH
AudioSegment.ffmpeg = FFMPEG_PATH

def normalize_audio(input_path):
    if not Path(FFMPEG_PATH).exists() or not Path(FFPROBE_PATH).exists():
        raise RuntimeError("FFMPEG_PATH and FFPROBE_PATH must point to valid executables")

    input_path = Path(input_path)
    output_path = Path(NORMALIZED_DIR) / (input_path.stem + ".wav")

    audio = AudioSegment.from_file(input_path)
    audio = audio.set_frame_rate(16000)
    audio = audio.set_channels(1)
    audio.export(
        output_path,
        format="wav"
    )

    return str(output_path)
