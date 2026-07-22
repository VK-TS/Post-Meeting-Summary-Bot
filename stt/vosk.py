import wave
import json
from vosk import Model, KaldiRecognizer

MODEL_PATH = "models/vosk-model-small-en-us-0.15"

model = Model(MODEL_PATH)

def transcribe_audio(audio_path: str, with_words=False):
    wf = wave.open(audio_path, "rb")

    rec = KaldiRecognizer(model, wf.getframerate())
    if with_words:
        rec.SetWords(True)

    results = []
    words = []

    while True:
        data = wf.readframes(4000)

        if len(data) == 0:
            break
        if rec.AcceptWaveform(data):
            part = json.loads(rec.Result())
            results.append(part.get("text"," "))
            words.extend(part.get("result", []))
    
    final = json.loads(rec.FinalResult())
    results.append(final.get("text"," "))
    words.extend(final.get("result", []))

    text = " ".join(results)
    return (text, words) if with_words else text
