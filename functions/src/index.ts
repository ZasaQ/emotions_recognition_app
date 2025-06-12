/**
 * Import function triggers from their respective submodules:
 *
 * import {onCall} from "firebase-functions/v2/https";
 * import {onDocumentWritten} from "firebase-functions/v2/firestore";
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

import {onCall, onRequest, HttpsError} from "firebase-functions/v2/https";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

admin.initializeApp();

export const deleteFirebaseAuthUser = onCall(async (request) => {
  const uid = request.data.uid;
  if (!uid) {
    throw new HttpsError("invalid-argument", "Missing 'uid' in request data.");
  }

  try {
    await admin.auth().revokeRefreshTokens(uid);
    await admin.auth().deleteUser(uid);
    logger.info(`Successfully deleted user with UID: ${uid}`);
    return {success: true};
  } catch (error: unknown) {
    if (error instanceof Error) {
      logger.error(`Error deleting user with UID: ${uid}: ${error.message}`,
        error);
    } else {
      logger.error(`An unknown error occurred while deleting user with UID:
        ${uid}.`);
    }
    throw new HttpsError("internal", "Failed to delete user.");
  }
});

export const getData = onRequest((request, response) => {
  if (request.method !== "GET") {
    response.status(405).send("Method Not Allowed");
    return;
  }
  response.status(200).send("Hello! This is a GET request.");
});

export const postData = onRequest((request, response) => {
  if (request.method !== "POST") {
    response.status(405).send("Method Not Allowed");
    return;
  }

  const data = request.body;
  logger.info("Received POST data:", data);
  response.status(200).send(`Hello! Sending: ${JSON.stringify(data)}.`);
});


// Start writing functions
// https://firebase.google.com/docs/functions/typescript

// export const helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
