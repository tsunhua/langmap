-- Keep the system-seeded Mandarin locale labels aligned with their locale codes.
UPDATE language_locales SET name = '普通话(CN)' WHERE code = 'cmn-Hans-CN';
UPDATE language_locales SET name = '華語(TW)' WHERE code = 'cmn-Hant-TW';
