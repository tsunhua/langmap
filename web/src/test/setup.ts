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
