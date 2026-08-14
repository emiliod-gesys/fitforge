# FitForge

App móvil de entrenamiento tipo **Fitbod** para Android e iOS, construida con **Flutter** y **Supabase**.

## Características

- **Autenticación** con email/contraseña, **Google** y **Apple**, y verificación **Cloudflare Turnstile**
- **Rutinas personalizadas** — crear, editar y ejecutar rutinas
- **Registro de entrenamientos** — series, reps, peso, RIR, temporizador de descanso
- **Biblioteca de ejercicios** — +200 ejercicios con imágenes y videos desde [wger.de](https://wger.de) (API pública, CC-BY-SA)
- **Progreso** — gráfico de peso corporal, records personales (1RM), volumen total
- **Mapa de recuperación muscular** — estimación de fatiga por grupo muscular
- **Coach IA** — recomendaciones con tu propia API key de **OpenAI** o **Gemini** (guardada de forma segura en el dispositivo)
- **Generación de rutinas con IA** — desde la pantalla de rutinas
- **Social** — amigos por email/nombre, ver perfiles y PRs, avisos cuando un amigo entrena
- **Notificaciones push** — avisos sociales con la app cerrada (FCM)

## Requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.16+
- Cuenta en [Supabase](https://supabase.com)
- (Opcional) API key de OpenAI o Google Gemini para el coach IA

## Configuración rápida

### 1. Clonar e instalar dependencias

```bash
cd fitforge
flutter create . --project-name fitforge --org io.fitforge
flutter pub get
```

### 2. Configurar Supabase

1. Crea un proyecto en [supabase.com](https://supabase.com)
2. En **SQL Editor**, ejecuta el contenido de `supabase/migrations/001_initial_schema.sql`
3. **Authentication → Providers → Email** → desactiva **Confirm email**
4. **Authentication → Bot and Abuse Protection** → activa CAPTCHA con **Cloudflare Turnstile** y pega la **Secret key**
5. Configurar **Google** y **Apple** — ver [Google Sign-In](#google-sign-in) y [Apple Sign-In](#apple-sign-in)
6. **Recuperación de contraseña (móvil)** — ver [Reset password](#reset-password) más abajo

### 2b. Configurar Cloudflare Turnstile

1. En [Cloudflare Dashboard](https://dash.cloudflare.com/) → **Turnstile** → **Add widget**
2. Modo recomendado: **Managed**
3. En dominios permitidos añade: `localhost` (desarrollo) y tu dominio si tienes
4. Copia el **Site key** (va en la app) y **Secret key** (solo en Supabase)
5. Añade en `dart_defines.json`:

```json
"TURNSTILE_SITE_KEY": "tu-site-key",
"TURNSTILE_BASE_URL": "http://localhost/"
```

`TURNSTILE_BASE_URL` debe coincidir con un dominio del widget de Turnstile.

### 3. Variables de entorno

Copia el ejemplo y rellena tus credenciales de Supabase:

```bash
copy dart_defines.json.example dart_defines.json
```

Ejecuta la app:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

> `dart_defines.json` está en `.gitignore` — no lo subas a git.

### 3b. Notificaciones push (FCM)

Para avisos cuando un amigo entrena **con la app cerrada**:

#### Firebase

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com)
2. Añade app **Android** (`io.fitforge.fitforge`) e **iOS** (`io.fitforge.fitforge`)
3. En **Configuración del proyecto → Cuentas de servicio**, genera una clave JSON (Admin SDK)
4. Copia en `dart_defines.json` los valores de cada app:
   - `FIREBASE_API_KEY`
   - `FIREBASE_APP_ID`
   - `FIREBASE_MESSAGING_SENDER_ID`
   - `FIREBASE_PROJECT_ID`
5. **iOS:** en Xcode → Runner → Signing & Capabilities → **Push Notifications**; sube la clave APNs a Firebase

#### Supabase

1. Ejecuta `supabase/migrations/004_push_tokens.sql` en el SQL Editor
2. Despliega la Edge Function:
   ```bash
   supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account",...}'
   supabase secrets set WEBHOOK_SECRET='un-secreto-largo-aleatorio'
   supabase functions deploy send-social-push --no-verify-jwt
   ```
3. En **Database → Webhooks → Create hook**:
   - Tabla: `social_notifications`
   - Evento: `INSERT`
   - URL: `https://TU_PROYECTO.supabase.co/functions/v1/send-social-push`
   - Header: `Authorization: Bearer tu-webhook-secret`

Sin las variables `FIREBASE_*` la app funciona igual; solo se desactivan los push nativos.

### Google Sign-In

1. **Google Cloud Console** (mismo proyecto que Firebase `fitforge-76fa2`):
   - **APIs & Services → Credentials → Create credentials → OAuth client ID**
   - Crea un cliente **Web** → copia el Client ID → `GOOGLE_WEB_CLIENT_ID` en `dart_defines.json`
   - Crea un cliente **Android** (`io.fitforge.fitforge`) con el SHA-1 de debug/release
   - Crea un cliente **iOS** (`io.fitforge.app`) → `GOOGLE_IOS_CLIENT_ID` en `dart_defines.json`
2. **Supabase → Authentication → Providers → Google**: activa y pega el **Web Client ID** y **Client Secret**
3. **Supabase → Authentication → URL Configuration → Additional Redirect URLs**:
   `io.fitforge.fitforge://login-callback`
4. **iOS** (`ios/Runner/Info.plist`): añade también el URL scheme invertido de Google:
   `com.googleusercontent.apps.TU_CLIENT_ID_SIN_SUFFIX` (ver consola de Google)
5. Ejecuta `supabase/migrations/016_oauth_profile_metadata.sql` si aún no está aplicada

Sin `GOOGLE_WEB_CLIENT_ID` el botón usa OAuth en navegador (deep link). Con el Web Client ID usa el selector nativo de Google (recomendado).

El SHA-1 de debug actual (para el cliente Android en Google Cloud) es:
`2A:29:7E:E5:4D:9C:0E:28:11:1A:59:E6:CF:9A:CD:14:48:3D:9B:C7`

### Apple Sign-In

1. **Apple Developer** → Identifiers → tu App ID (`io.fitforge.app`) → activa **Sign In with Apple**.
2. **Supabase → Authentication → Providers → Apple**:
   - Activa el proveedor.
   - iOS nativo: usa el **Services ID** / Bundle ID y la clave (`.p8`) de Sign in with Apple. Guía: [Auth Apple](https://supabase.com/docs/guides/auth/social-login/auth-apple).
3. **Supabase → Authentication → URL Configuration → Additional Redirect URLs**:
   - `io.fitforge.fitforge://login-callback`
   - `io.fitforge.app://login-callback`
4. En Xcode → Runner → Signing & Capabilities confirma **Sign In with Apple** (el repo ya incluye el entitlement).

En iOS el botón abre el sheet nativo de Apple. En Android abre OAuth en el navegador (hace falta el proveedor Apple activo en Supabase).

### Reset password

Para que el enlace del email abra la app y permita elegir contraseña nueva:

1. **Supabase → Authentication → URL Configuration → Additional Redirect URLs**, añade:
   - `io.fitforge.fitforge://login-callback`
   - `io.fitforge.fitforge://reset-password`
2. (Opcional) **Authentication → Email Templates → Reset password**: personaliza asunto y cuerpo HTML. El enlace debe seguir usando `{{ .ConfirmationURL }}` (Supabase lo reemplaza automáticamente).
3. En el móvil, al pulsar el enlace del correo se abre FitForge en la pantalla **Nueva contraseña**.

Si el enlace abre el navegador y no la app, revisa que las redirect URLs estén en Supabase y que hayas reinstalado la app tras cambiar el `AndroidManifest` / `Info.plist`.

### 4. API Keys de IA

1. Abre la app → **Perfil** → **API Keys**
2. Elige OpenAI o Gemini
3. Pega tu API key (se guarda en almacenamiento seguro del dispositivo, nunca en Supabase)

## Estructura del proyecto

```
lib/
├── core/           # Tema, router, constantes
├── models/         # Exercise, Routine, Workout, Profile
├── services/       # Supabase, Auth, wger API, AI Coach
├── providers/      # Riverpod providers
├── screens/        # Pantallas de la app
└── widgets/        # Componentes reutilizables
supabase/
└── migrations/     # Schema SQL con RLS
```

## Ejercicios e imágenes

Los ejercicios se obtienen de la API pública de **wger** (`wger.de/api/v2`):
- Imágenes: endpoint `exerciseimage`
- Videos: endpoint `video`
- Licencia: CC-BY-SA 3.0

## Build para producción

```bash
# Android
flutter build apk --dart-define-from-file=dart_defines.json

# iOS
flutter build ios --dart-define-from-file=dart_defines.json
```

## Próximos pasos sugeridos

- Modo offline con caché local (Hive/Isar)
- Integración con wearables
- Planes de nutrición

## Licencia

Código del proyecto: MIT. Datos de ejercicios de wger: CC-BY-SA 3.0.
