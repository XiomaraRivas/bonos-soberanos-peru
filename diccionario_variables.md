# Diccionario de variables — datos_procesados_2024200520M.csv

| Variable | Definición | Unidad | Frecuencia | Fuente | Endpoint / origen |
|---|---|---|---|---|---|
| fecha | Mes de observación (primer día del mes) | fecha | mensual | — | llave |
| instrumento | Bono soberano nominal en soles (SB2026 … SB2042) | texto | — | MEF (condiciones de emisión) | llave |
| cupon | Tasa cupón anual, pago semestral | % | fija | MEF | parámetro en 03_limpieza_datos.R |
| fecha_vencimiento | Fecha de vencimiento del bono | fecha | fija | MEF | parámetro en 03_limpieza_datos.R |
| plazo_residual | Años que faltan para el vencimiento | años | mensual | calculada | (vencimiento − fecha) / 365.25 |
| rend_pe_10a | Rendimiento del bono del gobierno peruano a 10 años en soles | % | mensual | BCRPData, serie PD31895MM | https://estadisticas.bcrp.gob.pe/estadisticas/series/api/PD31895MM/json |
| rend_ust_plazo | Rendimiento del Tesoro de EE. UU. interpolado al plazo residual del bono | % | mensual | FRED, series GS1, GS2, GS3, GS5, GS7, GS10, GS20, GS30 | https://api.stlouisfed.org/fred/series/observations |
| spread_pb | Spread soberano: rend_pe_10a − GS10 | pb | mensual | calculada (BCRP y FRED) | 03_limpieza_datos.R |
| ytm | Rendimiento al vencimiento del bono: rend_ust_plazo + spread | % | mensual | calculada | 03_limpieza_datos.R |
| precio | Valor presente de los flujos descontados al ytm | por 100 de valor nominal | mensual | calculada | funciones_bonos.R |
| dur_mod | Duración modificada | años | mensual | calculada | funciones_bonos.R |
| convexidad | Convexidad | años² | mensual | calculada | funciones_bonos.R |
