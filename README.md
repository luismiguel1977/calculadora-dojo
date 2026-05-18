# Calculadora Oferta Dojo

Calculadora comercial para tarifas Dojo (1–3), cuota mínima, penalizaciones y propuesta imprimible al estilo PDF.

## URL en el móvil (importante)

**No uses** `luismiguel1977.github.io` solo (da error 404).

Abre esta dirección completa:

### https://luismiguel1977.github.io/calculadora-dojo/dojo-v2.1.html

## Si ves «There isn't a GitHub Pages site here»

Hay que activar Pages **una vez** en GitHub:

1. Abre: https://github.com/luismiguel1977/calculadora-dojo/settings/pages  
2. En **Build and deployment** → **Source**, elige **Deploy from a branch**  
3. **Branch:** `gh-pages` (si ya existe) o `main` · **Folder:** `/ (root)`  
4. Pulsa **Save** y espera 2–3 minutos  

Si no aparece la rama `gh-pages`, entra en **Actions** y ejecuta el workflow **Publicar GitHub Pages** (o haz un push a `main` y espera a que termine).

El repositorio debe ser **público** para Pages gratuito.

## Uso local

```powershell
.\servir.ps1
```

Luego: http://localhost:8080/dojo-v2.1.html

## Instalar como app (PWA)

Solo funciona con la URL **HTTPS** de arriba (no archivo local ni `http://192.168...`).

- **Android (Chrome):** menú ⋮ → Instalar aplicación  
- **iPhone (Safari):** Compartir → Añadir a pantalla de inicio  
