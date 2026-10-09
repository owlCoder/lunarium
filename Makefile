SHELL := /bin/bash
.PHONY: icons project build clean

icons:
	@swift scripts/generate-icon.swift

project: icons
	@command -v xcodegen >/dev/null || (echo "Install XcodeGen: brew install xcodegen" && exit 1)
	xcodegen generate

build: project
	xcodebuild -project Lunarium.xcodeproj -scheme Lunarium -configuration Debug -destination 'platform=macOS,arch=arm64' CODE_SIGNING_ALLOWED=NO build

clean:
	rm -rf Lunarium.xcodeproj
	rm -f Lunarium/Resources/Assets.xcassets/AppIcon.appiconset/icon-*.png

.PHONY: test ui-test

test: project
	xcodebuild test -project Lunarium.xcodeproj -scheme Lunarium -configuration Debug -destination 'platform=macOS,arch=arm64' -only-testing:LunariumTests CODE_SIGNING_ALLOWED=NO

ui-test: project
	xcodebuild test -project Lunarium.xcodeproj -scheme Lunarium -configuration Debug -destination 'platform=macOS,arch=arm64' -only-testing:LunariumUITests
