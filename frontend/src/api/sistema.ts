import { pedir } from './cliente'

export interface InfoSistema {
  version: string
  modoFel: string
  baseDatos: string
  horaServidor: string
}

export const obtenerInfoSistema = () => pedir<InfoSistema>('/api/sistema/info')
