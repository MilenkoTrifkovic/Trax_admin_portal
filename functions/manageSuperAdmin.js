import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import postmark from "postmark";

// Secret for Postmark API
const POSTMARK_SERVER_TOKEN = defineSecret("POSTMARK_SERVER_TOKEN");

// Email configuration
const FROM_EMAIL = "developer@trax-event.com";
const FROM_NAME = "Trax Admin Portal";

/**
 * Cloud function to manage super admin accounts
 * Supports: create, edit, disable/enable, delete (soft delete), reset password operations
 * Only callable by existing super admins
 * 
 * Expected request data:
 * - action: string (required) - "create" | "edit" | "disable" | "delete" | "reset_password"
 * - email: string (required for all actions)
 * - name: string (required for create and edit)
 * - phoneNumber: string (optional for create and edit)
 * - isDisabled: boolean (required for disable action)
 * - isDeleted: boolean (required for delete action)
 * 
 * Returns:
 * - uid: Firebase Auth user ID
 * - message: Success message
 * - action: The action performed
 */
export const manageSuperAdmin = onCall(
  { secrets: [POSTMARK_SERVER_TOKEN] },
  async (request) => {
    const { auth, data } = request;

    // Security: Only super admins can manage super admin accounts
    if (!auth) {
      throw new HttpsError("unauthenticated", "Authentication required");
    }

    try {
      const db = getFirestore();
      const userDoc = await db.collection("users").doc(auth.uid).get();

      if (!userDoc.exists || userDoc.data()?.role !== "super_admin") {
        throw new HttpsError(
          "permission-denied",
          "Only super admins can manage super admin accounts"
        );
      }
    } catch (error) {
      logger.error("Error checking admin permissions:", error);
      throw new HttpsError("internal", "Failed to verify permissions");
    }

    // Validate action
    const { action, email } = data;

    if (!action || typeof action !== "string") {
      throw new HttpsError("invalid-argument", "Valid action is required");
    }

    const validActions = ["create", "edit", "disable", "delete", "reset_password"];
    if (!validActions.includes(action)) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid action. Must be one of: ${validActions.join(", ")}`
      );
    }

    if (!email || typeof email !== "string") {
      throw new HttpsError("invalid-argument", "Valid email is required");
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      throw new HttpsError("invalid-argument", "Invalid email format");
    }

    const authService = getAuth();
    const db = getFirestore();

    try {
      // Handle different actions
      switch (action) {
        case "create":
          return await handleCreate(authService, db, data);
        case "edit":
          return await handleEdit(authService, db, data);
        case "disable":
          return await handleDisable(authService, db, data);
        case "delete":
          return await handleDelete(db, data);
        case "reset_password":
          return await handleResetPassword(authService, db, data);
        default:
          throw new HttpsError("invalid-argument", "Invalid action");
      }
    } catch (error) {
      logger.error(`Error in manageSuperAdmin (${action}):`, error);

      // Handle specific Firebase Auth errors
      if (error.code === "auth/email-already-exists") {
        throw new HttpsError(
          "already-exists",
          "An account with this email already exists"
        );
      }

      if (error.code === "auth/invalid-email") {
        throw new HttpsError("invalid-argument", "Invalid email format");
      }

      if (error.code === "auth/operation-not-allowed") {
        throw new HttpsError(
          "failed-precondition",
          "Email/password accounts are not enabled"
        );
      }

      if (error.code === "auth/user-not-found") {
        throw new HttpsError("not-found", "User not found");
      }

      // Rethrow HttpsError as is
      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        "internal",
        `Failed to ${action} super admin account: ${error.message}`
      );
    }
  }
);

/**
 * Handle CREATE action - creates new super admin
 */
async function handleCreate(authService, db, data) {
  const { email, name } = data;

  if (!name || typeof name !== "string") {
    throw new HttpsError("invalid-argument", "Valid name is required for create");
  }

  // Get Postmark token
  const token = (POSTMARK_SERVER_TOKEN.value() || "").trim();
  if (!token) {
    throw new HttpsError(
      "failed-precondition",
      "POSTMARK_SERVER_TOKEN missing/empty at runtime."
    );
  }

  const postmarkClient = new postmark.ServerClient(token);

  let userRecord;
  let resetLink;
  let isExistingUser = false;

  try {
    // Check if user already exists
    const existingUser = await authService.getUserByEmail(email);
    logger.info(`User already exists with email: ${email}`);

    userRecord = existingUser;
    isExistingUser = true;

    // Update their custom claims to include super admin role
    await authService.setCustomUserClaims(existingUser.uid, {
      role: "super_admin",
    });

    // Generate password reset link
    resetLink = await authService.generatePasswordResetLink(email);
    logger.info(`Password reset link generated for existing user: ${email}`);
  } catch (userNotFoundError) {
    // User doesn't exist, create new one
    logger.info(`Creating new super admin user for: ${email}`);

    // Create Firebase Auth user
    userRecord = await authService.createUser({
      email: email,
      displayName: name,
      emailVerified: false,
    });

    logger.info(`Created Firebase Auth user: ${userRecord.uid}`);

    // Set custom claims for role-based access
    await authService.setCustomUserClaims(userRecord.uid, {
      role: "super_admin",
    });

    logger.info(`Set custom claims for user: ${userRecord.uid}`);

    // Generate password reset link
    resetLink = await authService.generatePasswordResetLink(email);
    logger.info(`Password reset link generated for: ${email}`);
  }

  // Create Firestore document in users collection
  const userDocRef = db.collection("users").doc(userRecord.uid);
  const userData = {
    docId: userRecord.uid,
    superAdminId: userRecord.uid,
    name: name,
    email: email,
    phoneNumber: data.phoneNumber || null,
    role: "super_admin",
    isDisabled: false,
    isBlocked: false,
    createdAt: new Date(),
    modifiedAt: new Date(),
  };

  await userDocRef.set(userData, { merge: true });
  logger.info(`Created/Updated Firestore user document for: ${userRecord.uid}`);

  // Send email via Postmark
  const subject = "Welcome to Trax Admin Portal - Set Up Your Password";

  const textBody =
    `Hello ${name},\n\n` +
    `Your Super Admin account has been created for the Trax Admin Portal. Please click the link below to set up your password:\n\n` +
    `${resetLink}\n\n` +
    `This link will expire in 1 hour.\n\n` +
    `Once you've set your password, you'll be able to log in to the admin portal.\n\n` +
    `— ${FROM_NAME}`;

  const htmlBody = `
    <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
      <h2 style="color: #2563eb;">Welcome to Trax Admin Portal</h2>
      <p>Hello ${name},</p>
      <p>Your Super Admin account has been created. Please click the button below to set up your password:</p>
      
      <p style="margin: 24px 0;">
        <a href="${resetLink}" style="display:inline-block;padding:12px 24px;background:#2563eb;color:#fff;text-decoration:none;border-radius:6px;font-weight:bold;">
          Set Up Password
        </a>
      </p>
      
      <p style="color:#6b7280;font-size:14px;">
        If the button doesn't work, copy and paste this link into your browser:<br/>
        <a href="${resetLink}" style="color:#2563eb;">${resetLink}</a>
      </p>
      
      <hr style="border:none;border-top:1px solid #e5e7eb;margin:24px 0;">
      
      <p>After setting up your password, access the Admin Portal here:</p>
      
      <p style="margin: 24px 0;">
        <a href="https://trax-admin-portal.web.app" style="display:inline-block;padding:12px 24px;background:#10b981;color:#fff;text-decoration:none;border-radius:6px;font-weight:bold;">
          Open Admin Portal
        </a>
      </p>
      
      <p style="color:#6b7280;font-size:14px;">
        If the button doesn't work, copy and paste this link into your browser:<br/>
        <a href="https://trax-admin-portal.web.app" style="color:#2563eb;">https://trax-admin-portal.web.app</a>
      </p>
      
      <p style="color:#6b7280;font-size:13px;margin-top:20px;">
        <strong>Note:</strong> This link will expire in 1 hour for security reasons.
      </p>
      
      <p style="margin-top:24px;">As a Super Admin, you have full access to manage the portal.</p>
      
      <hr style="border:none;border-top:1px solid #e5e7eb;margin:24px 0;">
      
      <p style="color:#6b7280;font-size:12px;">
        — ${FROM_NAME}<br/>
        <a href="mailto:${FROM_EMAIL}" style="color:#2563eb;">${FROM_EMAIL}</a>
      </p>
    </div>
  `;

  try {
    const emailResult = await postmarkClient.sendEmail({
      From: FROM_EMAIL,
      To: email,
      Subject: subject,
      TextBody: textBody,
      HtmlBody: htmlBody,
      MessageStream: "outbound",
    });

    logger.info(`Password setup email sent successfully to ${email}`, {
      messageId: emailResult.MessageID,
    });
  } catch (emailError) {
    logger.error(`Failed to send email to ${email}:`, emailError);
    throw new HttpsError(
      "internal",
      `Account created but failed to send email: ${emailError.message}`
    );
  }

  return {
    uid: userRecord.uid,
    message: isExistingUser
      ? "User already exists. Updated to super admin and password setup email sent."
      : "Super admin account created successfully. Password setup email sent.",
    action: "create",
    alreadyExists: isExistingUser,
  };
}

/**
 * Handle EDIT action - updates super admin information
 */
async function handleEdit(authService, db, data) {
  const { email, name } = data;

  if (!name || typeof name !== "string") {
    throw new HttpsError("invalid-argument", "Valid name is required for edit");
  }

  // Find user by email
  let userRecord;
  try {
    userRecord = await authService.getUserByEmail(email);
  } catch (error) {
    throw new HttpsError("not-found", `User with email ${email} not found`);
  }

  // Update Firestore document
  const userDocRef = db.collection("users").doc(userRecord.uid);
  const userDoc = await userDocRef.get();

  if (!userDoc.exists) {
    throw new HttpsError("not-found", "User document not found in Firestore");
  }

  if (userDoc.data()?.role !== "super_admin") {
    throw new HttpsError("permission-denied", "User is not a super admin");
  }

  const updateData = {
    name: name,
    email: email,
    modifiedAt: new Date(),
  };

  // Add optional fields if provided
  if (data.phoneNumber !== undefined) updateData.phoneNumber = data.phoneNumber || null;

  await userDocRef.update(updateData);
  logger.info(`Updated super admin document for: ${userRecord.uid}`);

  // Update display name in Firebase Auth if changed
  if (userRecord.displayName !== name) {
    await authService.updateUser(userRecord.uid, {
      displayName: name,
    });
    logger.info(`Updated display name in Auth for: ${userRecord.uid}`);
  }

  return {
    uid: userRecord.uid,
    message: "Super admin updated successfully",
    action: "edit",
  };
}

/**
 * Handle DISABLE action - disables/enables user (prevents login but remains visible)
 */
async function handleDisable(authService, db, data) {
  const { email, isDisabled } = data;

  if (typeof isDisabled !== "boolean") {
    throw new HttpsError("invalid-argument", "isDisabled must be a boolean");
  }

  // Find user by email using Auth
  let userRecord;
  try {
    userRecord = await authService.getUserByEmail(email);
  } catch (error) {
    throw new HttpsError("not-found", `User with email ${email} not found`);
  }

  // Update Firestore document
  const userDocRef = db.collection("users").doc(userRecord.uid);
  const userDoc = await userDocRef.get();

  if (!userDoc.exists) {
    throw new HttpsError("not-found", "User document not found in Firestore");
  }

  if (userDoc.data()?.role !== "super_admin") {
    throw new HttpsError("permission-denied", "User is not a super admin");
  }

  await userDocRef.update({
    isDisabled: isDisabled,
    modifiedAt: new Date(),
  });

  // Also disable/enable the Firebase Auth account to prevent login
  await authService.updateUser(userRecord.uid, {
    disabled: isDisabled,
  });

  logger.info(`${isDisabled ? "Disabled" : "Enabled"} super admin: ${userRecord.uid}`);

  return {
    uid: userRecord.uid,
    message: `Super admin ${isDisabled ? "disabled" : "enabled"} successfully`,
    action: "disable",
    isDisabled: isDisabled,
  };
}

/**
 * Handle DELETE action - soft delete in Firestore + remove from Firebase Auth
 * When deleting (isDeleted=true):
 *   - Sets isDeleted flag in Firestore (for record keeping)
 *   - Completely removes user from Firebase Authentication
 * When restoring (isDeleted=false):
 *   - Updates isDeleted flag back to false in Firestore
 *   - Note: Cannot restore Firebase Auth user - they need to be recreated
 */
async function handleDelete(db, data) {
  const { email, isDeleted } = data;

  if (typeof isDeleted !== "boolean") {
    throw new HttpsError("invalid-argument", "isDeleted must be a boolean");
  }

  // Find user by email using Auth
  const authService = getAuth();
  let userRecord;
  try {
    userRecord = await authService.getUserByEmail(email);
  } catch (error) {
    if (isDeleted) {
      // If deleting and user not found in Auth, that's okay - might already be deleted
      throw new HttpsError("not-found", `User with email ${email} not found in Authentication`);
    } else {
      // If restoring and user not found, throw error
      throw new HttpsError("not-found", `User with email ${email} not found in Authentication. Cannot restore - user needs to be recreated.`);
    }
  }

  // Update Firestore document
  const userDocRef = db.collection("users").doc(userRecord.uid);
  const userDoc = await userDocRef.get();

  if (!userDoc.exists) {
    throw new HttpsError("not-found", "User document not found in Firestore");
  }

  if (userDoc.data()?.role !== "super_admin") {
    throw new HttpsError("permission-denied", "User is not a super admin");
  }

  // Update Firestore with soft delete flag
  await userDocRef.update({
    isDeleted: isDeleted,
    modifiedAt: new Date(),
  });

  // Handle Firebase Auth deletion/restoration
  if (isDeleted) {
    // When deleting, completely remove the user from Firebase Authentication
    await authService.deleteUser(userRecord.uid);
    logger.info(`Deleted super admin from Firebase Auth: ${userRecord.uid}`);
  } else {
    // When restoring, just update Firestore
    // Note: Cannot restore Firebase Auth user - they would need to be recreated
    logger.info(`Restored super admin in Firestore (Auth account needs recreation): ${userRecord.uid}`);
  }

  return {
    uid: userRecord.uid,
    message: `Super admin ${isDeleted ? "deleted" : "restored"} successfully`,
    action: "delete",
    isDeleted: isDeleted,
  };
}

/**
 * Handle RESET_PASSWORD action - sends password reset email to super admin
 */
async function handleResetPassword(authService, db, data) {
  const { email } = data;

  logger.info(`Resetting password for super admin: ${email}`);

  // Check if user exists
  let userRecord;
  try {
    userRecord = await authService.getUserByEmail(email);
  } catch (error) {
    throw new HttpsError("not-found", `User with email ${email} not found`);
  }

  // Verify user is a super admin in Firestore
  const userDocRef = db.collection("users").doc(userRecord.uid);
  const userDoc = await userDocRef.get();

  if (!userDoc.exists) {
    throw new HttpsError("not-found", "User document not found in Firestore");
  }

  if (userDoc.data()?.role !== "super_admin") {
    throw new HttpsError("permission-denied", "User is not a super admin");
  }

  const userData = userDoc.data();
  const name = userData.name || "Admin";

  // Generate password reset link
  let resetLink;
  try {
    resetLink = await authService.generatePasswordResetLink(email);
    logger.info(`Password reset link generated for: ${email}`);
  } catch (error) {
    logger.error("Error generating password reset link:", error);
    throw new HttpsError(
      "internal",
      "Failed to generate password reset link"
    );
  }

  // Send email via Postmark
  const token = (POSTMARK_SERVER_TOKEN.value() || "").trim();
  if (!token) {
    throw new HttpsError(
      "failed-precondition",
      "POSTMARK_SERVER_TOKEN is not configured"
    );
  }

  const client = new postmark.ServerClient(token);
  const subject = "Reset Your Trax Admin Portal Password";

  const textBody =
    `Hello ${name},\n\n` +
    `A password reset has been requested for your Trax Admin Portal account. ` +
    `Please click the link below to reset your password:\n\n` +
    `${resetLink}\n\n` +
    `This link will expire in 1 hour.\n\n` +
    `If you didn't request this password reset, you can safely ignore this email.\n\n` +
    `— ${FROM_NAME}`;

  const htmlBody = `
    <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
      <h2 style="color: #2563eb;">Reset Your Password</h2>
      <p>Hello ${name},</p>
      <p>A password reset has been requested for your Trax Admin Portal account.</p>
      <p>Please click the button below to reset your password:</p>
      <p style="margin: 25px 0;">
        <a href="${resetLink}" 
           style="background-color: #2563eb; color: white; padding: 12px 24px; 
                  text-decoration: none; border-radius: 5px; display: inline-block;">
          Reset Password
        </a>
      </p>
      <p style="color: #666; font-size: 14px;">
        Or copy and paste this link into your browser:<br>
        <a href="${resetLink}" style="color: #2563eb;">${resetLink}</a>
      </p>
      <p style="color: #666; font-size: 14px;">
        This link will expire in 1 hour.
      </p>
      <p style="color: #999; font-size: 12px; margin-top: 30px;">
        If you didn't request this password reset, you can safely ignore this email.
      </p>
      <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
      <p style="color: #999; font-size: 12px;">
        — ${FROM_NAME}
      </p>
    </div>
  `;

  try {
    await client.sendEmail({
      From: `${FROM_NAME} <${FROM_EMAIL}>`,
      To: email,
      Subject: subject,
      TextBody: textBody,
      HtmlBody: htmlBody,
    });

    logger.info(`Password reset email sent to: ${email}`);
  } catch (error) {
    logger.error("Error sending password reset email:", error);
    throw new HttpsError("internal", "Failed to send password reset email");
  }

  return {
    uid: userRecord.uid,
    message: "Password reset email sent successfully",
    action: "reset_password",
    email: email,
  };
}
