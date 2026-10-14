#include "mqtt_manager.h"
#include "config.h"
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <time.h>

WiFiClientSecure secureClient;
PubSubClient mqttClient(secureClient);

// Sync time via NTP so the SSL certificate validation doesn't fail
static void syncTime() {
    Serial.println("[MQTT] Syncing time for SSL...");
    configTime(0, 0, "pool.ntp.org", "time.nist.gov");
    
    time_t now = time(nullptr);
    while (now < 24 * 3600) {
        Serial.print(".");
        delay(500);
        now = time(nullptr);
    }
    Serial.println("\n[MQTT] Time synced!");
}

bool mqttInit() {
    syncTime();
    secureClient.setCACert(root_ca);
    secureClient.setCertificate(device_cert);
    secureClient.setPrivateKey(device_private_key);
    
    mqttClient.setServer(MQTT_BROKER, MQTT_PORT);
    mqttClient.setBufferSize(512);
    
    // ADD THIS LINE: Increase keepalive to 60 seconds
    mqttClient.setKeepAlive(60); 

    return mqttMaintain();
}

bool mqttMaintain() {
    // If already connected, just pump the loop
    if (mqttClient.connected()) {
        mqttClient.loop();
        return true;
    }

    Serial.print("[MQTT] Connecting to AWS IoT...");
    String clientId = "NafasBand-" + String(random(0xffff), HEX);
    
    // AWS uses certificates, so we leave the username and password blank!
    if (mqttClient.connect(clientId.c_str())) {
        Serial.println(" CONNECTED!");
        return true;
    } else {
        Serial.print(" FAILED, rc=");
        Serial.println(mqttClient.state());
        return false;
    }
}

void mqttUploadAll(const SensorData &data) {
    if (!mqttClient.connected()) return;

    
    char payload[256];
    snprintf(payload, sizeof(payload), 
        "{\"bpm\":%d,\"spo2\":%d,\"temp\":%.1f,\"hum\":%.1f,\"iaq\":%.1f,\"co2\":%.1f,\"x\":%.2f,\"y\":%.2f,\"z\":%.2f}",
        data.bpm, data.spo2, data.temperature, data.humidity, data.iaq, data.co2, data.x, data.y, data.z
    );

    Serial.printf("[MQTT] Publishing: %s\n", payload);
    
    // Send it to the secure broker!
    mqttClient.publish(MQTT_TOPIC, payload);
}