const globals = require('./globals');

/*
*
* Model:
    var obj = {
      title: "Teste Notificacao",
      body: 'Estou testando!',
        buttons: [{"id": "id1", "text": "button1"}, {"id": "id2", "text": "button2"}],
        data: {
            action: "act",
        }
    };
*
* */

function clone(obj) {
    if (obj === null || typeof (obj) !== 'object')
        return obj;

    var temp = new obj.constructor();
    for (var key in obj)
        temp[key] = clone(obj[key]);

    return temp;
}


const sendNotification = (obj, userId, playerId, uid) => {
    obj.player_ids = [playerId];
    globals.db.collection('notifications').add({
        toWho: userId,
        obj: obj,
        creationDate: new Date().getTime(),
        uniqueId: uid
    });
};


exports.sendNotificationByUserId = async (id, notification) => {
    try {
        var userDoc = await globals.db.collection('users').doc(id).get();
        var userIds = userDoc.data().playerIds;
        if (typeof userIds === 'object' && Object.keys(userIds).length !== 0) {
            Object.entries(userIds).forEach((data) => {
                let playerId = data[0];
                let uid = data[1].uid;
                sendNotification(clone(notification), id, playerId.slice(0), uid.slice(0));
            });
        } else {
            console.error("No player ids");
        }
    } catch (e) {
        console.error(e);
    }
};


exports.createChatNotification = (senderName, content, rideId, senderId, iconUrl, driverId, riderId) => {
    var not = {
        title: "Nova mensagem de " + senderName + "!",
        body: content,
        data: {
            action: 'chat',
            rideId: rideId,
            driverId: driverId,
            riderId: riderId
        },
        buttons: [{"id": "answer", "text": "RESPONDER"}],
        large_icon: iconUrl === undefined ? null : iconUrl,
        android_group: "chat-" + rideId + senderId,
        android_group_message: {"en": "$[notif_count] novas mensagens de " + senderName}
    };
    return not;
};

exports.createDriverRequestNotification = (accepted) => {
    let title = "Parabéns você agora é um motorista!";
    let body = "Você agora pode oferecer caronas!";
    if(!accepted){
        title = "Seu pedido foi negado!";
        body = "Nossa equipe decidiu deferir seu pedido para ser motorista!";
    }
    var not = {
        title: title,
        body: body,
        data: {
            action: 'driver_request',
            accepted: accepted
        },
        large_icon: null,
    };
    return not;
};

exports.createInitRideNotification = (rideId,date,isDriver,iconUrl) => {
    var not = {
        title: "Sua carona vai começar!",
        body: "A carona do dia "+date+" está prestes a começar!",
        data: {
            action: 'init_ride',
            rideId: rideId,
            isDriver: isDriver
        },
        large_icon: iconUrl === undefined ? null : iconUrl,
    };
    return not;
};

exports.createRateDriver = (rideId,driverId,driverName,data,iconUrl) =>{
    var not = {
        title: "Avalie o motorista da carona do dia "+data+"!",
        body: "Como foi a carona com "+driverName+"? Deixe seu feedback!",
        data: {
            action: "rate_driver",
            rideId: rideId,
            driverId: driverId,
            driverName: driverName,
            data: data,
            picUrl: iconUrl
        },
        large_icon: iconUrl === undefined ? null : iconUrl,
    };
    return not;
};

exports.createFrequentSearch = (search_data,iconUrl, standard) => {
    let body = "Uma carona que combina com o perfil de uma busca frequente sua acabou de ser criada!";
    if(standard === false){
        body = "Uma carona parecida com uma busca recente sua acabou de ser criada!"
    }
    var not = {
        title: "Nova carona que pode ser de seu interesse!",
        body: body,
        data: {
            action: "frequent_search",
            search_data: search_data
        },
        large_icon: iconUrl === undefined ? null : iconUrl,
    };
    return not;
};


exports.createRateRiders = (rideId,data,riders,iconUrl) =>{
    var not = {
        title: "Avalie os caroneiros da carona do dia "+data+"!",
        body: "Como foi a carona? Deixe seu feedback!",
        data: {
            action:"rate_riders",
            rideId: rideId,
            date: data,
            riders: riders
        },
        large_icon: iconUrl === undefined ? null : iconUrl,
    };
    return not;
};

exports.createRequestAcceptedNotification = (date, rideId, iconUrl) => {
    var not = {
        title: "Pedido Aceito!",
        body: "Você foi aceito na carona do dia " + date + "!",
        data: {
            action: 'ride_applied',
            rideId: rideId,
            event: "accepted"
        },
        buttons: [{"id": "chat", "text": "CHAT"}],
        large_icon: iconUrl === undefined ? null : iconUrl,
    };
    return not;
};

exports.createNewRequestNotification = (requesterName, rideId, requesterId, iconUrl) => {
    var not = {
        title: "Novo Pedido De Carona!",
        body: requesterName + " pediu para se juntar à sua carona!",
        data: {
            action: 'my_ride',
            rideId: rideId,
            requesterId: requesterId
        },
        large_icon: iconUrl === undefined ? null : iconUrl,
    };
    return not;
};

exports.createRemovedNotification = (date, iconUrl,rideId) => {
    var not = {
        title: "Você foi removido da carona do dia " + date + "!",
        body: "Infelizmente o motorista teve que te remover da carona!",
        data: {
            action: 'ride_applied',
            event: 'removed',
            rideId: rideId
        },
        large_icon: iconUrl === undefined ? null : iconUrl,
    };
    return not;
};

exports.createRequestDropNotification = (requesterName, rideId, iconUrl) => {
    var not = {
        title: "Desistência de Carona!",
        body: requesterName + " desistiu de sua carona!",
        data: {
            action: 'my_ride',
            rideId: rideId,
        },
        large_icon: iconUrl,
    };
    return not;
};

exports.createRideDeletedNotification = (date, iconUrl,rideId) => {
    var not = {
        title: "A carona do dia " + date + " foi deletada!",
        body: "Infelizmente o motorista deletou a carona que você estava!",
        data: {
            action: 'ride_applied',
            event: 'deleted',
            rideId: rideId
        },
        large_icon: iconUrl === undefined ? null : iconUrl,
    };
    return not;
};