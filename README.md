# JollyMix Advent Challenge 2026

This source package is for a separate iPhone and iPad app. It bundles all 24 daily puzzles and the bonus cryptic crossword. It uses the device’s local date and saves play progress locally. The Swift host presents the iOS share sheet for puzzle results.

## Apple and Codemagic setup

1. In Certificates, Identifiers & Profiles, register the explicit App ID `uk.co.jollymix.adventchallenge2026`.
2. In App Store Connect, create an iOS app record with the name **JollyMix Advent Challenge 2026**, that Bundle ID, English (U.K.) and SKU `jollymix-advent-2026`.
3. Upload the contents of this package to the root of a dedicated source repository. Connect it in Codemagic, reuse the existing `bluffle_apple` integration, and make an App Store signing profile available for the new bundle ID.
4. Run **JollyMix Advent Challenge for iPhone and iPad**. The workflow generates the Xcode project, archives the signed IPA and uploads the build to App Store Connect. It leaves the App Review submission for you to send after testing.
5. Test the signed build on iPhone and iPad. Check first launch, rotation, zoom and foil tearing, typing, sound, reopened doors, progress after restarting, crossword, and result sharing.
6. Upload the terms, privacy and support pages to the existing JollyMix website once. Keep those URLs stable so website edits take effect in the app without a rebuild. Confirm support and privacy load before entering them in App Store Connect.
7. Use App-Store-Connect.md from the separate App Store materials ZIP, upload iPhone and iPad screenshots, choose the processed build, and submit it for review. Keep the listing as a standard Games app.

Run locally on a Mac with Xcode 26 and XcodeGen installed using `xcodegen generate`, then open `AdventChallenge.xcodeproj`. The screenshots in the App Store materials ZIP are browser-rendered previews at App Store dimensions. Cross-check them against the signed iPhone and iPad app before upload.

The share links currently point to the JollyMix Advent Challenge webpage. After Apple assigns the app a numeric ID, supply its App Store URL as JOLLYMIX_APP_STORE_URL when generating the iOS HTML to include a direct download link.
