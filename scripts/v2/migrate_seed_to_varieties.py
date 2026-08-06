#!/usr/bin/env python3
"""一次性 generator：把扁平 `language_seed_profiles.json` 重寫成兩層 shape。

為什麼保留這支腳本：spec §8.1 把語言模型拆成 variety（語言／方言）與 profile
（書寫／地區形式）兩層。Seed 檔案的 variety code、name、id 與 profile 歸屬是
策展結果（49 個 variety 不是機械推導），需要一份可重跑、可稽核的產生器記錄
對應表與演算法，而不是把結果直接手寫進 JSON。

演算法與約定：
- VARIETY_MAP：舊 variety_key → (new variety code, variety name, variety name_en)。
  `system:mn-Mong` 與 `system:mn-Cyrl` 兩鍵都指向 `mn`，合併成一個 variety。
- variety id 由 `seed_variety_id(code)` 產生，與 backend `seedVarietyId` (Task 1)
  byte-for-byte 一致：固定 epoch + `sha256("langmap-seed-variety:"+code)[:10]`，
  再以 Crockford base32 編碼（時間 10 字、隨機 16 字）。
- profile name 採 script label（如「傳承體」），不是 variety 名；保留鋒面資訊。
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Iterable

SEED_PATH = Path(__file__).with_name("language_seed_profiles.json")

# VARIETY_MAP：鍵為舊 variety_key，值為 (new variety code, variety name, variety name_en)。
# system:mn-Mong 與 system:mn-Cyrl 兩鍵都指向 mn，合併成一個 variety。
VARIETY_MAP: dict[str, tuple[str, str, str]] = {
    "system:und": ("und", "Undetermined", "Undetermined"),
    "system:x-emoji": ("x-emoji", "Emoji 表情", "Emoji"),
    "system:x-image": ("x-image", "圖片", "Image"),
    "system:fa": ("fa", "فارسی", "Persian"),
    "system:mn-Mong": ("mn", "蒙古語", "Mongolian"),
    "system:mn-Cyrl": ("mn", "蒙古語", "Mongolian"),
    "system:za-Latn": ("za", "壯語", "Zhuang"),
    "glotto:stan1293": ("en", "English", "English"),
    "glotto:swah1253": ("swh", "Swahili", "Swahili"),
    "glotto:ralt1242": ("ral", "Raltic", "Raltic"),
    "glotto:yang1286": ("zyg", "Yangzhuang", "Yangzhuang"),
    "glotto:ouji1238": ("wuu-x-ouji1238", "溫州話", "Wenzhou (Oujiang)"),
    "glotto:taiz1238": ("wuu-x-taiz1238", "台州話", "Taizhou"),
    "glotto:chao1238": ("nan-x-chao1238", "潮州話", "Chaozhou (Teochew)"),
    "glotto:minn1241": ("nan", "閩南語", "Min Nan"),
    "glotto:mand1415": ("cmn", "華語", "Mandarin Chinese"),
    "glotto:stan1318": ("ar", "العربية", "Arabic"),
    "glotto:beng1280": ("bn", "বাংলা", "Bengali"),
    "glotto:stan1295": ("de", "Deutsch", "German"),
    "glotto:stan1288": ("es", "Español", "Spanish"),
    "glotto:stan1290": ("fr", "Français", "French"),
    "glotto:hind1269": ("hi", "हिन्दी", "Hindi"),
    "glotto:indo1316": ("id", "Bahasa Indonesia", "Indonesian"),
    "glotto:ital1282": ("it", "Italiano", "Italian"),
    "glotto:nucl1643": ("ja", "日本語", "Japanese"),
    "glotto:kore1280": ("ko", "한국어", "Korean"),
    "glotto:mara1378": ("mr", "मराठी", "Marathi"),
    "glotto:panj1256": ("pa", "ਪੰਜਾਬੀ", "Punjabi"),
    "glotto:port1283": ("pt", "Português", "Portuguese"),
    "glotto:russ1263": ("ru", "Русский", "Russian"),
    "glotto:thai1261": ("th", "ไทย", "Thai"),
    "glotto:nucl1301": ("tr", "Türkçe", "Turkish"),
    "glotto:urdu1245": ("ur", "اردو", "Urdu"),
    "glotto:viet1252": ("vi", "Tiếng Việt", "Vietnamese"),
    "glotto:wuch1236": ("wuu", "吳語", "Wu Chinese"),
    "glotto:yuec1235": ("yue", "粵語", "Cantonese"),
    "glotto:xian1251": ("hsn", "湘語", "Xiang Chinese"),
    "glotto:hakk1236": ("hak", "客家話", "Hakka"),
    "glotto:mind1253": ("cdo", "閩東語", "Min Dong"),
    "glotto:minb1236": ("mnp", "閩北語", "Min Bei"),
    "glotto:tibe1272": ("bo", "བོད་སྐད་", "Tibetan"),
    "glotto:uigh1240": ("ug", "ئۇيغۇرچە", "Uyghur"),
    "glotto:kaza1248": ("kk", "قازاق تىلى", "Kazakh"),
    "glotto:kirg1245": ("ky", "قىرعىز تىلى", "Kyrgyz"),
    "glotto:jiny1235": ("cjy", "晉語", "Jin Chinese"),
    "glotto:ganc1239": ("gan", "贛語", "Gan Chinese"),
    "glotto:minz1235": ("czo", "閩中語", "Min Zhong"),
    "glotto:puxi1243": ("cpx", "莆仙話", "Pu-Xian"),
    "glotto:nort3268": ("cnp", "桂北平話", "Northern Pinghua"),
    "glotto:sout3250": ("csp", "桂南平話", "Southern Pinghua"),
}

# script label 對應表：profile name 用 script 鋒面名稱，而非 variety 名。
SCRIPT_LABELS: dict[str, tuple[str, str]] = {
    "Hans": ("簡體", "Simplified"),
    "Hant": ("傳承體", "Traditional"),
    "Latn": ("拉丁", "Latin"),
    "Cyrl": ("西里爾", "Cyrillic"),
    "Arab": ("阿拉伯文", "Arabic"),
    "Mong": ("傳統蒙古文", "Traditional Script"),
    "Tibt": ("藏文", "Tibetan"),
    "Guru": ("古木奇文", "Gurmukhi"),
}

# --- ULID 編碼（與 backend/src/utils/ulid.ts byte-for-byte 一致）-----------------

_ULID_ENCODE = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
_SEED_EPOCH_MS = 1_753_987_200_000
_SEED_PREFIX = "langmap-seed-variety:"
_SEED_RANDOM_BYTES = 10


def _encode_time(timestamp_ms: int) -> str:
    ts = timestamp_ms
    chars: list[str] = []
    for _ in range(10):
        chars.append(_ULID_ENCODE[ts % 32])
        ts //= 32
    chars.reverse()
    return "".join(chars)


def _encode_random(bytes_: bytes) -> str:
    value = 0
    for byte in bytes_:
        value = (value << 8) | byte
    chars: list[str] = []
    for _ in range(16):
        chars.append(_ULID_ENCODE[value & 31])
        value >>= 5
    chars.reverse()
    return "".join(chars)


def seed_variety_id(variety_code: str) -> str:
    """產生 deterministic seed variety ULID，與 TS `seedVarietyId` 完全一致。"""
    digest = hashlib.sha256((_SEED_PREFIX + variety_code).encode("utf-8")).digest()
    return _encode_time(_SEED_EPOCH_MS) + _encode_random(digest[:_SEED_RANDOM_BYTES])


# --- profile label 推導 --------------------------------------------------------

_DEFAULT_LABEL = ("標準", "Default")


def _split_script(code: str) -> str | None:
    """從 BCP 47 code 的 public 段（不含 private use）取出 4-letter script。"""
    parts = code.split("-")
    private_idx = next((i for i, p in enumerate(parts) if p.lower() == "x"), len(parts))
    public = parts[1:private_idx]
    for p in public:
        if len(p) == 4 and p.isalpha():
            return p
    return None


def _has_extra_public_subtag(code: str) -> bool:
    """profile code 除了 language 與 (script/region) 外是否還帶 variant 或 private。"""
    parts = code.split("-")
    private_idx = next((i for i, p in enumerate(parts) if p.lower() == "x"), len(parts))
    public = parts[1:private_idx]
    for p in public:
        is_script = len(p) == 4 and p.isalpha()
        is_region = (len(p) == 2 and p.isalpha()) or (len(p) == 3 and p.isdigit())
        if not is_script and not is_region:
            return True
    return private_idx < len(parts)


def profile_label(code: str, fallback_name: str, fallback_name_en: str) -> tuple[str, str]:
    """依 script 推導 profile 顯示名（spec §8.1：profile name 是 script 鋒面標籤）。

    - script 在 SCRIPT_LABELS 且沒有額外 variant/private 段 → 取對應 script label。
    - 含 Latn 且帶 variant/private（如 tailo/pehoeji/x-chao1238）→ 保留原 profile 名。
    - 其他 → ("標準", name_en or "Default")。
    """
    script = _split_script(code)
    if script == "Latn" and _has_extra_public_subtag(code):
        return (fallback_name, fallback_name_en)
    if script in SCRIPT_LABELS:
        return SCRIPT_LABELS[script]
    return (_DEFAULT_LABEL[0], fallback_name_en or _DEFAULT_LABEL[1])


# --- generator 主流程 ----------------------------------------------------------

def _old_variety_key(entry: dict) -> str:
    glottocode = entry.get("glottocode")
    return f"glotto:{glottocode}" if glottocode else f"system:{entry['code']}"


def build_two_layer_seed(flat: dict) -> dict:
    """把扁平 seed 轉成兩層 {version, varieties, locations, online_code_migrations}。"""
    languages = flat.get("languages", [])
    if not isinstance(languages, list):
        raise ValueError("languages 必須是 JSON array")

    # 1. 用舊 variety_key 分組，再透過 VARIETY_MAP 對應到新 variety code。
    groups: dict[str, list[dict]] = {}
    for entry in languages:
        old_key = _old_variety_key(entry)
        if old_key not in VARIETY_MAP:
            raise ValueError(f"VARIETY_MAP 缺少舊鍵：{old_key}（code={entry.get('code')}）")
        vcode = VARIETY_MAP[old_key][0]
        groups.setdefault(vcode, []).append(entry)

    # 2. 對每個 distinct variety code（依 code 排序）組裝 variety 與其 profiles。
    varieties: list[dict] = []
    for vcode in sorted(groups):
        _, v_name, v_name_en = next(
            item for item in VARIETY_MAP.values() if item[0] == vcode
        )
        members = sorted(groups[vcode], key=lambda row: row["code"])

        profiles: list[dict] = []
        alternate_names: list[str] = []
        glottocode: str | None = None
        for entry in members:
            label_name, label_name_en = profile_label(
                entry["code"], entry.get("name", ""), entry.get("name_en", "")
            )
            profiles.append({
                "code": entry["code"],
                "name": label_name,
                "name_en": label_name_en,
            })
            for alt in entry.get("alternate_names") or []:
                if alt not in alternate_names:
                    alternate_names.append(alt)
            if glottocode is None and entry.get("glottocode"):
                glottocode = entry["glottocode"]

        first = members[0]
        varieties.append({
            "id": seed_variety_id(vcode),
            "code": vcode,
            "name": v_name,
            "name_en": v_name_en,
            "glottocode": glottocode,
            "origin": first.get("origin", ""),
            "reason": first.get("reason", ""),
            "description": "",
            "alternate_names": alternate_names,
            "profiles": profiles,
        })

    # 3. locations：variety_key → variety_code，其餘欄位原樣保留。
    locations: list[dict] = []
    for loc in flat.get("locations", []):
        old_key = loc.get("variety_key", "")
        if old_key not in VARIETY_MAP:
            raise ValueError(f"location 引用未知 variety_key：{old_key}")
        new_loc = {k: v for k, v in loc.items() if k != "variety_key"}
        new_loc["variety_code"] = VARIETY_MAP[old_key][0]
        locations.append(new_loc)

    return {
        "version": 5,
        "varieties": varieties,
        "locations": locations,
        "online_code_migrations": flat.get("online_code_migrations", {}),
    }


def main() -> int:
    flat = json.loads(SEED_PATH.read_text(encoding="utf-8"))
    result = build_two_layer_seed(flat)

    # __main__ 斷言：產出符合 spec §8.1 兩層不變量。
    codes = [v["code"] for v in result["varieties"]]
    assert len(result["varieties"]) == 49, len(result["varieties"])
    assert len(set(codes)) == len(codes), "variety code 重複"
    ids = [v["id"] for v in result["varieties"]]
    assert len(set(ids)) == len(ids), "variety id 重複"
    for v in result["varieties"]:
        assert v["profiles"], f"variety {v['code']} 沒有 profile"

    SEED_PATH.write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(f"wrote {len(result['varieties'])} varieties, {len(result['locations'])} locations")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
