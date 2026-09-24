# Duración y convexidad de un bono soberano peruano: medición del riesgo de tasa

- **Autora:** Xiomara Heydi Rivas Ames
- **Código de matrícula:** 2024200520M
- **Tema del temario:** N.º 34 — S05 Valuación de bonos (Unidad I)
- **Repositorio:** https://github.com/USUARIO/REPOSITORIO

## Fuentes y endpoints (vía API)
| Fuente | Series | Endpoint | Clave |
|---|---|---|---|
| BCRPData | PD31895MM (rendimiento bono soberano 10 años, S/) | https://estadisticas.bcrp.gob.pe/estadisticas/series/api/{serie}/json/{inicio}/{fin}/esp | No |
| FRED | GS1, GS2, GS3, GS5, GS7, GS10, GS20, GS30 (curva del Tesoro de EE. UU.) | https://api.stlouisfed.org/fred/series/observations | Sí, gratuita |

**Clave de FRED:** crear una cuenta gratuita en https://fredaccount.stlouisfed.org/apikeys, copiar `.env.example` como `.env` y pegar la clave.

## Periodo congelado
`FECHA_INICIO = 2018-01-01` · `FECHA_CORTE = 2025-12-31` · frecuencia mensual · 5 bonos (llave: instrumento + fecha).

## Orden de ejecución (RStudio)
1. Abrir `bonos_soberanos.Rproj`.
2. `install.packages(c("httr", "jsonlite", "writexl", "digest"))`
3. `source("codigo/01_extraccion_api.R")`
4. `source("codigo/02_scraping_web.R")` (no aplica: Unidad I, vía única por API)
5. `source("codigo/03_limpieza_datos.R")`
6. `source("codigo/04_analisis.R")`

## Versiones
R y librerías: ver `sessionInfo.txt` (lo genera 03).

## Verificación
SHA-256 de `datos_procesados/datos_procesados_2024200520M.csv`:
`PEGAR_AQUI_EL_HASH_DEL_LOG`
