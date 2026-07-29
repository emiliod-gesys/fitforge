/// Rutas del shell que requieren conexión a internet.
const onlineOnlyShellRoutes = [
  '/ai-coach',
  '/food',
  '/progress',
  '/social',
  '/students',
];

bool isOnlineOnlyShellRoute(String location) {
  return onlineOnlyShellRoutes.any(location.startsWith);
}
