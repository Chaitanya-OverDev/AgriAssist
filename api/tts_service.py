import re
import edge_tts
from langdetect import detect, LangDetectException

def clean_text_for_tts(text: str) -> str:
    """Cleans markdown, links, and formatting for smooth TTS reading."""
    if not text: return ""
    
    text = text.replace('\n', '. ')
    # Remove markdown characters
    text = re.sub(r'[\*#_`~]', '', text)
    # Extract text from markdown links
    text = re.sub(r'\[([^\]]+)\]\([^\)]+\)', r'\1', text)
    # Prevent extremely long pauses by collapsing multiple periods
    text = re.sub(r'\.+', '.', text)
    # Collapse multiple spaces
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
            return "hi-IN-MadhurNeural"
    except LangDetectException:
        return "hi-IN-MadhurNeural"

async def stream_audio_generator(text: str):
    """Generates TTS and yields raw MP3 chunks instantly for streaming."""
    clean_text = clean_text_for_tts(text)
    voice = get_voice_for_language(clean_text)
    
    communicate = edge_tts.Communicate(clean_text, voice)
    
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            yield chunk["data"]

async def generate_audio_bytes(text: str) -> bytes:
    """Collects all chunks into a single byte payload for background saving."""
    audio_data = bytearray()
    
    # Reuse the generator 
    async for chunk in stream_audio_generator(text):
        audio_data.extend(chunk)
        
    return bytes(audio_data)