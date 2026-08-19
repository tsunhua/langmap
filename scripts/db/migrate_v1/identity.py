from __future__ import annotations

import hashlib
import unicodedata


BASE32_ALPHABET = 'abcdefghijklmnopqrstuvwxyz234567'


def canonicalize_text(text: str) -> str:
    return unicodedata.normalize('NFC', text.strip())


def compute_text_hash(text: str) -> str:
    digest = hashlib.sha256(text.encode('utf-8')).digest()[:16]
    bits = ''.join(f'{byte:08b}' for byte in digest)
    return ''.join(BASE32_ALPHABET[int(bits[index:index + 5].ljust(5, '0'), 2)] for index in range(0, len(bits), 5))


def build_expression_id(lang_code: str, text_hash: str, homograph_index: int = 1) -> str:
    return f'{lang_code}:{text_hash}' if homograph_index <= 1 else f'{lang_code}:{text_hash}.{homograph_index}'
