INSERT INTO parts_of_speech(code, name_en, sort_order, bit_index) VALUES
  ('noun', 'Noun', 1, 0),
  ('proper-noun', 'Proper noun', 2, 1),
  ('verb', 'Verb', 3, 2),
  ('auxiliary', 'Auxiliary verb', 4, 3),
  ('adjective', 'Adjective', 5, 4),
  ('adverb', 'Adverb', 6, 5),
  ('pronoun', 'Pronoun', 7, 6),
  ('determiner', 'Determiner', 8, 7),
  ('numeral', 'Numeral', 9, 8),
  ('adposition', 'Adposition', 10, 9),
  ('conjunction', 'Conjunction', 11, 10),
  ('particle', 'Particle', 12, 11),
  ('interjection', 'Interjection', 13, 12),
  ('abbreviation', 'Abbreviation', 14, 13),
  ('phrase', 'Phrase', 15, 14)
ON CONFLICT (code) DO NOTHING;
