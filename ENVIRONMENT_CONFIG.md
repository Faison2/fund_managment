# Environment Configuration Guide

## Issue Fixed
**Vulnerability 4.8**: Production App Hardcoded to UAT API Endpoints

### What Was Wrong
- The app was hardcoded to use UAT API: `https://portaluat.tsl.co.tz/FMSAPI/Home`
- Production endpoint was commented out
- API credentials were hardcoded in constants

## Solution Implemented

### New Environment Configuration System
Created a centralized environment management system in `lib/config/environment_config.dart` that:
- Supports multiple environments (UAT, Production)
- Manages API endpoints per environment
- Manages API credentials per environment
- Easily switches between environments by changing one constant

### How to Use

#### Current Configuration
- **Current Environment**: PRODUCTION ✓
- **Production API**: `https://portalprod.tsl.co.tz/FMSAPI/Home`
- **UAT API**: `https://portaluat.tsl.co.tz/FMSAPI/Home`

#### To Switch Environments
Edit `lib/config/environment_config.dart` line 7:

```dart
// For Production (recommended for production builds)
static const Environment currentEnvironment = Environment.production;

// For UAT (for testing)
static const Environment currentEnvironment = Environment.uat;
```

#### To Update Credentials
Edit `lib/config/environment_config.dart` lines 14-22:

```dart
static const Map<Environment, String> apiUsernames = {
  Environment.uat: 'User2',
  Environment.production: 'YOUR_PROD_USERNAME_HERE', // Update this
};

static const Map<Environment, String> apiPasswords = {
  Environment.uat: 'CBZ1234#2',
  Environment.production: 'YOUR_PROD_PASSWORD_HERE', // Update this
};
```

### Files Modified
1. **`lib/config/environment_config.dart`** - NEW: Centralized environment configuration
2. **`lib/constants/constants.dart`** - UPDATED: Now uses EnvironmentConfig instead of hardcoded values

### Best Practices Going Forward

1. **For Production Builds**: Ensure `currentEnvironment = Environment.production`
2. **Don't Commit Sensitive Data**: Store production credentials securely (use environment variables or secure vaults)
3. **Use Build Variants** (recommended): Consider implementing Android/iOS build flavors for automatic environment switching
4. **Verify Before Release**: Always verify the correct environment is configured before building for release

### Related Security Notes
- API credentials should ideally be stored in secure vaults, not hardcoded
- Consider implementing OAuth or token-based authentication instead of username/password
- Add logging to track which environment is being used for debugging

---
**Last Updated**: July 1, 2026

