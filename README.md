# Calculadora Oferta Dojo

Calculadora comercial para tarifas Dojo (Go / Pocket), cuota mínima, comparativa con competencia y propuesta imprimible.

## Estructura del proyecto

| Carpeta / archivo | Uso |
|-------------------|-----|
| `www/index.html` | Fuente web (Capacitor / APK) |
| `dojo-v2.1.html` | Misma app para GitHub Pages |
| `apk/calculadora-dojo.apk` | App Android instalable |
| `capacitor.config.json` | Config de la app (`com.dojo.calculadora`) |
| `manifest.webmanifest`, `sw.js`, `icons/` | PWA en navegador |

## App Android (APK)

Descarga e instala:

**[apk/calculadora-dojo.apk](apk/calculadora-dojo.apk)**

En el móvil: ajustes → permitir instalar apps de esta fuente si Android lo pide.

## Web y GitHub Pages (PWA)

**Calculadora:** https://luismiguel1977.github.io/calculadora-dojo/dojo-v2.1.html

**APK Android:** https://luismiguel1977.github.io/calculadora-dojo/apk/calculadora-dojo.apk

### Instalar en iPhone (PWA)

1. Abre el enlace en **Safari** (no en Chrome).
2. Pulsa el botón **Compartir** (cuadrado con flecha hacia arriba).
3. Elige **Añadir a pantalla de inicio**.
4. Confirma con **Añadir**.

La app quedará como un icono en el iPhone, a pantalla completa, sin App Store.

Activar Pages (si no carga): [Settings → Pages](https://github.com/luismiguel1977/calculadora-dojo/settings/pages) → **Deploy from a branch** → `gh-pages` → `/ (root)`.

## Desarrollo local

```powershell
.\servir.ps1
```

Abre http://localhost:8080/dojo-v2.1.html

## Sincronizar tras editar `www/`

```powershell
Copy-Item www\index.html dojo-v2.1.html
```

## Novedades v2.1 (APK)

- Bloque **tarifa más barata** con comparativa T1/T2/T3
- Competencia: alquiler terminal y cargo fijo por operación (en lugar de % tickets)
- Mejoras en impresión PDF y maquetación de formulario
