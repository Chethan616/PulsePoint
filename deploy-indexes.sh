#!/bin/bash
echo "Deploying Firestore Indexes for PulsePoint..."
firebase deploy --only firestore:indexes

echo ""
echo "If you encounter any issues, make sure to:"
echo "1. Install Firebase CLI: npm install -g firebase-tools"
echo "2. Login to Firebase: firebase login"
echo "3. Select your project: firebase use YOUR_PROJECT_ID"
echo "" 