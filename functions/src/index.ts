import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import * as logger from "firebase-functions/logger";

admin.initializeApp();

const LIVREUR_EMAIL_DOMAIN = "@dksoft-market-livreur.app";

export const setLivreurRoleClaim = functions.auth
  .user()
  .onCreate(async (user) => {
    const email = user.email;

    if (!email || !email.endsWith(LIVREUR_EMAIL_DOMAIN)) {
      logger.info(
        `User ${user.uid}: email does not match the livreur domain. ` +
          "No claim set — treated as a non-livreur account.",
      );
      return;
    }

    try {
      await admin.auth().setCustomUserClaims(user.uid, {role: "livreur"});
      logger.info(`Custom claim role='livreur' set for user ${user.uid}.`);
    } catch (error) {
      logger.error(`Error setting custom claims for user ${user.uid}:`, error);
    }
  });
