package gt.supermercado.pos.compartido.api;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.OffsetDateTime;

/**
 * Estado del sistema para el frontend y para verificar la instalación. Público, sin datos sensibles.
 */
@RestController
@RequestMapping("/api/sistema")
public class SistemaController {

    private final JdbcTemplate jdbc;
    private final String version;
    private final String modoFel;

    public SistemaController(JdbcTemplate jdbc,
                             @Value("${pos.version}") String version,
                             @Value("${pos.fel.modo}") String modoFel) {
        this.jdbc = jdbc;
        this.version = version;
        this.modoFel = modoFel;
    }

    public record InfoSistema(String version, String modoFel, String baseDatos, OffsetDateTime horaServidor) {}

    @GetMapping("/info")
    public InfoSistema info() {
        // La hora sale de PostgreSQL, no del equipo de la caja (HU-11.02).
        return jdbc.queryForObject(
                "SELECT current_setting('server_version') AS version_bd, now() AS ahora",
                (rs, fila) -> new InfoSistema(
                        version,
                        modoFel,
                        "PostgreSQL " + rs.getString("version_bd"),
                        rs.getObject("ahora", OffsetDateTime.class)));
    }
}
