# Flutter Group Project

## Setup Instructions for Team Members

### Prerequisites
- Flutter SDK installed
- Android Studio installed
- Firebase CLI installed
- Git installed

### Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/yourusername/flutter-group-project.git
   cd flutter-group-project
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup:**
    - Place it in `android/app/google-services.json`
    - Or set up your own Firebase project and run `flutterfire configure`
4. **Run the project in chrome**

### Project Structure
```
lib/
├── main.dart              # Main application entry point
├── firebase_options.dart  # Firebase configuration
└── ...

android/
├── app/
│   ├── google-services.json  # Firebase config (not in git)
│   └── build.gradle
└── build.gradle
```