# RideSathi — Firebase Cloud Firestore Data Structure & Schema Reference

This document defines the schema, data models, field mutability rules, and security expectations for Cloud Firestore in RideSathi.

---

## 1. Collections Overview

| Collection | Document ID | Purpose | PR Introduced |
| :--- | :--- | :--- | :--- |
| `users` | Firebase Auth UID (`request.auth.uid`) | User profile, role, verification status, and contact details. | PR 12, PR 13, PR 18 |

---

## 2. Collection: `users`

### Document Path: `/users/{uid}`

```json
{
  "id": "string (matches document ID and auth.uid)",
  "name": "string (Full Name)",
  "phoneNumber": "string (Phone number with optional + prefix)",
  "email": "string? (Account email)",
  "role": "string ('rider' | 'driver')",
  "isUnionVerified": "boolean (Default false)",
  "vehicleInfo": "string? (Driver vehicle details, e.g. 'Auto DL-01-AB-1234')",
  "createdAt": "Timestamp (Server timestamp on create)",
  "updatedAt": "Timestamp (Server timestamp on create and update)"
}
```

### Field Mutability & Permissions Matrix

| Field | Type | Client Mutability | Update Pattern | Notes / Security Expectations |
| :--- | :--- | :---: | :--- | :--- |
| `id` | `String` | **Immutable** | Set once on signup | Must match `request.auth.uid`. Re-assignment rejected by service & security rules. |
| `email` | `String?` | **Immutable** | Set once on signup | Linked to Firebase Authentication credential. Read-only in profile. |
| `role` | `String` | **Immutable** | Set once on signup | `'rider'` or `'driver'`. Client-side role escalation is strictly forbidden. |
| `isUnionVerified` | `Boolean` | **Immutable** | Set to `false` on signup | Can only be updated by authorized union/admin dispatchers. Self-promotion rejected. |
| `createdAt` | `Timestamp` | **Immutable** | Injected on create | Server timestamp (`FieldValue.serverTimestamp()`). Never updated after creation. |
| `name` | `String` | **Mutable** | Partial `update` | Required, 2–100 characters. Validated client-side and in Firestore rules. |
| `phoneNumber` | `String` | **Mutable** | Partial `update` | Required, 7–15 digits, optional `+` prefix. |
| `vehicleInfo` | `String?` | **Mutable (Driver only)** | Partial `update` | Required for drivers (min 2 characters). Ignored/null for riders. |
| `updatedAt` | `Timestamp` | **Auto-injected** | Partial `update` | Injected automatically on every update with `FieldValue.serverTimestamp()`. |

---

## 3. Profile Update Rules & Service Contract

### Partial Update vs Overwrite
* Profile updates MUST execute via partial document update:
  ```dart
  await _usersCollection.doc(uid).update(payload);
  ```
* Calling `set` with full replacement is forbidden for updates because it risks wiping server-managed metadata or unread fields.
* Whitelist enforcement is performed by `UserProfileService`:
  ```dart
  static const Set<String> allowedUpdateKeys = {'name', 'phoneNumber', 'vehicleInfo'};
  static const Set<String> protectedKeys = {'id', 'email', 'role', 'isUnionVerified', 'createdAt'};
  ```
  Any attempt to submit protected or unknown keys throws an `ArgumentError`.

### Server-Side Security Rule Expectations (PR 55/56)
* Read access:
  ```javascript
  allow read: if request.auth != null && (request.auth.uid == uid || request.auth.token.role == 'dispatcher' || request.auth.token.role == 'admin');
  ```
* Create access:
  ```javascript
  allow create: if request.auth != null && request.auth.uid == uid &&
                request.resource.data.role in ['rider', 'driver'] &&
                request.resource.data.isUnionVerified == false;
  ```
* Update access:
  ```javascript
  allow update: if request.auth != null && request.auth.uid == uid &&
                request.resource.data.id == resource.data.id &&
                request.resource.data.email == resource.data.email &&
                request.resource.data.role == resource.data.role &&
                request.resource.data.isUnionVerified == resource.data.isUnionVerified &&
                request.resource.data.createdAt == resource.data.createdAt;
  ```
