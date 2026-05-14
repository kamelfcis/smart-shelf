# Smart Shelf

An IoT-connected mobile application for real-time shelf monitoring using ESP8266 weight sensors.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter 3.x (Dart) |
| State | Riverpod 2 |
| Backend | Supabase (Auth + DB + Realtime + Edge Functions) |
| Animations | flutter_animate + Lottie |
| Charts | fl_chart |
| IoT | ESP8266 + HX711 (Arduino) |
| Routing | go_router |

## Project Structure

```
smart_shelf/
├── lib/
│   ├── core/
│   │   ├── constants/      # AppColors, AppTypography, AppDimensions
│   │   ├── theme/          # AppTheme (dark + light)
│   │   ├── router/         # go_router config + transitions
│   │   └── utils/          # formatters, validators, extensions
│   ├── data/
│   │   ├── models/         # Shelf, Item, Notification, Profile, ItemLog
│   │   ├── repositories/   # Auth, Shelf, Item, Notification repos
│   │   └── datasources/    # Supabase client singleton
│   ├── presentation/
│   │   ├── auth/           # Login + Signup screens + AuthProvider
│   │   ├── onboarding/     # Splash + 3 Onboarding screens
│   │   ├── dashboard/      # Home screen with shelf cards
│   │   ├── shelf_detail/   # Shelf detail + Item history + Forms
│   │   ├── notifications/  # Notification center
│   │   ├── profile/        # Profile + settings + theme toggle
│   │   └── widgets/        # Shared reusable components
│   └── main.dart
├── supabase/
│   ├── schema.sql          # Full Supabase SQL schema
│   └── functions/
│       └── sensor-data/    # Edge Function for ESP8266 data
├── iot/
│   └── smart_shelf_firmware.ino  # Arduino firmware
└── assets/
    ├── animations/         # Lottie files
    ├── images/             # Static images
    └── fonts/              # JetBrains Mono
```

## Setup

### 1. Supabase

1. Create a new project at [supabase.com](https://supabase.com)
2. Run `supabase/schema.sql` in the SQL Editor
3. Enable Realtime for tables: `items`, `notifications`, `shelves`
4. Create storage buckets: `item-images` and `avatars` (both public)
5. Deploy the Edge Function:
   ```bash
   supabase functions deploy sensor-data
   ```

### 2. Flutter App

1. Update `lib/core/constants/app_constants.dart`:
   ```dart
   static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
   static const String supabaseAnonKey = 'YOUR_ANON_KEY';
   ```

2. Add JetBrains Mono fonts to `assets/fonts/` (download from [jetbrains.com/lp/mono](https://www.jetbrains.com/lp/mono/))

3. Run the app:
   ```bash
   flutter pub get
   flutter run
   ```

### 3. ESP8266 Firmware

1. Install Arduino IDE with ESP8266 board support
2. Install libraries: `HX711`, `ArduinoJson`
3. Open `iot/smart_shelf_firmware.ino`
4. Update WiFi credentials, Supabase URL, anon key, and sensor ID
5. Calibrate the HX711 (run calibration sketch first)
6. Flash to your ESP8266

## Screens

| Screen | Description |
|--------|-------------|
| Splash | Animated logo with glow pulse |
| Onboarding | 3 screens with animated icons |
| Login / Signup | Glassmorphism auth forms |
| Dashboard | Shelf cards with live sensor status |
| Shelf Detail | Real-time item list with weight bars |
| Item History | fl_chart line graph of weight over time |
| Notifications | Grouped alerts with swipe-to-dismiss |
| Profile | Theme toggle, account info, logout |

## IoT Integration

The ESP8266 sends HTTP POST requests to the Supabase Edge Function every 5 seconds:

```json
POST /functions/v1/sensor-data
{
  "sensor_id": "shelf-A1-esp8266",
  "readings": [
    { "slot": 1, "weight_g": 482.5 }
  ]
}
```

The Edge Function:
- Updates `items.current_weight`
- Inserts weight logs
- Detects low stock / item removal
- Creates notification rows
- Updates sensor online status

## Design System

- **Dark mode first** — `#0A0A0F` background
- **Accent Primary** — `#6C63FF` electric violet
- **Accent Secondary** — `#00E5FF` cyan glow
- **Glassmorphism** cards with backdrop blur
- **flutter_animate** micro-interactions on every element
- **JetBrains Mono** for all sensor/weight values
