import { QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { BrowserRouter, Navigate, Route, Routes } from 'react-router'
import { EstadoSistema } from './modulos/sistema/EstadoSistema'

const clienteConsultas = new QueryClient({
  defaultOptions: { queries: { retry: 1, refetchOnWindowFocus: false } },
})

// Cada sprint agrega aquí las rutas de su módulo (login, venta, caja, catálogo, ...).
export default function App() {
  return (
    <QueryClientProvider client={clienteConsultas}>
      <BrowserRouter>
        <Routes>
          <Route path="/sistema" element={<EstadoSistema />} />
          <Route path="*" element={<Navigate to="/sistema" replace />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  )
}
