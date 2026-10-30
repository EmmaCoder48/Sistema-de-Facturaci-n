package gt.supermercado.pos.facturacion.aplicacion;

import gt.supermercado.pos.facturacion.dominio.CertificadorNoDisponibleException;
import gt.supermercado.pos.facturacion.dominio.Contribuyente;
import gt.supermercado.pos.facturacion.dominio.ResultadoAnulacion;
import gt.supermercado.pos.facturacion.dominio.ResultadoCertificacion;

import java.util.Optional;
import java.util.UUID;

/**
 * Puerto hacia el certificador FEL (Architecture.md §7.2). Hay un adaptador simulado para desarrollo
 * y pruebas; el adaptador REST del certificador contratado se agrega en el Sprint 4.
 * Todas las operaciones lanzan {@link CertificadorNoDisponibleException} si no hay respuesta a tiempo.
 */
public interface CertificadorFel {

    /**
     * Certifica un DTE. El {@code identificadorUnico} es {@code venta.uuid}: reenviar el mismo
     * identificador nunca genera una segunda factura (HU-08.04).
     */
    ResultadoCertificacion certificar(String xmlDte, UUID identificadorUnico);

    /** Consulta si ya se certificó un DTE con ese identificador, para reintentar sin duplicar (HU-08.04 crit. 2). */
    Optional<ResultadoCertificacion> consultarPorIdentificador(UUID identificadorUnico);

    ResultadoAnulacion anular(UUID autorizacion, String motivo);

    Optional<Contribuyente> consultarNit(String nit);

    Optional<Contribuyente> consultarCui(String cui);

    void solicitarEnvioCorreo(UUID autorizacion, String correo);

    void probarConexion();
}
