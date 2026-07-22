import os
import smtplib

from dotenv import load_dotenv
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

load_dotenv()

EMAIL_USER = os.getenv("EMAIL USER")
EMAIL_PASS = os.getenv("EMAIL PASS")


def send_email(recipient, subject, html):
    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = EMAIL_USER
    msg["To"] = recipient
    msg.attach(MIMEText(html, "html"))

    with smtplib.SMTP("smtp.gmail.com", 587) as server:
        server.starttls()
        server.login(EMAIL_USER, EMAIL_PASS)
        server.sendmail(EMAIL_USER, recipient, msg.as_string())


def send_report_email(recipient, summary, feedbacks, transcript=None):
    if isinstance(feedbacks, dict):
        feedback_html = "".join(
            f"<h3>{speaker}</h3><p>{text}</p>"
            for speaker, text in feedbacks.items()
        )
    else:
        feedback_html = f"<p>{feedbacks}</p>"

    transcript_html = f"<h2>Transcript</h2><p>{transcript}</p>" if transcript else ""
    html = f"""
    <html>
    <body>
    <h2>Meeting Summary</h2>
    <p>{summary}</p>
    {transcript_html}
    <h2>Coaching Feedback</h2>
    {feedback_html}
    </body>
    </html>
    """

    send_email(recipient, "Meeting Coaching Report", html)


def send_speaker_feedback_email(recipient, speaker, feedback):
    html = f"""
    <html>
    <body>
    <h2>Feedback for {speaker}</h2>
    <p>{feedback}</p>
    </body>
    </html>
    """

    send_email(recipient, f"Feedback for {speaker}", html)

