/*
 * wifi_manager.cpp - Multi-WiFi connection management
 *
 * wifiConnectMulti() reads stored networks from NVS and tries each
 * in order (index 0, 1, 2). Each network gets WIFI_RETRY_MAX attempts.
 * If all networks fail, state becomes WIFI_STATE_FAILED -> BLE fallback.
 *
 * wifiConnect() is still available for single-network use when new
 * credentials arrive via BLE.
 */

#include "wifi_manager.h"
#include "nvs_storage.h"
#include "config.h"
#include <WiFi.h>

static WiFiState currentState = WIFI_STATE_DISCONNECTED;
static String currentSSID = "";
static String currentPassword = "";
static unsigned long connectStartTime = 0;
static uint8_t retryCount = 0;

// Multi-network cycling
static bool multiMode = false;
static int networkIndex = 0;
static int networkTotal = 0;

// Start connecting to the network at networkIndex
static void beginConnect(const String &ssid, const String &password) {
  currentSSID = ssid;
  currentPassword = password;
  retryCount = 0;

  Serial.printf("[WiFi] Trying network %d: %s\n", networkIndex, ssid.c_str());
  WiFi.disconnect();
  delay(100);
  WiFi.begin(ssid.c_str(), password.c_str());
  connectStartTime = millis();
  currentState = WIFI_STATE_CONNECTING;
}

// Try the next stored network, or fail if none left
static bool tryNextNetwork() {
  networkIndex++;
  if (networkIndex >= networkTotal) {
    return false; // No more networks
  }

  String ssid, password;
  if (nvsGetWiFi(networkIndex, ssid, password)) {
    beginConnect(ssid, password);
    return true;
  }
  return false;
}

void wifiInit() {
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  Serial.println("[WiFi] Initialized in STA mode");
}

void wifiConnect(const String &ssid, const String &password) {
  multiMode = false;
  networkIndex = 0;
  networkTotal = 1;
  beginConnect(ssid, password);
}

void wifiConnectMulti() {
  int count = nvsGetWiFiCount();
  if (count <= 0) {
    Serial.println("[WiFi] No stored networks");
    currentState = WIFI_STATE_FAILED;
    return;
  }

  multiMode = true;
  networkIndex = 0;
  networkTotal = count;

  Serial.printf("[WiFi] Starting multi-network cycle (%d networks)\n", count);

  String ssid, password;
  if (nvsGetWiFi(0, ssid, password)) {
    beginConnect(ssid, password);
  } else {
    currentState = WIFI_STATE_FAILED;
  }
}

WiFiState wifiUpdate() {
  switch (currentState) {

    case WIFI_STATE_CONNECTING:
      if (WiFi.status() == WL_CONNECTED) {
        currentState = WIFI_STATE_CONNECTED;
        retryCount = 0;
        Serial.println("[WiFi] Connected! IP: " + WiFi.localIP().toString());
        Serial.printf("[WiFi] Network: %s (index %d)\n", currentSSID.c_str(), networkIndex);
      }
      else if (millis() - connectStartTime > WIFI_CONNECT_TIMEOUT) {
        retryCount++;
        Serial.printf("[WiFi] Timeout on '%s' (attempt %d/%d)\n",
                      currentSSID.c_str(), retryCount, WIFI_RETRY_MAX);

        if (retryCount >= WIFI_RETRY_MAX) {
          // This network exhausted — try next in multi mode
          if (multiMode && tryNextNetwork()) {
            // tryNextNetwork() already started the next connection
          } else {
            currentState = WIFI_STATE_FAILED;
            WiFi.disconnect();
            Serial.println("[WiFi] All networks exhausted");
          }
        } else {
          // Retry same network
          WiFi.disconnect();
          delay(500);
          WiFi.begin(currentSSID.c_str(), currentPassword.c_str());
          connectStartTime = millis();
        }
      }
      break;

    case WIFI_STATE_CONNECTED:
      if (WiFi.status() != WL_CONNECTED) {
        Serial.println("[WiFi] Connection lost, reconnecting...");
        WiFi.begin(currentSSID.c_str(), currentPassword.c_str());
        connectStartTime = millis();
        retryCount = 0;
        currentState = WIFI_STATE_CONNECTING;
      }
      break;

    case WIFI_STATE_FAILED:
      break;

    case WIFI_STATE_DISCONNECTED:
      break;
  }

  return currentState;
}

WiFiState wifiGetState() {
  return currentState;
}

void wifiDisconnect() {
  WiFi.disconnect();
  currentState = WIFI_STATE_DISCONNECTED;
  Serial.println("[WiFi] Disconnected");
}

bool wifiIsConnected() {
  return (currentState == WIFI_STATE_CONNECTED && WiFi.status() == WL_CONNECTED);
}

void wifiResetRetries() {
  retryCount = 0;
  networkIndex = 0;
  multiMode = false;
  currentState = WIFI_STATE_DISCONNECTED;
}