const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
const serviceAccount = require('/Users/elebi/Documents/AfrikaNaOne/afrikanaone-1e89f4424bbb.json'); // Replace with your actual file path
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://afrikanaone-default-rtdb.firebaseio.com",
});

const db = admin.firestore();

async function updateArtsAndLiteratureCollection() {
  try {
    const collectionRef = db.collection("ARTS & LITERATURE");

    // Get all documents in the collection
    const snapshot = await collectionRef.get();

    if (snapshot.empty) {
      console.log("No documents found in ARTS & LITERATURE collection.");
      return;
    }

    snapshot.forEach(async (doc) => {
      const docRef = collectionRef.doc(doc.id);

      // Update the IMAGE field
      await docRef.update({
        IMAGE: "gs://afrikanaone.firebasestorage.app/Arts & Literature.png"
      });

      console.log(`Updated IMAGE field for document ID: ${doc.id}`);

      // Check if the incorrect 'image' field exists, and delete it
      const data = doc.data();
      if (data.image) {
        await docRef.update({
          image: admin.firestore.FieldValue.delete()
        });
        console.log(`Deleted incorrect 'image' field for document ID: ${doc.id}`);
      }
    });
  } catch (error) {
    console.error("Error updating ARTS & LITERATURE collection:", error);
  }
}

// Run the script
updateArtsAndLiteratureCollection();