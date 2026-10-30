package gt.supermercado.pos.compartido.dominio;

/**
 * Error de una regla de negocio. El {@code codigo} es estable (lo puede usar el frontend)
 * y el {@code mensaje} está listo para mostrarse al usuario.
 */
public class NegocioException extends RuntimeException {

    private final String codigo;

    public NegocioException(String codigo, String mensaje) {
        super(mensaje);
        this.codigo = codigo;
    }

    public String getCodigo() {
        return codigo;
    }
}
