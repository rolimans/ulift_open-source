process.env.TZ = 'America/Fortaleza'; //REMOVE THIS WHEN FIXED

const admin = require("firebase-admin");
const OneSignal = require('onesignal-node');
const TelegramBot = require('node-telegram-bot-api');
const fs = require('fs');
const schedule = require('node-schedule');

const startTime = new Date().getTime();
const bot = new TelegramBot("YOUR TELEGRAM API KEY", {polling: true});
var ids = [];

const myClient = new OneSignal.Client({
    userAuthKey: 'YOUR ONESIGNAL USER AUTH KEY',
    app: {appAuthKey: 'YOUR ONESIGNAL APP AUTH KEY', appId: "YOUR ONESIGNAL APP ID"}
});

var serviceAccount = require("./key.json");

admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: "YOUR DATABASE URL"
});

const db = admin.firestore();

var schedulesInitFrequent = {};
var schedulesHappenFrequent = {};
var schedulesEndFrequent = {};
var offersDocs = {};

var schedulesInitRides = {};
var schedulesEndRides = {};
var ridesDocs = {};

loadFromFile();
watchDriverRequests();
watchFeedbacks();
watchRides();
watchFrequentRides();
watchNotifications();


// *NOTIFPICATIONS*

async function watchNotifications() {
    db.collection('notifications').onSnapshot(querySnapshot => {
        querySnapshot.docChanges().forEach(change => {
            if (change.type === 'added') {
                let createTime = change.doc.createTime.toMillis();
                if (createTime >= startTime) {
                    let id = change.doc.id;
                    let obj = change.doc.data().obj;
                    let toWho = change.doc.data().toWho;
                    console.log(id);
                    console.log(obj);
                    console.log(toWho);
                    sendNotification(obj, id);
                }
            }
        });
    });
}

const sendNotification = (obj, id) => {
    obj.data.notificationId = id;
    var notification = new OneSignal.Notification({
        headings: {
            en: obj.title
        },
        contents: {
            en: obj.body,
        },
        android_channel_id: "YOUR ONESIGNAL ANDROID CHANNEL ID",
        priority: 10,
        url: obj.url,
        data: obj.data,
        buttons: obj.buttons,
        include_player_ids: obj.player_ids,
        large_icon: obj.large_icon,
        android_group: obj.android_group,
        android_group_message: obj.android_group_message
    });

    myClient.sendNotification(notification)
        .then((response) => {
            console.log(response.data, response.httpResponse.statusCode);
        })
        .catch((err) => {
            console.log('Something went wrong...', err);
        });
};

// *DRIVER REQUESTS*

async function watchDriverRequests() {
    db.collection("driverRequests").onSnapshot(querySnapshot => {
        querySnapshot.docChanges().forEach(async change => {
            if (change.type === "added") {
                let createTime = change.doc.updateTime.toMillis();
                if (createTime >= startTime) {
                    let requesterId = change.doc.id;
                    await sendTextMessage("New Driver Request From: " + requesterId + "!");
                    await sendTextMessage("Fetching Data...");
                    await getAndSendRequestData(change.doc.data(), change.doc.id);
                }

            } else if (change.type === "modified") {
                let createTime = change.doc.updateTime.toMillis();
                if (createTime >= startTime) {
                    await sendTextMessage("UNUSUAL BEHAVIOR 102");
                    let requesterId = change.doc.id;
                    await sendTextMessage("New Driver Request From: " + requesterId + "!");
                    await sendTextMessage("Fetching Data...");
                    await getAndSendRequestData(change.doc.data(), change.doc.id);

                }
            }
        });
    });
}

async function getAndSendRequestData(data, id) {
    let cpf = data.cpfUser;
    let cnh = data.cnhNumber;
    let cnhDate = data.cnhValidate;
    let front = data.frontUrl;
    let back = data.backUrl;
    let selfie = data.selfieUrl;
    await sendTextMessage("CPF:");
    await sendTextMessage(cpf);
    await sendTextMessage("Número CNH:");
    await sendTextMessage(cnh);
    await sendTextMessage("Data de Validade CNH:");
    await sendTextMessage(dateFormatted(dateFromSeconds(cnhDate.seconds)));
    await sendTextMessage("Foto da Frente:");
    await sendImageMessage(front);
    await sendTextMessage("Foto de Trás:");
    await sendImageMessage(back);
    await sendTextMessage("Foto Selfie:");
    await sendImageMessage(selfie);
    await sendTextMessage("Envie o comando /allow " + id + " para habilitá-lo!");
    await sendTextMessage("Envie o comando /deny " + id + " para deferi-lo!");
}

async function sendCurrentRequesters() {
    db.collection("driverRequests").get().then(async querySnapshot => {
        if (querySnapshot.docs.length === 0) {
            await sendTextMessage("No on going requests!");
        }
        for (var doc of querySnapshot.docs) {
            let requesterId = doc.id;
            // eslint-disable-next-line no-await-in-loop
            await sendTextMessage("Driver Request From: " + requesterId + "!");
            // eslint-disable-next-line no-await-in-loop
            await sendTextMessage("Fetching Data...");
            // eslint-disable-next-line no-await-in-loop
            await getAndSendRequestData(doc.data(), doc.id);
        }
    });
}

// *RIDES*

async function watchRides() {
    db.collection("rides").onSnapshot(querySnaphot => {
        querySnaphot.docChanges().forEach(async change => {
            if (change.type === "added") {
                ridesDocs[change.doc.id] = change.doc;
                let rideDate = new Date(change.doc.data().date);
                schedulesInitRides[change.doc.id] = schedule.scheduleJob(rideDate, function (rideDoc) {
                    rideDoc.ref.set({status: 1}, {merge: true});
                    let rideDuration = (ridesDocs[rideDoc.id] !== undefined && ridesDocs[rideDoc.id] !== null) ? ((ridesDocs[rideDoc.id].data().currentDuration) * 1000) : 0;
                    if (rideDuration > 1000) {
                        let startTime = new Date(Date.now() + rideDuration);
                        schedulesEndRides[rideDoc.id] = schedule.scheduleJob(startTime, function (rideDoc) {
                            rideDoc.ref.set({status: 3}, {merge: true});
                            schedulesEndRides[rideDoc.id] = undefined;
                        }.bind(null, rideDoc));
                    } else {
                        rideDoc.ref.set({status: 3}, {merge: true});
                        schedulesEndRides[rideDoc.id] = undefined;
                    }
                    schedulesInitRides[change.doc.id] = undefined;
                }.bind(null, change.doc));
            } else if (change.type === "modified") {
                if (change.doc.data().status >= 2) {
                    if (schedulesInitRides[change.doc.id] !== null && schedulesInitRides[change.doc.id] !== undefined) {
                        schedulesInitRides[change.doc.id].cancel();
                        schedulesInitRides[change.doc.id] = undefined;
                    }
                    if (schedulesEndRides[change.doc.id] !== null && schedulesEndRides[change.doc.id] !== undefined) {
                        schedulesEndRides[change.doc.id].cancel();
                        schedulesEndRides[change.doc.id] = undefined;
                    }
                } else {
                    ridesDocs[change.doc.id] = change.doc;
                }
            } else if (change.type === "removed") {
                ridesDocs[change.doc.id] = undefined;
                //ONLY DELETION IS TRHOUGH MODIFICATION
            }
        });
    });
}

// *FEEDBACKS*

async function watchFeedbacks() {
    db.collection("feedbacks").onSnapshot(querySnapshot => {
        querySnapshot.docChanges().forEach(async change => {
            if (change.type === "added") {
                let createTime = change.doc.updateTime.toMillis();
                if (createTime >= startTime) {
                    let data = change.doc.data();
                    await sendTextMessage("New feedback (" + change.doc.id + ") of ride " + data.rideIdOf);
                    await sendTextMessage("Rated as: " + data.ratedAs);
                    await sendTextMessage("For: " + data.for);
                    await sendTextMessage("Message: " + data.text);
                }

            } else if (change.type === "modified") {
                let createTime = change.doc.updateTime.toMillis();
                if (createTime >= startTime) {
                    await sendTextMessage("UNUSUAL BEHAVIOR 103");
                    let data = change.doc.data();
                    await sendTextMessage("New feedback (" + change.doc.id + ") of ride " + data.rideIdOf);
                    await sendTextMessage("Rated as: " + data.ratedAs);
                    await sendTextMessage("For: " + data.for);
                    await sendTextMessage("Message: " + data.text);
                }
            }
        });
    });
}

// *FREQUENT RIDES*

function offerRide(id) {
    let offerDoc = offersDocs[id];
    if (offerDoc === undefined || offerDoc === null) {
        return;
    }
    if (offerDoc.data().paused === false) {
        let willDo = true;
        const correctedTime = (offerDoc.data().time - hoursInMs(6));
        const now = new Date();
        const dateToConsider = now;
        if (correctedTime < 0) {
            dateToConsider.setDate(dateToConsider.getDate() + 1);
            if (offerDoc.data().endDate !== null && offerDoc.data().endDate < dateToConsider.getTime()) {
                willDo = false;
            }
        } else {
            if (offerDoc.data().initDate !== null && offerDoc.data().initDate > (new Date().getTime())) {
                willDo = false;
            }
        }
        if (willDo) {
            const dayOfWeek = dateToConsider.getDay();
            if (offerDoc.data().daysOfWeek[dayOfWeek]) {
                let data = offerDoc.data();
                let rideDate = new Date();
                let timeOfRide = new Date(data.time);
                if (correctedTime < 0) {
                    rideDate.setDate(rideDate.getDate() + 1);
                }
                rideDate.setHours(timeOfRide.getHours() + (timeOfRide.getTimezoneOffset() / 60));
                rideDate.setMinutes(timeOfRide.getMinutes());
                const rideObj = {
                    polylineTotal: data.polylineTotal,
                    status: 0,
                    typeAccepted: data.type,
                    motorista: data.author,
                    limit: data.limit,
                    lastChange: now.getTime(),
                    initialDuration: data.initialDuration,
                    initalDistance: data.initialDistance,
                    genderAccepted: data.gender,
                    depLat: data.goFrom[0],
                    depLon: data.goFrom[1],
                    depDesc: data.goFromDesc,
                    date: rideDate.getTime(),
                    currentDuration: data.currentDuration,
                    currentDistance: data.currentDistance,
                    closeNeibourhoodToArr: data.closeNeighbourhood,
                    arrLon: data.goTo[1],
                    arrLat: data.goTo[0],
                    arrDesc: data.goToDesc
                };
                db.collection("rides").add(rideObj).then((d) => {
                    db.collection('users').doc(data.author).collection('rides').doc(d.id).set({});
                });
            }
        }
    }
}

async function watchFrequentRides() {
    db.collection("frequentOffers").onSnapshot(querySnapshot => {
        querySnapshot.docChanges().forEach(async change => {
            if (change.type === "added") {
                offersDocs[change.doc.id] = change.doc;
                let time = change.doc.data().time;
                let correctedTime = (time - hoursInMs(6));
                let timeOfNot = new Date(correctedTime);
                let hourOfNot = timeOfNot.getHours() + (timeOfNot.getTimezoneOffset() / 60);
                let minOfNot = timeOfNot.getMinutes();
                if (change.doc.data().initDate === null) {
                    schedulesHappenFrequent[change.doc.id] = schedule.scheduleJob({
                        hour: hourOfNot,
                        minute: minOfNot
                    }, function (offerDoc) {
                        offerRide(offerDoc.id);
                    }.bind(null, change.doc));
                } else {
                    let initDate = new Date(change.doc.data().initDate);
                    schedulesInitFrequent[change.doc.id] = schedule.scheduleJob(initDate, function (offerDoc, hourOfNot, minOfNot) {
                        schedulesInitFrequent[offerDoc.id] = undefined;
                        schedulesHappenFrequent[change.doc.id] = schedule.scheduleJob({
                            hour: hourOfNot,
                            minute: minOfNot
                        }, function (offerDoc) {
                            offerRide(offerDoc.id);
                        }.bind(null, offerDoc, hourOfNot, minOfNot));
                    }.bind(null, change.doc));

                    let endDate = new Date(change.doc.data().endDate);

                    schedulesEndFrequent[change.doc.id] = schedule.scheduleJob(endDate, function (doc) {
                        schedulesEndFrequent[doc.id] = undefined;
                        if (schedulesHappenFrequent[doc.id] !== undefined && schedulesHappenFrequent[doc.id] !== null) {
                            schedulesHappenFrequent[doc.id].cancel();
                            schedulesHappenFrequent[doc.id] = undefined;
                        }
                        doc.ref.delete();
                    }.bind(null, change.doc));

                }
            } else if (change.type === "modified") {
                offersDocs[change.doc.id] = change.doc;
            } else if (change.type === "removed") {
                if (schedulesHappenFrequent[change.doc.id] !== undefined && schedulesHappenFrequent[change.doc.id] !== null) {
                    schedulesHappenFrequent[change.doc.id].cancel();
                    schedulesHappenFrequent[change.doc.id] = undefined;
                }
                if (schedulesInitFrequent[change.doc.id] !== undefined && schedulesInitFrequent[change.doc.id] !== null) {
                    schedulesInitFrequent[change.doc.id].cancel();
                    schedulesInitFrequent[change.doc.id] = undefined;
                }
                if (schedulesEndFrequent[change.doc.id] !== undefined && schedulesEndFrequent[change.doc.id] !== null) {
                    schedulesEndFrequent[change.doc.id].cancel();
                    schedulesEndFrequent[change.doc.id] = undefined;
                }
                offersDocs[change.doc.id] = undefined;
            }
        });
    });
}


// *UTIL*

function hoursInMs(hours) {
    return (hours * 60 * 60 * 1000);
}

const dateFormatted = (date) => {
    return leadingZero(date.getDate()) + "/" + leadingZero(date.getMonth() + 1) + "/" + date.getFullYear();
};

function leadingZero(s) {
    var n = '0' + s;
    if (n.length > 2) {
        return s;
    } else {
        return n;
    }
}

function dateFromSeconds(s) {
    var t = new Date(1970, 0, 1);
    t.setSeconds(s);
    return t;
}

// *BOT*

function loadFromFile() {
    try {
        let json = fs.readFileSync('./listeners.json', 'utf8');

        ids = JSON.parse(json);
    } catch (e) {
        console.log("NO FILE OR CORRUPTED");
    }
}

function saveToFile() {
    let json = JSON.stringify(ids);

    fs.writeFileSync('./listeners.json', json);
}

function addToMsgList(id) {
    if (!ids.includes(id)) {
        ids.push(id);
        saveToFile();
    }
}

async function sendTextMessage(txt) {
    for (let id of ids) {
        // eslint-disable-next-line no-await-in-loop
        await bot.sendMessage(id, txt);
    }
}

async function sendImageMessage(url) {
    for (let id of ids) {
        // eslint-disable-next-line no-await-in-loop
        await bot.sendPhoto(id, url);
    }
}

bot.onText(/\/sign (.+)/, (msg, match) => {
    const chatId = msg.chat.id;
    const txt = match[1];

    if (txt === "YOUR BOT PASSWORD") {
        addToMsgList(chatId);
        bot.sendMessage(chatId, "Hello Master!");
    } else {
        bot.sendMessage(chatId, "Potatos are red!");
    }
});

bot.onText(/\/start/, (msg, match) => {
    const chatId = msg.chat.id;

    if (ids.includes(chatId)) {
        bot.sendMessage(chatId, "Hello Again Master!");
    } else {
        bot.sendMessage(chatId, "I only talk to my master");
    }
});

bot.onText(/\/requesters/, (msg, match) => {
    const chatId = msg.chat.id;

    if (ids.includes(chatId)) {
        sendCurrentRequesters();
    } else {
        bot.sendMessage(chatId, "I only talk to my master");
    }
});


async function allowUser(id) {
    try {
        var userDoc = await db.collection('users').doc(id).get();
        if (userDoc.exists) {
            await userDoc.ref.set({onGoingRequest: false, tipo: 2}, {merge: true});
            await db.collection("driverRequests").doc(id).delete();
            await sendTextMessage(id + " allowed!");
        } else {
            await sendTextMessage("User ID isn't valid!")
        }
    } catch (e) {
        await sendTextMessage("ERROR ALLOWING USER " + id);
    }
}

async function denyUser(id) {
    try {
        var userDoc = await db.collection('users').doc(id).get();
        if (userDoc.exists) {
            await userDoc.ref.set({onGoingRequest: false, tipo: 1}, {merge: true});
            await db.collection("driverRequests").doc(id).delete();
            await sendTextMessage(id + " denied!");
        } else {
            await sendTextMessage("User ID isn't valid!")
        }
    } catch (e) {
        await sendTextMessage("ERROR DENYING USER " + id);
    }
}

async function setAluno(id) {
    try {
        var userDoc = await db.collection('users').doc(id).get();
        if (userDoc.exists) {
            await userDoc.ref.set({level: "A"}, {merge: true});
            await sendTextMessage(id + " now is Aluno!");
        } else {
            await sendTextMessage("User ID isn't valid!")
        }
    } catch (e) {
        await sendTextMessage("ERROR SETTING AS ALUNO | USER " + id);
    }
}

async function setServidor(id) {
    try {
        var userDoc = await db.collection('users').doc(id).get();
        if (userDoc.exists) {
            await userDoc.ref.set({level: "S"}, {merge: true});
            await sendTextMessage(id + " now is Servidor!");
        } else {
            await sendTextMessage("User ID isn't valid!")
        }
    } catch (e) {
        await sendTextMessage("ERROR SETTING AS SERVIDOR | USER " + id);
    }
}

bot.onText(/\/allow (.+)/, (msg, match) => {
    const chatId = msg.chat.id;
    const userId = match[1];

    if (ids.includes(chatId)) {
        allowUser(userId);
    } else {
        bot.sendMessage(chatId, "I only talk to my master");
    }
});

bot.onText(/\/setAluno (.+)/, (msg, match) => {
    const chatId = msg.chat.id;
    const userId = match[1];

    if (ids.includes(chatId)) {
        setAluno(userId);
    } else {
        bot.sendMessage(chatId, "I only talk to my master");
    }
});

bot.onText(/\/setServidor (.+)/, (msg, match) => {
    const chatId = msg.chat.id;
    const userId = match[1];

    if (ids.includes(chatId)) {
        setServidor(userId);
    } else {
        bot.sendMessage(chatId, "I only talk to my master");
    }
});

bot.onText(/\/deny (.+)/, (msg, match) => {
    const chatId = msg.chat.id;
    const userId = match[1];

    if (ids.includes(chatId)) {
        denyUser(userId);
    } else {
        bot.sendMessage(chatId, "I only talk to my master");
    }
});