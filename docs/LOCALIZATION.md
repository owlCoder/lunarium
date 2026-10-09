# Localization

Lunarium currently ships English (`en`) and Serbian Latin (`sr-Latn`) translations. Strings are in `Lunarium/Resources/<locale>.lproj/Localizable.strings`. English is the source language.

1. Copy the English keys into a new locale folder.
2. Translate values without changing keys or placeholders.
3. Check long labels, VoiceOver, small screens and Shortcut Recorder focus.
4. Test the app with `-AppleLanguages '(sr-Latn)'` in the Run scheme arguments.
5. Keep strings UTF-8, and avoid including user screenshot content in reports.

Contributions to additional locales are welcome.
