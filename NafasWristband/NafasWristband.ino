/*
 * NafasWristband.ino - Main application for Nafas Smart Wristband
 *
 * ESP32 wristband firmware with AWS IoT Core (Secure MQTT)
 */

#include "config.h"
#include "nvs_storage.h"
#include "ble_provision.h"
#include "wifi_manager.h"
#include "sensors.h"
#include "mqtt_manager.h" // Now using MQTT instead of Firebase!

// ======================== SYSTEM STATES ========================
enum SystemState {
  STATE_INIT,
  STATE_BLE_PROVISIONING,
  STATE_WIFI_CONNECTING,
  STATE_CLOUD_INIT,
  STATE_RUNNING,
  STATE_WIFI_LOST
};

static SystemState systemState = STATE_INIT;

// Timing
static unsigned long lastUpload = 0;

// LED blink for provisioning mode
static unsigned long lastBlink = 0;
static bool ledState = false;

// ======================== LED HELPERS ========================

static void ledBlinkProvisioning() {
  if (millis() - lastBlink > 300) {
    lastBlink = millis();
    ledState = !ledState;
    digitalWrite(LED_BUILTIN_BLUE, ledState ? HIGH : LOW);
  }
}

static void ledSolid(bool on) {
  digitalWrite(LED_BUILTIN_BLUE, on ? HIGH : LOW);
}

static void vibrateSuccess() {
  for (int i = 0; i < 3; i++) {
    digitalWrite(VIBRATION_PIN, HIGH);
    delay(300);
    digitalWrite(VIBRATION_PIN, LOW);
    delay(300);
  }
}

// ======================== SETUP ========================
void setup() {
  Serial.begin(115200);
  Serial.println("\n========================================");
  Serial.println("  NAFAS WRISTBAND - Starting...");
  Serial.println("========================================\n");

  pinMode(VIBRATION_PIN, OUTPUT);
  pinMode(LED_BUILTIN_BLUE, OUTPUT);
  digitalWrite(VIBRATION_PIN, LOW);
  digitalWrite(LED_BUILTIN_BLUE, LOW);

  sensorsInit();
  nvsInit();
  nvsClearAllWiFi();
  nvsPrintNetworks();
  wifiInit();

  if (nvsGetWiFiCount() > 0) {
    Serial.println("[Main] Stored networks found, cycling...");
    wifiConnectMulti();
    systemState = STATE_WIFI_CONNECTING;
  } else {
    Serial.println("[Main] No networks stored, starting BLE provisioning...");
    bleProvisionStart();
    systemState = STATE_BLE_PROVISIONING;
  }
}

// ======================== MAIN LOOP ========================
void loop() {
  sensorsBsecRun();

  switch (systemState) {

    case STATE_BLE_PROVISIONING:
      ledBlinkProvisioning();
      if (bleHasNewCredentials()) {
        String ssid = bleGetSSID();
        String password = bleGetPassword();
        
        // Clean invisible spaces or newlines from the app!
        ssid.trim();
        password.trim();

        Serial.println("[Main] Credentials received: '" + ssid + "'");
        bleSetStatus("CONNECTING");

        nvsAddWiFi(ssid, password);
        nvsPrintNetworks();

        wifiConnect(ssid, password);
        systemState = STATE_WIFI_CONNECTING;
      }
      break;

    case STATE_WIFI_CONNECTING: {
      WiFiState wState = wifiUpdate();
      if (wState == WIFI_STATE_CONNECTED) {
        Serial.println("[Main] WiFi connected!");
        bleSetStatus("SUCCESS"); 
        delay(1000); 
        bleProvisionStop();
        systemState = STATE_CLOUD_INIT;
      }
      else if (wState == WIFI_STATE_FAILED) {
        Serial.println("[Main] All WiFi networks failed");
        bleSetStatus("FAILED");
        delay(500); 
        bleClearCredentials();
        wifiResetRetries();
        
        bleProvisionStart(); 
        
        systemState = STATE_BLE_PROVISIONING;
      }
      break;
    }
    
    case STATE_CLOUD_INIT:
      if (mqttInit()) {
        vibrateSuccess();
        ledSolid(true);
        lastUpload = millis();
        systemState = STATE_RUNNING;
        Serial.println("[Main] Secure MQTT System running");
      } else {
        Serial.println("[Main] MQTT Init failed, will retry...");
        delay(2000); 
      }
      break;

    case STATE_RUNNING: {
      WiFiState wState = wifiUpdate();
      if (wState != WIFI_STATE_CONNECTED) {
        systemState = STATE_WIFI_LOST;
        ledSolid(false);
        Serial.println("[Main] WiFi lost");
        break;
      }

      bool mqttReady = mqttMaintain();
      ledSolid(mqttReady);

      if (millis() - lastUpload >= UPLOAD_INTERVAL_MS) {
        lastUpload = millis();

        SensorData data;
        sensorsRead(data);

        if (data.fingerDetected && data.healthValid) {
          Serial.printf("[Main] BPM=%d SpO2=%d%%\n", data.bpm, data.spo2);
        }

        if (mqttReady) {
          mqttUploadAll(data);
        }
      }
      break;
    }

    case STATE_WIFI_LOST: {
      WiFiState wState = wifiUpdate();

      if (wState == WIFI_STATE_CONNECTED) {
        Serial.println("[Main] WiFi recovered");
        systemState = STATE_RUNNING;
        ledSolid(true);
      }
      else if (wState == WIFI_STATE_FAILED) {
        Serial.println("[Main] WiFi recovery failed, cycling all networks...");
        wifiResetRetries();

        if (nvsGetWiFiCount() > 0) {
          wifiConnectMulti();
          systemState = STATE_WIFI_CONNECTING;
        } else {
          bleProvisionStart();
          systemState = STATE_BLE_PROVISIONING;
        }
      }
      break;
    }

    default:
      break;
  }
}