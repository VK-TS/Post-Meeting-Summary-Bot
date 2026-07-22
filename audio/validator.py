SUPPORTED_FORMATS = {
    ".mp3",
    ".wav",
    ".m4a"
}

def validate_audio_file(filename):
    extension = filename.lower().split(".")[-1]
    extension = f".{extension}"
    return extension in SUPPORTED_FORMATS