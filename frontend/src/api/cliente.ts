// Cliente HTTP del backend. Los errores siguen el formato único de la API (Architecture.md §8).

export interface ErrorApi {
  codigo: string
  mensaje: string
  detalles: string[]
}

export class ErrorDeApi extends Error {
  readonly estado: number
  readonly codigo: string
  readonly detalles: string[]

  constructor(estado: number, error: ErrorApi) {
    super(error.mensaje)
    this.estado = estado
    this.codigo = error.codigo
    this.detalles = error.detalles
  }
}

export async function pedir<T>(ruta: string, opciones: RequestInit = {}): Promise<T> {
  const respuesta = await fetch(ruta, {
    ...opciones,
    credentials: 'include',
    headers: { 'Content-Type': 'application/json', ...opciones.headers },
  })

  if (!respuesta.ok) {
    const error: ErrorApi = await respuesta.json().catch(() => ({
      codigo: 'SIN_RESPUESTA',
      mensaje: 'No se pudo comunicar con el servidor.',
      detalles: [],
    }))
    throw new ErrorDeApi(respuesta.status, error)
  }

  return respuesta.status === 204 ? (undefined as T) : respuesta.json()
}
