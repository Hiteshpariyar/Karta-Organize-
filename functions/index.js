const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');

admin.initializeApp();
const db = admin.firestore();

// Bootstrap verified admin emails
const BOOTSTRAP_ADMIN_EMAILS = [
  'hiteshpariyar73@gmail.com',
  'admin@tourneyzone.com'
];

/**
 * Checks if the caller is an authorized administrator.
 */
function isCallerAdmin(context) {
  if (!context.auth) return false;
  const token = context.auth.token;
  if (token.admin === true || token.role === 'admin') return true;
  if (token.email_verified === true && BOOTSTRAP_ADMIN_EMAILS.includes(token.email)) return true;
  return false;
}

/**
 * Generates an anonymized hash for rate limit bucket keying.
 */
function hashIdentifier(identifier) {
  return crypto.createHash('sha256').update(identifier.trim().toLowerCase()).digest('hex');
}

/**
 * Cloud Function: requestPasswordReset
 * 
 * Enforces backend rate limiting:
 * Maximum 4 requests per account within a rolling 90-second window.
 * Generic response returned to prevent account enumeration.
 */
exports.requestPasswordReset = functions.https.onCall(async (data, context) => {
  const email = (data.email || '').trim().toLowerCase();
  if (!email || !email.includes('@')) {
    throw new functions.https.HttpsError('invalid-argument', 'A valid email address is required.');
  }

  const emailHash = hashIdentifier(email);
  const bucketRef = db.collection('rate_limits').doc(`pwd_reset_${emailHash}`);
  const now = admin.firestore.Timestamp.now();
  const windowDurationMs = 90 * 1000; // 90 seconds
  const maxAttempts = 4;

  const rateCheck = await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(bucketRef);
    let history = [];

    if (doc.exists && doc.data().history) {
      const cutoff = Date.now() - windowDurationMs;
      history = doc.data().history.filter(ts => ts.toMillis() > cutoff);
    }

    if (history.length >= maxAttempts) {
      const oldestInWindow = history[0].toMillis();
      const remainingMs = windowDurationMs - (Date.now() - oldestInWindow);
      const remainingSec = Math.max(1, Math.ceil(remainingMs / 1000));
      return {
        allowed: false,
        remainingSec: remainingSec,
        count: history.length + 1
      };
    }

    history.push(now);
    transaction.set(bucketRef, {
      bucketKey: `pwd_reset_${emailHash}`,
      attempts: history.length,
      lastAttemptAt: now,
      history: history,
      windowExpiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + windowDurationMs)
    });

    return { allowed: true, count: history.length };
  });

  if (!rateCheck.allowed) {
    // Log throttling event in audit logs
    await db.collection('audit_logs').add({
      id: `audit_${Date.now()}_${emailHash.substring(0, 8)}`,
      eventType: 'password_reset_throttled',
      accountIdentifier: emailHash,
      timestamp: now,
      metadata: {
        attemptCount: rateCheck.count,
        retryAfterSeconds: rateCheck.remainingSec
      }
    });

    throw new functions.https.HttpsError(
      'resource-exhausted',
      `Too many password reset requests. For security, please wait ${rateCheck.remainingSec} seconds before trying again.`
    );
  }

  // Security best practice: dispatch via Admin Auth, return generic confirmation
  try {
    await admin.auth().getUserByEmail(email);
    // User exists: dispatch password reset email
    await admin.auth().generatePasswordResetLink(email);
  } catch (error) {
    // Silently continue if user not found to prevent user enumeration
  }

  await db.collection('audit_logs').add({
    id: `audit_${Date.now()}_${emailHash.substring(0, 8)}`,
    eventType: 'password_reset_dispatched',
    accountIdentifier: emailHash,
    timestamp: now,
    metadata: { attemptInWindow: rateCheck.count }
  });

  return {
    success: true,
    message: 'If an account exists with this email address, a password reset link has been dispatched.'
  };
});

/**
 * Cloud Function: setAdminRole
 * 
 * Securely assigns admin custom claims to a target user.
 * Restricted strictly to verified administrators.
 */
exports.setAdminRole = functions.https.onCall(async (data, context) => {
  if (!isCallerAdmin(context)) {
    throw new functions.https.HttpsError(
      'permission-denied',
      'Unauthorized. Only verified platform administrators can assign administrative privileges.'
    );
  }

  const targetUid = data.targetUid;
  if (!targetUid || typeof targetUid !== 'string') {
    throw new functions.https.HttpsError('invalid-argument', 'Target UID is required.');
  }

  // 1. Assign custom claims
  await admin.auth().setCustomUserClaims(targetUid, {
    admin: true,
    role: 'admin'
  });

  // 2. Sync user profile role in Firestore
  await db.collection('users').doc(targetUid).update({
    role: 'admin',
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  // 3. Record immutable security audit log
  await db.collection('audit_logs').add({
    id: `audit_${Date.now()}_role_elevated`,
    eventType: 'admin_role_assigned',
    accountIdentifier: targetUid,
    performedBy: context.auth.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    metadata: { targetUid: targetUid, assignedRole: 'admin' }
  });

  return { success: true, message: `Admin role successfully assigned to user ${targetUid}.` };
});

/**
 * Cloud Function: reviewOrganizerApplication
 * 
 * Reviews and approves or rejects an organizer application.
 * Restricted strictly to verified administrators.
 */
exports.reviewOrganizerApplication = functions.https.onCall(async (data, context) => {
  if (!isCallerAdmin(context)) {
    throw new functions.https.HttpsError('permission-denied', 'Unauthorized. Only administrators can review applications.');
  }

  const { applicantUid, status, rejectionReason } = data;
  if (!applicantUid || !['approved', 'rejected'].includes(status)) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid application review parameters.');
  }

  const updateData = {
    status: status,
    reviewedBy: context.auth.uid,
    reviewedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };

  if (status === 'rejected') {
    updateData.rejectionReason = rejectionReason || 'Application did not satisfy verification criteria.';
  } else {
    updateData.rejectionReason = null;
    // Grant organizer custom claim
    await admin.auth().setCustomUserClaims(applicantUid, {
      organizer: true,
      role: 'organizer'
    });
    // Update user profile role
    await db.collection('users').doc(applicantUid).update({
      role: 'organizer',
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    });
  }

  await db.collection('organizer_applications').doc(applicantUid).update(updateData);

  // Record audit log
  await db.collection('audit_logs').add({
    id: `audit_${Date.now()}_organizer_review`,
    eventType: 'organizer_application_reviewed',
    accountIdentifier: applicantUid,
    performedBy: context.auth.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    metadata: { status: status, rejectionReason: updateData.rejectionReason }
  });

  return { success: true, message: `Organizer application ${status} successfully.` };
});

/**
 * Cloud Function: deleteUserAccount
 * 
 * Deletes user profile and personal data from Firestore, then removes Auth record.
 */
exports.deleteUserAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Authentication required to delete account.');
  }

  const uidToDelete = data.targetUid || context.auth.uid;

  // Non-admins can only delete their own account
  if (uidToDelete !== context.auth.uid && !isCallerAdmin(context)) {
    throw new functions.https.HttpsError('permission-denied', 'You do not have permission to delete this account.');
  }

  const batch = db.batch();
  const userDocRef = db.collection('users').doc(uidToDelete);

  // Cleanup subcollections
  const policies = await userDocRef.collection('policy_acceptances').get();
  policies.forEach(doc => batch.delete(doc.ref));

  const notifs = await userDocRef.collection('notifications').get();
  notifs.forEach(doc => batch.delete(doc.ref));

  const settings = await userDocRef.collection('settings').get();
  settings.forEach(doc => batch.delete(doc.ref));

  batch.delete(userDocRef);
  await batch.commit();

  // Delete Auth account
  await admin.auth().deleteUser(uidToDelete);

  // Record audit log
  await db.collection('audit_logs').add({
    id: `audit_${Date.now()}_account_deleted`,
    eventType: 'account_deleted',
    accountIdentifier: uidToDelete,
    performedBy: context.auth.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    metadata: { deletedUid: uidToDelete }
  });

  return { success: true, message: 'Account and associated personal data successfully deleted.' };
});

