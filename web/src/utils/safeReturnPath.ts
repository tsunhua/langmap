// Returns a same-origin absolute path safe to redirect to after auth, or null
// when the value is unsafe. Pure so it can be unit tested directly.
export function safeReturnPath(value: unknown): string | null {
  if (typeof value !== 'string' || value.length === 0) return null
  if (!value.startsWith('/')) return null
  // Reject protocol-relative and backslash-based authorities; browsers treat
  // `\` like `/`, so any backslash could smuggle a host.
  if (value.startsWith('//') || value.includes('\\')) return null
  if (/[\u0000-\u001f\u007f]/.test(value)) return null
  // Strip query/hash before checking for a redirect loop into the auth page.
  const path = value.split(/[?#]/, 1)[0]
  if (path === '/auth' || path.startsWith('/auth/')) return null
  return value
}
