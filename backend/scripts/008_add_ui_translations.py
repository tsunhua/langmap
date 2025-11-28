#!/usr/bin/env python3
"""
Migration script to add UI translation expressions and meanings to the database.
This script reads all language files and creates entries in the expressions 
and meanings tables for UI translations.
"""

import sys
import os
import json
import glob

# Add the app directory to the Python path
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'app'))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from app.db.models import Expression, Meaning
from app.db.session import DATABASE_URL


def flatten_dict(d, parent_key='', sep='.'):
    """
    Flatten a nested dictionary structure.
    For example, {'a': {'b': 'c'}} becomes {'a.b': 'c'}
    """
    items = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)


def add_ui_translations():
    """Add UI translations as expressions and meanings to the database"""
    # Create database engine and session
    engine = create_engine(DATABASE_URL)
    SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
    db = SessionLocal()
    
    try:
        # Get the locales directory path
        base_dir = os.path.join(os.path.dirname(__file__), '..', '..')
        locales_dir = os.path.join(base_dir, 'web', 'src', 'locales')
        
        print(f"Looking for JSON files in: {locales_dir}")
        
        # Find all JSON files in the locales directory
        json_files = glob.glob(os.path.join(locales_dir, "*.json"))
        
        if not json_files:
            print("No JSON files found in locales directory")
            return
            
        print(f"Found {len(json_files)} JSON files")
        
        # Counter for tracking additions
        total_added_expr_count = 0
        total_skipped_expr_count = 0
        total_added_meaning_count = 0
        total_linked_count = 0
        
        # Process each JSON file
        for json_file in json_files:
            filename = os.path.basename(json_file)
            # Extract language code from filename (e.g., en.json -> en, zh-CN.json -> zh-CN)
            language_code = filename.replace('.json', '')
            
            print(f"\nProcessing {filename} (language: {language_code})")
            
            # Read the language file
            with open(json_file, 'r') as f:
                lang_data = json.load(f)
            
            # Flatten the nested structure
            flattened_data = flatten_dict(lang_data)
            
            # Counter for tracking additions per language
            added_expr_count = 0
            skipped_expr_count = 0
            added_meaning_count = 0
            linked_count = 0
            
            # Add each flattened key-value pair as an expression with its own meaning
            for key, value in flattened_data.items():
                # Skip non-string values
                if not isinstance(value, str):
                    continue
                    
                # Check if expression already exists
                existing_expr = db.query(Expression).filter(
                    Expression.language == language_code,
                    Expression.text == value
                ).first()
                
                expression_id = None
                if existing_expr:
                    expression_id = existing_expr.id
                    print(f"  Using existing expression: {value[:50]}...")
                    skipped_expr_count += 1
                else:
                    # Create new expression
                    expression = Expression(
                        language=language_code,
                        text=value,
                        source_type='ui_translation',
                        source_ref='ai',
                        tags=['langmap'],
                        review_status='approved',
                        auto_approved=True
                    )
                    
                    db.add(expression)
                    db.flush()  # Flush to get the expression ID
                    expression_id = expression.id
                    
                    print(f"  Added expression: {value[:50]}...")
                    added_expr_count += 1
                
                # Create a meaning for this expression
                meaning_gloss = f"langmap.{key}"
                meaning_description = f"UI Translation in langmap.{key}"
                tags = ["langmap"]
                
                # Check if meaning already exists
                meaning = db.query(Meaning).filter(Meaning.gloss == meaning_gloss).first()
                meaning_id = None
                if not meaning:
                    meaning = Meaning(
                        gloss=meaning_gloss,
                        description=meaning_description,
                        tags=tags
                    )
                    db.add(meaning)
                    db.flush()  # Flush to get the meaning ID
                    meaning_id = meaning.id
                    added_meaning_count += 1
                    print(f"  Created meaning: {meaning_gloss}")
                else:
                    meaning_id = meaning.id
                    print(f"  Using existing meaning: {meaning_gloss}")
                
                # Check if the expression is already linked to the meaning
                result = db.execute(
                    text("SELECT 1 FROM expression_meanings WHERE expression_id = :expr_id AND meaning_id = :meaning_id"),
                    {"expr_id": expression_id, "meaning_id": meaning_id}
                ).fetchone()
                
                if not result:
                    # Create link between expression and meaning
                    db.execute(
                        text("INSERT INTO expression_meanings (expression_id, meaning_id, note) VALUES (:expr_id, :meaning_id, :note)"),
                        {"expr_id": expression_id, "meaning_id": meaning_id, "note": "UI translation"}
                    )
                    linked_count += 1
            
            # Update totals
            total_added_expr_count += added_expr_count
            total_skipped_expr_count += skipped_expr_count
            total_added_meaning_count += added_meaning_count
            total_linked_count += linked_count
            
            print(f"Finished processing {filename}:")
            print(f"  Added {added_expr_count} expressions, skipped {skipped_expr_count}")
            print(f"  Added {added_meaning_count} meanings, linked {linked_count} expressions")
        
        # Commit all changes
        db.commit()
        print(f"\nSuccessfully processed all files:")
        print(f"  Added {total_added_expr_count} UI translation expressions")
        print(f"  Skipped {total_skipped_expr_count} existing ones")
        print(f"  Created {total_added_meaning_count} meanings")
        print(f"  Linked {total_linked_count} expressions to meanings")
        
    except Exception as e:
        print(f"Error adding UI translations: {e}")
        db.rollback()
        raise
    finally:
        db.close()


if __name__ == "__main__":
    add_ui_translations()