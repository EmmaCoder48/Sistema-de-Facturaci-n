// Mapa central de atajos de teclado de la caja (HU-06.17, Architecture.md §7.6).
// Las pantallas registran su acción por nombre; la tecla solo se define aquí.

export type AccionCaja =
  | 'ayuda'
  | 'buscarProducto'
  | 'consultarPrecio'
  | 'cambiarCantidad'
  | 'eliminarLinea'
  | 'asignarCliente'
  | 'suspenderVenta'
  | 'retomarVenta'
  | 'reimprimirUltima'
  | 'cancelarVenta'
  | 'cobrar'

export interface Atajo {
  tecla: string
  accion: AccionCaja
  descripcion: string
}

export const ATAJOS: readonly Atajo[] = [
  { tecla: 'F1', accion: 'ayuda', descripcion: 'Mostrar atajos' },
  { tecla: 'F2', accion: 'buscarProducto', descripcion: 'Buscar producto por descripción' },
  { tecla: 'F3', accion: 'consultarPrecio', descripcion: 'Consultar precio' },
  { tecla: 'F4', accion: 'cambiarCantidad', descripcion: 'Cambiar cantidad' },
  { tecla: 'Delete', accion: 'eliminarLinea', descripcion: 'Eliminar línea' },
  { tecla: 'F6', accion: 'asignarCliente', descripcion: 'Asignar cliente (NIT/CUI/CF)' },
  { tecla: 'F7', accion: 'suspenderVenta', descripcion: 'Suspender venta' },
  { tecla: 'F8', accion: 'retomarVenta', descripcion: 'Retomar venta' },
  { tecla: 'F9', accion: 'reimprimirUltima', descripcion: 'Reimprimir última factura' },
  { tecla: 'F10', accion: 'cancelarVenta', descripcion: 'Cancelar venta' },
  { tecla: 'F12', accion: 'cobrar', descripcion: 'Cobrar' },
]

export function accionDeTecla(tecla: string): AccionCaja | undefined {
  return ATAJOS.find((atajo) => atajo.tecla === tecla)?.accion
}
