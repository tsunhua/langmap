# Backend Deployment Guide

## Overview

This document provides instructions for deploying and configuring the Langmap backend, including database setup, API endpoints, and internationalization features.

## Database Schema

The backend uses a relational database with the following key tables:

### Languages Table
Stores information about supported languages:
- `id`: Primary key
- `code`: Unique language code (e.g., 'en', 'zh-CN')
- `name`: Language name in English
- `native_name`: Language name in its native script
- `direction`: Text direction ('ltr' or 'rtl')
- `is_active`: Whether the language is active
- `created_by`: User ID of creator
- `created_at`: Creation timestamp
- `updated_at`: Last update timestamp

### Expressions Table
Stores linguistic expressions with their metadata:
- `id`: Primary key
- `language`: Language code
- `region`: Geographic region (optional)
- `text`: The actual expression text
- `source_type`: Source type ('user', 'ai', etc.)
- `source_ref`: Source reference (URL, book, etc.)
- `audio_url`: Audio pronunciation URL (optional)
- `created_by`: User ID of creator
- `created_at`: Creation timestamp
- `review_status`: Review status ('pending', 'approved', 'rejected')
- `auto_approved`: Whether automatically approved
- `tags`: Tags for categorization (stored as JSON array in SQLite, native array in PostgreSQL)

### Meanings Table
Stores semantic meanings that can link expressions across languages:
- `id`: Primary key
- `gloss`: Short label for the meaning (e.g., 'langmap.home.title')
- `description`: Detailed description of the meaning
- `tags`: Tags for categorization (stored as JSON array in SQLite, native array in PostgreSQL)
- `created_by`: User ID of creator
- `created_at`: Creation timestamp

### ExpressionMeaning Table
Many-to-many relationship table linking expressions to meanings:
- `id`: Primary key
- `expression_id`: Foreign key to expressions table
- `meaning_id`: Foreign key to meanings table
- `created_by`: User ID of creator
- `created_at`: Creation timestamp
- `note`: Additional notes about the relationship
- `parent_version_id`: Links to specific expression version

## API Endpoints

### Language Management
- `GET /api/v1/languages`: List all supported languages
- `POST /api/v1/languages`: Create a new language

### Expression Management
- `GET /api/v1/expressions`: List expressions with optional filtering
- `POST /api/v1/expressions`: Create a new expression
- `POST /api/v1/ai/suggest`: Create an AI-suggested expression
- `GET /api/v1/search`: Search expressions
- `GET /api/v1/expressions/{id}`: Get a specific expression
- `GET /api/v1/expressions/{id}/versions`: Get expression versions
- `GET /api/v1/expressions/{id}/translations`: Get expression translations
- `GET /api/v1/expressions/{id}/meanings`: Get expression meanings

### Meaning Management
- `POST /api/v1/meanings`: Create a new meaning
- `POST /api/v1/meanings/{id}/link`: Link an expression to a meaning
- `GET /api/v1/meanings/{id}`: Get a specific meaning
- `GET /api/v1/meanings/{id}/members`: Get expressions linked to a meaning

### UI Translation Endpoints
- `GET /api/v1/ui-translations/{language}`: Get UI translations for a specific language by meaning tags

## Internationalization Implementation

Langmap supports dynamic language loading through a meaning-based approach with tags:

1. UI elements are identified by meanings with:
   - Glosses following the pattern "langmap.section.key" 
   - Tags including "langmap" to identify them as UI translations

2. Expressions in different languages can be linked to the same meaning

3. The frontend fetches UI translations by:
   - Requesting meanings with the "langmap" tag
   - Finding expressions linked to those meanings in the target language
   - Using the meaning's gloss as the translation key and the expression's text as the value

4. The backend transforms these into nested objects for the frontend i18n system

For example, to translate the homepage title:
1. Create a meaning with gloss "langmap.home.title" and tag ["langmap"]
2. Create expressions in different languages (e.g., "Home" in English, "首页" in Chinese)
3. Link all expressions to the same meaning
4. When the frontend requests UI translations for Chinese, it receives the Chinese expression linked to the "langmap.home.title" meaning

This approach allows for:
- Consistent translation management across languages
- Easy addition of new languages
- Shared semantic meaning across linguistic expressions
- Better organization of UI translations
- Efficient querying through tag-based filtering

## Database Migration

To add the tags column to the expressions table, run:
```bash
python scripts/add_tags_column.py
```

To add the tags column to the meanings table, run:
```bash
python scripts/add_tags_to_meanings.py
```

To create the languages table, run:
```bash
python scripts/create_languages_table.py
```

## Environment Variables

- `DATABASE_URL`: Database connection string (default: sqlite:///./backend_dev.db)

## Running the Application

To start the backend server:
```bash
uvicorn app.main:app --reload
```