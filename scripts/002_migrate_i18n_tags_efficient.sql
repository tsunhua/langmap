-- D1 Migration: Update i18n tags in expressions table (Optimized Version)
-- This script migrates old i18n keys to new flat underscore-separated format
-- Only affects expressions in collection_id = 1000000
-- Migration 002: Update i18n tags (Efficient)

BEGIN TRANSACTION;

-- Step 1: Create a temporary table for updated tags
-- This is much faster than updating each row multiple times
CREATE TEMP TABLE temp_tag_updates AS
SELECT 
    e.id,
    -- Build new tags array by replacing all old keys with new keys
    json_patch(
        e.tags,
        json_object(
            "add_anguage": "add_language",
            "add_xpression": "add_expression",
            "agree_o_erms": "agree_to_terms",
            "assist_ranslation": "assist_translation",
            "click_n_ap_o_elect": "click_on_map_to_select",
            "collections.addToCollection": "add_to_collection",
            "collections.deleteConfirm": "deleteConfirm",
            "collections.private": "private",
            "common_start_xport": "start_export",
            "create_ew": "create_new",
            "create_success": "expression_created_success",
            "csv_esc": "csv_desc",
            "delete_onfirm": "delete_confirm",
            "desc_laceholder": "desc_placeholder",
            "detail_no_expressions_found": "no_expressions_found",
            "detail_unlink": "unlink",
            "error_essage": "error_message",
            "error_message": "verification_link_invalid_or_expired",
            "forgot_assword": "forgot_password",
            "geolocation_ot_upported": "geolocation_not_supported",
            "home.regions": "regions",
            "home.subtitle": "subtitle",
            "home.title": "home_title",
            "home_regions": "regions",
            "json_esc": "json_desc",
            "language_elp": "language_help",
            "language_ode_elp": "language_code_help",
            "language_ot_ctivated": "language_not_activated",
            "location_arsing_ailed": "location_parsing_failed",
            "location_etection_ailed": "location_detection_failed",
            "login_ailed": "login_failed",
            "login_remember_me": "remember_me",
            "map_itle": "map_title",
            "meaning_ags_elp": "meaning_tags_help",
            "meaning_escription_elp": "meaning_description_help",
            "meaning_escription_laceholder": "meaning_description_placeholder",
            "meaning_loss_elp": "meaning_gloss_help",
            "meaning_loss_laceholder": "meaning_gloss_placeholder",
            "no_eanings": "no_meanings",
            "no_esults": "no_results",
            "no_xpressions_ound": "no_expressions_found",
            "not_ound": "not_found",
            "parsing_ocation": "parsing_location",
            "redirect_onfirm": "redirect_confirm",
            "region_elp": "region_help",
            "region_laceholder": "region_placeholder",
            "registration_success_message": "registration_check_email",
            "registration_successful_message": "registration_verify_email",
            "remember_e": "remember_me",
            "remove_tem_onfirm": "remove_item_confirm",
            "same_anguage_rror": "same_language_error",
            "save_ranslations": "save_translations",
            "search.placeholder": "search_placeholder",
            "search_add_xpression": "add_expression",
            "search_laceholder": "search_placeholder",
            "search_xpressions_esc": "search_expressions_desc",
            "select_eaning": "select_meaning",
            "select_ormat": "select_format",
            "sign_n": "login",
            "source_elp": "source_help",
            "source_laceholder": "source_placeholder",
            "start_xport": "start_export",
            "success_essage": "email_verified_success",
            "text_elp": "text_help",
            "text_laceholder": "text_placeholder",
            "update_rror": "update_error",
            "updated_uccess": "updated_success",
            "user.profile": "user_profile",
            "verifying_essage": "verifying_email_address",
            "verifying_message": "verifying_email_address",
            "version.history": "version_history"
        )
    ) as new_tags
FROM expressions e
WHERE e.collection_id = 1000000
  AND e.tags IS NOT NULL
  AND e.tags != '';

-- Step 2: Update the expressions table with new tags
UPDATE expressions
SET tags = (
    SELECT new_tags FROM temp_tag_updates t
    WHERE t.id = expressions.id
)
WHERE collection_id = 1000000
  AND id IN (SELECT id FROM temp_tag_updates);

-- Step 3: Verify the update
SELECT 
    COUNT(*) as updated_count,
    MIN(id) as first_updated_id,
    MAX(id) as last_updated_id
FROM expressions
WHERE collection_id = 1000000
  AND id IN (SELECT id FROM temp_tag_updates);

-- Step 4: Show sample updates (for verification)
SELECT 
    'Sample Updated Tags:' as info,
    id,
    tags as updated_tags
FROM expressions
WHERE collection_id = 1000000
  AND id IN (SELECT id FROM temp_tag_updates)
ORDER BY id
LIMIT 5;

COMMIT;

-- Clean up temp table (auto-dropped on connection close)
DROP TABLE IF EXISTS temp_tag_updates;

-- Log migration completion
SELECT 'Migration 002: i18n tags migration completed' AS message;
