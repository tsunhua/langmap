import type { Config } from 'tailwindcss'

export default {
  content: ['./index.html', './src/**/*.{vue,ts}'],
  theme: {
    extend: {
      colors: {
        parchment:  '#F5F0E8',
        'parchment-dark': '#EDE5D8',
        ink:        '#1A1A1A',
        'ink-light': '#4A4A4A',
        accent:     '#8B4513',
        'accent-light': '#A0522D',
        'accent-soft': '#F5E6D3',
        muted:      '#6B7280',
        highlight:  '#D4A574',
        'highlight-light': '#E8C9A0',
        edge:       '#4A6FA5',
        success:    '#2D5016',
        error:      '#8B0000',
        up:         '#2D7A3A',
        down:       '#A03030',
        fold:       '#B8A88A',
      },
      fontFamily: {
        serif: ['"Noto Serif"', 'Georgia', 'serif'],
        sans:  ['"Inter"', 'system-ui', 'sans-serif'],
        mono:  ['"IBM Plex Mono"', 'monospace'],
      },
      borderRadius: {
        atlas: '4px',
      },
      boxShadow: {
        atlas:    '0 1px 3px rgba(0,0,0,0.08)',
        'atlas-lg': '0 4px 12px rgba(0,0,0,0.1)',
        'glow':   '0 0 12px rgba(139,69,19,0.3)',
      },
      height: {
        'bar': '44px',
      },
    },
  },
  plugins: [],
} satisfies Config
