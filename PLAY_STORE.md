# Google Play Store – MedCode submission checklist

Use this checklist to publish MedCode on the Google Play Store.

---

## 1. Developer account

- [ ] Create / sign in to [Google Play Console](https://play.google.com/console)
- [ ] Pay the one-time **$25** registration fee (if new)
- [ ] Complete identity verification

---

## 2. App signing (release build)

Your app is already set up to use a release keystore via `android/key.properties` (you have this file).

- [ ] Build the **App Bundle** (AAB) for upload:

  ```bash
  flutter build appbundle
  ```

  Output: `build/app/outputs/bundle/release/app-release.aab`

---

## 3. Store listing

In Play Console → Your app → **Main store listing**:

| Field | Suggestion |
|-------|------------|
| **App name** | MedCode |
| **Short description** (max 80 chars) | Medical codes reference and management for healthcare professionals. |
| **Full description** (max 4000 chars) | Describe search, code details, favorites, offline use, and that it’s for professionals. |
| **App category** | **Medical** → **Medical reference and education** |
| **Tags** (optional) | medical codes, ICD, reference, healthcare |

---

## 4. Graphics and media

- [ ] **App icon**: 512×512 px (you have `assets/icons/logo.png`; ensure it meets [Play icon guidelines](https://support.google.com/googleplay/android-developer/answer/9866151))
- [ ] **Feature graphic**: 1024×500 px (required)
- [ ] **Phone screenshots**: At least 2, up to 8 (min 320px short side, max 3840px long side)
- [ ] Optional: 7-inch and 10-inch tablet screenshots if you target tablets

---

## 5. Content rating

- [ ] In Play Console go to **Policy** → **App content** → **Content rating**
- [ ] Complete the questionnaire (medical/reference app; no ads/gambling/social etc. if not applicable)
- [ ] Submit and download the rating certificate

---

## 6. Privacy and permissions

- [ ] **Privacy policy**: Required if you collect any user data (account, email, usage). Host a URL and add it in **App content** → **Privacy policy**.
- [ ] **Data safety**: In **App content** → **Data safety**, declare what data you collect and how it’s used.
- [ ] **MANAGE_EXTERNAL_STORAGE**: Your app requests this. Play has strict [policy](https://support.google.com/googleplay/android-developer/answer/10467936) for “All files access”. Either:
  - Justify it in the declaration (e.g. file import/export for medical codes), or
  - Prefer scoped storage / SAF for Android 11+ to avoid policy risk.

---

## 7. Target audience and ads

- [ ] Set **Target audience** (e.g. 18+ or “Not for children” if for professionals only).
- [ ] If you don’t use ads, say “No” in the ads section.

---

## 8. Release

- [ ] Create a **Release** → **Production** (or **Testing** first).
- [ ] Upload `app-release.aab`.
- [ ] Set **Release name** (e.g. “1.0.2 (3)” to match `pubspec.yaml`).
- [ ] Add **Release notes** for users.
- [ ] Review and roll out.

---

## 9. Version updates

In `pubspec.yaml` you have:

```yaml
version: 1.0.2+3   # 1.0.2 = versionName, 3 = versionCode
```

- For each new store upload, **increase** the number after `+` (e.g. `1.0.2+4`).
- Optionally increase the semantic part (e.g. `1.0.3+4`) for visible version.

---

## Quick build and test

```bash
# Install Flutter dependencies
flutter pub get

# Build release AAB for Play Store
flutter build appbundle

# Optional: test release APK locally
flutter build apk
```

---

## Summary

1. **Account**: Play Console, pay and verify.
2. **Signing**: Create keystore, add `android/key.properties`, build with `flutter build appbundle`.
3. **Listing**: Name, short/full description, category **Medical → Medical reference and education**.
4. **Assets**: 512×512 icon, 1024×500 feature graphic, 2+ phone screenshots.
5. **Policy**: Content rating, privacy policy (if you collect data), Data safety, and MANAGE_EXTERNAL_STORAGE justification or scoped storage.
6. **Release**: Upload AAB, set audience and release notes, then roll out.
