package gt.supermercado.pos.facturacion.dominio;

/** Respuesta del certificador al anular una factura (HU-08.10). */
public record ResultadoAnulacion(boolean aceptada, String codigoError, String mensajeError) {}
