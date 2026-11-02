import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { Toaster } from 'react-hot-toast';
import App from './App';
import { AuthProvider } from './auth';
import './styles.css';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <BrowserRouter>
      <AuthProvider>
        <App />
        <Toaster
          position="top-center"
          gutter={10}
          toastOptions={{
            duration: 3500,
            style: {
              background: '#111',
              color: '#fff',
              borderRadius: '14px',
              padding: '12px 16px',
              fontSize: '14px',
              boxShadow: '0 10px 30px rgba(0,0,0,.25)',
            },
            success: { iconTheme: { primary: '#c6ff3d', secondary: '#111' } },
            error: { iconTheme: { primary: '#ff6b6b', secondary: '#111' }, duration: 5000 },
          }}
        />
      </AuthProvider>
    </BrowserRouter>
  </StrictMode>,
);
