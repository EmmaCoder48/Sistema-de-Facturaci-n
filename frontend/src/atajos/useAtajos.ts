import { useEffect } from 'react'
import { accionDeTecla, type AccionCaja } from './atajos'

type Manejadores = Partial<Record<AccionCaja, () => void>>

/** Ejecuta la acción asociada a cada tecla mientras la pantalla esté montada. */
export function useAtajos(manejadores: Manejadores) {
  useEffect(() => {
    const alPresionar = (evento: KeyboardEvent) => {
      const accion = accionDeTecla(evento.key)
      const manejador = accion && manejadores[accion]
      if (manejador) {
        evento.preventDefault()
        manejador()
      }
    }
    window.addEventListener('keydown', alPresionar)
    return () => window.removeEventListener('keydown', alPresionar)
  }, [manejadores])
}
