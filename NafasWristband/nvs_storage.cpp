/*
 * nvs_storage.cpp - Multi-WiFi NVS storage implementation
 *
 * Storage layout in NVS (namespace "wifi_creds"):
 *   Key "count" -> number of stored networks (0-3)
 *   Key "ssid0" / "pass0" -> first network
 *   Key "ssid1" / "pass1" -> second network
 *   Key "ssid2" / "pass2" -> third network
 *
 * When adding a 4th network, the oldest (index 0) is removed
 * and everything shifts down: [1]->0, [2]->1, new->2
 */

#include "nvs_storage.h"
#include <Preferences.h>

static Preferences prefs;

// Helper: build key string like "ssid0", "pass2"
static String ssidKey(int i) { return "ssid" + String(i); }
static String passKey(int i) { return "pass" + String(i); }

void nvsInit() {
  prefs.begin(NVS_NAMESPACE, false);
  int count = nvsGetWiFiCount();
  Serial.printf("[NVS] Initialized, %d network(s) stored\n", count);
}

int nvsGetWiFiCount() {
  return prefs.getInt("count", 0);
}

bool nvsGetWiFi(int index, String &ssid, String &password) {
  int count = nvsGetWiFiCount();
  if (index < 0 || index >= count) return false;

  ssid = prefs.getString(ssidKey(index).c_str(), "");
  password = prefs.getString(passKey(index).c_str(), "");
  return ssid.length() > 0;
}

bool nvsAddWiFi(const String &ssid, const String &password) {
  int count = nvsGetWiFiCount();

  // Check for duplicate SSID
  for (int i = 0; i < count; i++) {
    String existing = prefs.getString(ssidKey(i).c_str(), "");
    if (existing == ssid) {
      // Update password for existing network
      prefs.putString(passKey(i).c_str(), password);
      Serial.println("[NVS] Updated password for: " + ssid);
      return true;
    }
  }

  // If full, shift everything down (remove oldest at index 0)
  if (count >= NVS_MAX_NETWORKS) {
    Serial.println("[NVS] Full, removing oldest network");
    for (int i = 0; i < NVS_MAX_NETWORKS - 1; i++) {
      String s = prefs.getString(ssidKey(i + 1).c_str(), "");
      String p = prefs.getString(passKey(i + 1).c_str(), "");
      prefs.putString(ssidKey(i).c_str(), s);
      prefs.putString(passKey(i).c_str(), p);
    }
    count = NVS_MAX_NETWORKS - 1;
  }

  // Add new network at the end
  prefs.putString(ssidKey(count).c_str(), ssid);
  prefs.putString(passKey(count).c_str(), password);
  prefs.putInt("count", count + 1);

  Serial.printf("[NVS] Added network '%s' at slot %d\n", ssid.c_str(), count);
  return true;
}

void nvsRemoveWiFi(const String &ssid) {
  int count = nvsGetWiFiCount();
  int found = -1;

  // Find the network
  for (int i = 0; i < count; i++) {
    if (prefs.getString(ssidKey(i).c_str(), "") == ssid) {
      found = i;
      break;
    }
  }

  if (found < 0) return;

  // Shift entries after it down by one
  for (int i = found; i < count - 1; i++) {
    String s = prefs.getString(ssidKey(i + 1).c_str(), "");
    String p = prefs.getString(passKey(i + 1).c_str(), "");
    prefs.putString(ssidKey(i).c_str(), s);
    prefs.putString(passKey(i).c_str(), p);
  }

  // Remove last slot and decrement count
  prefs.remove(ssidKey(count - 1).c_str());
  prefs.remove(passKey(count - 1).c_str());
  prefs.putInt("count", count - 1);

  Serial.println("[NVS] Removed network: " + ssid);
}

void nvsClearAllWiFi() {
  int count = nvsGetWiFiCount();
  for (int i = 0; i < count; i++) {
    prefs.remove(ssidKey(i).c_str());
    prefs.remove(passKey(i).c_str());
  }
  prefs.putInt("count", 0);
  Serial.println("[NVS] All networks cleared");
}

void nvsPrintNetworks() {
  int count = nvsGetWiFiCount();
  Serial.printf("[NVS] Stored networks (%d):\n", count);
  for (int i = 0; i < count; i++) {
    String ssid = prefs.getString(ssidKey(i).c_str(), "");
    Serial.printf("[NVS]   [%d] %s\n", i, ssid.c_str());
  }
}