"""
Arabic Natural Language Normalization Service — مشروع «مُعين» (Mouin)
Normalizes Arabic diacritics, hamzas, alif maqsura, tatweel, and taa marbuta
to enable fuzzy, highly accurate, and forgiving Arabic search and categorization.
"""

import re
import unicodedata
from typing import List

# Unicode ranges for Arabic diacritics / Tashkeel
TASHKEEL_PATTERN = re.compile(r'[\u0617-\u061A\u064B-\u0652\u0670]')
TATWEEL_CHAR = '\u0640'

def strip_tashkeel(text: str) -> str:
    """Removes Arabic diacritics/tashkeel."""
    if not text:
        return ""
    return TASHKEEL_PATTERN.sub('', text)

def remove_tashkeel(text: str) -> str:
    """Alias for strip_tashkeel."""
    return strip_tashkeel(text)

def strip_tatweel(text: str) -> str:
    """Removes Tatweel (Kashida)."""
    if not text:
        return ""
    return text.replace(TATWEEL_CHAR, '')

def remove_tatweel(text: str) -> str:
    """Alias for strip_tatweel."""
    return strip_tatweel(text)

def normalize_alef(text: str) -> str:
    """Normalizes Alef forms (أ, إ, آ, ٱ -> ا)."""
    if not text:
        return ""
    return re.sub(r'[أإآٱ]', 'ا', text)

def normalize_hamza(text: str) -> str:
    """Normalizes Hamza forms."""
    if not text:
        return ""
    t = normalize_alef(text)
    t = re.sub(r'[ؤ]', 'و', t)
    t = re.sub(r'[ئ]', 'ي', t)
    return t

def normalize_hamzas(text: str) -> str:
    """Alias for normalize_hamza."""
    return normalize_hamza(text)

def normalize_yeh(text: str) -> str:
    """Normalizes Alif Maqsura to Yeh."""
    if not text:
        return ""
    return re.sub(r'ى', 'ي', text)

def normalize_yehs(text: str) -> str:
    """Alias for normalize_yeh."""
    return normalize_yeh(text)

def normalize_teh_marbuta(text: str) -> str:
    """Normalizes Teh Marbuta to Heh."""
    if not text:
        return ""
    return re.sub(r'ة', 'ه', text)

def normalize_teh_marbutas(text: str) -> str:
    """Alias for normalize_teh_marbuta."""
    return normalize_teh_marbuta(text)

def normalize_endings(text: str) -> str:
    """Normalizes word endings (Alef Maqsura & Teh Marbuta)."""
    if not text:
        return ""
    t = normalize_yeh(text)
    return normalize_teh_marbuta(t)

def normalize_arabic(text: str) -> str:
    """
    Normalizes raw Arabic text for unified searching and indexing:
    1. Removes Tashkeel (harakat / diacritics).
    2. Removes Tatweel (Kashida).
    3. Normalizes Hamzas (أ, إ, آ, ٱ -> ا).
    4. Normalizes Alif Maqsura (ى -> ي).
    5. Normalizes Taa Marbuta (ة -> ه).
    6. Strips extraneous punctuation and whitespace.
    """
    if not text:
        return ""

    normalized = strip_tashkeel(text)
    normalized = strip_tatweel(normalized)
    normalized = normalize_hamzas(normalized)
    normalized = normalize_endings(normalized)
    normalized = re.sub(r'\s+', ' ', normalized).strip()

    return normalized.lower()

def normalize_search_query(text: str) -> str:
    """Normalizes query for search matching."""
    return normalize_arabic(text)

def tokenize_search_query(query: str) -> List[str]:
    """Tokenizes normalized Arabic search query."""
    normalized = normalize_arabic(query)
    return [w for w in normalized.split() if w]

def is_arabic_text(text: str) -> bool:
    """Checks if a string contains Arabic unicode characters."""
    return bool(re.search(r'[\u0600-\u06FF]', text))
