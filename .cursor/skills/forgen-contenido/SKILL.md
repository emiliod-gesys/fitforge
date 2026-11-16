---
name: forgen-contenido
description: >-
  Produce piezas de redes y de tienda para FORGEN (historias 9:16, foto de feed
  4:5 y capturas de Play/App Store) usando solo pantallas reales, la paleta negra
  y cobalto, y los precios vigentes. Úsala cuando pidan una historia, un anuncio,
  un post de Instagram o TikTok, una foto de feed, un reel estático, copy de
  redes, o refrescar las capturas de la ficha de la tienda.
---

# Contenido FORGEN

Receta para piezas públicas de FORGEN. El producto ya está publicado. El nombre en toda pieza es **FORGEN**, nunca FitForge ni «la app».

Elige un formato y no mezcles:

| Pedido | Formato | Archivo |
|---|---|---|
| Historia, story, TikTok estático, anuncio vertical | 9:16 | [historias.md](historias.md) |
| Foto de feed, carrusel, spotlight de una función | 4:5 | [foto-feed.md](foto-feed.md) |
| Ficha de Play o App Store | tamaños de tienda | [tienda.md](tienda.md) |

No hay pipeline de video con voz. Si piden un reel animado, entrega la historia 9:16 o la foto 4:5 y dilo. No inventes un video.

## Marca

| Uso | Valor |
|---|---|
| Fondo | `#000000` |
| Tarjeta | `#1A1B1E` |
| Tarjeta elevada | `#242528` |
| Borde | `#2C2D31` |
| Texto | `#F4F3EF` |
| Texto secundario | `#9FA3A8` |
| Acento | `#4A9EFF` |
| Éxito | `#3DCF8E` |
| Tipo | Montserrat |

El cobalto es la línea gráfica. No uses dorado, ni el azul del logo `#305890`, como color de campaña. El texto que va sobre un botón cobalto es negro.

Español latinoamericano. Frases cortas. Una idea por pieza.

## Planes (texto permitido)

- Gratis.
- Gymrat: **$4.99 al mes**.
- Gymrat Pro: **$9.99 al mes**.
- El tachado $7.99 y $11.99 solo puede salir como precio de comparación, nunca como el precio que se cobra.
- No hay plan anual. No lo menciones.
- No hay prueba gratis de pago ni lista de espera.

Funciones de pago que sí existen: rutina inteligente y código de barras desde Gymrat; foto de comida, modo entrenador y acento personal desde Gymrat Pro. En el plan gratis la foto de comida y el Coach proactivo también se desbloquean si la persona pone su propia clave de IA. No prometas eso en un anuncio salvo que la pieza hable de esa opción.

## Pantallas reales

Solo estas capturas, dentro del teléfono o del recuadro de la app. No redibujes la interfaz con un modelo de imagen. Si generas un marco, compón el JPG real encima.

Teléfono (1080×1920), en `store/play_console/screenshots/`:

| Id | Archivo | Qué se puede decir |
|---|---|---|
| entrenar | `01-entrenar-1080x1920.jpg` | La rutina del día y el botón para empezarla |
| entrenando | `02-entrenando-1080x1920.jpg` | Series, peso y repeticiones durante el entrenamiento |
| coach | `03-coach-ia-1080x1920.jpg` | El Coach responde sobre el entrenamiento y la comida |
| nutricion | `04-nutricion-1080x1920.jpg` | Registrar lo que se comió |
| progreso | `05-progreso-1080x1920.jpg` | El avance y los récords quedan guardados |
| social | `06-social-1080x1920.jpg` | Amigos y lo que comparten al terminar |
| perfil | `07-perfil-1080x1920.jpg` | El plan y el perfil |

Tableta, mismo orden, en `store/play_console/screenshots-tablet/` con altura 2560. Icono: `store/play_console/icon-512.png`. Referencia de historia ya publicada: `store/FORGEN_story_ig.png`.

## Prohibido

- Inventar capturas, testimonios, cifras de usuarios, ratings o resultados («baja 5 kg»).
- Nombres de personas reales, comidas de alguien, o el Excel de calorías que está en `store/`.
- Pedir contraseñas, datos bancarios o acceso a la cuenta.
- Dorado como color principal, pesos en una moneda que no sea la de la pieza, o «Chapi» / otra marca.
- Marcar la pieza como publicada en Instagram o TikTok. Este repo no programa redes. Entrega el archivo y el texto para copiar.

## Entrega

Al terminar, di la ruta del archivo, el titular, el texto para pegar y qué captura usaste. Si no pudiste componer la imagen, entrega el texto y la captura exacta, y no sustituyas la pantalla por un dibujo.
