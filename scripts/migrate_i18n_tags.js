/**
 * Efficient D1 Migration for i18n Tags
 * Uses Node.js to process tags efficiently
 * Only updates expressions associated with collection_id = 1000000
 */

import { createClient } from '@cloudflare/d1';
import { config as loadEnv } from 'dotenv';

// Load environment variables
loadEnv({ path: '.dev.vars' });

// Key mappings
const KEY_MAPPINGS = {
  "login_ailed": "login_failed",
  "map_itle": "map_title",
  "add_anguage": "add_language",
  "add_xpression": "add_expression",
  "delete_onfirm": "delete_confirm",
  "select_ormat": "select_format",
  "region_elp": "region_help",
  "region_laceholder": "region_placeholder",
  "same_anguage_rror": "same_language_error",
  "success_essage": "email_verified_success",
  "csv_esc": "csv_desc",
  "json_esc": "json_desc",
  "select_eaning": "select_meaning",
  "error_message": "verification_link_invalid_or_expired",
  "verifying_message": "verifying_email_address",
  "create_success": "expression_created_success",
  "registration_success_message": "registration_check_email",
  "registration_successful_message": "registration_verify_email",
  "agree_o_erms": "agree_to_terms",
  "assist_ranslation": "assist_translation",
  "click_n_ap_o_elect": "click_on_map_to_select",
  "common_start_xport": "start_export",
  "create_ew": "create_new",
  "desc_laceholder": "desc_placeholder",
  "error_essage": "error_message",
  "forgot_assword": "forgot_password",
  "geolocation_ot_upported": "geolocation_not_supported",
  "language_elp": "language_help",
  "language_ode_elp": "language_code_help",
  "language_ot_ctivated": "language_not_activated",
  "location_arsing_ailed": "location_parsing_failed",
  "location_etection_ailed": "location_detection_failed",
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
  "remember_e": "remember_me",
  "remove_tem_onfirm": "remove_item_confirm",
  "save_ranslations": "save_translations",
  "search_add_xpression": "add_expression",
  "search_laceholder": "search_placeholder",
  "search_xpressions_esc": "search_expressions_desc",
  "sign_n": "login",
  "source_elp": "source_help",
  "source_laceholder": "source_placeholder",
  "start_xport": "start_export",
  "text_elp": "text_help",
  "text_laceholder": "text_placeholder",
  "update_rror": "update_error",
  "updated_uccess": "updated_success",
  "verifying_essage": "verifying_email_address",
  "home_regions": "regions",
  "detail_no_expressions_found": "no_expressions_found",
  "detail_unlink": "unlink",
  "login_remember_me": "remember_me",
  "home.title": "home_title",
  "home.subtitle": "subtitle",
  "home.regions": "regions",
  "search.placeholder": "search_placeholder",
  "user.profile": "user_profile",
  "version.history": "version_history",
  "collections.addToCollection": "add_to_collection",
  "collections.deleteConfirm": "deleteConfirm",
  "collections.private": "private",
};

async function migrate() {
  const COLLECTION_ID = 1000000;
  
  console.log('======================================');
  console.log('D1 Migration: i18n Tags Update');
  console.log('======================================');
  console.log(`Collection ID: ${COLLECTION_ID}`);
  console.log(`Key Mappings: ${Object.keys(KEY_MAPPINGS).length}`);
  console.log('');

  // Initialize D1 client (for local testing)
  const db = createClient({
    databasePath: '.wrangler/state/v3/d1/miniflare-D1DatabaseObject'
  });

  try {
    // Step 1: Fetch all expressions in the collection
    console.log('Step 1: Fetching expressions from collection...');
    const result = await db
      .prepare(`
        SELECT DISTINCT e.id, e.tags
        FROM expressions e
        INNER JOIN collection_items ci ON e.id = ci.expression_id
        WHERE ci.collection_id = ? AND e.tags IS NOT NULL AND e.tags != ''
      `)
      .bind(COLLECTION_ID)
      .all();
    
    const expressions = result.results;
    console.log(`Found ${expressions.length} expressions with tags in collection ${COLLECTION_ID}`);
    console.log('');

    // Step 2: Update tags in memory
    console.log('Step 2: Processing tags...');
    const updates = [];
    let updatedCount = 0;
    let unchangedCount = 0;

    for (const expr of expressions) {
      let tags;
      try {
        tags = JSON.parse(expr.tags);
      } catch (e) {
        console.warn(`Failed to parse tags for expression ${expr.id}, skipping`);
        continue;
      }

      const originalTags = [...tags];
      let hasChanges = false;

      // Replace old keys with new keys
      for (let i = 0; i < tags.length; i++) {
        const oldKey = tags[i];
        if (KEY_MAPPINGS[oldKey]) {
          tags[i] = KEY_MAPPINGS[oldKey];
          hasChanges = true;
        }
      }

      if (hasChanges) {
        updates.push({
          id: expr.id,
          newTags: JSON.stringify(tags),
          oldTags: originalTags
        });
        updatedCount++;
      } else {
        unchangedCount++;
      }
    }

    console.log(`Updated: ${updatedCount}`);
    console.log(`Unchanged: ${unchangedCount}`);
    console.log('');

    // Step 3: Batch update
    if (updates.length > 0) {
      console.log('Step 3: Applying batch updates...');
      
      const BATCH_SIZE = 100;
      for (let i = 0; i < updates.length; i += BATCH_SIZE) {
        const batch = updates.slice(i, i + BATCH_SIZE);
        
        const stmt = db.batch();
        for (const update of batch) {
          stmt.prepare('UPDATE expressions SET tags = ?, updated_at = datetime("now") WHERE id = ?')
            .bind(update.newTags, update.id);
        }
        
        await stmt.all();
        console.log(`  Batch ${Math.floor(i / BATCH_SIZE) + 1}/${Math.ceil(updates.length / BATCH_SIZE)}: ${batch.length} records`);
      }
    }

    console.log('');
    console.log('======================================');
    console.log('Migration completed successfully!');
    console.log('======================================');
    console.log(`Total updated: ${updatedCount}`);
    console.log(`Total unchanged: ${unchangedCount}`);

    // Show sample changes
    if (updates.length > 0) {
      console.log('');
      console.log('Sample changes:');
      updates.slice(0, 5).forEach(update => {
        console.log(`  Expression ${update.id}:`);
        console.log(`    Old: [${update.oldTags.join(', ')}]`);
        console.log(`    New: [${JSON.parse(update.newTags).join(', ')}]`);
      });
    }

  } catch (error) {
    console.error('Migration failed:', error);
    process.exit(1);
  }
}

// Run migration
migrate().catch(console.error);
