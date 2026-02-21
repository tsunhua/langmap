-- D1 Migration: Update i18n tags in expressions table (Optimized SQL Version)
-- This script migrates old i18n keys to new flat underscore-separated format
-- Only affects expressions associated with collection_id = 1000000 via collection_items
-- Uses a single efficient UPDATE with CASE statement
-- Migration 002: Update i18n tags (Optimized)

BEGIN TRANSACTION;

-- Single UPDATE statement with nested REPLACE for all key mappings
-- This is much faster than 71 separate UPDATEs
-- Only updates expressions in the specified collection
UPDATE expressions
SET tags = 
  REPLACE(
    REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(
                      REPLACE(
                        REPLACE(
                          REPLACE(
                            REPLACE(
                              REPLACE(
                                REPLACE(
                                  REPLACE(
                                    REPLACE(
                                      REPLACE(
                                        REPLACE(
                                          REPLACE(
                                            REPLACE(
                                              REPLACE(
                                                REPLACE(
                                                  REPLACE(
                                                    REPLACE(
                                                      REPLACE(
                                                        REPLACE(
                                                          REPLACE(
                                                            REPLACE(
                                                              REPLACE(
                                                                REPLACE(
                                                                  REPLACE(
                                                                    REPLACE(
                                                                      REPLACE(
                                                                        REPLACE(
                                                                          REPLACE(
                                                                            REPLACE(
                                                                              REPLACE(
                                                                                REPLACE(
                                                                                  REPLACE(
                                                                                    REPLACE(
                                                                                      REPLACE(
                                                                                        REPLACE(
                                                                                          REPLACE(
                                                                                            tags,
                                                                                            '"login_ailed"', '"login_failed"'
                                                                                          ),
                                                                                          '"map_itle"', '"map_title"'
                                                                                        ),
                                                                                        '"add_anguage"', '"add_language"'
                                                                                      ),
                                                                                      '"add_xpression"', '"add_expression"'
                                                                                    ),
                                                                                    '"delete_onfirm"', '"delete_confirm"'
                                                                                  ),
                                                                                  '"select_ormat"', '"select_format"'
                                                                                ),
                                                                                '"region_elp"', '"region_help"'
                                                                              ),
                                                                              '"region_laceholder"', '"region_placeholder"'
                                                                            ),
                                                                            '"same_anguage_rror"', '"same_language_error"'
                                                                          ),
                                                                          '"success_essage"', '"email_verified_success"'
                                                                        ),
                                                                        '"csv_esc"', '"csv_desc"'
                                                                      ),
                                                                      '"json_esc"', '"json_desc"'
                                                                    ),
                                                                    '"select_eaning"', '"select_meaning"'
                                                                  ),
                                                                  '"error_message"', '"verification_link_invalid_or_expired"'
                                                                ),
                                                                '"verifying_message"', '"verifying_email_address"'
                                                              ),
                                                              '"create_success"', '"expression_created_success"'
                                                            ),
                                                            '"registration_success_message"', '"registration_check_email"'
                                                          ),
                                                          '"registration_successful_message"', '"registration_verify_email"'
                                                        ),
                                                        '"agree_o_erms"', '"agree_to_terms"'
                                                      ),
                                                      '"assist_ranslation"', '"assist_translation"'
                                                    ),
                                                    '"click_n_ap_o_elect"', '"click_on_map_to_select"'
                                                  ),
                                                  '"common_start_xport"', '"start_export"'
                                                ),
                                                '"create_ew"', '"create_new"'
                                              ),
                                              '"desc_laceholder"', '"desc_placeholder"'
                                            ),
                                            '"error_essage"', '"error_message"'
                                          ),
                                          '"forgot_assword"', '"forgot_password"'
                                        ),
                                        '"geolocation_ot_upported"', '"geolocation_not_supported"'
                                      ),
                                      '"language_elp"', '"language_help"'
                                    ),
                                    '"language_ode_elp"', '"language_code_help"'
                                  ),
                                  '"language_ot_ctivated"', '"language_not_activated"'
                                ),
                                '"location_arsing_ailed"', '"location_parsing_failed"'
                              ),
                              '"location_etection_ailed"', '"location_detection_failed"'
                            ),
                            '"meaning_ags_elp"', '"meaning_tags_help"'
                          ),
                          '"meaning_escription_elp"', '"meaning_description_help"'
                        ),
                        '"meaning_escription_laceholder"', '"meaning_description_placeholder"'
                      ),
                      '"meaning_loss_elp"', '"meaning_gloss_help"'
                    ),
                    '"meaning_loss_laceholder"', '"meaning_gloss_placeholder"'
                  ),
                  '"no_eanings"', '"no_meanings"'
                ),
                '"no_esults"', '"no_results"'
              ),
              '"no_xpressions_ound"', '"no_expressions_found"'
            ),
            '"not_ound"', '"not_found"'
          ),
          '"parsing_ocation"', '"parsing_location"'
        ),
        '"redirect_onfirm"', '"redirect_confirm"'
      ),
      '"remember_e"', '"remember_me"'
    ),
    '"remove_tem_onfirm"', '"remove_item_confirm"'
  ),
  '"save_ranslations"', '"save_translations"'
),
'"search_add_xpression"', '"add_expression"'
),
'"search_laceholder"', '"search_placeholder"'
),
'"search_xpressions_esc"', '"search_expressions_desc"'
),
'"sign_n"', '"login"'
),
'"source_elp"', '"source_help"'
),
'"source_laceholder"', '"source_placeholder"'
),
'"start_xport"', '"start_export"'
),
'"text_elp"', '"text_help"'
),
'"text_laceholder"', '"text_placeholder"'
),
'"update_rror"', '"update_error"'
),
'"updated_uccess"', '"updated_success"'
),
'"verifying_essage"', '"verifying_email_address"'
),
'"home_regions"', '"regions"'
),
'"detail_no_expressions_found"', '"no_expressions_found"'
),
'"detail_unlink"', '"unlink"'
),
'"login_remember_me"', '"remember_me"'
),
'"home.title"', '"home_title"'
),
'"home.subtitle"', '"subtitle"'
),
'"home.regions"', '"regions"'
),
'"search.placeholder"', '"search_placeholder"'
),
'"user.profile"', '"user_profile"'
),
'"version.history"', '"version_history"'
),
'"collections.addToCollection"', '"add_to_collection"'
),
'"collections.deleteConfirm"', '"deleteConfirm"'
),
'"collections.private"', '"private"'
),
updated_at = datetime('now')
WHERE id IN (
  SELECT DISTINCT e.id
  FROM expressions e
  INNER JOIN collection_items ci ON e.id = ci.expression_id
  WHERE ci.collection_id = 1000000
);

-- Verify update
SELECT 
  COUNT(*) as updated_count
FROM expressions e
WHERE e.id IN (
  SELECT DISTINCT ci.expression_id
  FROM collection_items ci
  WHERE ci.collection_id = 1000000
) AND e.tags LIKE '%login_failed%';  -- Check for a known new key

-- Show sample updates
SELECT 
  'Sample Updated Tags:' as info,
  e.id,
  e.text,
  e.tags as updated_tags
FROM expressions e
WHERE e.id IN (
  SELECT DISTINCT ci.expression_id
  FROM collection_items ci
  WHERE ci.collection_id = 1000000
  LIMIT 5
);

COMMIT;

-- Log migration completion
SELECT 'Migration 002: i18n tags migration completed' AS message;
