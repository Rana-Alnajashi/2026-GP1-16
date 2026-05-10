/*
 * sensors.h - Sensor management for Nafas Wristband
 *
 * Encapsulates initialization and reading for:
 *   - MAX30102: Heart rate (BPM) and SpO2 with filtering
 *   - MPU6050:  3-axis accelerometer
 *   - BME680:   IAQ, temperature, humidity, CO2 (via BSEC)
 *
 * Improvements over original:
 *   - Moving average filter smooths BPM and SpO2 across reads
 *   - Finger detection via IR threshold rejects bad readings
 *   - Tighter validation range (50-150 BPM, 70-100 SpO2)
 *   - Confidence flag indicates if readings are trustworthy
 */

#ifndef SENSORS_H
#define SENSORS_H

#include <Arduino.h>

// Sensor data structure - extends original with quality metadata
struct SensorData {
  // Health (MAX30102)
  int bpm;              // Filtered BPM (0 if invalid)
  int spo2;             // Filtered SpO2 (0 if invalid)
  bool fingerDetected;  // True if finger is on the sensor
  bool healthValid;     // True if BPM/SpO2 readings are confident

  // Environment (BME680/BSEC)
  float iaq;
  float temperature;
  float humidity;
  float co2;

  // Motion (MPU6050)
  float x; 
  float y;
  float z;
};

// Initialize all sensors. Halts if MAX30102 is not found (original behavior).
void sensorsInit();

// Run BSEC algorithm - must be called every loop iteration
void sensorsBsecRun();

// Collect heart rate samples and compute BPM/SpO2, read accelerometer,
// and populate the SensorData struct with all current readings.
void sensorsRead(SensorData &data);

#endif // SENSORS_H