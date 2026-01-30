/**
 * Cleanup script for duplicate sales person accounts
 * Run this locally to remove duplicate Firebase Auth users
 * 
 * Usage: node cleanupDuplicateUsers.js <email>
 */

import admin from "firebase-admin";
import { readFileSync } from "fs";

// Initialize Firebase Admin
const serviceAccount = JSON.parse(
  readFileSync("./serviceAccountKey.json", "utf8")
);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const email = process.argv[2];

if (!email) {
  console.error("Usage: node cleanupDuplicateUsers.js <email>");
  process.exit(1);
}

async function cleanupDuplicates() {
  try {
    console.log(`Looking for user with email: ${email}`);
    
    const authService = admin.auth();
    const db = admin.firestore();

    // Get the user from Firebase Auth
    const user = await authService.getUserByEmail(email);
    console.log(`Found user in Firebase Auth: ${user.uid}`);
    
    // Check if user document exists in Firestore
    const userDoc = await db.collection("users").doc(user.uid).get();
    
    if (userDoc.exists) {
      const userData = userDoc.data();
      console.log(`User document in Firestore:`, userData);
      console.log(`Role: ${userData.role}`);
      console.log(`Created: ${userData.createdAt || "N/A"}`);
    } else {
      console.log(`No user document found in Firestore for UID: ${user.uid}`);
    }

    // Ask for confirmation before deleting
    console.log("\n⚠️  Do you want to delete this user? (yes/no)");
    
    process.stdin.once("data", async (data) => {
      const response = data.toString().trim().toLowerCase();
      
      if (response === "yes") {
        try {
          // Delete from Firebase Auth
          await authService.deleteUser(user.uid);
          console.log(`✓ Deleted user from Firebase Auth: ${user.uid}`);
          
          // Delete from Firestore if exists
          if (userDoc.exists) {
            await db.collection("users").doc(user.uid).delete();
            console.log(`✓ Deleted user document from Firestore: ${user.uid}`);
          }
          
          console.log("\n✅ User deleted successfully!");
        } catch (error) {
          console.error("❌ Error deleting user:", error);
        }
      } else {
        console.log("Deletion cancelled.");
      }
      
      process.exit(0);
    });

  } catch (error) {
    if (error.code === "auth/user-not-found") {
      console.log("No user found with this email.");
    } else {
      console.error("Error:", error);
    }
    process.exit(1);
  }
}

cleanupDuplicates();
