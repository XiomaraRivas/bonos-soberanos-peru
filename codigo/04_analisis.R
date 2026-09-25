# Autora: Xiomara Heydi Rivas Ames
# Código de matrícula: 2024200520M
# Tema N.º 34 del temario: Duración y convexidad de un bono soberano peruano: medición del riesgo de tasa
# Fecha de extracción: 2026-09-24

# ---------------------------------------------------------------------------
# 04_analisis.R
# Genera en /salidas todas las tablas y figuras del artículo, a partir de
# datos_procesados. Sin aleatoriedad (no requiere semilla).
#   Tabla 1  Estadísticos descriptivos
#   Tabla 2  Métricas de riesgo de cada bono a la fecha de corte
#   Tabla 3  Shocks de ±50, ±100 y ±200 pb: exacto vs duración vs duración+convexidad
#   Tabla 4  Traspaso de tasas EE. UU. -> Perú (regresión) y escenarios de estrés
#   Figura 1 Rendimiento soberano peruano vs. Tesoro EE. UU. y spread
#   Figura 2 Duración modificada de los bonos en el tiempo
#   Figura 3 Relación precio-rendimiento: el efecto de la convexidad
# ---------------------------------------------------------------------------

library(writexl)
source("codigo/funciones_bonos.R")

CODIGO <- "2024200520M"
SHOCKS <- c(-200, -100, -50, 50, 100, 200)             # puntos básicos
dir.create("salidas", showWarnings = FALSE)

panel <- read.csv(paste0("datos_procesados/datos_procesados_", CODIGO, ".csv"))
panel$fecha <- as.Date(panel$fecha)
panel$fecha_vencimiento <- as.Date(panel$fecha_vencimiento)
curva <- read.csv(paste0("datos_procesados/curva_diaria_", CODIGO, ".csv"))
curva$fecha <- as.Date(curva$fecha)

guardar_tabla <- function(df, nombre) {
  write.csv(df, file.path("salidas", paste0(nombre, ".csv")), row.names = FALSE)
  write_xlsx(df, file.path("salidas", paste0(nombre, ".xlsx")))
}

# ---- Tabla 1: descriptivos ------------------------------------------------------
vars <- c("plazo_residual", "ytm", "precio", "dur_mod", "convexidad",
          "rend_pe_10a", "rend_ust_plazo", "spread_pb")
t1 <- data.frame(variable = vars,
                 n      = sapply(panel[vars], function(x) sum(!is.na(x))),
                 media  = sapply(panel[vars], mean, na.rm = TRUE),
                 desv   = sapply(panel[vars], sd,   na.rm = TRUE),
                 minimo = sapply(panel[vars], min,  na.rm = TRUE),
                 maximo = sapply(panel[vars], max,  na.rm = TRUE))
t1[, -1] <- round(t1[, -1], 3)
guardar_tabla(t1, "tabla1_descriptivos")

# ---- Tabla 2: métricas a la fecha de corte --------------------------------------
corte <- panel[panel$fecha == max(panel$fecha), ]
t2 <- corte[, c("instrumento", "cupon", "plazo_residual", "ytm", "precio", "dur_mod", "convexidad")]
guardar_tabla(t2, "tabla2_metricas_fecha_corte")

# ---- Tabla 3: shocks deterministas -----------------------------------------------
# Aproximación de Taylor: dP/P ≈ -Dmod·Δy + ½·Conv·Δy²
t3 <- list()
for (k in seq_len(nrow(corte))) {
  b <- corte[k, ]
  f <- flujos_bono(b$fecha, b$fecha_vencimiento, b$cupon)
  for (s in SHOCKS) {
    dy      <- s / 10000
    exacto  <- 100 * (precio_con_shock(b$ytm, f$t, f$cf, s) / b$precio - 1)
    solo_d  <- 100 * (-b$dur_mod * dy)
    d_conv  <- 100 * (-b$dur_mod * dy + 0.5 * b$convexidad * dy^2)
    t3[[length(t3) + 1]] <- data.frame(
      instrumento = b$instrumento, shock_pb = s,
      var_exacta_pct = exacto, aprox_duracion_pct = solo_d, aprox_dur_conv_pct = d_conv,
      error_duracion_pb = 100 * (solo_d - exacto), error_dur_conv_pb = 100 * (d_conv - exacto))
  }
}
t3 <- do.call(rbind, t3)
t3[, -(1:2)] <- round(t3[, -(1:2)], 4)
guardar_tabla(t3, "tabla3_shocks_de_tasa")

# ---- Tabla 4: traspaso EE. UU. -> Perú y escenarios de estrés ------------------
# Regresión en primeras diferencias diarias: Δy_PE = α + β·Δy_US + ε
curva <- curva[order(curva$fecha), ]
d_pe <- diff(curva$rend_pe_10a)
d_us <- diff(curva$DGS10)
modelo <- lm(d_pe ~ d_us)
coefs  <- summary(modelo)$coefficients
beta   <- coefs["d_us", "Estimate"]

t4a <- data.frame(parametro = c("alfa", "beta"), estimado = coefs[, 1], error_est = coefs[, 2],
                  t = coefs[, 3], p_valor = coefs[, 4],
                  r2 = summary(modelo)$r.squared, n = length(d_pe))
t4a[, -1] <- round(t4a[, -1], 4)
guardar_tabla(t4a, "tabla4a_regresion_traspaso")

# Escenarios: (i) histórico = mayor alza diaria observada del rendimiento peruano
#             (ii) importado = alza de 100 pb en el Tesoro de EE. UU. × β
escenarios <- c(historico = max(d_pe, na.rm = TRUE) * 100, importado_100pb = beta * 100)
t4b <- list()
for (e in names(escenarios)) {
  for (k in seq_len(nrow(corte))) {
    b <- corte[k, ]
    f <- flujos_bono(b$fecha, b$fecha_vencimiento, b$cupon)
    t4b[[length(t4b) + 1]] <- data.frame(
      escenario = e, shock_pb = round(escenarios[[e]], 2), instrumento = b$instrumento,
      var_precio_pct = round(100 * (precio_con_shock(b$ytm, f$t, f$cf, escenarios[[e]]) /
                                      b$precio - 1), 4))
  }
}
guardar_tabla(do.call(rbind, t4b), "tabla4b_escenarios_estres")

# ---- Figura 1: rendimientos y spread --------------------------------------------
png("salidas/figura1_rendimientos_spread.png", width = 1600, height = 1000, res = 160)
par(mfrow = c(2, 1), mar = c(3, 4.5, 2, 1))
plot(curva$fecha, curva$rend_pe_10a, type = "l", lwd = 1.5, col = "firebrick",
     ylim = range(c(curva$rend_pe_10a, curva$DGS10), na.rm = TRUE),
     xlab = "", ylab = "Rendimiento (%)", main = "Bono soberano a 10 años")
lines(curva$fecha, curva$DGS10, lwd = 1.5, col = "navy")
legend("topleft", c("Perú (S/)", "EE. UU."), col = c("firebrick", "navy"), lwd = 2, bty = "n")
plot(curva$fecha, curva$spread_pb, type = "l", lwd = 1.5, col = "darkgreen",
     xlab = "", ylab = "Puntos básicos", main = "Spread Perú - EE. UU.")
dev.off()

# ---- Figura 2: duración modificada por bono ---------------------------------------
png("salidas/figura2_duracion_modificada.png", width = 1600, height = 900, res = 160)
bonos   <- unique(panel$instrumento)
colores <- c("firebrick", "darkorange", "darkgreen", "navy", "purple")
plot(NA, xlim = range(panel$fecha), ylim = range(panel$dur_mod),
     xlab = "", ylab = "Duración modificada (años)", main = "Duración modificada por bono")
for (k in seq_along(bonos)) {
  s <- panel[panel$instrumento == bonos[k], ]
  lines(s$fecha, s$dur_mod, lwd = 2, col = colores[k])
}
legend("topright", bonos, col = colores, lwd = 2, bty = "n")
dev.off()

# ---- Figura 3: precio-rendimiento del bono más largo a la fecha de corte ---------
b <- corte[which.max(corte$plazo_residual), ]
f <- flujos_bono(b$fecha, b$fecha_vencimiento, b$cupon)
dy_pb <- seq(-300, 300, by = 10)
exacto <- sapply(dy_pb, function(s) precio_con_shock(b$ytm, f$t, f$cf, s))
dy     <- dy_pb / 10000
aprox_d  <- b$precio * (1 - b$dur_mod * dy)
aprox_dc <- b$precio * (1 - b$dur_mod * dy + 0.5 * b$convexidad * dy^2)

png("salidas/figura3_precio_rendimiento.png", width = 1600, height = 900, res = 160)
plot(b$ytm + dy_pb / 100, exacto, type = "l", lwd = 3, col = "black",
     xlab = "Rendimiento al vencimiento (%)", ylab = "Precio",
     main = paste("Relación precio-rendimiento,", b$instrumento))
lines(b$ytm + dy_pb / 100, aprox_d,  lwd = 2, lty = 2, col = "firebrick")
lines(b$ytm + dy_pb / 100, aprox_dc, lwd = 2, lty = 3, col = "navy")
legend("topright", c("Precio exacto", "Aprox. duración", "Aprox. duración + convexidad"),
       col = c("black", "firebrick", "navy"), lwd = c(3, 2, 2), lty = c(1, 2, 3), bty = "n")
dev.off()

message("Análisis terminado: tablas y figuras en /salidas")
