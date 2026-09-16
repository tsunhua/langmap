# Keep generated translations outside the canonical graph

**Status: accepted**

Generated translation results remain transient and never automatically create canonical expressions or mapping edges. A full-input exact match may use an existing canonical target directly without invoking AI; this is a read of established knowledge, not a generated result. For assisted results, a logged-in user may review and submit one primary translation through the existing contribution flow, with the confirmation UI disclosing AI assistance but without persisting a separate AI-provenance event in the first release; this keeps model output separate from community knowledge and avoids treating repeated or existing edges as a new fact.
