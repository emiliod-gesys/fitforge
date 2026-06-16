# FitForge

App móvil de entrenamiento tipo **Fitbod** para Android e iOS, construida con **Flutter** y **Supabase**.

## Características

- **Autenticación** con email/contraseña y verificación **Cloudflare Turnstile** (sin confirmación por email)
- **Rutinas personalizadas** — crear, editar y ejecutar rutinas
- **Registro de entrenamientos** — series, reps, peso, RIR, temporizador de descanso
- **Biblioteca de ejercicios** — +200 ejercicios con imágenes y videos desde [wger.de](https://wger.de) (API pública, CC-BY-SA)
- **Progreso** — gráfico de peso corporal, records personales (1RM), volumen total
- **Mapa de recuperación muscular** — estimación de fatiga por grupo muscular
- **Coach IA** — recomendaciones con tu propia API key de **OpenAI** o **Gemini** (guardada de forma segura en el dispositivo)
- **Generación de rutinas con IA** — desde la pantalla de rutinas
- **Sincronización en la nube** — Supabase Postgres con Row Level Security

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
5. (Opcional, más adelante) Configurar Google OAuth en Authentication → Providers

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

- Notificaciones push para recordatorios de entrenamiento
- Modo offline con caché local (Hive/Isar)
- Apple Sign-In
- Integración con wearables
- Planes de nutrición

## Licencia

Código del proyecto: MIT. Datos de ejercicios de wger: CC-BY-SA 3.0.
