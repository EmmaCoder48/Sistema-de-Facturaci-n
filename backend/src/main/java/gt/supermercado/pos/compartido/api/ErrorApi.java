package gt.supermercado.pos.compartido.api;

import java.util.List;

/** Formato único de error de la API (Architecture.md §8). */
public record ErrorApi(String codigo, String mensaje, List<String> detalles) {

    public static ErrorApi de(String codigo, String mensaje) {
        return new ErrorApi(codigo, mensaje, List.of());
    }
}
