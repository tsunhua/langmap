from __future__ import annotations


LANGUAGE_MAPPING: dict[str, tuple[str, str | None]] = {
    'zh-TW': ('cmn', 'cmn-Hant-TW'),
    'zh-CN': ('cmn', 'cmn-Hans-CN'),
    'en-US': ('eng', 'eng-Latn-US'),
    'en-GB': ('eng', 'eng-Latn-GB'),
    'ja-JP': ('jpn', 'jpn-Jpan-JP'),
    'es-ES': ('spa', 'spa-Latn-ES'),
    # yue-HK currently only contains UI translation rows; defer it until Cantonese UI localization is ready.
    'nan-TW': ('nan', 'nan-Hant-TW'),
    'nan-x-cha': ('nan', 'nan-Hant-CN_Chaozhou'),
    'nan-x-cha-jiazi': ('nan', 'nan-Hant-CN_LufengJiazi'),
    'nan-TW-POJ': ('nan', 'nan-Latn_Pehoeji-TW'),
    'nan-TW-TL': ('nan', 'nan-Latn_Tailo-TW'),
    'cieh-tc': ('wuu', 'wuu-Hant-CN_Taizhou'),
    'wuu-sh': ('wuu', 'wuu-Hans-CN_Wenzhou'),
    'zyg-jx': ('zha', 'zha-Latn-CN_Jingxi'),
    'ral': ('ral', 'ral-Latn-IN'),
    'swh': ('swh', 'swh-Latn-TZ'),
    'image': ('x-image', None),
    'emoji': ('x-emoji', None),
}


def map_language_code(code: str) -> str | None:
    mapped = LANGUAGE_MAPPING.get(code)
    return mapped[0] if mapped else None


def map_expression_locale(code: str) -> str | None:
    mapped = LANGUAGE_MAPPING.get(code)
    return mapped[1] if mapped else None
