# Mapbox Maps SDK Integration Instructions

## Step 1: Add Mapbox SDK to your project using Swift Package Manager

1. Open your Xcode project
2. Go to File > Add Packages...
3. In the search bar, paste the Mapbox Maps SDK repository URL: `https://github.com/mapbox/mapbox-maps-ios.git`
4. Select "Up to Next Major Version" as the dependency rule
5. Click "Add Package"
6. Select the "MapboxMaps" package product and click "Add Package"

## Step 2: Configure your Mapbox access token

1. Replace `YOUR_MAPBOX_ACCESS_TOKEN` in the Info.plist file with your actual Mapbox access token
2. Replace `YOUR_MAPBOX_ACCESS_TOKEN` in the MapboxMapView.swift file with the same token

## Step 3: Build and run your app

1. Clean your build folder (Product > Clean Build Folder)
2. Build and run your app

## Troubleshooting

If you encounter any issues:

1. Make sure your Mapbox account is active and your access token has the necessary permissions
2. Check that your Info.plist file contains the required Mapbox configuration
3. Ensure your app has the necessary location permissions

## Additional Resources

- [Mapbox Maps SDK for iOS Documentation](https://docs.mapbox.com/ios/maps/guides/)
- [Mapbox Navigation SDK for iOS](https://docs.mapbox.com/ios/navigation/guides/) - For turn-by-turn navigation
- [Mapbox API Documentation](https://docs.mapbox.com/api/overview/)
