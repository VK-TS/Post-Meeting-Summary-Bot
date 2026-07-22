import os
import wave
from array import array

from dotenv import load_dotenv

load_dotenv()
pipeline = None


def load_wav_for_pyannote(audio_path):
    with wave.open(str(audio_path), "rb") as wav:
        sample_rate = wav.getframerate()
        channels = wav.getnchannels()
        sample_width = wav.getsampwidth()
        frames = wav.readframes(wav.getnframes())

    if sample_width != 2:
        raise RuntimeError("Diarization expects 16-bit PCM WAV after normalization")

    samples = array("h")
    samples.frombytes(frames)

    import torch

    waveform = torch.tensor(samples, dtype=torch.float32).reshape(-1, channels).T
    return {"waveform": waveform / 32768.0, "sample_rate": sample_rate}


def get_speaker_diarization(output):
    return getattr(output, "speaker_diarization", output)


def merge_segments(segments, max_gap=0.75):
    merged = []
    for segment in segments:
        if (
            merged
            and merged[-1]["speaker"] == segment["speaker"]
            and segment["start"] - merged[-1]["end"] <= max_gap
        ):
            merged[-1]["end"] = segment["end"]
        else:
            merged.append(segment)
    return merged


def diarize_audio(audio_path):
    global pipeline
    if pipeline is None:
        from pyannote.audio import Pipeline

        token = os.getenv("HF_TOKEN")
        if not token:
            raise RuntimeError("HF_TOKEN is required for pyannote diarization")
        pipeline = Pipeline.from_pretrained(
            "pyannote/speaker-diarization-3.1",
            token=token,
        )

    diarization = get_speaker_diarization(pipeline(load_wav_for_pyannote(audio_path)))

    segments = []

    for turn, _, speaker in diarization.itertracks(yield_label=True):

        segments.append({
            "speaker": speaker,
            "start": turn.start,
            "end": turn.end
        })

    return merge_segments(segments)
