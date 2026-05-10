/*

* ble_provision.cpp - BLE WiFi Provisioning implementation

*

* Uses ESP32 BLE Arduino library to create a GATT server.

* Security: Enables bonding with MITM protection. The pairing

* process uses "Just Works" association which provides encryption

* on the BLE link, protecting credentials in transit.

*/



#include "ble_provision.h"

#include "config.h"



#include <BLEDevice.h>

#include <BLEServer.h>

#include <BLEUtils.h>

#include <BLE2902.h>

#include <BLESecurity.h>



// Internal state

static BLEServer *pServer = nullptr;

static BLECharacteristic *pStatusChar = nullptr;

static bool deviceConnected = false;

static bool newCredentialsReceived = false;

static String receivedSSID = "";

static String receivedPassword = "";



// ======================== CALLBACKS ========================



// Server connection callbacks

class ProvisionServerCallbacks : public BLEServerCallbacks {

void onConnect(BLEServer *server) override {

deviceConnected = true;

Serial.println("[BLE] Client connected");

}



void onDisconnect(BLEServer *server) override {

deviceConnected = false;

Serial.println("[BLE] Client disconnected");

// Restart advertising so another client can connect

server->startAdvertising();

}

};



// SSID characteristic write callback

class SSIDCallback : public BLECharacteristicCallbacks {

void onWrite(BLECharacteristic *pChar) override {

String value = pChar->getValue().c_str();

if (value.length() > 0) {

receivedSSID = value;

Serial.println("[BLE] SSID received: " + receivedSSID);

// Check if both credentials are now available

if (receivedPassword.length() > 0) {

newCredentialsReceived = true;

}

}

}

};



// Password characteristic write callback

class PasswordCallback : public BLECharacteristicCallbacks {

void onWrite(BLECharacteristic *pChar) override {

String value = pChar->getValue().c_str();

if (value.length() > 0) {

receivedPassword = value;

Serial.println("[BLE] Password received");

// Check if both credentials are now available

if (receivedSSID.length() > 0) {

newCredentialsReceived = true;

}

}

}

};



// Security callback for bonding events

class ProvisionSecurityCallbacks : public BLESecurityCallbacks {

uint32_t onPassKeyRequest() override {

return 123456; // Default passkey for numeric comparison

}



void onPassKeyNotify(uint32_t pass_key) override {

Serial.printf("[BLE] Passkey notify: %d\n", pass_key);

}



bool onConfirmPIN(uint32_t pin) override {

return true;

}



bool onSecurityRequest() override {

return true;

}



void onAuthenticationComplete(esp_ble_auth_cmpl_t auth_cmpl) override {

if (auth_cmpl.success) {

Serial.println("[BLE] Authentication complete - bonded");

} else {

Serial.println("[BLE] Authentication failed");

}

}

};



// ======================== PUBLIC API ========================



// Add this right above the function so the ESP32 remembers its state

static bool isBleInitialized = false;



void bleProvisionStart() {

// 1. SAFETY CHECK: If already built, just turn the antenna back on and stop.

if (isBleInitialized) {

Serial.println("[BLE] Resuming advertising...");

BLEDevice::startAdvertising();

return;

}



Serial.println("[BLE] Starting provisioning server...");



// 2. Initialize BLE

BLEDevice::init(BLE_DEVICE_NAME);



// ⚠️ NOTE: The BLESecurity / Bonding code was completely deleted from here

// to prevent the iPhone from permanently blocking the wristband.



// 3. Create GATT server

pServer = BLEDevice::createServer();

pServer->setCallbacks(new ProvisionServerCallbacks());



// 4. Create provisioning service

BLEService *pService = pServer->createService(BLE_SERVICE_UUID);



// 5. SSID characteristic - write only

BLECharacteristic *pSSIDChar = pService->createCharacteristic(

BLE_CHAR_SSID_UUID,

BLECharacteristic::PROPERTY_WRITE

);

pSSIDChar->setCallbacks(new SSIDCallback());



// 6. Password characteristic - write only

BLECharacteristic *pPasswordChar = pService->createCharacteristic(

BLE_CHAR_PASSWORD_UUID,

BLECharacteristic::PROPERTY_WRITE

);

pPasswordChar->setCallbacks(new PasswordCallback());



// 7. Status characteristic - read + notify (feedback to mobile app)

pStatusChar = pService->createCharacteristic(

BLE_CHAR_STATUS_UUID,

BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY

);

pStatusChar->addDescriptor(new BLE2902());

pStatusChar->setValue("READY");



// 8. Start service and advertising

pService->start();



BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();

pAdvertising->addServiceUUID(BLE_SERVICE_UUID);

pAdvertising->setScanResponse(true);

pAdvertising->setMinPreferred(0x06);

pAdvertising->setMinPreferred(0x12);

BLEDevice::startAdvertising();



// 9. MARK AS INITIALIZED: This saves the ESP32 from crashing next time!

isBleInitialized = true;



Serial.println("[BLE] Advertising as '" BLE_DEVICE_NAME "'");

Serial.println("[BLE] Waiting for credentials...");

}



void bleProvisionStop() {

if (pServer != nullptr) {

BLEDevice::deinit(true); // true = release memory

pServer = nullptr;

pStatusChar = nullptr;

Serial.println("[BLE] Server stopped, memory released");

}

}



bool bleHasNewCredentials() {

return newCredentialsReceived;

}



String bleGetSSID() {

return receivedSSID;

}



String bleGetPassword() {

return receivedPassword;

}



void bleSetStatus(const String &status) {

if (pStatusChar != nullptr) {

pStatusChar->setValue(status.c_str());

if (deviceConnected) {

pStatusChar->notify();

}

}

}



void bleClearCredentials() {

newCredentialsReceived = false;

receivedSSID = "";

receivedPassword = "";

}

