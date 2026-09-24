# Autora: Xiomara Heydi Rivas Ames
# Código de matrícula: 2024200520M
# Tema N.º 34 del temario: Duración y convexidad de un bono soberano peruano: medición del riesgo de tasa
# Fecha de extracción: COMPLETAR (AAAA-MM-DD)

# ---------------------------------------------------------------------------
# funciones_bonos.R
# Funciones de valuación usadas por 03_limpieza_datos.R y 04_analisis.R.
# Convención: cupón semestral (m = 2), valor nominal 100, tasas en porcentaje.
# ---------------------------------------------------------------------------

# Flujos pendientes de un bono en una fecha dada.
# Las fechas de cupón se generan cada 6 meses hacia atrás desde el vencimiento.
flujos_bono <- function(fecha, vencimiento, cupon) {
  fechas <- rev(seq(vencimiento, by = "-6 months", length.out = 120))
  fechas <- fechas[fechas > fecha]
  t  <- as.numeric(fechas - fecha) / 365.25          # tiempo a cada flujo, en años
  cf <- rep(cupon / 2, length(t))                     # cupón semestral
  cf[length(cf)] <- cf[length(cf)] + 100              # último flujo: cupón + principal
  list(t = t, cf = cf)
}

# Precio, duración de Macaulay, duración modificada y convexidad.
valorar_bono <- function(ytm_pct, t, cf, m = 2) {
  y    <- ytm_pct / 100
  desc <- (1 + y / m)^(-m * t)                        # factores de descuento
  P    <- sum(cf * desc)
  dmac <- sum(t * cf * desc) / P
  dmod <- dmac / (1 + y / m)
  conv <- sum(cf * t * (t + 1 / m) * desc) / (P * (1 + y / m)^2)
  c(precio = P, dur_mac = dmac, dur_mod = dmod, convexidad = conv)
}

# Precio exacto tras un shock de tasa (en puntos básicos).
precio_con_shock <- function(ytm_pct, t, cf, shock_pb) {
  valorar_bono(ytm_pct + shock_pb / 100, t, cf)[["precio"]]
}
