import { describe, expect, it } from 'vitest'
import { ATAJOS, accionDeTecla } from './atajos'

describe('atajos de caja', () => {
  it('cada tecla y cada acción se usan una sola vez', () => {
    expect(new Set(ATAJOS.map((a) => a.tecla)).size).toBe(ATAJOS.length)
    expect(new Set(ATAJOS.map((a) => a.accion)).size).toBe(ATAJOS.length)
  })

  it('cubre las acciones que pide HU-06.17', () => {
    const acciones = ATAJOS.map((a) => a.accion)
    expect(acciones).toEqual(
      expect.arrayContaining([
        'buscarProducto', 'cambiarCantidad', 'eliminarLinea', 'asignarCliente', 'consultarPrecio',
        'suspenderVenta', 'retomarVenta', 'cancelarVenta', 'cobrar',
      ]),
    )
  })

  it('traduce la tecla presionada a su acción', () => {
    expect(accionDeTecla('F12')).toBe('cobrar')
    expect(accionDeTecla('a')).toBeUndefined()
  })
})
