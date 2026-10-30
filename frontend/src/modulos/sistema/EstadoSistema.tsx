import { useQuery } from '@tanstack/react-query'
import { obtenerInfoSistema } from '../../api/sistema'
import { ATAJOS } from '../../atajos/atajos'

/** Pantalla del Sprint 0: confirma que frontend, backend y PostgreSQL están conectados. */
export function EstadoSistema() {
  const { data, error, isPending } = useQuery({
    queryKey: ['sistema', 'info'],
    queryFn: obtenerInfoSistema,
    refetchInterval: 30_000,
  })

  return (
    <main className="pagina">
      <h1>POS Supermercado</h1>
      <p className="subtitulo">Sprint 0 · Estado del entorno</p>

      <section className="tarjeta">
        <h2>Conexión</h2>
        {isPending && <p>Consultando el servidor…</p>}
        {error && <p className="error">Sin conexión con el backend: {error.message}</p>}
        {data && (
          <dl>
            <dt>Backend</dt>
            <dd className="ok">Conectado · v{data.version}</dd>
            <dt>Base de datos</dt>
            <dd>{data.baseDatos}</dd>
            <dt>Certificador FEL</dt>
            <dd>{data.modoFel}</dd>
            <dt>Hora del servidor</dt>
            <dd>{new Date(data.horaServidor).toLocaleString('es-GT')}</dd>
          </dl>
        )}
      </section>

      <section className="tarjeta">
        <h2>Atajos de la caja</h2>
        <ul className="atajos">
          {ATAJOS.map((atajo) => (
            <li key={atajo.tecla}>
              <kbd>{atajo.tecla === 'Delete' ? 'Supr' : atajo.tecla}</kbd> {atajo.descripcion}
            </li>
          ))}
        </ul>
      </section>
    </main>
  )
}
