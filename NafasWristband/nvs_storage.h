/*
 * nvs_storage.h - Multi-WiFi credential storage (up to 3 networks)
 *
 * Stores WiFi networks in NVS using indexed keys:
 *   ssid0/pass0, ssid1/pass1, ssid2/pass2
 *
 * On boot, wifi_manager tries each stored network in order.
 * New networks received via BLE are added (not overwritten),
 * unless the SSID already exists (duplicate prevention).
 * When full, the oldest entry (index 0) is removed and
 * entries shift down.
 */

#ifndef NVS_STORAGE_H
#define NVS_STORAGE_H

#include <Arduino.h>
#include "config.h"

// Initialize NVS storage
void nvsInit();

// Add a WiFi network. Prevents duplicates. Returns true if added.
bool nvsAddWiFi(const String &ssid, const String &password);

// Get the number of stored networks (0 to NVS_MAX_NETWORKS)
int nvsGetWiFiCount();

// Load network at index (0-based). Returns false if index is empty.
bool nvsGetWiFi(int index, String &ssid, String &password);

// Remove a specific network by SSID
void nvsRemoveWiFi(const String &ssid);

// Clear ALL stored networks
void nvsClearAllWiFi();

// Print all stored networks to Serial (for debugging)
void nvsPrintNetworks();

#endif // NVS_STORAGE_H