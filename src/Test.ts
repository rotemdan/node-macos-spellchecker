import { createMacosSpellChecker, getSupportedLanguages, isAddonAvailable } from './Exports.js'

const available = isAddonAvailable()
console.log(`Addon availble: ${available}`)

if (!available) {
	process.exit(1)
}

const languages = getSupportedLanguages()

console.log(languages)

const checker = createMacosSpellChecker('en')

console.log(checker.testSpelling('Hello'))
console.log(checker.testSpelling('Hellow'))

console.log(checker.testSpelling('遺事可堪解頤'))

//checker.addWord('Hellow')
//checker.removeWord('Hellow')

console.log(checker.testSpelling('Hellow'))

console.log(checker.getSpellingSuggestions('Hellow'))

checker.dispose()

const x = 0

