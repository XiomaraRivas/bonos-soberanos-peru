# Autora: Xiomara Heydi Rivas Ames
# Código de matrícula: 2024200520M
# Tema N.º 34 del temario: Duración y convexidad de un bono soberano peruano: medición del riesgo de tasa
# Fecha de extracción: 2026-09-24

# ---------------------------------------------------------------------------
# 03_limpieza_datos.R
# 1. Limpia los crudos diarios de BCRP y FRED y los une por la fecha (día).
#    Solo se conservan los días con dato en ambos mercados (Perú y EE. UU.).
# 2. Construye el rendimiento de cada bono a su plazo residual:
#      ytm = rendimiento del Tesoro EE. UU. a ese plazo (interpolado)
#            + spread soberano Perú - EE. UU. a 10 años
#    Supuesto declarado: el spread se traslada en paralelo a toda la curva.
# 3. Calcula precio, duración modificada y convexidad de cada bono cada mes.
# 4. Genera datos_procesados_<código>.csv (llave: instrumento + fecha),
#    su hash SHA-256 y sessionInfo.txt.
# ---------------------------------------------------------------------------

library(writexl)
library(digest)
source("codigo/funciones_bonos.R")

CODIGO <- "2024200520M"

# Bonos soberanos nominales en soles analizados (condiciones de emisión).
# VERIFICAR cupón y vencimiento en el Perú: Reporte Diario del MEF antes de la corrida final.
BONOS <- data.frame(
  instrumento = c("SB2026", "SB2028", "SB2032", "SB2037", "SB2042"),
  cupon       = c(8.20, 6.35, 6.15, 6.90, 6.85),
  vencimiento = as.Date(c("2026-08-12", "2028-08-12", "2032-08-12", "2037-08-12", "2042-02-12")),
  stringsAsFactors = FALSE
)

PLAZOS <- c(DGS1 = 1, DGS2 = 2, DGS3 = 3, DGS5 = 5, DGS7 = 7, DGS10 = 10, DGS20 = 20, DGS30 = 30)
MESES  <- c(Ene = 1, Feb = 2, Mar = 3, Abr = 4, May = 5, Jun = 6, Jul = 7,
            Ago = 8, Set = 9, Sep = 9, Oct = 10, Nov = 11, Dic = 12)

dir.create("datos_procesados", showWarnings = FALSE)
LOG <- "log_ejecucion.txt"

# ---- 1. BCRP: "02.Ene.18" -> 2018-01-02 ; "n.d." -> NA -------------------------
bcrp <- read.csv(paste0("datos_crudos/datos_crudos_bcrp_", CODIGO, ".csv"),
                 colClasses = "character", encoding = "UTF-8")
partes <- strsplit(bcrp$periodo, ".", fixed = TRUE)
pe <- data.frame(
  fecha       = as.Date(sapply(partes, function(p) sprintf("20%s-%02d-%s", p[3], MESES[p[2]], p[1]))),
  rend_pe_10a = suppressWarnings(as.numeric(bcrp$valor))
)

# ---- 2. FRED: formato largo -> ancho (una columna por plazo) ; "." -> NA -------
fred <- read.csv(paste0("datos_crudos/datos_crudos_fred_", CODIGO, ".csv"),
                 colClasses = "character", encoding = "UTF-8")
fred$fecha <- as.Date(fred$fecha)
fred$valor <- suppressWarnings(as.numeric(fred$valor))
curva <- reshape(fred, idvar = "fecha", timevar = "serie", direction = "wide")
names(curva) <- sub("valor.", "", names(curva), fixed = TRUE)

# ---- 3. Unión por fecha (días comunes) y control de faltantes y atípicos -----
curva <- merge(pe, curva, by = "fecha")
curva <- curva[order(curva$fecha), ]
n_ini <- nrow(curva)
curva <- curva[!is.na(curva$rend_pe_10a) & !is.na(curva$DGS10), ]
atipicos <- sum(curva$rend_pe_10a < 0 | curva$rend_pe_10a > 20)   # rango plausible
curva$spread_pb <- round((curva$rend_pe_10a - curva$DGS10) * 100, 2)

write.csv(curva, paste0("datos_procesados/curva_diaria_", CODIGO, ".csv"), row.names = FALSE)

# ---- 4. Panel instrumento + fecha: rendimiento, precio, duración, convexidad --
filas <- list()
for (i in seq_len(nrow(curva))) {
  fila   <- curva[i, ]
  ust    <- unlist(fila[names(PLAZOS)])
  validos <- !is.na(ust)

  for (j in seq_len(nrow(BONOS))) {
    b <- BONOS[j, ]
    plazo <- as.numeric(b$vencimiento - fila$fecha) / 365.25
    if (plazo <= 0) next

    ust_plazo <- approx(PLAZOS[validos], ust[validos], xout = plazo, rule = 2)$y
    ytm       <- ust_plazo + fila$spread_pb / 100
    f         <- flujos_bono(fila$fecha, b$vencimiento, b$cupon)
    v         <- valorar_bono(ytm, f$t, f$cf)

    filas[[length(filas) + 1]] <- data.frame(
      fecha = fila$fecha, instrumento = b$instrumento, cupon = b$cupon,
      fecha_vencimiento = b$vencimiento, plazo_residual = round(plazo, 4),
      rend_pe_10a = fila$rend_pe_10a, rend_ust_plazo = round(ust_plazo, 4),
      spread_pb = fila$spread_pb, ytm = round(ytm, 4),
      precio = round(v[["precio"]], 4), dur_mod = round(v[["dur_mod"]], 4),
      convexidad = round(v[["convexidad"]], 4)
    )
  }
}
panel <- do.call(rbind, filas)
panel <- panel[order(panel$instrumento, panel$fecha), ]

# ---- 5. Guardado, hash y registro ------------------------------------------------
salida <- paste0("datos_procesados/datos_procesados_", CODIGO, ".csv")
write.csv(panel, salida, row.names = FALSE, fileEncoding = "UTF-8")
write_xlsx(panel, paste0("datos_procesados/datos_procesados_", CODIGO, ".xlsx"))

hash <- digest(file = salida, algo = "sha256")
linea <- sprintf(paste("%s | LIMPIEZA | dias=%d (descartados %d por faltantes)",
                       "| atipicos=%d | filas panel=%d | bonos=%d | SHA-256=%s"),
                 format(Sys.time(), "%Y-%m-%d %H:%M:%S"), nrow(curva), n_ini - nrow(curva),
                 atipicos, nrow(panel), length(unique(panel$instrumento)), hash)
cat(linea, "\n", file = LOG, append = TRUE)
message(linea)

writeLines(capture.output(sessionInfo()), "sessionInfo.txt")   # versiones exactas
