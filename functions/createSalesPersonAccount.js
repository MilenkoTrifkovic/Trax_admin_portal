import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import postmark from "postmark";

// Secret for Postmark API
const POSTMARK_SERVER_TOKEN = defineSecret("POSTMARK_SERVER_TOKEN");

// Email configuration
const FROM_EMAIL = "developer@trax-event.com";
const FROM_NAME = "Trax Sales Portal";

/**
 * Cloud function to create a sales person account
 * Creates Firebase Auth user, Firestore document, and sends password reset email
 * 
 * Expected request data:
 * - email: string (required)
 * - name: string (required)
 * - salesPersonId: string (required) - UUID for the user document
 * - refCode: string (required) - Unique reference code
 * - address: string (optional)
 * - city: string (optional)
 * - state: string (optional)
 * - country: string (optional)
 * - isResend: boolean (optional) - If true, allows resending to existing users
 * 
 * Returns:
 * - uid: Firebase Auth user ID
 * - message: Success message
 */
export const createSalesPersonAccount = onCall(
  { secrets: [POSTMARK_SERVER_TOKEN] },
  async (request) => {
  const { auth, data } = request;

  // Security: Only super admins can create sales person accounts
  if (!auth) {
    throw new HttpsError("unauthenticated", "Authentication required");
  }

  try {
    const db = getFirestore();
    const userDoc = await db.collection("users").doc(auth.uid).get();

    if (!userDoc.exists || userDoc.data()?.role !== "super_admin") {
      throw new HttpsError(
        "permission-denied",
        "Only super admins can create sales person accounts"
      );
    }
  } catch (error) {
    logger.error("Error checking admin permissions:", error);
    throw new HttpsError("internal", "Failed to verify permissions");
  }

  // Validate input
  const { email, name, salesPersonId, refCode, address, city, state, country, isResend } = data;

  if (!email || typeof email !== "string") {
    throw new HttpsError("invalid-argument", "Valid email is required");
  }

  if (!name || typeof name !== "string") {
    throw new HttpsError("invalid-argument", "Valid name is required");
  }

  if (!salesPersonId || typeof salesPersonId !== "string") {
    throw new HttpsError("invalid-argument", "Valid salesPersonId is required");
  }

  if (!refCode || typeof refCode !== "string") {
    throw new HttpsError("invalid-argument", "Valid refCode is required");
  }

  // Validate email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    throw new HttpsError("invalid-argument", "Invalid email format");
  }

  try {
    const authService = getAuth();
    const db = getFirestore();

    // Step 1: Check if email already exists in Firestore users collection
    logger.info(`Checking if user with email ${email} exists in Firestore`);
    const usersSnapshot = await db.collection("users")
      .where("email", "==", email)
      .limit(1)
      .get();

    const userExists = !usersSnapshot.empty;

    if (userExists && !isResend) {
      // Block creation if user exists and this is NOT a resend operation
      const existingUserData = usersSnapshot.docs[0].data();
      const existingRole = existingUserData.role || "unknown role";
      logger.warn(`User with email ${email} already exists in Firestore with role: ${existingRole}`);
      throw new HttpsError(
        "already-exists",
        `This email is already registered as ${existingRole}. Cannot create a sales person account.`
      );
    }

    if (userExists && isResend) {
      // This is a resend operation for an existing user
      logger.info(`Resending password setup email for existing user: ${email}`);
    } else {
      // This is a new user creation
      logger.info(`No existing user found in Firestore for ${email}, proceeding with creation`);
    }

    // Step 2: Get Postmark token
    const token = (POSTMARK_SERVER_TOKEN.value() || "").trim();
    if (!token) {
      throw new HttpsError(
        "failed-precondition",
        "POSTMARK_SERVER_TOKEN missing/empty at runtime."
      );
    }

    const postmarkClient = new postmark.ServerClient(token);

    // Step 3: Check if user exists in Firebase Auth, create if not
    let userRecord;
    let authUserExists = false;

    try {
      userRecord = await authService.getUserByEmail(email);
      authUserExists = true;
      logger.info(`User already exists in Firebase Auth: ${userRecord.uid}`);
    } catch (authError) {
      if (authError.code === "auth/user-not-found") {
        // User doesn't exist in Auth, create new one
        logger.info(`Creating new Firebase Auth user for: ${email}`);
        
        userRecord = await authService.createUser({
          email: email,
          displayName: name,
          emailVerified: false,
        });

        logger.info(`Created Firebase Auth user: ${userRecord.uid}`);
      } else {
        // Some other auth error, re-throw it
        throw authError;
      }
    }

    // Step 4: Set custom claims for role-based access
    await authService.setCustomUserClaims(userRecord.uid, {
      role: "sales_person",
      salesPersonId: salesPersonId,
    });

    logger.info(`Set custom claims for user: ${userRecord.uid}`);

    // Step 5: Create or update user document in Firestore
    if (isResend && userExists) {
      // For resend, only update modifiedAt timestamp and any changed fields
      logger.info(`Updating existing Firestore document for: ${userRecord.uid}`);
      await db.collection("users").doc(userRecord.uid).update({
        name: name, // Update name in case it changed
        modifiedAt: FieldValue.serverTimestamp(),
        // Optionally update address fields if provided
        ...(address !== undefined && { address: address || null }),
        ...(city !== undefined && { city: city || null }),
        ...(state !== undefined && { state: state || null }),
        ...(country !== undefined && { country: country || null }),
      });
      logger.info(`Updated Firestore user document for: ${userRecord.uid}`);
    } else {
      // For new users, create the full document
      logger.info(`Creating new Firestore document for: ${userRecord.uid}`);
      await db.collection("users").doc(userRecord.uid).set({
        email: email,
        name: name,
        role: "sales_person",
        salesPersonId: salesPersonId,
        refCode: refCode,
        address: address || null,
        city: city || null,
        state: state || null,
        country: country || null,
        createdAt: FieldValue.serverTimestamp(),
        modifiedAt: FieldValue.serverTimestamp(),
        emailVerified: false,
        isDisabled: false,
      });
      logger.info(`Created Firestore user document for: ${userRecord.uid}`);
    }

    // Step 6: Generate password reset code and construct custom domain link
    // Instead of using generatePasswordResetLink (which points to Firebase domain),
    // we generate the oobCode and construct a link to our custom domain
    logger.info(`Generating password reset code for: ${email}`);
    
    // Generate the password reset link with our custom domain
    const resetLink = await authService.generatePasswordResetLink(email);
    
    // Extract the oobCode from Firebase's link
    const url = new URL(resetLink);
    const oobCode = url.searchParams.get('oobCode');
    
    // Construct our custom domain link
    // const customResetLink = `https://trax-admin-portal.web.app/reset-password?oobCode=${oobCode}`;
    const customResetLink = `https://admin.trax-event.app/reset-password?oobCode=${oobCode}`;
    
    logger.info(`Custom password reset link generated for: ${email}`);

    // Send email via Postmark
    const subject = "Set Up Your Trax Sales Portal Password";
    
    const textBody =
      `Hello ${name},\n\n` +
      `Your Trax Sales Portal account has been created. Please click the link below to set up your password:\n\n` +
      `${customResetLink}\n\n` +
      `This link will expire in 1 hour.\n\n` +
      `Once you've set your password, you'll be able to log in to the sales portal.\n\n` +
      `— ${FROM_NAME}`;

    const htmlBody = `
      <div style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
        <h2 style="color: #2563eb;">Welcome to Trax Sales Portal</h2>
        <p>Hello ${name},</p>
        <p>Your Trax Sales Portal account has been created as a Sales Person. Please click the button below to set up your password:</p>
        
        <p style="margin: 24px 0;">
          <a href="${customResetLink}" style="display:inline-block;padding:12px 24px;background:#2563eb;color:#fff;text-decoration:none;border-radius:6px;font-weight:bold;">
            Set Up Password
          </a>
        </p>
        
        <p style="color:#6b7280;font-size:14px;">
          If the button doesn't work, copy and paste this link into your browser:<br/>
          <a href="${customResetLink}" style="color:#2563eb;">${customResetLink}</a>
        </p>
        
        <hr style="border:none;border-top:1px solid #e5e7eb;margin:24px 0;">
        
        <p>After setting up your password, access the Sales Portal here:</p>
        
        <p style="margin: 24px 0;">
          <a href="https://admin.trax-event.app" style="display:inline-block;padding:12px 24px;background:#10b981;color:#fff;text-decoration:none;border-radius:6px;font-weight:bold;">
            Open Sales Portal
          </a>
        </p>
        
        <p style="color:#6b7280;font-size:14px;">
          If the button doesn't work, copy and paste this link into your browser:<br/>
          <a href="https://admin.trax-event.app" style="color:#2563eb;">https://admin.trax-event.app</a>
        </p>
        
        <p style="color:#6b7280;font-size:13px;margin-top:20px;">
          <strong>Note:</strong> This link will expire in 1 hour for security reasons.
        </p>
        
        <p style="margin-top:24px;">Once you've set your password, you'll be able to log in to the sales portal and start managing your assignments.</p>
        
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
        to: emailResult.To,
        submittedAt: emailResult.SubmittedAt,
      });
    } catch (emailError) {
      logger.error(`Failed to send email to ${email}:`, {
        error: emailError.message,
        code: emailError.code,
        statusCode: emailError.statusCode,
      });
      throw new HttpsError(
        "internal",
        `Account created but failed to send email: ${emailError.message}`
      );
    }

    return {
      uid: userRecord.uid,
      message: isResend 
        ? "Password setup email resent successfully."
        : authUserExists 
          ? "Sales person added to Firestore. User already existed in Firebase Auth. Password setup email sent."
          : "Sales person account created successfully in both Firestore and Firebase Auth. Password setup email sent.",
      wasAlreadyInAuth: authUserExists,
      wasResend: isResend || false,
    };
  } catch (error) {
    logger.error("Error creating sales person account:", error);

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

    throw new HttpsError(
      "internal",
      `Failed to create sales person account: ${error.message}`
    );
  }
});
