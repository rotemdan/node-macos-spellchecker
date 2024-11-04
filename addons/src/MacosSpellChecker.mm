#include <string>
#include <vector>

#import <Cocoa/Cocoa.h>
#import <napi.h>

class MacosSpellChecker {
private:
	NSSpellChecker* spellChecker;

public:
	MacosSpellChecker(const std::string& languageCode) {
		spellChecker = [[NSSpellChecker alloc] init];

		SetLanguage(languageCode);
	}

	bool TestSpelling(const std::string& word) {
		NSString* nsWord = [NSString stringWithUTF8String:word.c_str()];
		NSRange range = [spellChecker checkSpellingOfString:nsWord startingAt:0];

		return range.length == 0;
	}

	std::vector<std::string> GetSpellingSuggestions(const std::string& word) {
		std::vector<std::string> suggestions;

		NSString* nsWord = [NSString stringWithUTF8String:word.c_str()];

		NSRange range = NSMakeRange(0, [nsWord length]);

		NSArray* guesses = [spellChecker
							guessesForWordRange:range
							inString:nsWord
							language:[spellChecker language]
							inSpellDocumentWithTag:0];

		for (NSString* guess in guesses) {
			suggestions.push_back([guess UTF8String]);
		}

		return suggestions;
	}

	void AddWord(const std::string& word) {
		NSString* nsWord = [NSString stringWithUTF8String:word.c_str()];
		[spellChecker learnWord:nsWord];
	}

	void RemoveWord(const std::string& word) {
		NSString* nsWord = [NSString stringWithUTF8String:word.c_str()];
		[spellChecker unlearnWord:nsWord];
	}

	~MacosSpellChecker() {
		[spellChecker release];
	}

private:
	bool SetLanguage(const std::string& languageCode) {
		NSString* nsLanguageCode = [NSString stringWithUTF8String:languageCode.c_str()];
		return [spellChecker setLanguage:nsLanguageCode];
	}
};

std::vector<std::string> getSupportedLanguageList() {
	std::vector<std::string> result;

	auto spellChecker = [NSSpellChecker sharedSpellChecker];

	NSArray* languages = [spellChecker availableLanguages];

	for (size_t i = 0; i < languages.count; ++i) {
		result.push_back([[languages objectAtIndex:i] UTF8String]);
	}

	return result;
}

///////////////////////////////////////////////////////////////////////////////////////////
// N-API wrapper methods
///////////////////////////////////////////////////////////////////////////////////////////
Napi::Value createMacosSpellChecker(const Napi::CallbackInfo& info) {
	auto env = info.Env();

	auto language = info[0].As<Napi::String>().Utf8Value();

	auto macosSpellChecker = new MacosSpellChecker(language);

	// Handle error

	// Build JavaScript result object

	auto resultObject = Napi::Object().New(env);

	auto testSpelling = [macosSpellChecker](const Napi::CallbackInfo& info) {
		auto env = info.Env();

		auto wordString = info[0].As<Napi::String>().Utf8Value();

		auto result = macosSpellChecker->TestSpelling(wordString);

		return Napi::Boolean::New(env, result);
	};

	auto getSpellingSuggestions = [macosSpellChecker](const Napi::CallbackInfo& info) {
		auto env = info.Env();

		auto wordString = info[0].As<Napi::String>().Utf8Value();

		auto suggestions = macosSpellChecker->GetSpellingSuggestions(wordString);

		auto resultNapiArray = Napi::Array::New(env, suggestions.size());

		for (size_t i = 0; i < suggestions.size(); i++) {
			const std::string& suggestion = suggestions[i];

			auto suggestionNapiString = Napi::String::New(env, suggestion);

			resultNapiArray.Set(i, suggestionNapiString);
		}

		return resultNapiArray;
	};

	auto addWord = [macosSpellChecker](const Napi::CallbackInfo& info) {
		auto env = info.Env();

		auto wordString = info[0].As<Napi::String>().Utf8Value();

		macosSpellChecker->AddWord(wordString);

		return env.Undefined();
	};

	auto removeWord = [macosSpellChecker](const Napi::CallbackInfo& info) {
		auto env = info.Env();

		auto wordString = info[0].As<Napi::String>().Utf8Value();

		macosSpellChecker->RemoveWord(wordString);

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

Napi::Array getSupportedLanguages(const Napi::CallbackInfo& info) {
	auto env = info.Env();

	auto languageList = getSupportedLanguageList();

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
