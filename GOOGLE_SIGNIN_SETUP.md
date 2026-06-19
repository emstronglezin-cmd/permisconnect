# Configuration Google Sign-In — PermisConnect

## Étapes à faire par le développeur

### 1. Google Cloud Console

1. Aller sur https://console.cloud.google.com/
2. Sélectionner votre projet (ou en créer un nouveau "PermisConnect")
3. **APIs & Services** → **Credentials**
4. **+ CREATE CREDENTIALS** → **OAuth 2.0 Client ID**

#### Créer le Web Client ID (obligatoire pour Supabase)
- Application type: **Web application**
- Name: PermisConnect Web
- Authorized redirect URIs: `https://hruisploxlmhigbsnzbn.supabase.co/auth/v1/callback`
- → Copier le **Client ID** et le **Client Secret**

#### Créer l'Android Client ID (pour google_sign_in natif)
- Application type: **Android**
- Package name: `com.permisconnect.driving`
- SHA-1 fingerprint: récupérer avec `keytool -keystore release-key.jks -list -v`

### 2. Supabase Dashboard

1. https://supabase.com/dashboard/project/hruisploxlmhigbsnzbn
2. **Authentication** → **Providers** → **Google**
3. Activer Google
4. Coller le **Client ID** (Web) et **Client Secret**
5. Redirect URL: `https://hruisploxlmhigbsnzbn.supabase.co/auth/v1/callback`
6. Sauvegarder

### 3. Fichiers Flutter à mettre à jour

#### `lib/core/services/google_auth_service.dart`
```dart
const String kGoogleWebClientId =
    'VOTRE_VRAI_CLIENT_ID.apps.googleusercontent.com';
// Remplacer par votre vrai Web Client ID
```

#### `android/app/src/main/res/values/strings.xml`
```xml
<string name="default_web_client_id">VOTRE_VRAI_CLIENT_ID.apps.googleusercontent.com</string>
```

### 4. Test

Après configuration :
```bash
flutter run
# Tester "Continuer avec Google" sur Login et Register
```

## Architecture technique

```
Flutter App
    ↓
GoogleAuthService.signIn()
    ↓ (google_sign_in package)
Google SDK → Compte Google sélectionné
    ↓ idToken + accessToken
Supabase.auth.signInWithIdToken(provider: google, idToken: ...)
    ↓
Session Supabase créée
    ↓
Trigger PostgreSQL handle_new_user() → profil créé automatiquement
    ↓
Navigation vers /student/home
```

## Fichiers modifiés

| Fichier | Modification |
|---------|-------------|
| `lib/core/services/google_auth_service.dart` | Nouveau — service Google Sign-In |
| `lib/presentation/providers/auth_provider.dart` | Ajout `signInWithGoogle()` |
| `lib/presentation/screens/auth/login_screen.dart` | Bouton Google + gestion erreurs réelles |
| `lib/presentation/screens/auth/register_screen.dart` | Bouton Google + gestion erreurs réelles |
| `lib/presentation/widgets/google_sign_in_button.dart` | Nouveau — widget bouton Google |
| `android/app/src/main/AndroidManifest.xml` | Deep link OAuth callback |
| `android/app/src/main/res/values/strings.xml` | Nouveau — Client ID placeholder |
