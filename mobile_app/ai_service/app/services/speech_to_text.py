import os
import base64
import tempfile
from typing import Optional

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY", "")


def transcribe_audio(file_base64: str, mimetype: str = "audio/webm", filename: str = "audio.webm") -> dict:
    """Transcribe audio to text using OpenAI Whisper API."""
    if not OPENAI_API_KEY:
        return _fallback_transcription()

    try:
        import openai

        client = openai.OpenAI(api_key=OPENAI_API_KEY)

        # Decode base64 to bytes
        audio_bytes = base64.b64decode(file_base64)

        # Write to temp file (Whisper API needs a file-like object with a name)
        ext = _get_extension(mimetype, filename)
        with tempfile.NamedTemporaryFile(suffix=ext, delete=False) as tmp:
            tmp.write(audio_bytes)
            tmp_path = tmp.name

        try:
            with open(tmp_path, "rb") as audio_file:
                # Transcribe with language detection
                transcript = client.audio.transcriptions.create(
                    model="whisper-1",
                    file=audio_file,
                    response_format="verbose_json",
                )

            text = transcript.text if hasattr(transcript, "text") else str(transcript)
            language = getattr(transcript, "language", "en") or "en"

            # If not English, translate
            translated = text
            if language != "en" and text.strip():
                try:
                    translation = client.audio.translations.create(
                        model="whisper-1",
                        file=open(tmp_path, "rb"),
                    )
                    translated = translation.text if hasattr(translation, "text") else text
                except Exception:
                    translated = text

            return {
                "text": translated,
                "original_text": text if language != "en" else None,
                "language": language,
                "confidence": 0.85,
            }

        finally:
            os.unlink(tmp_path)

    except Exception as e:
        print(f"[AI-VOICE] Transcription failed: {e}")
        return _fallback_transcription()


def _get_extension(mimetype: str, filename: str) -> str:
    """Get file extension from mimetype or filename."""
    ext_map = {
        "audio/mpeg": ".mp3",
        "audio/wav": ".wav",
        "audio/webm": ".webm",
        "audio/ogg": ".ogg",
        "audio/mp4": ".m4a",
    }
    ext = ext_map.get(mimetype)
    if ext:
        return ext
    if "." in filename:
        return "." + filename.rsplit(".", 1)[1]
    return ".webm"


def _fallback_transcription() -> dict:
    """Fallback when OpenAI is not available."""
    return {
        "text": "",
        "language": "en",
        "confidence": 0.0,
    }
