/// <reference types="vitest/globals" />
import { afterEach } from 'vitest'
import { config, enableAutoUnmount } from '@vue/test-utils'
import { i18n } from '@/locales'

enableAutoUnmount(afterEach)
config.global.plugins = [i18n]

if (typeof globalThis.ResizeObserver === 'undefined') {
  class ResizeObserverMock {
    observe() {}
    unobserve() {}
    disconnect() {}
  }
  globalThis.ResizeObserver = ResizeObserverMock as unknown as typeof ResizeObserver
}

// Node >= 26 exposes an experimental localStorage global (undefined without
// --localstorage-file) that shadows the jsdom implementation, so provide an
// in-memory storage for tests that persist tokens and preferences.
if (typeof globalThis.localStorage === 'undefined') {
  class MemoryStorage implements Storage {
    private readonly entries = new Map<string, string>()
    get length() {
      return this.entries.size
    }
    key(index: number) {
      return [...this.entries.keys()][index] ?? null
    }
    getItem(key: string) {
      return this.entries.get(key) ?? null
    }
    setItem(key: string, value: string) {
      this.entries.set(key, String(value))
    }
    removeItem(key: string) {
      this.entries.delete(key)
    }
    clear() {
      this.entries.clear()
    }
  }
  Object.defineProperty(globalThis, 'localStorage', {
    value: new MemoryStorage(),
    configurable: true,
    writable: true,
  })
}

const svgProto = SVGElement.prototype as any

if (typeof SVGElement !== 'undefined' && !svgProto.getBBox) {
  svgProto.getBBox = () => ({
    x: 0,
    y: 0,
    width: 80,
    height: 28,
    toJSON() {},
  })
}

if (typeof SVGElement !== 'undefined' && !svgProto.getBoundingClientRect) {
  svgProto.getBoundingClientRect = () => ({
    x: 0,
    y: 0,
    top: 0,
    left: 0,
    right: 80,
    bottom: 28,
    width: 80,
    height: 28,
    toJSON() {},
  })
}
