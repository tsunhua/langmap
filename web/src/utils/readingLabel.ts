const SCHEME_LABELS: Record<string, string> = {
  ipa: 'IPA',
  jyutping: '粵拼',
  'hakka-pinyin': '客語拼音',
  pinyin: '漢語拼音',
  'wade-giles': '威妥瑪拼音',
}

export function readingSchemeLabel(scheme: string): string {
  return SCHEME_LABELS[scheme] ?? scheme
}
