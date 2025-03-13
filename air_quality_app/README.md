# Airy - Air Quality Monitoring App

<p align="center">
  <img src="air_quality_app/assets/images/app_logo.png" alt="Airy App Logo" width="200"/>
</p>

## 📱 About the App

Airy is a mobile application that allows users to monitor real-time air quality data at their location. The app visualizes air quality index (AQI) data to help users protect their health and sends notifications during hazardous air conditions.

## ✨ Features

- **Real-Time Air Quality Data**: Current air quality information based on location
- **Detailed Pollutant Analysis**: Detailed measurements of PM2.5, PM10, O3, NO2, SO2, CO
- **Visual Air Quality Indicators**: Easy-to-understand graphs and indicators
- **Location Tracking**: Automatic detection and tracking of user's location
- **Notifications**: Automatic notifications for dangerous air quality levels
- **Customization**: Adjustable notification thresholds based on user preferences
- **User Accounts**: Storage of personal data and preferences
- **Offline Access**: Access to last received data without internet connection
- **Modern and User-Friendly Interface**: UI enriched with animations and visual effects

## 🛠️ Technologies Used

- **Flutter**: Cross-platform mobile app development
- **Firebase**: For authentication, database, and notifications
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Cloud Messaging
- **Provider**: State management
- **Geolocator & Geocoding**: Location services
- **HTTP & Dio**: API requests
- **OpenAQ & WAQI API**: Air quality data

## 🚀 Installation

### Requirements

- Flutter SDK (2.10.0 or higher)
- Dart SDK (2.16.0 or higher)
- Android Studio / VS Code
- Android SDK / Xcode (for iOS development)
- Firebase account

### Steps

1. Clone the project:
   ```bash
   git clone https://github.com/ogulcanodemis/airy.git
   cd airy
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Firebase configuration:
   - Create a new project in Firebase console
   - Register Android and iOS apps
   - Place `google-services.json` and `GoogleService-Info.plist` files in the appropriate folders

4. API Keys:
   - Register for OpenAQ API (free)
   - Register for WAQI API and get an API key
   - Update API keys in `lib/services/air_quality_service.dart`

5. Run the app:
   ```bash
   flutter run
   ```

## 🔑 Environment Variables

You need to set the following environment variables for the app to work properly:

- `WAQI_API_KEY`: WAQI API key
- `OPENAQ_API_KEY`: OpenAQ API key (optional)

## 📝 Usage

1. Open the app and create an account or log in
2. Approve location permissions
3. View air quality data at your current location on the main screen
4. Click on the air quality card for detailed information
5. Check past alerts from the notifications screen
6. Customize your notification preferences and other options from the settings screen

## 🤝 Contributing

If you want to contribute, please follow these steps:

1. Fork the project
2. Create a new branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request


## 📞 Contact

Project Owner - [@ogulcanodemis](https://github.com/ogulcanodemis)
LinkedIn - [Oğulcan Ödemiş](https://www.linkedin.com/in/ogulcanodemiss/)
Project Link: [https://github.com/ogulcanodemis/airy](https://github.com/ogulcanodemis/airy)

## 🙏 Acknowledgments

- [OpenAQ](https://openaq.org/) - Open source air quality data
- [WAQI](https://waqi.info/) - World Air Quality Index data
- [Flutter](https://flutter.dev/) - Amazing UI framework
- [Firebase](https://firebase.google.com/) - Backend services 