package gt.supermercado.pos.facturacion.dominio;

/**
 * El certificador no respondió a tiempo o no hay conexión. Al certificar, esto lleva la factura a
 * contingencia (HU-08.07); al consultar NIT o CUI, el cajero escribe el nombre a mano (HU-05.04).
 */
public class CertificadorNoDisponibleException extends RuntimeException {

    public CertificadorNoDisponibleException(String mensaje) {
        super(mensaje);
    }
}
