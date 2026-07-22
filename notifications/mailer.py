import html
import os
from pathlib import Path

import requests
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parents[1] / ".env")


def html_block(text):
    return f"<pre style='white-space:pre-wrap;font-family:Arial,sans-serif'>{html.escape(text)}</pre>"


def send_email(recipient, subject, body_html):
    api_key = os.getenv("RESEND_API_KEY")
    from_email = os.getenv("RESEND_FROM") or os.getenv("EMAIL_FROM")
    if not api_key or not from_email:
        raise RuntimeError("RESEND_API_KEY and RESEND_FROM are required to send email")

    response = requests.post(
        "https://api.resend.com/emails",
        headers={"Authorization": f"Bearer {api_key}"},
        json={"from": from_email, "to": [recipient], "subject": subject, "html": body_html},
        timeout=30,
    )
    response.raise_for_status()


def send_report_email(recipient, summary, feedbacks, transcript=None):
    if isinstance(feedbacks, dict):
        feedback_html = "".join(
            f"<h3>{html.escape(speaker)}</h3>{html_block(text)}"
            for speaker, text in feedbacks.items()
        )
    else:
        feedback_html = html_block(feedbacks)

    transcript_html = (
        f"<h2>Transcript</h2>{html_block(transcript)}" if transcript else ""
    )
    body_html = f"""
    <html><body>
    <h2>Meeting Summary</h2>{html_block(summary)}
    {transcript_html}
    <h2>Coaching Feedback</h2>{feedback_html}
    </body></html>
    """
    send_email(recipient, "Meeting Coaching Report", body_html)


def send_speaker_feedback_email(recipient, speaker, feedback):
    body_html = f"""
    <html><body>
    <h2>Feedback for {html.escape(speaker)}</h2>
    {html_block(feedback)}
    </body></html>
    """
    send_email(recipient, f"Feedback for {speaker}", body_html)
