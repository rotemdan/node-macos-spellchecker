# Node.js binding to the macOS spell-checker

Uses N-API to bind to the macOS native spell-checker (part of the Cocoa framework):

* Only a minimal set of operations are currently implemented: `testSpelling`, `getSpellingSuggestions`, `addWord` and `removeWord` (all apply to a single word only)
* Addon binary is pre-bundled. Doesn't require any install-time scripts
* Uses the stable `napi.h` C++ API (with `NAPI_VERSION = 8`). It should not generally require recompilation for new different Node.js versions
* Should work in different versions of Electron.js without recompilation
* Supports both x64 and arm64 versions of macOS

## Usage example
```
npm install macos-spellchecker
```

```ts
import { createMacosSpellChecker, getSupportedLanguages } from 'macos-spellchecker'

console.log(getSupportedLanguages())
// Output: [ 'en',  'en_CA', 'en_GB', 'en_AU', 'en_IN', ...  'hi', 'pa', 'te', 'ko' ]

const checker = createMacosSpellChecker('en')

console.log(checker.testSpelling('Hello'))
// Output: true

console.log(checker.testSpelling('Hellow'))
// Output: false

console.log(checker.getSpellingSuggestions('Hellow'))
// Output: [
//   'Hallow', 'Hollow', 'Hello', 'Hellos', 'Hallows',
//   'Henlow', 'Mellow', 'Yellow'
// ]

checker.dispose()
```

## Adding and removing words

```ts
checker.addWord('Hellow')
```
```ts
checker.removeWord('Hellow')
```

## Building the N-API addons

The library is bundled with pre-built addons, so recompilation shouldn't be needed.

If you still want to compile yourself, for a modification or a fork:

* In the `addons` directory, run `npm install`, which would install the necessary build tools. Then run `npm run build-x64` (x64) or `npm run build-arm64` (arm64).
* Resulting binaries should be written to the `addons/bin` directory

## License

MIT
