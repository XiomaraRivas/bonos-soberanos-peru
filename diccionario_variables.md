# Diccionario de variables — datos_procesados_2024200520M.csv

| Variable | Definición | Unidad | Frecuencia | Fuente | Endpoint / origen |
|---|---|---|---|---|---|
| fecha | Día de observación (días hábiles comunes a Perú y EE. UU.) | fecha | diaria | — | llave |
| instrumento | Bono soberano nominal en soles (SB2026 … SB2042) | texto | — | MEF (condiciones de emisión) | llave |
| cupon | Tasa cupón anual, pago semestral | % | fija | MEF | parámetro en 03_limpieza_datos.R |
| fecha_vencimiento | Fecha de vencimiento del bono | fecha | fija | MEF | parámetro en 03_limpieza_datos.R |
| plazo_residual | Años que faltan para el vencimiento | años | diaria | calculada | (vencimiento − fecha) / 365.25 |
| rend_pe_10a | Rendimiento del bono del gobierno peruano a 10 años en soles | % | diaria | BCRPData, serie PD31893DD | https://estadisticas.bcrp.gob.pe/estadisticas/series/api/PD31893DD/json |
| rend_ust_plazo | Rendimiento del Tesoro de EE. UU. interpolado al plazo residual del bono | % | diaria | FRED, series DGS1, DGS2, DGS3, DGS5, DGS7, DGS10, DGS20, DGS30 | https://api.stlouisfed.org/fred/series/observations |
| spread_pb | Spread soberano: rend_pe_10a − DGS10 | pb | diaria | calculada (BCRP y FRED) | 03_limpieza_datos.R |
| ytm | Rendimiento al vencimiento del bono: rend_ust_plazo + spread | % | diaria | calculada | 03_limpieza_datos.R |
| precio | Valor presente de los flujos descontados al ytm | por 100 de valor nominal | diaria | calculada | funciones_bonos.R |
| dur_mod | Duración modificada | años | diaria | calculada | funciones_bonos.R |
| convexidad | Convexidad | años² | diaria | calculada | funciones_bonos.R |
