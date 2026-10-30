package gt.supermercado.pos;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

import java.util.List;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

/**
 * Reglas de dependencias entre módulos y capas (Architecture.md §4): un módulo solo usa la capa
 * {@code aplicacion} (y los tipos de {@code dominio}) de otro, nunca su {@code api} ni su {@code infraestructura}.
 */
@AnalyzeClasses(packages = "gt.supermercado.pos", importOptions = ImportOption.DoNotIncludeTests.class)
class ArquitecturaTest {

    private static final String BASE = "gt.supermercado.pos.";

    private static final List<String> MODULOS = List.of(
            "compartido", "seguridad", "catalogo", "impuestos", "clientes", "ventas", "pagos",
            "facturacion", "caja", "reportes", "bitacora", "configuracion", "impresion");

    @ArchTest
    static final ArchRule elDominioNoDependeDeApiNiInfraestructura = noClasses()
            .that().resideInAPackage("..dominio..")
            .should().dependOnClassesThat().resideInAnyPackage("..api..", "..infraestructura..", "org.springframework..")
            .allowEmptyShould(true);

    @ArchTest
    static final ArchRule impuestosEsCalculoPuro = classes()
            .that().resideInAPackage(BASE + "impuestos..")
            .should().onlyDependOnClassesThat().resideInAnyPackage("java..", BASE + "impuestos..", BASE + "compartido.dominio..")
            .allowEmptyShould(true);

    @ArchTest
    static void apiEInfraestructuraSonPrivadasDeCadaModulo(JavaClasses clases) {
        for (String modulo : MODULOS) {
            noClasses()
                    .that().resideOutsideOfPackage(BASE + modulo + "..")
                    .should().dependOnClassesThat()
                    .resideInAnyPackage(BASE + modulo + ".api..", BASE + modulo + ".infraestructura..")
                    .allowEmptyShould(true)
                    .because("otros módulos deben usar la capa aplicacion de '" + modulo + "'")
                    .check(clases);
        }
    }
}
