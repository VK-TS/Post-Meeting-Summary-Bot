from fastapi import FastAPI, UploadFile, File, BackgroundTasks, Form, Response
from fastapi.middleware.cors import CORSMiddleware

import asyncio
import shutil
import os
import uuid
from pathlib import Path

from audio.converter import normalize_audio
from audio.validator import validate_audio_file

from notifications.mailer import send_report_email, send_speaker_feedback_email

from diarization.diarizer import diarize_audio
from diarization.transcript_builder import build_speaker_transcript
from utils.exporter import make_docx, make_pdf
from utils.transcript_formatter import format_generated_text, transcript_to_text

from stt.vosk import transcribe_audio

from llm.summarizer import summarize_large_transcript
from llm.coaching import coaching_feedback

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173", "http://localhost:3000"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = "uploads"

jobs = {}

os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs("normalized", exist_ok=True)
os.makedirs("segments", exist_ok=True)


def parse_speaker_emails(raw_text):
    mapping = {}
    if not raw_text:
        return mapping

    for line in raw_text.splitlines():
        if not line.strip():
            continue
        if ":" in line:
            speaker, email = line.split(":", 1)
        elif "=" in line:
            speaker, email = line.split("=", 1)
        elif "," in line:
            speaker, email = line.split(",", 1)
        else:
            continue
        mapping[speaker.strip()] = email.strip()

    return mapping


def set_job_status(job_id, stage, **extra):
    jobs[job_id] = {"status": "processing", "stage": stage, **extra}


def assign_words_to_segments(words, diarization_segments):
    speaker_segments = [dict(segment, words=[]) for segment in diarization_segments]
    segment_index = 0
    for word in words:
        midpoint = (word["start"] + word["end"]) / 2
        while (
            segment_index < len(speaker_segments) - 1
            and speaker_segments[segment_index]["end"] < midpoint
        ):
            segment_index += 1
        segment = speaker_segments[segment_index] if speaker_segments else None
        if segment and segment["start"] <= midpoint <= segment["end"]:
            segment["words"].append(word["word"])
    return [
        {"speaker": segment["speaker"], "text": " ".join(segment["words"])}
        for segment in speaker_segments
        if segment["words"]
    ]


def process_audio_job(job_id, file_path, recipient_email, speaker_emails, speaker_names, send_mode):
    normalized_path = None
    stage = "starting"
    try:
        stage = "normalizing"
        set_job_status(job_id, stage)
        normalized_path = normalize_audio(file_path)
        stage = "diarizing"
        set_job_status(job_id, stage)
        diarization_segments = diarize_audio(normalized_path)
        stage = "transcribing"
        set_job_status(job_id, stage)
        _, words = transcribe_audio(normalized_path, with_words=True)
        speaker_segments = assign_words_to_segments(words, diarization_segments)
        for segment in speaker_segments:
            segment["speaker"] = speaker_names.get(segment["speaker"], segment["speaker"])
        speaker_texts = {}
        for segment in speaker_segments:
            speaker_texts.setdefault(segment["speaker"], []).append(segment["text"])

        transcript_text = transcript_to_text(build_speaker_transcript(speaker_segments))
        stage = "summarizing"
        set_job_status(job_id, stage)
        summary = format_generated_text(asyncio.run(summarize_large_transcript(transcript_text)))

        stage = "coaching"
        set_job_status(job_id, stage)
        speaker_feedback = {
            speaker: format_generated_text(coaching_feedback(text, speaker=speaker))
            for speaker, texts in speaker_texts.items()
            for text in [" ".join(texts)]
        }

        feedback_summary = "\n\n".join(
            f"{speaker}: {feedback}"
            for speaker, feedback in speaker_feedback.items()
        )

        stage = "emailing"
        set_job_status(job_id, stage)
        if send_mode == "per_speaker" and speaker_emails:
            for speaker, email in speaker_emails.items():
                if email and speaker in speaker_feedback:
                    send_speaker_feedback_email(email, speaker, speaker_feedback[speaker])
        elif recipient_email:
            send_report_email(recipient_email, summary, speaker_feedback, transcript_text)

        jobs[job_id] = {
            "status": "done",
            "result": {
                "transcript": transcript_text,
                "summary": summary,
                "feedback": feedback_summary,
                "speaker_feedback": speaker_feedback,
            },
        }
    except Exception as exc:
        jobs[job_id] = {"status": "failed", "stage": stage, "error": str(exc)}
    finally:
        for path in (file_path, normalized_path):
            if path:
                Path(path).unlink(missing_ok=True)


@app.post("/process-call")
async def process_call(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    recipient_email: str = Form(""),
    speaker_emails: str = Form(""),
    speaker_names: str = Form(""),
    send_mode: str = Form("all"),
):
    if not validate_audio_file(file.filename):
        return {"error": "Unsupported audio format"}
    if send_mode not in {"all", "per_speaker"}:
        return {"error": "Unsupported send mode"}

    job_id = str(uuid.uuid4())
    set_job_status(job_id, "queued")

    suffix = Path(file.filename).suffix
    file_path = os.path.join(UPLOAD_DIR, f"{job_id}{suffix}")
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    background_tasks.add_task(
        process_audio_job,
        job_id,
        file_path,
        recipient_email,
        parse_speaker_emails(speaker_emails),
        parse_speaker_emails(speaker_names),
        send_mode,
    )

    return {"job_id": job_id}


@app.get("/job/{job_id}")
def get_job(job_id: str):
    if job_id not in jobs:
        return {"status": "not_found"}
    return jobs[job_id]


@app.get("/job/{job_id}/export/{file_type}")
def export_job(job_id: str, file_type: str):
    job = jobs.get(job_id)
    if not job or job.get("status") != "done":
        return {"status": "not_found"}
    if file_type == "docx":
        return Response(make_docx(job["result"]), media_type="application/vnd.openxmlformats-officedocument.wordprocessingml.document", headers={"Content-Disposition": "attachment; filename=meeting-report.docx"})
    if file_type == "pdf":
        return Response(make_pdf(job["result"]), media_type="application/pdf", headers={"Content-Disposition": "attachment; filename=meeting-report.pdf"})
    return {"error": "Unsupported export type"}
