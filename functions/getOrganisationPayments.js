// functions/getOrganisationPayments.js
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { db } from "./admin.js";

/**
 * Cloud function to fetch payments/transactions for specified organisations.
 * 
 * Request data:
 * - organisationIds: Array of organisation IDs to fetch payments for
 * 
 * Returns:
 * - payments: Map of organisationId to array of payment documents
 */
export const getOrganisationPayments = onCall(async (request) => {
  // Verify user is authenticated
  if (!request.auth?.uid) {
    throw new HttpsError("unauthenticated", "Sign in required");
  }

  const organisationIds = request.data?.organisationIds;

  if (!organisationIds || !Array.isArray(organisationIds) || organisationIds.length === 0) {
    throw new HttpsError("invalid-argument", "organisationIds array is required");
  }

  // Check if user has permission to view payments
  // User must be either a super admin or belong to one of the organisations
  const userSnap = await db.collection("users").doc(request.auth.uid).get();
  const user = userSnap.exists ? (userSnap.data() || {}) : {};
  const userRole = (user.role || "").toString().trim();
  const userOrgId = (user.organisationId || "").toString().trim();

  const isSuperAdmin = userRole === "super_admin";

  // Check if user is a salesperson (now stored in users collection with role = sales_person)
  // Sales people are active if they are not disabled
  const isSalesPerson = userRole === "sales_person" && 
    user.isDisabled !== true;

  // Regular users can only view their own organisation's payments
  if (!isSuperAdmin && !isSalesPerson) {
    if (!userOrgId || !organisationIds.includes(userOrgId)) {
      throw new HttpsError("permission-denied", "You don't have permission to view these payments");
    }
    // Filter to only include user's own organisation
    organisationIds.length = 0;
    organisationIds.push(userOrgId);
  }

  try {
    // Firestore 'in' queries are limited to 30 items, so we need to batch
    const batchSize = 30;
    const payments = {};

    // Initialize empty arrays for all requested organisation IDs
    for (const orgId of organisationIds) {
      payments[orgId] = [];
    }

    // Process in batches
    for (let i = 0; i < organisationIds.length; i += batchSize) {
      const batch = organisationIds.slice(i, i + batchSize);
      
      const querySnapshot = await db.collection("payments")
        .where("organisationId", "in", batch)
        .orderBy("createdAt", "desc")
        .get();

      querySnapshot.forEach((doc) => {
        const data = doc.data();
        const orgId = data.organisationId;
        
        if (orgId && payments[orgId] !== undefined) {
          payments[orgId].push({
            id: doc.id,
            transactionId: data.transactionId,
            organisationId: data.organisationId,
            organisationName: data.organisationName || null,
            events: data.events,
            amount: data.amount,
            currency: data.currency || 'usd',
            paymentStatus: data.paymentStatus,
            packageName: data.packageName,
            productName: data.productName,
            userEmail: data.userEmail,
            userId: data.userId,
            // Timestamps - convert Firestore timestamps to ISO strings
            createdAt: data.createdAt?.toDate?.()?.toISOString() || data.createdAt,
            modifiedAt: data.modifiedAt?.toDate?.()?.toISOString() || data.modifiedAt,
            isDisabled: data.isDisabled || false,
            // Free credit fields
            isAssignedBySuperAdmin: data.isAssignedBySuperAdmin || false,
            isFreeCredit: data.isFreeCredit || false,
            assignedByEmail: data.assignedByEmail || null,
            assignedByName: data.assignedByName || null,
            assignedByUserId: data.assignedByUserId || null,
            note: data.note || null,
            // Stripe fields (null for free credits)
            paymentIntentId: data.paymentIntentId || null,
            stripeCustomerId: data.stripeCustomerId || null,
            receiptUrl: data.receiptUrl || null,
          });
        }
      });
    }

    console.log(`Fetched payments for ${organisationIds.length} organisations`);

    return {
      success: true,
      payments: payments,
    };

  } catch (error) {
    console.error("Error fetching payments:", error);
    throw new HttpsError("internal", "Failed to fetch payments: " + error.message);
  }
});
