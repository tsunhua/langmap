#!/usr/bin/env python3
"""
Script to merge GNOME translation CSV files with en_GB as the standard reference.
Creates a merged CSV with columns: en_GB,es,ja,zh_CN,zh_TW,en_US
"""

import csv
import os
import re
import sys

# Add the common_language module to the path
sys.path.append(os.path.join(os.path.dirname(__file__), 'common_language'))

# Import the British to American English mappings from common_language
try:
    from common_language.bijective_map import uk_us
    # Create a dictionary for British to American conversion
    BRITISH_TO_AMERICAN = dict(uk_us)
    print("Successfully loaded common_language library with", len(BRITISH_TO_AMERICAN), "conversion rules")
except ImportError:
    print("Warning: Could not import common_language. Using fallback dictionary.")
    # Fallback dictionary
    BRITISH_TO_AMERICAN = {
        'colour': 'color',
        'flavour': 'flavor',
        'honour': 'honor',
        'humour': 'humor',
        'labour': 'labor',
        'neighbour': 'neighbor',
        'rumour': 'rumor',
        'saviour': 'savior',
        'splendour': 'splendor',
        'valour': 'valor',
        'behaviour': 'behavior',
        'centre': 'center',
        'fibre': 'fiber',
        'litre': 'liter',
        'metre': 'meter',
        'theatre': 'theater',
        'titre': 'titer',
        'analyse': 'analyze',
        'breathalyse': 'breathalyze',
        'catalyse': 'catalyze',
        'characterise': 'characterize',
        'chlorinise': 'chlorinize',
        'circularise': 'circularize',
        'civilise': 'civilize',
        'clarinettist': 'clarinetist',
        'computerise': 'computerize',
        'connexion': 'connection',
        'criticise': 'criticize',
        'crystallisation': 'crystallization',
        'defence': 'defense',
        'distil': 'distill',
        'draught': 'draft',
        'dreamt': 'dreamed',
        'encyclopaedia': 'encyclopedia',
        'endeavour': 'endeavor',
        'favour': 'favor',
        'fervour': 'fervor',
        'finalise': 'finalize',
        'flannel': 'flannelette',
        'fulfil': 'fulfill',
        'glamour': 'glamor',
        'harbour': 'harbor',
        'honourable': 'honorable',
        'initialise': 'initialize',
        'instalment': 'installment',
        'jewellery': 'jewelry',
        'judgement': 'judgment',
        'kerb': 'curb',
        'learned': 'learnt',
        'leukaemia': 'leukemia',
        'liquorice': 'licorice',
        'lit': 'lighted',
        'lustre': 'luster',
        'manoeuvre': 'maneuver',
        'marshalling': 'marshaling',
        'marvelled': 'marveled',
        'marvelling': 'marveling',
        'meagre': 'meager',
        'misdemeanour': 'misdemeanor',
        'mitre': 'miter',
        'mould': 'mold',
        'moult': 'molt',
        'multicoloured': 'multicolored',
        'odour': 'odor',
        'offence': 'offense',
        'optimise': 'optimize',
        'organise': 'organize',
        'organiser': 'organizer',
        'paralyse': 'paralyze',
        'passivised': 'passivized',
        'patronise': 'patronize',
        'plough': 'plow',
        'popularise': 'popularize',
        'pretence': 'pretense',
        'prise': 'prize',
        'programme': 'program',
        'prologue': 'prolog',
    }

# Precompile regex patterns for better performance
BRITISH_TO_AMERICAN_PATTERNS = [(re.compile(r'\b' + re.escape(british) + r'\b', re.IGNORECASE), american) 
                                for british, american in BRITISH_TO_AMERICAN.items()]

# Character patterns
JAPANESE_CHARACTERS_PATTERN = re.compile(r'[\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]')
ENGLISH_LETTERS_PATTERN = re.compile(r'[a-zA-Z]')

# Directory containing the CSV files
INPUT_DIR = "./gnome_pairs"
OUTPUT_FILE = "merged_gnome_translations.csv"

# Language pairs and their corresponding column names
LANGUAGE_PAIRS = {
    "es_en_GB_clean.csv": "es",
    "ja_en_GB_clean.csv": "ja", 
    "zh_CN_en_GB_clean.csv": "zh_CN",
    "zh_TW_en_GB_clean.csv": "zh_TW"
}

def british_to_american(text):
    """
    Convert British English text to American English.
    
    Args:
        text: British English text
        
    Returns:
        American English text
    """
    # Apply word-by-word conversion using precompiled patterns
    for pattern, american in BRITISH_TO_AMERICAN_PATTERNS:
        text = pattern.sub(american, text)
    
    return text

def is_english_chinese_same(en_gb, zh_cn, zh_tw):
    """
    Check if English and Chinese content are exactly the same.
    
    Args:
        en_gb: English (GB) text
        zh_cn: Chinese (Simplified) text
        zh_tw: Chinese (Traditional) text
        
    Returns:
        True if English and Chinese content are the same, False otherwise
    """
    # Check if English content is the same as either Chinese content
    # Avoid unnecessary string operations
    return en_gb == zh_cn or en_gb == zh_tw

def has_japanese_characters(text):
    """
    Check if the text contains Japanese characters (hiragana, katakana, or kanji).
    
    Args:
        text: Text to check
        
    Returns:
        True if text contains Japanese characters, False otherwise
    """
    return bool(JAPANESE_CHARACTERS_PATTERN.search(text))

def has_sufficient_english_letters(text):
    """
    Check if the text contains at least two English letters and no underscores.
    
    Args:
        text: Text to check
        
    Returns:
        True if text contains at least two English letters and no underscores, False otherwise
    """
    # Check if text contains underscore
    if '_' in text:
        return False
        
    english_letters = ENGLISH_LETTERS_PATTERN.findall(text)
    return len(english_letters) >= 2

def load_translations(filename, lang_code):
    """
    Load translations from a CSV file into a dictionary.
    
    Args:
        filename: Path to the CSV file
        lang_code: Target language code
        
    Returns:
        Dictionary mapping en_GB text to target language text
    """
    translations = {}
    filepath = os.path.join(INPUT_DIR, filename)
    
    if not os.path.exists(filepath):
        print(f"Warning: File {filename} not found")
        return translations
        
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                en_gb_text = row['tgt']  # en_GB is in the 'tgt' column
                target_text = row['src']  # Target language is in the 'src' column
                
                # Skip empty translations
                if not en_gb_text or not target_text:
                    continue
                    
                # For Japanese, filter out entries that don't contain Japanese characters
                if lang_code == 'ja' and not has_japanese_characters(target_text):
                    continue
                    
                # Direct assignment without extra strip() calls
                translations[en_gb_text] = target_text
    except Exception as e:
        print(f"Error reading {filename}: {e}")
        
    return translations

def main():
    """Main function to merge all translation files."""
    print("Loading translation files...")
    
    # Load en_GB to target language mappings
    translations = {}
    for filename, lang_code in LANGUAGE_PAIRS.items():
        translations[lang_code] = load_translations(filename, lang_code)
        print(f"Loaded {len(translations[lang_code])} translations from {filename}")
    
    # Collect all unique en_GB texts
    all_en_gb_texts = set()
    for lang_translations in translations.values():
        all_en_gb_texts.update(lang_translations.keys())
    
    print(f"Total unique en_GB texts: {len(all_en_gb_texts)}")
    
    # Cache Chinese translations for faster lookup
    zh_cn_translations = translations.get('zh_CN', {})
    zh_tw_translations = translations.get('zh_TW', {})
    
    # Create merged CSV
    output_path = os.path.join(INPUT_DIR, OUTPUT_FILE)
    filtered_count = 0
    written_count = 0
    
    with open(output_path, 'w', encoding='utf-8', newline='') as f:
        writer = csv.writer(f)
        
        # Write header
        header = ['en_GB'] + list(LANGUAGE_PAIRS.values()) + ['en_US']
        writer.writerow(header)
        
        # Prepare language list for consistent ordering
        lang_list = list(LANGUAGE_PAIRS.values())
        
        # Write data rows
        total_count = 0
        batch_rows = []
        batch_size = 1000
        
        for en_gb_text in sorted(all_en_gb_texts):
            total_count += 1
            
            # Filter out entries where en_GB doesn't contain at least two English letters or contains underscores
            if not has_sufficient_english_letters(en_gb_text):
                filtered_count += 1
                continue
            
            # Collect translations for all languages
            row = [en_gb_text]
            zh_cn_text = ''
            zh_tw_text = ''
            ja_text = ''
            
            for lang_code in lang_list:
                # Get translation or empty string if not available
                translation = translations.get(lang_code, {}).get(en_gb_text, '')
                row.append(translation)
                
                # Capture translations for comparison
                if lang_code == 'zh_CN':
                    zh_cn_text = translation
                elif lang_code == 'zh_TW':
                    zh_tw_text = translation
                elif lang_code == 'ja':
                    ja_text = translation
            
            # Convert British English to American English
            en_us_text = british_to_american(en_gb_text)
            row.append(en_us_text)
            
            # Check filtering conditions:
            # 1. English and Chinese are the same
            # 2. Japanese text doesn't contain Japanese characters
            if is_english_chinese_same(en_gb_text, zh_cn_text, zh_tw_text) or (ja_text and not has_japanese_characters(ja_text)):
                filtered_count += 1
                continue
                
            batch_rows.append(row)
            written_count += 1
            
            # Write in batches for better I/O performance
            if len(batch_rows) >= batch_size:
                writer.writerows(batch_rows)
                batch_rows.clear()
                # Progress indicator
                print(f"Processed {total_count}/{len(all_en_gb_texts)} entries...")
        
        # Write remaining rows
        if batch_rows:
            writer.writerows(batch_rows)
    
    print(f"Merged CSV written to {output_path}")
    print(f"Total entries processed: {total_count}")
    print(f"Entries written: {written_count}")
    print(f"Entries filtered out (English same as Chinese, Japanese without Japanese characters, or en_GB with less than 2 English letters or containing underscores): {filtered_count}")
    print("Conversion from British English to American English completed using common_language library.")

if __name__ == "__main__":
    main()