import * as functions from "firebase-functions";
import * as admin from 'firebase-admin';
const nodemailer = require('nodemailer');
admin.initializeApp();

var transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true,
    auth: {
        user: 'ahsan386fast@gmail.com',
        pass: 'ygxnkyckrqvksinz'
    }
});

export const sendPushNotificationToArtist = functions.https.onRequest(async (request, response) => {
    functions.logger.info("Send Push Notification To Artist", {
        structuredData: true
    });
    var tokenList: string[] = [];
    await admin.firestore()
        .collection('Elocker')
        .where('artistId', '==', request.body.id)
        .get().then((docs) => {
            docs.forEach(async (doc) => {
                let fcmToken = doc.data().fcmToken;
                if (fcmToken.length > 10 && tokenList.includes(fcmToken) == false)
                    tokenList.push(fcmToken);
            });
        });
    const payload = {
        notification: {
            title: request.body.title,
            body: request.body.message
        }
    };
    try {
        await admin.messaging().sendToDevice(tokenList, payload);
        response.send("Notification sent!");
    } catch (e) {
        response.send(e);
    }
});

export const sendPushNotificationToUser = functions.https.onRequest(async (request, response) => {
    functions.logger.info("Send Push Notification To User", {
        structuredData: true
    });
    var tokenList: string[] = [];
    await admin.firestore()
        .collection('Users')
        .where('id', '==', request.body.id)
        .get().then((docs) => {
            docs.forEach(async (doc) => {
                let fcmToken = doc.data().fcmToken;
                if (fcmToken.length > 10 && tokenList.includes(fcmToken) == false)
                    tokenList.push(fcmToken);
            });
        });
    const payload = {
        notification: {
            title: request.body.title,
            body: request.body.message
        }
    };
    try {
        await admin.messaging().sendToDevice(tokenList, payload);
        response.send("Notification sent!");
    } catch (e) {
        response.send(e);
    }
});

export const sendPushNotificationToAllUsers = functions.https.onRequest(async (request, response) => {
    functions.logger.info("Send Push Notification To All User", {
        structuredData: true
    });
    var tokenList: string[] = [];
    await admin.firestore()
        .collection('Users')
        .get().then((docs) => {
            docs.forEach(async (doc) => {
                let fcmToken = doc.data().fcmToken;
                if (fcmToken.length > 10 && tokenList.includes(fcmToken) == false)
                    tokenList.push(fcmToken);
            });
        });
    const payload = {
        notification: {
            title: request.body.title,
            body: request.body.message
        }
    };
    try {
        await admin.messaging().sendToDevice(tokenList, payload);
        response.send("Notification sent!");
    } catch (e) {
        response.send(e);
    }
});

export const sendEmail = functions.https.onRequest(async (request, response) => {
    const mailOptions = {
        from: '***********',
        to: request.body.email,
        subject: 'Vizidot',
        html: 'Your Password for Vizidot ' + request.body.password + '.'
    };
    return transporter.sendMail(mailOptions, (error: any, data: any) => {
        if (error) {
            console.log(error)
            response.send(error);
            return
        }
        console.log("Sent!");
        response.send("Sent!");
    });
});