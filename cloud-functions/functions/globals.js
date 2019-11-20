// The Firebase Admin SDK to access the Firebase Realtime Database.
const admin = require('firebase-admin');

admin.initializeApp();

exports.db = admin.firestore();

exports.mode = "driving";
exports.alternatives = false;
exports.optimize = true;


exports.dateFormatted = (date) =>{
    return leadingZero(date.getDate()) + "/"+ leadingZero(date.getMonth()+1) + "/" + date.getFullYear();
};

function leadingZero (s){
    var n = '0' + s;
    if(n.length>2){
        return s;
    }else{
        return n;
    }
}