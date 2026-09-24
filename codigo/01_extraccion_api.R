# Autora: Xiomara Heydi Rivas Ames
# Código de matrícula: 2024200520M
# Tema N.º 34 del temario: Duración y convexidad de un bono soberano peruano: medición del riesgo de tasa
# Fecha de extracción: COMPLETAR (AAAA-MM-DD)

# ---------------------------------------------------------------------------
# 01_extraccion_api.R
# Vía API (numeral 2.4.1, Unidad I):
#   - BCRPData: rendimiento del bono del gobierno peruano a 10 años en soles (PD31895MM)
#   - FRED: curva del Tesoro de EE. UU. por plazo (GS1 ... GS30), mensual
# Guarda las respuestas JSON originales y los crudos en CSV y Excel, sin editar.
# Se ejecuta desde el proyecto de RStudio: todas las rutas son relativas.
# ---------------------------------------------------------------------------

library(httr)
library(jsonlite)
library(writexl)

# ---- 1. Parámetros congelados de la consulta (numeral 2.4.5) ---------------
FECHA_INICIO <- "2018-01-01"
FECHA_CORTE  <- "2025-12-31"
CODIGO       <- "2024200520M"

SERIE_BCRP  <- "PD31895MM"                           # rendimiento bono soberano 10 años, S/
SERIES_FRED <- c("GS1", "GS2", "GS3", "GS5", "GS7", "GS10", "GS20", "GS30")

USER_AGENT <- "UNCP-Finanzas-I proyecto academico (e_2024200520M@uncp.edu.pe)"

# ---- 2. Carpetas, log y clave de FRED --------------------------------------
dir.create("datos_crudos", showWarnings = FALSE)
LOG <- "log_ejecucion.txt"

if (file.exists(".env")) readRenviron(".env")        # la clave nunca va en el código
FRED_API_KEY <- Sys.getenv("FRED_API_KEY")
if (!nzchar(FRED_API_KEY)) stop("Falta FRED_API_KEY en el archivo .env (ver README).")

registrar <- function(fuente, filas, http, url) {
  linea <- sprintf("%s | %s | filas=%s | HTTP=%s | %s",
                   format(Sys.time(), "%Y-%m-%d %H:%M:%S"), fuente, filas, http, url)
  cat(linea, "\n", file = LOG, append = TRUE)
  message(linea)
}

# BCRPData pide los periodos mensuales como "2018-1"
periodo_bcrp <- function(fecha) {
  d <- as.Date(fecha)
  paste0(format(d, "%Y"), "-", as.integer(format(d, "%m")))
}

# ---- 3. Extracción BCRPData ---------------------------------------------------
url_bcrp <- sprintf("https://estadisticas.bcrp.gob.pe/estadisticas/series/api/%s/json/%s/%s/esp",
                    SERIE_BCRP, periodo_bcrp(FECHA_INICIO), periodo_bcrp(FECHA_CORTE))

resp <- tryCatch(GET(url_bcrp, user_agent(USER_AGENT), timeout(60)),
                 error = function(e) stop("Sin conexión con BCRPData: ", e$message))
if (status_code(resp) != 200) {
  registrar(paste("BCRP", SERIE_BCRP), 0, status_code(resp), url_bcrp)
  stop("BCRPData respondió con código ", status_code(resp))
}

texto <- content(resp, as = "text", encoding = "UTF-8")
writeLines(texto, file.path("datos_crudos", paste0("bcrp_", SERIE_BCRP, "_", CODIGO, ".json")),
           useBytes = TRUE)

js   <- fromJSON(texto)
bcrp <- data.frame(serie   = SERIE_BCRP,
                   periodo = js$periods$name,                         # ej. "Ene.2018"
                   valor   = sapply(js$periods$values, `[`, 1),       # texto, "n.d." incluido
                   stringsAsFactors = FALSE)

write.csv(bcrp, file.path("datos_crudos", paste0("datos_crudos_bcrp_", CODIGO, ".csv")),
          row.names = FALSE, fileEncoding = "UTF-8")
write_xlsx(bcrp, file.path("datos_crudos", paste0("datos_crudos_bcrp_", CODIGO, ".xlsx")))
registrar(paste("BCRP", SERIE_BCRP), nrow(bcrp), status_code(resp), url_bcrp)

# ---- 4. Extracción FRED (una consulta por plazo) ------------------------------
url_fred <- "https://api.stlouisfed.org/fred/series/observations"
lista <- list()

for (serie in SERIES_FRED) {
  Sys.sleep(1)                                         # pausa entre solicitudes
  resp <- tryCatch(GET(url_fred, user_agent(USER_AGENT), timeout(60),
                       query = list(series_id = serie, api_key = FRED_API_KEY,
                                    file_type = "json",
                                    observation_start = FECHA_INICIO,
                                    observation_end   = FECHA_CORTE)),
                   error = function(e) stop("Sin conexión con FRED: ", e$message))
  if (status_code(resp) != 200) {
    registrar(paste("FRED", serie), 0, status_code(resp), url_fred)
    stop("FRED respondió con código ", status_code(resp), " para ", serie)
  }

  texto <- content(resp, as = "text", encoding = "UTF-8")
  writeLines(texto, file.path("datos_crudos", paste0("fred_", serie, "_", CODIGO, ".json")),
             useBytes = TRUE)

  js <- fromJSON(texto)
  lista[[serie]] <- data.frame(serie = serie,
                               fecha = js$observations$date,
                               valor = js$observations$value,          # "." = sin dato
                               stringsAsFactors = FALSE)
  registrar(paste("FRED", serie), nrow(lista[[serie]]), status_code(resp), url_fred)  # sin la clave
}

fred <- do.call(rbind, lista)
write.csv(fred, file.path("datos_crudos", paste0("datos_crudos_fred_", CODIGO, ".csv")),
          row.names = FALSE, fileEncoding = "UTF-8")
write_xlsx(fred, file.path("datos_crudos", paste0("datos_crudos_fred_", CODIGO, ".xlsx")))

message("Extracción terminada: ", FECHA_INICIO, " a ", FECHA_CORTE)
