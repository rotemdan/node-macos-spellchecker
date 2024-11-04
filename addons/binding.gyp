{
	"targets": [
		{
			"conditions": [
				[
					"OS=='mac'",
					{
						"sources": ["src/MacosSpellChecker.mm"],
						"include_dirs": [
							"<!@(node -p \"require('node-addon-api').include\")"
						],
						"cflags!": ["-fno-exceptions"],
						"cflags_cc!": ["-fno-exceptions"],
						"xcode_settings": {
							"OTHER_CPLUSPLUSFLAGS": ["-x", "objective-c++"],
							"GCC_ENABLE_CPP_EXCEPTIONS": "YES",
						},
						"libraries": ["-framework", "Cocoa"],
						"conditions": [
							[
								"target_arch=='x64'",
								{
									"target_name": "macos-x64-spellchecker",
								},
							],
							[
								"target_arch=='arm64'",
								{
									"target_name": "macos-arm64-spellchecker",
								},
							],
						],						
					},
				]
			],
		}
	]
}
