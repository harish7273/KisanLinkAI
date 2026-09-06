const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/*
 * ============================================================
 * Vidhai - Farmer New Order Push Notification
 * ============================================================
 *
 * Trigger:
 *
 * notifications/{notificationId}
 *
 * Whenever Flutter creates a notification document,
 * this function gets the farmer's FCM token and sends
 * an Android push notification.
 *
 * ============================================================
 */

exports.sendFarmerOrderNotification = onDocumentCreated(
    "notifications/{notificationId}",
    async (event) => {
      try {
      // ========================================================
      // GET NOTIFICATION
      // ========================================================

        const snapshot = event.data;

        if (!snapshot) {
          console.log(
              "No notification document found.",
          );
          return;
        }

        const notification =
        snapshot.data();

        console.log(
            "========================================",
        );

        console.log(
            "NEW VIDHAI NOTIFICATION",
        );

        console.log(
            "Notification ID:",
            event.params.notificationId,
        );

        console.log(
            "Type:",
            notification.type,
        );

        console.log(
            "Recipient:",
            notification.recipientId,
        );

        console.log(
            "Title:",
            notification.title,
        );

        console.log(
            "Message:",
            notification.message,
        );

        console.log(
            "========================================",
        );

        // ========================================================
        // ONLY PROCESS NEW ORDERS
        // ========================================================

        if (
          notification.type !==
        "new_order"
        ) {
          console.log(
              "Not a new-order notification.",
          );

          return;
        }

        // ========================================================
        // FARMER UID
        // ========================================================

        const farmerId =
        notification.recipientId;

        if (!farmerId) {
          console.log(
              "Farmer ID missing.",
          );

          return;
        }

        // ========================================================
        // GET FARMER USER DOCUMENT
        // ========================================================

        const farmerSnapshot =
        await db
            .collection("users")
            .doc(farmerId)
            .get();

        if (!farmerSnapshot.exists) {
          console.log(
              "Farmer user does not exist:",
              farmerId,
          );

          return;
        }

        const farmer =
        farmerSnapshot.data();

        // ========================================================
        // CHECK ROLE
        // ========================================================

        if (
          farmer.role &&
        farmer.role !== "farmer"
        ) {
          console.log(
              "Recipient is not a farmer.",
          );

          return;
        }

        // ========================================================
        // GET FCM TOKEN
        // ========================================================

        const fcmToken =
        farmer.fcmToken;

        if (!fcmToken) {
          console.log(
              "No FCM token found for farmer:",
              farmerId,
          );

          return;
        }

        console.log(
            "Farmer FCM token found.",
        );

        // ========================================================
        // CREATE FCM MESSAGE
        // ========================================================

        const message = {
          token: fcmToken,

          notification: {
            title:
            notification.title ||
            "New Order",

            body:
            notification.message ||
            "You received a new order.",
          },

          data: {
            type:
            String(
                notification.type ||
              "new_order",
            ),

            orderId:
            String(
                notification.orderId ||
              "",
            ),

            recipientId:
            String(
                farmerId,
            ),
          },

          android: {
            priority: "high",

            notification: {
              channelId:
              "vidhai_orders",

              sound: "default",

              priority: "high",

              defaultVibrateTimings: true,
            },
          },
        };

        // ========================================================
        // SEND PUSH NOTIFICATION
        // ========================================================

        const response =
        await messaging.send(
            message,
        );

        console.log(
            "========================================",
        );

        console.log(
            "FCM NOTIFICATION SENT SUCCESSFULLY",
        );

        console.log(
            "FCM Message ID:",
            response,
        );

        console.log(
            "========================================",
        );

        // ========================================================
        // UPDATE FIRESTORE
        // ========================================================

        await snapshot.ref.update({
          pushSent: true,

          pushSentAt:
          new Date(),

          fcmMessageId:
          response,
        });

        console.log(
            "Notification marked as sent.",
        );
      } catch (error) {
        console.error(
            "========================================",
        );

        console.error(
            "FCM NOTIFICATION ERROR",
        );

        console.error(error);

        console.error(
            "========================================",
        );
      }
    },
);
