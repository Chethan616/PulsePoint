# Firestore Indexes for PulsePoint

This document outlines the required Firestore indexes for the PulsePoint application to function properly.

## Blood Donations Collection Indexes

### 1. Index for User Donations History (in History tab)

This index is required for querying a user's donation history (where the user is either a donor or recipient):

- **Collection**: `blood_donations`
- **Query**: Filter by `donorId` OR `recipientId` + Order by `requestDate` (descending)
- **Composite Index 1**:
  - Field path: `donorId` (Ascending)
  - Field path: `requestDate` (Descending)
- **Composite Index 2**:
  - Field path: `recipientId` (Ascending)
  - Field path: `requestDate` (Descending)

### 2. Index for Donor Requests

This index is used to show pending donation requests to a donor:

- **Collection**: `blood_donations`
- **Query**: Filter by `donorId` + Filter by `status` + Order by `requestDate` (descending)
- **Composite Index**:
  - Field path: `donorId` (Ascending)
  - Field path: `status` (Ascending)
  - Field path: `requestDate` (Descending)

### 3. Index for Recipient Requests

This index is used to show a recipient's requests:

- **Collection**: `blood_donations`
- **Query**: Filter by `recipientId` + Order by `requestDate` (descending)
- **Composite Index**:
  - Field path: `recipientId` (Ascending)
  - Field path: `requestDate` (Descending)

## How to Create These Indexes

1. Go to the [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Firestore Database
4. Click on the "Indexes" tab
5. Click "Create Index"
6. Select the collection (`blood_donations`)
7. Add the fields in the order specified above
8. Set the Query scope to "Collection"
9. Click "Create"

## Notes

- Indexes may take a few minutes to build after creation
- If you encounter a Firestore error about missing indexes, Firebase will often provide a direct link to create the required index
- These indexes help optimize query performance and are required for complex queries (combinations of filters and order by clauses) 