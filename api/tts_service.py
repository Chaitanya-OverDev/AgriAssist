
import re
import edge_tts
from langdetect import detect, LangDetectException

def clean_text_for_tts(text: str) -> str:
    """Cleans markdown, links, and formatting for smooth TTS reading."""
    if not text: return ""
    text = text.replace('\n', '. ')
    text = re.sub(r'[\*#_`~]', '', text)
    text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
    text = re.sub(r'\.+', '.', text)
    text = re.sub(r'\s+', ' ', text)
    return text.strip()

def get_voice_for_language(text: str) -> str:
    """Detects language and returns the appropriate Edge TTS voice."""
    try:
        lang = detect(text)
        if lang == 'mr': # Marathi
            return "mr-IN-ManoharNeural" 
        elif lang == 'hi': # Hindi
            return "hi-IN-MadhurNeural"
        elif lang == 'en': # English
            return "en-IN-PrabhatNeural"
        else:
            # Default to Hindi voice. Indian Edge TTS voices are generally 
            # quite good at reading 'Hinglish' natively.
            return "hi-IN-MadhurNeural"
    except LangDetectException:
        return "hi-IN-MadhurNeural"

async def generate_audio_bytes(text: str) -> bytes:
    """Generates TTS and returns raw MP3 bytes without saving to disk."""
    clean_text = clean_text_for_tts(text)
    voice = get_voice_for_language(clean_text)
    
    communicate = edge_tts.Communicate(clean_text, voice)
    audio_data = bytearray()
    
    # Stream the audio chunks directly into memory
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            audio_data.extend(chunk["data"])
            
    return bytes(audio_data)