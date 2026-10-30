package gt.supermercado.pos.facturacion.dominio;

import java.time.OffsetDateTime;
import java.util.UUID;

/** Respuesta del certificador al certificar un DTE (HU-08.03, 08.06). */
public record ResultadoCertificacion(
        boolean certificada,
        UUID autorizacion,
        String serie,
        String numero,
        OffsetDateTime fechaCertificacion,
        String codigoError,
        String mensajeError) {

    public static ResultadoCertificacion aceptada(UUID autorizacion, String serie, String numero,
                                                  OffsetDateTime fechaCertificacion) {
        return new ResultadoCertificacion(true, autorizacion, serie, numero, fechaCertificacion, null, null);
    }

    public static ResultadoCertificacion rechazada(String codigoError, String mensajeError) {
        return new ResultadoCertificacion(false, null, null, null, null, codigoError, mensajeError);
    }
}
