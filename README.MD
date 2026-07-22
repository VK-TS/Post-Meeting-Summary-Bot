# Post-Meeting Summary Bot

FastAPI + React app that uploads meeting audio, normalizes it, diarizes speakers with pyannote, transcribes segments with Vosk, summarizes/coaches with Ollama, and optionally emails results.

## Requirements

- Python 3.10+
- Node.js 20+
- FFmpeg available on PATH for `pydub`
- Python 3.13/3.14 compatibility requires `audioop-lts` for `pydub` imports
- Ollama running with the model from `OLLAMA_MODEL`
- Hugging Face access to `pyannote/speaker-diarization`

## Setup

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
Copy-Item .env.example .env
```

Fill `.env` with real values. `RESEND_FROM` must use a sender/domain verified in Resend.

```powershell
uvicorn app:app --reload
```

In another terminal:

```powershell
cd frontend
npm install
npm run dev
```

Open `http://localhost:5173`.

## Notes

- Put frontend-only overrides such as `VITE_API_URL` in `frontend/.env` if needed.
- Generated audio files are written to `uploads/`, `normalized/`, and `segments/` and ignored by git.
- Jobs are stored in memory, so restarting the API clears current job status.
