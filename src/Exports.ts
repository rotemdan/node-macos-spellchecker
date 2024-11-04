import { createRequire } from 'node:module'

export function getSupportedLanguages(): string[] {
	const addon = getAddonForCurrentPlatform()

	return addon.getSupportedLanguages()
}

export function createMacosSpellChecker(language: string) {
	const addon = getAddonForCurrentPlatform()

	const instance = addon.createMacosSpellChecker(language) as MacosSpellChecker

	let disposed = false

	const wrappedInstance: MacosSpellChecker = {
		testSpelling: (word: string) => {
			ensureNotDisposed()
			ensureIsString(word)

			return instance.testSpelling(word)
		},

		getSpellingSuggestions: (word: string) => {
			ensureNotDisposed()
			ensureIsString(word)

			return instance.getSpellingSuggestions(word)
		},

		addWord: (word: string) => {
			ensureNotDisposed()
			ensureIsString(word)

			instance.addWord(word)
		},

		removeWord: (word: string) => {
			ensureNotDisposed()
			ensureIsString(word)

			instance.removeWord(word)
		},

		dispose: () => {
			// Ensure the instance's `dispose` method is never called
			// more than once, to prevent memory corruption
			if (!disposed) {
				instance.dispose()
			}
		}
	}

	function ensureNotDisposed() {
		if (disposed) {
			throw new Error(`macOS spell checker instance has been disposed`)
		}
	}

	function ensureIsString(str: string) {
		if (typeof str !== 'string') {
			throw new Error(`Parameter ${str} is not a string`)
		}
	}

	return wrappedInstance
}

export function isAddonAvailable() {
	try {
		console.log(`Trying to create addon..`)
		const addon = getAddonForCurrentPlatform()

		console.log(`Trying to call 'isAddonLoaded'..`)
		const result = addon.isAddonLoaded()

		return result === true
	} catch (e) {
		console.log(e)
		return false
	}
}

function getAddonForCurrentPlatform() {
	const platform = process.platform
	const arch = process.arch

	const require = createRequire(import.meta.url)

	let addonModule: any

	if (platform === 'darwin' && arch === 'x64') {
		addonModule = require('../addons/bin/macos-x64-spellchecker.node')
	} else if (platform === 'darwin' && arch === 'arm64') {
		addonModule = require('../addons/bin/macos-arm64-spellchecker.node')
	} else {
		throw new Error(`macos-spellchecker initialization error: platform ${platform}, ${arch} is not supported`)
	}

	return addonModule
}

export interface MacosSpellChecker {
	testSpelling(word: string): boolean
	getSpellingSuggestions(word: string): string[]
	addWord(word: string): void
	removeWord(word: string): void
	dispose(): void
}