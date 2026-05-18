# Calculadora Oferta Dojo

Calculadora comercial para tarifas Dojo (1–3), cuota mínima, penalizaciones y propuesta imprimible al estilo PDF.

## Uso

Abre [`dojo-v2.1.html`](dojo-v2.1.html) en un navegador. Para instalarla como app (PWA) en el móvil, sirve la carpeta por **HTTPS** (no como archivo local).

```powershell
.\servir.ps1
```

Luego: `http://localhost:8080/dojo-v2.1.html`

## Archivos

| Archivo | Descripción |
|---------|-------------|
| `dojo-v2.1.html` | Calculadora principal |
| `manifest.webmanifest` | Manifest PWA |
| `sw.js` | Service worker |
| `icons/` | Iconos de la app |

## GitHub Pages

Si activas Pages en este repo (rama `main`, carpeta raíz `/`), la app quedará en:

`https://<usuario>.github.io/<repo>/dojo-v2.1.html`
