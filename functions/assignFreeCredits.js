// functions/assignFreeCredits.js
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { FieldValue } from "firebase-admin/firestore";
import { db } from "./admin.js";

/**
 * Cloud function to assign free event credits to an organisation.
 * Only super admins can use this function.
 * 
 * Request data:
 * - organisationId: string (required) - The organisation to assign credits to
 * - events: number (required) - Number of free events to assign (must be positive)
 * - note: string (optional) - A note explaining why credits were assigned
 * 
 * Returns:
 * - success: boolean
 * - paymentId: string - The ID of the created payment record
 * - message: string
 */
export const assignFreeCredits = onCall(async (request) => {
  // Verify user is authenticated
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }

  const { organisationId, events, note } = request.data || {};

  // Validate required fields
  if (!organisationId || typeof organisationId !== "string" || !organisationId.trim()) {
    throw new HttpsError("invalid-argument", "organisationId is required");
  }

  if (!events || typeof events !== "number" || events <= 0 || !Number.isInteger(events)) {
    throw new HttpsError("invalid-argument", "events must be a positive integer");
  }

  // Verify the caller is a super admin
  const userSnap = await db.collection("users").doc(request.auth.uid).get();
  
  if (!userSnap.exists) {
    throw new HttpsError("permission-denied", "User profile not found");
  }

  const user = userSnap.data() || {};
  const userRole = (user.role || "").toString().trim();
  
  if (userRole !== "super_admin") {
    console.error(`❌ Permission denied: User ${request.auth.uid} with role "${userRole}" attempted to assign free credits`);
    throw new HttpsError("permission-denied", "Only super admins can assign free credits");
  }

  // Verify the organisation exists
  const orgSnap = await db.collection("organisations").doc(organisationId.trim()).get();
  
  if (!orgSnap.exists) {
    throw new HttpsError("not-found", "Organisation not found");
  }

  const orgData = orgSnap.data() || {};
  const orgName = orgData.name || orgData.companyName || "Unknown Organisation";

  try {
    const adminEmail = request.auth.token.email || user.email || "unknown";
    const adminName = user.name || user.displayName || adminEmail;

    // Create the payment/credit record
    const paymentData = {
      // Transaction information
      transactionId: `FREE_CREDIT_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      paymentIntentId: null, // No Stripe payment
      stripeCustomerId: null, // No Stripe customer
      
      // Organisation information
      organisationId: organisationId.trim(),
      companyId: organisationId.trim(), // Alias for organisationId
      organisationName: orgName,
      
      // Credit details
      events: events,
      amount: 0, // Free - no charge
      currency: "usd",
      paymentStatus: "completed", // Immediately completed since it's free
      
      // Type flags - THIS IS THE KEY FIELD
      isAssignedBySuperAdmin: true,
      isFreeCredit: true,
      
      // Product information
      productName: "Free Event Credits",
      packageName: `${events} Free Event${events > 1 ? "s" : ""} - Assigned by Admin`,
      
      // Admin who assigned the credits
      assignedByUserId: request.auth.uid,
      assignedByEmail: adminEmail,
      assignedByName: adminName,
      
      // Optional note
      note: note ? note.toString().trim() : null,
      
      // User info (null since it's admin-assigned)
      userEmail: null,
      userId: null,
      
      // Status flags
      isDisabled: false,
      
      // Timestamps
      createdAt: FieldValue.serverTimestamp(),
      modifiedAt: FieldValue.serverTimestamp(),
      
      // No Stripe URLs for free credits
      receiptUrl: null,
      
      // Metadata
      metadata: {
        type: "free_credit",
        assignedBy: adminEmail,
        reason: note || "Assigned by super admin",
      },
    };

    // Save to Firestore payments collection
    const paymentRef = await db.collection("payments").add(paymentData);
    
    console.log(`✅ Free credits assigned successfully`);
    console.log(`   Payment ID: ${paymentRef.id}`);
    console.log(`   Organisation: ${orgName} (${organisationId})`);
    console.log(`   Events: ${events}`);
    console.log(`   Assigned by: ${adminEmail}`);

    // Optionally update organisation's total event balance
    // Uncomment if you want to track running balance on the org document
    /*
    await db.collection("organisations").doc(organisationId.trim()).update({
      availableEvents: FieldValue.increment(events),
      totalFreeCreditsReceived: FieldValue.increment(events),
      modifiedAt: FieldValue.serverTimestamp(),
    });
    */

    return {
      success: true,
      paymentId: paymentRef.id,
      transactionId: paymentData.transactionId,
      message: `Successfully assigned ${events} free event${events > 1 ? "s" : ""} to ${orgName}`,
      data: {
        organisationId: organisationId.trim(),
        organisationName: orgName,
        events: events,
        assignedBy: adminEmail,
        createdAt: new Date().toISOString(),
      },
    };

  } catch (error) {
    console.error("❌ Error assigning free credits:", error);
    throw new HttpsError("internal", "Failed to assign free credits: " + error.message);
  }
});
