# MyBlueBoard Admin - Flutter App

Admin application for managing MyBlueBoard accounts, schools, and users.

## Environment Configuration

The app supports two environments:

### Dev Environment
- **Base URL**: `http://signup.app.local:8000`
- **API Base**: `http://signup.app.local:8000/api/admin`
- Uses the `signup` schema for all admin API calls
- For local development and testing

### Production Environment
- **Base URL**: `https://signup.myblueboard.com`
- **API Base**: `https://signup.myblueboard.com/api/admin`
- Uses the `signup` schema for all admin API calls
- For production use

## Switching Environments

To switch between environments, edit `lib/config/environment.dart`:

```dart
class EnvironmentConfig {
  // Change this line:
  static const Environment current = Environment.dev;  // or Environment.prod
  // ...
}
```

## API Endpoints

The app expects the following endpoints on the backend:

### Authentication
- `POST /api/admin/auth/login/` - Admin login
- `POST /api/admin/auth/logout/` - Admin logout
- `GET /api/admin/auth/profile/` - Get admin profile

### Resources (to be implemented)
- `GET /api/admin/users/` - List users
- `GET /api/admin/schools/` - List schools
- `GET /api/admin/accounts/` - List accounts

## Running the App

### macOS
```bash
flutter run -d macos
```

### iOS
```bash
flutter run -d ios
```

### Web
```bash
flutter run -d chrome
```

## Features

- ✅ Environment-based configuration (Dev/Prod)
- ✅ Secure token storage using flutter_secure_storage
- ✅ Admin authentication with JWT tokens
- ✅ Login screen with email/password
- ✅ Environment indicator on login screen
- 🚧 Dashboard (to be implemented)
- 🚧 User management (to be implemented)
- 🚧 School management (to be implemented)

## Dependencies

- `provider` - State management
- `http` - HTTP client
- `flutter_secure_storage` - Secure storage for tokens
- `cupertino_icons` - iOS-style icons

## Development

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run the app:
   ```bash
   flutter run -d macos
   ```

3. Hot reload during development:
   - Press `r` in the terminal for hot reload
   - Press `R` for hot restart

## Backend Setup

Make sure your Django backend has the admin API endpoints set up under the `signup` schema at `/api/admin/`.
