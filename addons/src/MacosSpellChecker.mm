#include <string>
#include <vector>
#include <sstream>
#include <iostream>

#import <Cocoa/Cocoa.h>
#import <napi.h>

///////////////////////////////////////////////////////////////////////////////////////////
// macOS (Cocoa) spell-checker class
///////////////////////////////////////////////////////////////////////////////////////////
class MacosSpellChecker {
private:
	NSSpellChecker* spellChecker;
	bool isInitialized;

public:
	// Error codes
	enum ErrorCode {
		SUCCESS = 0,
		INIT_FAILED = -1,
		STRING_CONVERSION_FAILED = -2,
		INVALID_ARGUMENT = -3,
		OPERATION_FAILED = -4,
		UNINITIALIZED = -5
	};

	MacosSpellChecker() : spellChecker(nullptr), isInitialized(false) {
	}

	int Initialize(const std::string& languageCode) {
		if (isInitialized) {
			return SUCCESS;  // Already initialized
		}

		spellChecker = [[NSSpellChecker alloc] init];
		if (!spellChecker) {
			return INIT_FAILED;
		}

		auto errorCode = SetLanguage(languageCode);

		if (errorCode < 0) {
			[spellChecker release];
			spellChecker = nullptr;

			return errorCode;
		}

		isInitialized = true;

		return SUCCESS;
	}

	int TestSpelling(const std::string& word) {
		if (!isInitialized) {
			return UNINITIALIZED;
		}

		if (word.empty()) {
			return 1; // Empty words are considered valid
		}

		@try {
			NSString* nsWord = [NSString stringWithUTF8String:word.c_str()];
			if (!nsWord) {
				return STRING_CONVERSION_FAILED;
			}

			NSRange range = [spellChecker checkSpellingOfString:nsWord startingAt:0];

			return (range.length == 0) ? 1 : 0; // 1 for correct spelling, 0 for incorrect
		}
		@catch (NSException* exception) {
			return OPERATION_FAILED;
		}
	}

	int GetSpellingSuggestions(const std::string& word, std::vector<std::string>& suggestions) {
		suggestions.clear();

		if (!isInitialized) {
			return UNINITIALIZED;
		}

		if (word.empty()) {
			return SUCCESS;
		}

		@try {
			NSString* nsWord = [NSString stringWithUTF8String:word.c_str()];
			if (!nsWord) {
				return STRING_CONVERSION_FAILED;
			}

			NSRange range = NSMakeRange(0, [nsWord length]);
			NSArray* guesses = [spellChecker
							  guessesForWordRange:range
							  inString:nsWord
							  language:[spellChecker language]
							  inSpellDocumentWithTag:0];

			if (!guesses) {
				return OPERATION_FAILED;
			}

			for (NSString* guess in guesses) {
				const char* utf8Guess = [guess UTF8String];
				if (utf8Guess) {
					suggestions.push_back(utf8Guess);
				}
			}

			return SUCCESS;
		}
		@catch (NSException* exception) {
			return OPERATION_FAILED;
		}
	}

	int AddWord(const std::string& word) {
		if (!isInitialized) {
			return UNINITIALIZED;
		}

		if (word.empty()) {
			return INVALID_ARGUMENT;
		}

		@try {
			NSString* nsWord = [NSString stringWithUTF8String:word.c_str()];
			if (!nsWord) {
				return STRING_CONVERSION_FAILED;
			}

			[spellChecker learnWord:nsWord];

			return SUCCESS;
		}
		@catch (NSException* exception) {
			return OPERATION_FAILED;
		}
	}

	int RemoveWord(const std::string& word) {
		if (!isInitialized) {
			return UNINITIALIZED;
		}

		if (word.empty()) {
			return INVALID_ARGUMENT;
		}

		@try {
			NSString* nsWord = [NSString stringWithUTF8String:word.c_str()];
			if (!nsWord) {
				return STRING_CONVERSION_FAILED;
			}

			[spellChecker unlearnWord:nsWord];

			return SUCCESS;
		}
		@catch (NSException* exception) {
			return OPERATION_FAILED;
		}
	}

	~MacosSpellChecker() {
		if (spellChecker) {
			[spellChecker release];
			spellChecker = nullptr;
		}
	}

private:
	int SetLanguage(const std::string& languageCode) {
		if (languageCode.empty()) {
			return SUCCESS; // Empty language code would use the default language
		}

		@try {
			NSString* nsLanguageCode = [NSString stringWithUTF8String:languageCode.c_str()];

			if (!nsLanguageCode) {
				return STRING_CONVERSION_FAILED;
			}

			return [spellChecker setLanguage:nsLanguageCode];
		}
		@catch (NSException* exception) {
			return OPERATION_FAILED;
		}
	}
};

int getSupportedLanguageList(std::vector<std::string>& result) {
	result.clear();

	@try {
		NSSpellChecker* spellChecker = [NSSpellChecker sharedSpellChecker];
		if (!spellChecker) {
			return MacosSpellChecker::INIT_FAILED;
		}

		NSArray* languages = [spellChecker availableLanguages];
		if (!languages) {
			return MacosSpellChecker::OPERATION_FAILED;
		}

		for (size_t i = 0; i < languages.count; ++i) {
			NSString* language = [languages objectAtIndex:i];
			const char* utf8Language = [language UTF8String];

			if (utf8Language) {
				result.push_back(utf8Language);
			}
		}

		return MacosSpellChecker::SUCCESS;
	}
	@catch (NSException* exception) {
		return MacosSpellChecker::OPERATION_FAILED;
	}
}

///////////////////////////////////////////////////////////////////////////////////////////
// N-API wrapper methods
///////////////////////////////////////////////////////////////////////////////////////////
Napi::Value createMacosSpellChecker(const Napi::CallbackInfo& info) {
	auto env = info.Env();

	auto language = info[0].As<Napi::String>().Utf8Value();

	// Initialize
	auto macosSpellChecker = new MacosSpellChecker();

	auto errorCode = macosSpellChecker->Initialize(language);

	if (errorCode < 0) {
		std::stringstream errorString;
		errorString << "Failed to create macOS spell checker. Got error code " << errorCode;

		Napi::Error::New(env, errorString.str()).ThrowAsJavaScriptException();

		return env.Undefined();
	}

	// Build JavaScript result object
	auto resultObject = Napi::Object().New(env);

	auto testSpelling = [macosSpellChecker](const Napi::CallbackInfo& info) -> Napi::Value {
		auto env = info.Env();

		auto wordString = info[0].As<Napi::String>().Utf8Value();

		auto resultCode = macosSpellChecker->TestSpelling(wordString);

		if (resultCode < 0) {
			std::stringstream errorString;
			errorString << "Failed to test spelling of word '" << wordString << "'. Got error code " << resultCode;

			Napi::Error::New(env, errorString.str()).ThrowAsJavaScriptException();

			return env.Undefined();
		}

		return Napi::Boolean::New(env, resultCode);
	};

	auto getSpellingSuggestions = [macosSpellChecker](const Napi::CallbackInfo& info) -> Napi::Value {
		auto env = info.Env();

		auto wordString = info[0].As<Napi::String>().Utf8Value();

		std::vector<std::string> suggestions;

		auto errorCode = macosSpellChecker->GetSpellingSuggestions(wordString, suggestions);

		if (errorCode < 0) {
			std::stringstream errorString;
			errorString << "Failed to get spelling suggestions for word '" << wordString << "'. Got error code " << errorCode;

			Napi::Error::New(env, errorString.str()).ThrowAsJavaScriptException();

			return env.Undefined();
		}

		auto resultNapiArray = Napi::Array::New(env, suggestions.size());

		for (size_t i = 0; i < suggestions.size(); i++) {
			const std::string& suggestion = suggestions[i];

			auto suggestionNapiString = Napi::String::New(env, suggestion);

			resultNapiArray.Set(i, suggestionNapiString);
		}

		return resultNapiArray;
	};

	auto addWord = [macosSpellChecker](const Napi::CallbackInfo& info) -> Napi::Value {
		auto env = info.Env();

		auto wordString = info[0].As<Napi::String>().Utf8Value();

		auto errorCode = macosSpellChecker->AddWord(wordString);

		if (errorCode < 0) {
			std::stringstream errorString;
			errorString << "Failed to add word '" << wordString << "'. Got error code " << errorCode;

			Napi::Error::New(env, errorString.str()).ThrowAsJavaScriptException();
		}

		return env.Undefined();
	};

	auto removeWord = [macosSpellChecker](const Napi::CallbackInfo& info) {
		auto env = info.Env();

		auto wordString = info[0].As<Napi::String>().Utf8Value();

		auto errorCode = macosSpellChecker->RemoveWord(wordString);

		if (errorCode < 0) {
			std::stringstream errorString;
			errorString << "Failed to remove word '" << wordString << "'. Got error code " << errorCode;

			Napi::Error::New(env, errorString.str()).ThrowAsJavaScriptException();
		}

		return env.Undefined();
	};

	// Note: Should ensure, within a JavaScript wrapper, that 'dispose' is never called more than once.
	// Otherwise a memory corruption may occur.
	auto dispose = [macosSpellChecker](const Napi::CallbackInfo& info) {
		delete macosSpellChecker;
	};

	resultObject.Set(Napi::String::New(env, "testSpelling"), Napi::Function::New(env, testSpelling));
	resultObject.Set(Napi::String::New(env, "getSpellingSuggestions"), Napi::Function::New(env, getSpellingSuggestions));
	resultObject.Set(Napi::String::New(env, "addWord"), Napi::Function::New(env, addWord));
	resultObject.Set(Napi::String::New(env, "removeWord"), Napi::Function::New(env, removeWord));
	resultObject.Set(Napi::String::New(env, "dispose"), Napi::Function::New(env, dispose));

	return resultObject;
}

Napi::Value getSupportedLanguages(const Napi::CallbackInfo& info) {
	auto env = info.Env();

	std::vector<std::string> languageList;
	auto errorCode = getSupportedLanguageList(languageList);

	if (errorCode < 0) {
		std::stringstream errorString;
		errorString << "Failed to get supported languages for macOS spell-checker. Got error code " << errorCode;

		Napi::Error::New(env, errorString.str()).ThrowAsJavaScriptException();

		return env.Undefined();
	}

	auto resultNapiArray = Napi::Array::New(env, languageList.size());

	for (size_t i = 0; i < languageList.size(); i++) {
		auto languageNapiString = Napi::String::New(env, languageList[i]);

		resultNapiArray.Set(i, languageNapiString);
	}

	return resultNapiArray;
}

Napi::Value isAddonLoaded(const Napi::CallbackInfo& info) {
	auto env = info.Env();

	return Napi::Boolean::New(env, true);
}

Napi::Object Init(Napi::Env env, Napi::Object exports) {
	exports.Set(Napi::String::New(env, "getSupportedLanguages"), Napi::Function::New(env, getSupportedLanguages));
	exports.Set(Napi::String::New(env, "createMacosSpellChecker"), Napi::Function::New(env, createMacosSpellChecker));
	exports.Set(Napi::String::New(env, "isAddonLoaded"), Napi::Function::New(env, isAddonLoaded));

	return exports;
}

NODE_API_MODULE(addon, Init)
