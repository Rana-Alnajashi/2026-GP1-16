#ifndef MQTT_MANAGER_H
#define MQTT_MANAGER_H

#include "sensors.h" // To get the SensorData struct

bool mqttInit();
bool mqttMaintain();
void mqttUploadAll(const SensorData &data);

#endif