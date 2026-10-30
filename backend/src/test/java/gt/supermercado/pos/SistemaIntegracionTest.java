package gt.supermercado.pos;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

/** Verifica que el entorno del Sprint 0 arranca contra PostgreSQL con las migraciones aplicadas. */
@Import(TestcontainersConfiguration.class)
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class SistemaIntegracionTest {

    @Autowired
    JdbcTemplate jdbc;

    @Value("${local.server.port}")
    int puerto;

    private final HttpClient http = HttpClient.newHttpClient();

    @Test
    void flywayAplicaLasMigraciones() {
        Integer exitosas = jdbc.queryForObject(
                "SELECT count(*) FROM flyway_schema_history WHERE success AND version = '1'", Integer.class);
        assertThat(exitosas).isEqualTo(1);
    }

    @Test
    void lasExtensionesRequeridasEstanInstaladas() {
        List<String> extensiones = jdbc.queryForList("SELECT extname FROM pg_extension", String.class);
        assertThat(extensiones).contains("pg_trgm", "unaccent", "pgcrypto");
    }

    @Test
    void laBusquedaIgnoraTildesYMayusculas() {
        String normalizado = jdbc.queryForObject("SELECT f_unaccent(lower('Café ÁRBOL Piñata'))", String.class);
        assertThat(normalizado).isEqualTo("cafe arbol pinata");
    }

    @Test
    void elRolDeLaAplicacionNoPuedeBorrarRegistros() {
        jdbc.execute("CREATE TABLE prueba_privilegios (id int)");
        try {
            List<String> privilegios = jdbc.queryForList("""
                    SELECT privilege_type FROM information_schema.role_table_grants
                    WHERE grantee = 'pos_app' AND table_name = 'prueba_privilegios'""", String.class);
            assertThat(privilegios).containsExactlyInAnyOrder("SELECT", "INSERT", "UPDATE");
        } finally {
            jdbc.execute("DROP TABLE prueba_privilegios");
        }
    }

    @Test
    void elEstadoDelSistemaEsPublico() throws Exception {
        HttpResponse<String> respuesta = get("/api/sistema/info");
        assertThat(respuesta.statusCode()).isEqualTo(200);
        assertThat(respuesta.body()).contains("\"modoFel\":\"simulado\"").contains("PostgreSQL 16");
    }

    @Test
    void lasDemasRutasExigenSesion() throws Exception {
        assertThat(get("/api/productos").statusCode()).isEqualTo(401);
    }

    private HttpResponse<String> get(String ruta) throws Exception {
        HttpRequest peticion = HttpRequest.newBuilder(URI.create("http://localhost:" + puerto + ruta)).GET().build();
        return http.send(peticion, HttpResponse.BodyHandlers.ofString());
    }
}
