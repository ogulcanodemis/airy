/**
 * Import function triggers from their respective submodules:
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const logger = require("firebase-functions/logger");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");
const axios = require("axios");

// Firebase uygulamasını başlat
initializeApp();

// Firestore ve Messaging referanslarını al
const db = getFirestore();
const messaging = getMessaging();

// WAQI API anahtarı
// const WAQI_API_KEY = "d1ab1cb70a638cbd4584526599ee41577429a61f";
// Güvenlik için çevresel değişken olarak tanımlanmalı
const WAQI_API_KEY = process.env.WAQI_API_KEY || "d1ab1cb70a638cbd4584526599ee41577429a61f";

/**
 * Zamanlanmış olarak çalışan, tüm kullanıcılar için hava kalitesi kontrolü yapan fonksiyon
 * Bu fonksiyon her saat başı çalışır ve tüm kullanıcıların konumlarına göre hava kalitesi verilerini kontrol eder
 */
exports.scheduledAirQualityCheck = onSchedule({
  schedule: "every 1 hours",
  region: "us-central1"
}, async (event) => {
  try {
    logger.info("Zamanlanmış hava kalitesi kontrolü başlatılıyor...");
    
    // Bildirimleri etkinleştirmiş tüm kullanıcıları al
    const usersSnapshot = await db.collection("users")
      .where("settings.notificationsEnabled", "==", true)
      .get();
    
    if (usersSnapshot.empty) {
      logger.info("Bildirim alacak kullanıcı bulunamadı");
      return null;
    }
    
    // Her kullanıcı için hava kalitesi kontrolü yap
    const promises = [];
    
    usersSnapshot.forEach((userDoc) => {
      const userData = userDoc.data();
      const userId = userDoc.id;
      const settings = userData.settings || {};
      
      // Kullanıcının son konumunu al
      promises.push(
        db.collection("users").doc(userId).collection("locations")
          .where("isCurrentLocation", "==", true)
          .orderBy("timestamp", "desc")
          .limit(1)
          .get()
          .then(async (locationsSnapshot) => {
            if (locationsSnapshot.empty) {
              logger.info(`${userId} kullanıcısı için konum bulunamadı`);
              return;
            }
            
            const locationData = locationsSnapshot.docs[0].data();
            const latitude = locationData.latitude;
            const longitude = locationData.longitude;
            
            logger.info(`${userId} kullanıcısı için hava kalitesi kontrolü yapılıyor... (Konum: ${latitude}, ${longitude})`);
            
            // WAQI API'den veri al
            try {
              // Önce Geocoding API ile koordinatları detaylı konum bilgisine dönüştür
              const geocodingResponse = await axios.get(`https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${latitude}&longitude=${longitude}&localityLanguage=tr`);
              
              let locationQuery = ""; // Konum sorgusu
              
              if (geocodingResponse.data) {
                const geoData = geocodingResponse.data;
                
                // Şehir bilgisi
                const city = geoData.city || "";
                
                // İlçe bilgisi
                const district = geoData.locality || geoData.district || "";
                
                // Mahalle bilgisi
                const neighborhood = geoData.neighbourhood || "";
                
                // Konum bilgilerini kaydet
                logger.info(`Konum detayları: Şehir=${city}, İlçe=${district}, Mahalle=${neighborhood}`);
                
                // Konum sorgusu oluştur
                if (city && district) {
                  // Önce şehir ve ilçe ile deneyelim
                  locationQuery = `${city}/${district}`.toLowerCase();
                  logger.info(`Şehir ve ilçe ile sorgu yapılacak: ${locationQuery}`);
                } else if (city) {
                  // Sadece şehir ile deneyelim
                  locationQuery = city.toLowerCase();
                  logger.info(`Sadece şehir ile sorgu yapılacak: ${locationQuery}`);
                } else {
                  // Konum bilgisi yoksa varsayılan olarak boş bırak
                  logger.warn(`Koordinatlar (${latitude}, ${longitude}) için konum bilgisi bulunamadı`);
                  return; // Konum bilgisi yoksa işlemi sonlandır
                }
              } else {
                logger.warn(`Koordinatlar (${latitude}, ${longitude}) için konum bilgisi bulunamadı`);
                return; // Konum bilgisi yoksa işlemi sonlandır
              }
              
              // Konum adı ile WAQI API'den veri al
              logger.info(`WAQI API sorgusu yapılıyor: ${locationQuery}`);
              let response;
              
              try {
                // İlk olarak şehir/ilçe ile deneyelim
                response = await axios.get(`https://api.waqi.info/feed/${locationQuery}/?token=${WAQI_API_KEY}`);
                
                // Eğer sonuç bulunamazsa veya hata varsa, sadece şehir ile deneyelim
                if (response.data.status !== "ok" && locationQuery.includes("/")) {
                  const cityOnly = locationQuery.split("/")[0];
                  logger.info(`Şehir/ilçe sorgusu başarısız oldu, sadece şehir ile deneniyor: ${cityOnly}`);
                  response = await axios.get(`https://api.waqi.info/feed/${cityOnly}/?token=${WAQI_API_KEY}`);
                  
                  // Eğer şehir sorgusu başarılı olursa, locationQuery'yi güncelle
                  if (response.data.status === "ok") {
                    locationQuery = cityOnly;
                  }
                }
                
                // Eğer hala sonuç bulunamazsa, Türkiye'deki büyük şehirlerden birini deneyelim
                if (response.data.status !== "ok") {
                  const bigCities = ["istanbul", "ankara", "izmir", "bursa", "antalya"];
                  
                  for (const city of bigCities) {
                    logger.info(`Yerel sorgu başarısız oldu, büyük şehir deneniyor: ${city}`);
                    response = await axios.get(`https://api.waqi.info/feed/${city}/?token=${WAQI_API_KEY}`);
                    
                    if (response.data.status === "ok") {
                      locationQuery = city;
                      logger.info(`Büyük şehir sorgusu başarılı: ${city}`);
                      break;
                    }
                  }
                }
              } catch (error) {
                logger.error(`WAQI API sorgusu sırasında hata oluştu: ${error}`);
                return;
              }
              
              if (response.data.status === "ok") {
                const data = response.data.data;
                const aqi = data.aqi;
                const location = data.city.name || locationQuery;
                
                logger.info(`${userId} kullanıcısı için hava kalitesi verisi alındı: ${location}, AQI: ${aqi}`);
                
                // Hava kalitesi verisini Firestore'a kaydet
                await db.collection("airQualityData").doc(locationQuery.replace(/\//g, "_")).set({
                  aqi: aqi,
                  location: location,
                  locationQuery: locationQuery,
                  timestamp: new Date(),
                  updatedAt: new Date()
                });
                
                // Bildirim eşiğini kontrol et
                if (aqi >= settings.notificationThreshold) {
                  // Kullanıcının FCM token'ını al
                  const fcmToken = userData.fcmToken;
                  
                  if (!fcmToken) {
                    logger.warn(`${userId} kullanıcısı için FCM token bulunamadı`);
                    return;
                  }
                  
                  // Hava kalitesi kategorisini belirle
                  let category = "İyi";
                  if (aqi > 50 && aqi <= 100) category = "Orta";
                  else if (aqi > 100 && aqi <= 150) category = "Hassas Gruplar İçin Sağlıksız";
                  else if (aqi > 150 && aqi <= 200) category = "Sağlıksız";
                  else if (aqi > 200 && aqi <= 300) category = "Çok Sağlıksız";
                  else if (aqi > 300) category = "Tehlikeli";
                  
                  // Bildirim içeriğini hazırla
                  const message = {
                    notification: {
                      title: "Hava Kalitesi Uyarısı",
                      body: `${location} bölgesinde hava kalitesi ${category} seviyesinde (AQI: ${aqi}). Lütfen gerekli önlemleri alın.`,
                    },
                    data: {
                      type: "air_quality_alert",
                      aqi: aqi.toString(),
                      location: location,
                      category: category,
                      timestamp: new Date().toISOString(),
                    },
                    android: {
                      notification: {
                        channelId: "air_quality_alerts",
                        priority: "high",
                        sound: "default",
                        color: "#4CAF50",
                        icon: "ic_notification",
                        clickAction: "FLUTTER_NOTIFICATION_CLICK",
                      },
                    },
                    apns: {
                      payload: {
                        aps: {
                          sound: "default",
                          badge: 1,
                          contentAvailable: true,
                          category: "AIR_QUALITY_ALERT",
                        },
                      },
                      headers: {
                        "apns-priority": "10",
                      },
                    },
                    token: fcmToken,
                  };
                  
                  // Bildirimi gönder
                  await messaging.send(message);
                  logger.info(`${userId} kullanıcısına bildirim gönderildi`);
                  
                  // Bildirim kaydını Firestore'a ekle
                  await db.collection("users").doc(userId).collection("notifications").add({
                    title: message.notification.title,
                    body: message.notification.body,
                    data: message.data,
                    read: false,
                    createdAt: new Date(),
                  });
                } else {
                  logger.info(`${userId} kullanıcısı için AQI değeri (${aqi}) bildirim eşiğinin (${settings.notificationThreshold}) altında`);
                }
              } else {
                logger.warn(`WAQI API yanıtı başarısız: ${response.data.status}`);
              }
            } catch (error) {
              logger.error(`WAQI API'den veri alınırken hata oluştu: ${error}`);
            }
          })
          .catch((error) => {
            logger.error(`${userId} kullanıcısı için konum alınırken hata oluştu: ${error}`);
          })
      );
    });
    
    // Tüm işlemlerin tamamlanmasını bekle
    await Promise.all(promises);
    
    logger.info("Zamanlanmış hava kalitesi kontrolü tamamlandı");
    return null;
  } catch (error) {
    logger.error(`Zamanlanmış hava kalitesi kontrolü sırasında hata oluştu: ${error}`);
    return null;
  }
});

/**
 * Hava kalitesi verisi eklendiğinde veya güncellendiğinde çalışan fonksiyon
 * Bu fonksiyon, hava kalitesi verileri Firestore'a eklendiğinde veya güncellendiğinde tetiklenir
 * ve kullanıcının bildirim eşiğini aşan değerler için bildirim gönderir.
 */
exports.checkAirQualityAlerts = onDocumentCreated({
  document: "airQualityData/{locationId}",
  region: "us-central1"
}, async (event) => {
  try {
    // Yeni eklenen hava kalitesi verisini al
    const airQualityData = event.data.data();
    const locationId = event.params.locationId;
    
    if (!airQualityData) {
      logger.warn("Hava kalitesi verisi bulunamadı");
      return null;
    }
    
    // AQI değerini kontrol et
    const aqi = airQualityData.aqi;
    const location = airQualityData.location || "Bilinmeyen Konum";
    const locationQuery = airQualityData.locationQuery || "istanbul";
    
    logger.info(`Yeni hava kalitesi verisi: ${location} (${locationQuery}), AQI: ${aqi}`);
    
    // Bildirim eşiğini aşan kullanıcıları bul
    const usersSnapshot = await db.collection("users")
      .where("settings.notificationsEnabled", "==", true)
      .where("settings.notificationThreshold", "<=", aqi)
      .get();
    
    if (usersSnapshot.empty) {
      logger.info("Bildirim alacak kullanıcı bulunamadı");
      return null;
    }
    
    // Her kullanıcıya bildirim gönder
    const notifications = [];
    
    usersSnapshot.forEach((userDoc) => {
      const userData = userDoc.data();
      const userId = userDoc.id;
      const fcmToken = userData.fcmToken;
      
      if (!fcmToken) {
        logger.warn(`${userId} kullanıcısı için FCM token bulunamadı`);
        return;
      }
      
      // Bildirim içeriğini hazırla
      const message = {
        notification: {
          title: "Hava Kalitesi Uyarısı",
          body: `${location} bölgesinde hava kalitesi tehlikeli seviyede (AQI: ${aqi})`,
        },
        data: {
          type: "air_quality_alert",
          aqi: aqi.toString(),
          location: location,
          timestamp: new Date().toISOString(),
        },
        android: {
          notification: {
            channelId: "air_quality_alerts",
            priority: "high",
            sound: "default",
            color: "#4CAF50",
            icon: "ic_notification",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              contentAvailable: true,
              category: "AIR_QUALITY_ALERT",
            },
          },
          headers: {
            "apns-priority": "10",
          },
        },
        token: fcmToken,
      };
      
      // Bildirimi gönder
      notifications.push(
        messaging.send(message)
          .then(() => {
            logger.info(`${userId} kullanıcısına bildirim gönderildi`);
            
            // Bildirim kaydını Firestore'a ekle
            return db.collection("users").doc(userId).collection("notifications").add({
              title: message.notification.title,
              body: message.notification.body,
              data: message.data,
              read: false,
              createdAt: new Date(),
            });
          })
          .catch((error) => {
            logger.error(`Bildirim gönderilirken hata oluştu: ${error}`);
          })
      );
    });
    
    // Tüm bildirimlerin tamamlanmasını bekle
    await Promise.all(notifications);
    
    return null;
  } catch (error) {
    logger.error(`Hava kalitesi bildirimi işlenirken hata oluştu: ${error}`);
    return null;
  }
});

// Hava kalitesi verisi güncellendiğinde de aynı kontrolü yap
exports.checkAirQualityUpdates = onDocumentUpdated({
  document: "airQualityData/{locationId}",
  region: "us-central1"
}, async (event) => {
  try {
    // Güncellenen hava kalitesi verisini al
    const afterData = event.data.after.data();
    const beforeData = event.data.before.data();
    const locationId = event.params.locationId;
    
    if (!afterData) {
      logger.warn("Güncellenmiş hava kalitesi verisi bulunamadı");
      return null;
    }
    
    // AQI değerini kontrol et
    const newAqi = afterData.aqi;
    const oldAqi = beforeData && beforeData.aqi ? beforeData.aqi : 0;
    const location = afterData.location || "Bilinmeyen Konum";
    const locationQuery = afterData.locationQuery || "istanbul";
    
    // AQI değeri artmış mı kontrol et (sadece kötüleşme durumunda bildirim gönder)
    if (newAqi <= oldAqi) {
      logger.info(`Hava kalitesi iyileşti veya değişmedi: ${location} (${locationQuery}), AQI: ${oldAqi} -> ${newAqi}`);
      return null;
    }
    
    logger.info(`Hava kalitesi kötüleşti: ${location} (${locationQuery}), AQI: ${oldAqi} -> ${newAqi}`);
    
    // Bildirim eşiğini aşan kullanıcıları bul
    const usersSnapshot = await db.collection("users")
      .where("settings.notificationsEnabled", "==", true)
      .where("settings.notificationThreshold", "<=", newAqi)
      .where("settings.notificationThreshold", ">", oldAqi)
      .get();
    
    if (usersSnapshot.empty) {
      logger.info("Bildirim alacak kullanıcı bulunamadı");
      return null;
    }
    
    // Her kullanıcıya bildirim gönder
    const notifications = [];
    
    usersSnapshot.forEach((userDoc) => {
      const userData = userDoc.data();
      const userId = userDoc.id;
      const fcmToken = userData.fcmToken;
      
      if (!fcmToken) {
        logger.warn(`${userId} kullanıcısı için FCM token bulunamadı`);
        return;
      }
      
      // Bildirim içeriğini hazırla
      const message = {
        notification: {
          title: "Hava Kalitesi Uyarısı",
          body: `${location} bölgesinde hava kalitesi kötüleşti (AQI: ${oldAqi} -> ${newAqi})`,
        },
        data: {
          type: "air_quality_alert",
          aqi: newAqi.toString(),
          oldAqi: oldAqi.toString(),
          location: location,
          timestamp: new Date().toISOString(),
        },
        android: {
          notification: {
            channelId: "air_quality_alerts",
            priority: "high",
            sound: "default",
            color: "#4CAF50",
            icon: "ic_notification",
            clickAction: "FLUTTER_NOTIFICATION_CLICK",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
              contentAvailable: true,
              category: "AIR_QUALITY_ALERT",
            },
          },
          headers: {
            "apns-priority": "10",
          },
        },
        token: fcmToken,
      };
      
      // Bildirimi gönder
      notifications.push(
        messaging.send(message)
          .then(() => {
            logger.info(`${userId} kullanıcısına bildirim gönderildi`);
            
            // Bildirim kaydını Firestore'a ekle
            return db.collection("users").doc(userId).collection("notifications").add({
              title: message.notification.title,
              body: message.notification.body,
              data: message.data,
              read: false,
              createdAt: new Date(),
            });
          })
          .catch((error) => {
            logger.error(`Bildirim gönderilirken hata oluştu: ${error}`);
          })
      );
    });
    
    // Tüm bildirimlerin tamamlanmasını bekle
    await Promise.all(notifications);
    
    return null;
  } catch (error) {
    logger.error(`Hava kalitesi bildirimi işlenirken hata oluştu: ${error}`);
    return null;
  }
});

/**
 * Kullanıcı bildirim koleksiyonuna yeni bir belge eklendiğinde tetiklenen fonksiyon
 * Bu fonksiyon, kullanıcıya FCM bildirimi gönderir
 */
exports.sendNotificationToUser = onDocumentCreated({
  document: "users/{userId}/notifications/{notificationId}",
  region: "us-central1"
}, async (event) => {
  try {
    const notificationData = event.data.data();
    const userId = event.params.userId;
    const notificationId = event.params.notificationId;
    
    // Test bildirimlerini filtrele
    if (notificationData.data && notificationData.data.type === "test_notification") {
      logger.info("Test bildirimi gönderilmeyecek");
      return null;
    }
    
    // Kullanıcı bilgilerini al
    const userDoc = await db.collection("users").doc(userId).get();
    
    if (!userDoc.exists) {
      logger.error(`Kullanıcı bulunamadı: ${userId}`);
      return null;
    }
    
    const userData = userDoc.data();
    const fcmToken = userData.fcmToken;
    
    if (!fcmToken) {
      logger.warn(`${userId} kullanıcısı için FCM token bulunamadı`);
      return null;
    }
    
    // Bildirim içeriğini hazırla
    const message = {
      notification: {
        title: notificationData.title || "Airy",
        body: notificationData.body || "Yeni bir bildiriminiz var",
      },
      data: notificationData.data || {
        type: "general",
        timestamp: new Date().toISOString(),
      },
      android: {
        notification: {
          channelId: "general_notifications",
          priority: "high",
          sound: "default",
          color: "#4CAF50",
          icon: "ic_notification",
          clickAction: "FLUTTER_NOTIFICATION_CLICK",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
            badge: 1,
            contentAvailable: true,
            category: "GENERAL_NOTIFICATION",
          },
        },
        headers: {
          "apns-priority": "10",
        },
      },
      token: fcmToken,
    };
    
    // Bildirimi gönder
    await messaging.send(message);
    logger.info(`${userId} kullanıcısına bildirim gönderildi`);
    
    return null;
  } catch (error) {
    logger.error(`Bildirim gönderilirken hata oluştu: ${error}`);
    return null;
  }
});
