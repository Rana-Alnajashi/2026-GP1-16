/*
 * ble_provision.h - BLE WiFi Provisioning for Nafas Wristband
 *
 * Exposes a BLE GATT server with a custom service containing:
 *   - SSID characteristic (write)
 *   - Password characteristic (write)
 *   - Status characteristic (read/notify) for feedback to mobile app
 *
 * The mobile app writes SSID and password, then the ESP32 attempts
 * WiFi connection and reports status back via the status characteristic.
 *
 * Advertises as "NAFAS WRISTBAND" with bonding enabled for security.
 */

#ifndef BLE_PROVISION_H
#define BLE_PROVISION_H

#include <Arduino.h>

// Start BLE advertising and GATT server for WiFi provisioning
void bleProvisionStart();

// Stop BLE server and free resources to save memory
void bleProvisionStop();

// Check if new credentials have been received via BLE
bool bleHasNewCredentials();

// Retrieve the received SSID
String bleGetSSID();

// Retrieve the received password
String bleGetPassword();

// Send provisioning status back to mobile app via notify
// Status codes: "CONNECTING", "CONNECTED", "FAILED", "READY"
void bleSetStatus(const String &status);

// Clear the received credentials flag (after processing)
void bleClearCredentials();

#endif // BLE_PROVISION_H
