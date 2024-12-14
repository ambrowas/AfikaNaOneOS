const { onValueWritten } = require("firebase-functions/v2/database");
const { getDatabase } = require("firebase-admin/database");
const admin = require("firebase-admin");

admin.initializeApp();

const db = getDatabase();

exports.updateLeaderboard = onValueWritten("/user/{userId}/accumulatedPuntuacion", async (event) => {
  const after = event.data.after.val(); // New value
  const before = event.data.before.val(); // Previous value
  const context = event.params; // Context for params like userId
  const userId = context.userId;

  console.log(`Trigger fired for userId: ${userId}, before: ${before}, after: ${after}`);

  if (after === null) {
    console.log(`Puntuacion deleted for userId: ${userId}`);
    return null;
  }

  // Update scoreAchievedAt to the current timestamp if accumulatedPuntuacion changed
  if (after !== before) {
    try {
      const now = Date.now();
      await db.ref(`/user/${userId}`).update({
        scoreAchievedAt: now,
      });
      console.log(`Updated scoreAchievedAt for userId: ${userId} to ${now}`);
    } catch (error) {
      console.error(`Failed to update scoreAchievedAt for userId: ${userId}`, error);
    }
  }

  try {
    // Fetch all users ordered by accumulatedPuntuacion
    const snapshot = await db
      .ref("/user")
      .orderByChild("accumulatedPuntuacion")
      .once("value");

    const users = [];
    snapshot.forEach((childSnapshot) => {
      users.push({
        id: childSnapshot.key,
        ...childSnapshot.val(),
      });
    });

    // Sort users by accumulatedPuntuacion (descending), then by scoreAchievedAt (descending)
    users.sort((a, b) => {
      if (b.accumulatedPuntuacion === a.accumulatedPuntuacion) {
        const timeA = a.scoreAchievedAt || 0;
        const timeB = b.scoreAchievedAt || 0;
        return timeB - timeA; // Sort by timestamp (descending)
      }
      return b.accumulatedPuntuacion - a.accumulatedPuntuacion;
    });

    // Create updates for leaderboard positions
    const updates = {};
    users.forEach((user, index) => {
      const position = index + 1;
      updates[`${user.id}/positionInLeaderboard`] = position;
    });

    // Apply leaderboard updates
    await db.ref("/user").update(updates);

    console.log(`Leaderboard updated for ${users.length} users.`);
  } catch (error) {
    console.error("Error updating leaderboard:", error);
  }

  return null;
});