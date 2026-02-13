-- D1 Migration: Update i18n tags in expressions table
-- This script migrates old i18n keys to new flat underscore-separated format
-- Migration 002: Update i18n tags

BEGIN TRANSACTION;

UPDATE expressions
SET tags = REPLACE(tags, '"login_ailed"', '"login_failed"')
WHERE tags LIKE '%"login_ailed"%';

UPDATE expressions
SET tags = REPLACE(tags, '"map_itle"', '"map_title"')
WHERE tags LIKE '%"map_itle"%';

UPDATE expressions
SET tags = REPLACE(tags, '"add_anguage"', '"add_language"')
WHERE tags LIKE '%"add_anguage"%';

UPDATE expressions
SET tags = REPLACE(tags, '"add_xpression"', '"add_expression"')
WHERE tags LIKE '%"add_xpression"%';

UPDATE expressions
SET tags = REPLACE(tags, '"delete_onfirm"', '"delete_confirm"')
WHERE tags LIKE '%"delete_onfirm"%';

UPDATE expressions
SET tags = REPLACE(tags, '"select_ormat"', '"select_format"')
WHERE tags LIKE '%"select_ormat"%';

UPDATE expressions
SET tags = REPLACE(tags, '"region_elp"', '"region_help"')
WHERE tags LIKE '%"region_elp"%';

UPDATE expressions
SET tags = REPLACE(tags, '"region_laceholder"', '"region_placeholder"')
WHERE tags LIKE '%"region_laceholder"%';

UPDATE expressions
SET tags = REPLACE(tags, '"same_anguage_rror"', '"same_language_error"')
WHERE tags LIKE '%"same_anguage_rror"%';

UPDATE expressions
SET tags = REPLACE(tags, '"success_essage"', '"email_verified_success"')
WHERE tags LIKE '%"success_essage"%';

UPDATE expressions
SET tags = REPLACE(tags, '"csv_esc"', '"csv_desc"')
WHERE tags LIKE '%"csv_esc"%';

UPDATE expressions
SET tags = REPLACE(tags, '"json_esc"', '"json_desc"')
WHERE tags LIKE '%"json_esc"%';

UPDATE expressions
SET tags = REPLACE(tags, '"select_eaning"', '"select_meaning"')
WHERE tags LIKE '%"select_eaning"%';

UPDATE expressions
SET tags = REPLACE(tags, '"error_message"', '"verification_link_invalid_or_expired"')
WHERE tags LIKE '%"error_message"%';

UPDATE expressions
SET tags = REPLACE(tags, '"verifying_message"', '"verifying_email_address"')
WHERE tags LIKE '%"verifying_message"%';

UPDATE expressions
SET tags = REPLACE(tags, '"create_success"', '"expression_created_success"')
WHERE tags LIKE '%"create_success"%';

UPDATE expressions
SET tags = REPLACE(tags, '"registration_success_message"', '"registration_check_email"')
WHERE tags LIKE '%"registration_success_message"%';

UPDATE expressions
SET tags = REPLACE(tags, '"registration_successful_message"', '"registration_verify_email"')
WHERE tags LIKE '%"registration_successful_message"%';

UPDATE expressions
SET tags = REPLACE(tags, '"agree_o_erms"', '"agree_to_terms"')
WHERE tags LIKE '%"agree_o_erms"%';

UPDATE expressions
SET tags = REPLACE(tags, '"assist_ranslation"', '"assist_translation"')
WHERE tags LIKE '%"assist_ranslation"%';

UPDATE expressions
SET tags = REPLACE(tags, '"click_n_ap_o_elect"', '"click_on_map_to_select"')
WHERE tags LIKE '%"click_n_ap_o_elect"%';

UPDATE expressions
SET tags = REPLACE(tags, '"common_start_xport"', '"start_export"')
WHERE tags LIKE '%"common_start_xport"%';

UPDATE expressions
SET tags = REPLACE(tags, '"create_ew"', '"create_new"')
WHERE tags LIKE '%"create_ew"%';

UPDATE expressions
SET tags = REPLACE(tags, '"desc_laceholder"', '"desc_placeholder"')
WHERE tags LIKE '%"desc_laceholder"%';

UPDATE expressions
SET tags = REPLACE(tags, '"error_essage"', '"error_message"')
WHERE tags LIKE '%"error_essage"%';

UPDATE expressions
SET tags = REPLACE(tags, '"forgot_assword"', '"forgot_password"')
WHERE tags LIKE '%"forgot_assword"%';

UPDATE expressions
SET tags = REPLACE(tags, '"geolocation_ot_upported"', '"geolocation_not_supported"')
WHERE tags LIKE '%"geolocation_ot_upported"%';

UPDATE expressions
SET tags = REPLACE(tags, '"language_elp"', '"language_help"')
WHERE tags LIKE '%"language_elp"%';

UPDATE expressions
SET tags = REPLACE(tags, '"language_ode_elp"', '"language_code_help"')
WHERE tags LIKE '%"language_ode_elp"%';

UPDATE expressions
SET tags = REPLACE(tags, '"language_ot_ctivated"', '"language_not_activated"')
WHERE tags LIKE '%"language_ot_ctivated"%';

UPDATE expressions
SET tags = REPLACE(tags, '"location_arsing_ailed"', '"location_parsing_failed"')
WHERE tags LIKE '%"location_arsing_ailed"%';

UPDATE expressions
SET tags = REPLACE(tags, '"location_etection_ailed"', '"location_detection_failed"')
WHERE tags LIKE '%"location_etection_ailed"%';

UPDATE expressions
SET tags = REPLACE(tags, '"meaning_ags_elp"', '"meaning_tags_help"')
WHERE tags LIKE '%"meaning_ags_elp"%';

UPDATE expressions
SET tags = REPLACE(tags, '"meaning_escription_elp"', '"meaning_description_help"')
WHERE tags LIKE '%"meaning_escription_elp"%';

UPDATE expressions
SET tags = REPLACE(tags, '"meaning_escription_laceholder"', '"meaning_description_placeholder"')
WHERE tags LIKE '%"meaning_escription_laceholder"%';

UPDATE expressions
SET tags = REPLACE(tags, '"meaning_loss_elp"', '"meaning_gloss_help"')
WHERE tags LIKE '%"meaning_loss_elp"%';

UPDATE expressions
SET tags = REPLACE(tags, '"meaning_loss_laceholder"', '"meaning_gloss_placeholder"')
WHERE tags LIKE '%"meaning_loss_laceholder"%';

UPDATE expressions
SET tags = REPLACE(tags, '"no_eanings"', '"no_meanings"')
WHERE tags LIKE '%"no_eanings"%';

UPDATE expressions
SET tags = REPLACE(tags, '"no_esults"', '"no_results"')
WHERE tags LIKE '%"no_esults"%';

UPDATE expressions
SET tags = REPLACE(tags, '"no_xpressions_ound"', '"no_expressions_found"')
WHERE tags LIKE '%"no_xpressions_ound"%';

UPDATE expressions
SET tags = REPLACE(tags, '"not_ound"', '"not_found"')
WHERE tags LIKE '%"not_ound"%';

UPDATE expressions
SET tags = REPLACE(tags, '"parsing_ocation"', '"parsing_location"')
WHERE tags LIKE '%"parsing_ocation"%';

UPDATE expressions
SET tags = REPLACE(tags, '"redirect_onfirm"', '"redirect_confirm"')
WHERE tags LIKE '%"redirect_onfirm"%';

UPDATE expressions
SET tags = REPLACE(tags, '"remember_e"', '"remember_me"')
WHERE tags LIKE '%"remember_e"%';

UPDATE expressions
SET tags = REPLACE(tags, '"remove_tem_onfirm"', '"remove_item_confirm"')
WHERE tags LIKE '%"remove_tem_onfirm"%';

UPDATE expressions
SET tags = REPLACE(tags, '"save_ranslations"', '"save_translations"')
WHERE tags LIKE '%"save_ranslations"%';

UPDATE expressions
SET tags = REPLACE(tags, '"search_add_xpression"', '"add_expression"')
WHERE tags LIKE '%"search_add_xpression"%';

UPDATE expressions
SET tags = REPLACE(tags, '"search_laceholder"', '"search_placeholder"')
WHERE tags LIKE '%"search_laceholder"%';

UPDATE expressions
SET tags = REPLACE(tags, '"search_xpressions_esc"', '"search_expressions_desc"')
WHERE tags LIKE '%"search_xpressions_esc"%';

UPDATE expressions
SET tags = REPLACE(tags, '"sign_n"', '"login"')
WHERE tags LIKE '%"sign_n"%';

UPDATE expressions
SET tags = REPLACE(tags, '"source_elp"', '"source_help"')
WHERE tags LIKE '%"source_elp"%';

UPDATE expressions
SET tags = REPLACE(tags, '"source_laceholder"', '"source_placeholder"')
WHERE tags LIKE '%"source_laceholder"%';

UPDATE expressions
SET tags = REPLACE(tags, '"start_xport"', '"start_export"')
WHERE tags LIKE '%"start_xport"%';

UPDATE expressions
SET tags = REPLACE(tags, '"text_elp"', '"text_help"')
WHERE tags LIKE '%"text_elp"%';

UPDATE expressions
SET tags = REPLACE(tags, '"text_laceholder"', '"text_placeholder"')
WHERE tags LIKE '%"text_laceholder"%';

UPDATE expressions
SET tags = REPLACE(tags, '"update_rror"', '"update_error"')
WHERE tags LIKE '%"update_rror"%';

UPDATE expressions
SET tags = REPLACE(tags, '"updated_uccess"', '"updated_success"')
WHERE tags LIKE '%"updated_uccess"%';

UPDATE expressions
SET tags = REPLACE(tags, '"verifying_essage"', '"verifying_email_address"')
WHERE tags LIKE '%"verifying_essage"%';

UPDATE expressions
SET tags = REPLACE(tags, '"home_regions"', '"regions"')
WHERE tags LIKE '%"home_regions"%';

UPDATE expressions
SET tags = REPLACE(tags, '"detail_no_expressions_found"', '"no_expressions_found"')
WHERE tags LIKE '%"detail_no_expressions_found"%';

UPDATE expressions
SET tags = REPLACE(tags, '"detail_unlink"', '"unlink"')
WHERE tags LIKE '%"detail_unlink"%';

UPDATE expressions
SET tags = REPLACE(tags, '"login_remember_me"', '"remember_me"')
WHERE tags LIKE '%"login_remember_me"%';

UPDATE expressions
SET tags = REPLACE(tags, '"home.title"', '"home_title"')
WHERE tags LIKE '%"home.title"%';

UPDATE expressions
SET tags = REPLACE(tags, '"home.subtitle"', '"subtitle"')
WHERE tags LIKE '%"home.subtitle"%';

UPDATE expressions
SET tags = REPLACE(tags, '"home.regions"', '"regions"')
WHERE tags LIKE '%"home.regions"%';

UPDATE expressions
SET tags = REPLACE(tags, '"search.placeholder"', '"search_placeholder"')
WHERE tags LIKE '%"search.placeholder"%';

UPDATE expressions
SET tags = REPLACE(tags, '"user.profile"', '"user_profile"')
WHERE tags LIKE '%"user.profile"%';

UPDATE expressions
SET tags = REPLACE(tags, '"version.history"', '"version_history"')
WHERE tags LIKE '%"version.history"%';

UPDATE expressions
SET tags = REPLACE(tags, '"collections.addToCollection"', '"add_to_collection"')
WHERE tags LIKE '%"collections.addToCollection"%';

UPDATE expressions
SET tags = REPLACE(tags, '"collections.deleteConfirm"', '"deleteConfirm"')
WHERE tags LIKE '%"collections.deleteConfirm"%';

UPDATE expressions
SET tags = REPLACE(tags, '"collections.private"', '"private"')
WHERE tags LIKE '%"collections.private"%';

COMMIT;

-- Log migration completion
SELECT 'Migration 002: i18n tags migration completed' AS message;
