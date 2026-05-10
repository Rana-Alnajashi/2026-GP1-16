/*
 * wifi_manager.h - Multi-WiFi connection management
 *
 * Supports cycling through multiple stored networks:
 *   - wifiConnectMulti() reads NVS and tries each network in order
 *   - Each network gets WIFI_RETRY_MAX attempts before moving to next
 *   - After all networks fail -> WIFI_STATE_FAILED (fall back to BLE)
 *   - wifiConnect() still available for single-network use (BLE provisioning)
 */

#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <Arduino.h>

// WiFi connection states
enum WiFiState {
  WIFI_STATE_DISCONNECTED,
  WIFI_STATE_CONNECTING,
  WIFI_STATE_CONNECTED,
  WIFI_STATE_FAILED       // All networks exhausted -> need BLE provisioning
};

// Initialize WiFi in station mode
void wifiInit();

// Connect to a single network (used when BLE provides new credentials)
void wifiConnect(const String &ssid, const String &password);

// Start cycling through all stored NVS networks
// Tries network 0 -> 1 -> 2, each with WIFI_RETRY_MAX attempts
void wifiConnectMulti();

// Must be called in loop() - manages connection state machine
WiFiState wifiUpdate();

// Get current WiFi state
WiFiState wifiGetState();

// Disconnect WiFi
void wifiDisconnect();

// Check if WiFi is currently connected
bool wifiIsConnected();

// Reset retry counter (call when new credentials are received)
void wifiResetRetries();

#endif // WIFI_MANAGER_H