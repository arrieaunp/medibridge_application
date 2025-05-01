require("dotenv").config({ path: "../.env" }); 

const admin = require("firebase-admin");

admin.initializeApp({
  credential: admin.credential.cert({
    projectId: process.env.GCP_PROJECT_ID,
    clientEmail: process.env.GCP_CLIENT_EMAIL,
    privateKey: process.env.GCP_PRIVATE_KEY.replace(/\\n/g, '\n'),
  }),
});

module.exports = admin;
