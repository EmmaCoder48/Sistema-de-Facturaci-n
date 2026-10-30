package gt.supermercado.pos.facturacion.infraestructura.fel;

import gt.supermercado.pos.facturacion.aplicacion.CertificadorFel;
import gt.supermercado.pos.facturacion.dominio.CertificadorNoDisponibleException;
import gt.supermercado.pos.facturacion.dominio.Contribuyente;
import gt.supermercado.pos.facturacion.dominio.ResultadoAnulacion;
import gt.supermercado.pos.facturacion.dominio.ResultadoCertificacion;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.time.OffsetDateTime;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

/**
 * Certificador en memoria para desarrollar y probar sin el certificador real.
 * El escenario ({@code pos.fel.simulador.escenario}) permite probar aceptación, rechazo y contingencia.
 */
@Component
@ConditionalOnProperty(name = "pos.fel.modo", havingValue = "simulado")
public class CertificadorFelSimulado implements CertificadorFel {

    public enum Escenario { ACEPTAR, RECHAZAR, SIN_CONEXION }

    private final Map<UUID, ResultadoCertificacion> certificadas = new ConcurrentHashMap<>();
    private final AtomicLong correlativo = new AtomicLong();
    private volatile Escenario escenario;

    public CertificadorFelSimulado(@Value("${pos.fel.simulador.escenario:ACEPTAR}") Escenario escenario) {
        this.escenario = escenario;
    }

    /** Permite cambiar el escenario en pruebas automáticas. */
    public void usarEscenario(Escenario escenario) {
        this.escenario = escenario;
    }

    @Override
    public ResultadoCertificacion certificar(String xmlDte, UUID identificadorUnico) {
        verificarConexion();
        ResultadoCertificacion previa = certificadas.get(identificadorUnico);
        if (previa != null) {
            return previa;
        }
        if (escenario == Escenario.RECHAZAR) {
            return ResultadoCertificacion.rechazada("SIM-001", "NIT del receptor no válido (simulado).");
        }
        return certificadas.computeIfAbsent(identificadorUnico, id -> ResultadoCertificacion.aceptada(
                UUID.randomUUID(), "SIM", String.valueOf(correlativo.incrementAndGet()), OffsetDateTime.now()));
    }

    @Override
    public Optional<ResultadoCertificacion> consultarPorIdentificador(UUID identificadorUnico) {
        verificarConexion();
        return Optional.ofNullable(certificadas.get(identificadorUnico));
    }

    @Override
    public ResultadoAnulacion anular(UUID autorizacion, String motivo) {
        verificarConexion();
        boolean existe = certificadas.values().stream().anyMatch(r -> autorizacion.equals(r.autorizacion()));
        return existe
                ? new ResultadoAnulacion(true, null, null)
                : new ResultadoAnulacion(false, "SIM-404", "La factura no existe en el certificador (simulado).");
    }

    @Override
    public Optional<Contribuyente> consultarNit(String nit) {
        verificarConexion();
        return Optional.of(new Contribuyente(nit, "CONTRIBUYENTE SIMULADO " + nit));
    }

    @Override
    public Optional<Contribuyente> consultarCui(String cui) {
        verificarConexion();
        return Optional.of(new Contribuyente(cui, "PERSONA SIMULADA " + cui));
    }

    @Override
    public void solicitarEnvioCorreo(UUID autorizacion, String correo) {
        verificarConexion();
    }

    @Override
    public void probarConexion() {
        verificarConexion();
    }

    private void verificarConexion() {
        if (escenario == Escenario.SIN_CONEXION) {
            throw new CertificadorNoDisponibleException("Sin conexión con el certificador (simulado).");
        }
    }
}
