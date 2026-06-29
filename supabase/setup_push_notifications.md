# Configurar push sociales (FitForge)

## Estado automático (ya hecho)

- Edge Function `send-social-push` desplegada en el proyecto `cpxpqklbmiwguvuwifpd`
- Trigger en Postgres: cada `INSERT` en `social_notifications` llama a la función
- Secreto de webhook guardado en Vault (`social_push_webhook_secret`)

## Paso manual (solo si usas secretos por Dashboard)

Los secretos ya pueden vivir en **Supabase Vault** (`firebase_service_account` + `social_push_webhook_secret`).
La Edge Function `send-social-push` los lee automáticamente con `service_role`.

Si prefieres variables de entorno en lugar de Vault, añade en **Edge Functions → Secrets**:

| Nombre | Valor |
|--------|--------|
| `WEBHOOK_SECRET` | Mismo valor que `social_push_webhook_secret` en Vault |
| `FIREBASE_SERVICE_ACCOUNT` | JSON completo de la cuenta de servicio Firebase |

### 3. Probar

1. Rebuild de la app con `dart_defines.json` (Firebase ya configurado)
2. Inicia sesión en **dos cuentas** que sean amigos
3. En el dispositivo A: acepta permiso de notificaciones
4. En el dispositivo B: completa un entrenamiento
5. El dispositivo A debería recibir push aunque la app esté cerrada

### Verificar tokens registrados

```sql
SELECT user_id, platform, left(token, 20) AS token_prefix, updated_at
FROM public.user_push_tokens
ORDER BY updated_at DESC;
```

### Verificar llamadas del trigger

```sql
SELECT id, status_code, created
FROM net._http_response
ORDER BY created DESC
LIMIT 10;
```

Si `status_code` es 401 → `WEBHOOK_SECRET` no coincide con Vault.  
Si es 500 con `Missing FIREBASE_SERVICE_ACCOUNT` → falta el secreto de Firebase.
