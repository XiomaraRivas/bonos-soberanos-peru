# Duración y convexidad de un bono soberano peruano: medición del riesgo de tasa

- **Autora:** Xiomara Heydi Rivas Ames
- **Código de matrícula:** 2024200520M
- **Tema del temario:** N.º 34 — S05 Valuación de bonos (Unidad I)
- **Repositorio:** https://github.com/XiomaraRivas/bonos-soberanos-peru

## Fuentes y endpoints (vía API)
| Fuente | Series | Endpoint | Clave |
|---|---|---|---|
| BCRPData | PD31893DD (rendimiento bono soberano 10 años, S/) | https://estadisticas.bcrp.gob.pe/estadisticas/series/api/{serie}/json/{inicio}/{fin}/esp | No |
| FRED | DGS1, DGS2, DGS3, DGS5, DGS7, DGS10, DGS20, DGS30 (curva del Tesoro de EE. UU.) | https://api.stlouisfed.org/fred/series/observations | Sí, gratuita |

**Clave de FRED:** crear una cuenta gratuita en https://fredaccount.stlouisfed.org/apikeys, copiar `.env.example` como `.env` y pegar la clave.

## Periodo congelado
`FECHA_INICIO = 2018-01-01` · `FECHA_CORTE = 2025-12-31` · frecuencia diaria · 5 bonos (≈ 10 000 observaciones) (llave: instrumento + fecha).

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
`689edf668c3efef94c9011c07785e9ad5dcbb24dc92633db1c8e0b23f7e17a38`
