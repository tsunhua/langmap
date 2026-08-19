import { describe, expect, it } from 'vitest';
import bcrypt from 'bcryptjs';
import { hashPassword, verifyPassword } from './auth';

describe('password compatibility', () => {
  it('verifies bcrypt hashes from v1', async () => {
    const hash = await bcrypt.hash('password', 4);
    await expect(verifyPassword('password', hash)).resolves.toBe(true);
    await expect(verifyPassword('wrong', hash)).resolves.toBe(false);
  });

  it('still verifies the legacy v2 salt:hex format', async () => {
    const hash = await hashPassword('secret');
    await expect(verifyPassword('secret', hash)).resolves.toBe(true);
    await expect(verifyPassword('wrong', hash)).resolves.toBe(false);
  });
});
