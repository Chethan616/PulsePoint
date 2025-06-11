# PulsePoint Firebase Cloud Functions

This directory contains Firebase Cloud Functions to handle push notifications for the PulsePoint app.

## Features

- `sendBloodRequestNotifications`: Sends notifications to nearby users with matching blood types when a new blood request is created
- `sendChatNotifications`: Sends notifications to chat participants when new messages are sent

## Deployment Instructions

### Prerequisites

1. Install Firebase CLI globally:
   ```bash
   npm install -g firebase-tools
   ```

2. Log in to Firebase:
   ```bash
   firebase login
   ```

### Deploy Functions

1. Navigate to the functions directory:
   ```bash
   cd functions
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Deploy the functions:
   ```bash
   npm run deploy
   ```
   
   Alternatively, from the project root:
   ```bash
   firebase deploy --only functions
   ```

## Testing

You can test the functions locally using the Firebase Emulator:

```bash
npm run serve
```

## Notes

- These functions require Firebase Admin SDK, which is initialized in the code.
- For production use, you might want to add additional error handling and optimization.
- Make sure your Firebase project has the Blaze (pay-as-you-go) plan enabled, as functions require a paid plan. 