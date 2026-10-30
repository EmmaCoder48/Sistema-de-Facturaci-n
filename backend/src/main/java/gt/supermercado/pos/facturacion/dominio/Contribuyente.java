package gt.supermercado.pos.facturacion.dominio;

/** Nombre del contribuyente consultado por NIT o CUI en el servicio del certificador (HU-05.04, 05.06). */
public record Contribuyente(String identificacion, String nombre) {}
