/*
 * sensors.cpp - Sensor management implementation with improved accuracy
 *
 * Changes from original:
 *   1. Finger detection: checks IR signal level before trusting readings
 *   2. Moving average filter: smooths BPM and SpO2 over last N valid reads
 *   3. Tighter validation: BPM 50-150, SpO2 70-100 (realistic ranges)
 *   4. Confidence flag: tells upstream code whether to display values
 *
 * Firebase data structure is NOT changed - bpm and spo2 still upload as int.
 * Zero means "no valid reading" (same as before).
 */

#include "sensors.h"
#include "config.h"

#include <Wire.h>
#include "MAX30105.h"
#include "spo2_algorithm.h"
#include <GY521.h>
#include "bsec.h"

// Sensor objects
static MAX30105 particleSensor;
static GY521 mpu(0x68);
static Bsec iaqSensor;

// MAX30102 buffers
static uint32_t irBuffer[HR_BUFFER_SIZE];
static uint32_t redBuffer[HR_BUFFER_SIZE];
static int32_t spo2Val;
static int8_t validSpO2;
static int32_t heartRateVal;
static int8_t validHeartRate;

// ======================== MOVING AVERAGE FILTERS ========================

static int bpmHistory[HR_FILTER_SIZE];
static int spo2History[SPO2_FILTER_SIZE];
static uint8_t bpmHistIdx = 0;
static uint8_t spo2HistIdx = 0;
static uint8_t bpmHistCount = 0;   // How many valid readings stored so far
static uint8_t spo2HistCount = 0;

// Push a new valid BPM reading into the filter
static void bpmFilterPush(int value) {
  bpmHistory[bpmHistIdx] = value;
  bpmHistIdx = (bpmHistIdx + 1) % HR_FILTER_SIZE;
  if (bpmHistCount < HR_FILTER_SIZE) bpmHistCount++;
}

// Get the filtered (averaged) BPM. Returns 0 if no valid readings.
static int bpmFilterGet() {
  if (bpmHistCount == 0) return 0;
  int sum = 0;
  for (uint8_t i = 0; i < bpmHistCount; i++) {
    sum += bpmHistory[i];
  }
  return sum / bpmHistCount;
}

// Push a new valid SpO2 reading into the filter
static void spo2FilterPush(int value) {
  spo2History[spo2HistIdx] = value;
  spo2HistIdx = (spo2HistIdx + 1) % SPO2_FILTER_SIZE;
  if (spo2HistCount < SPO2_FILTER_SIZE) spo2HistCount++;
}

// Get the filtered (averaged) SpO2. Returns 0 if no valid readings.
static int spo2FilterGet() {
  if (spo2HistCount == 0) return 0;
  int sum = 0;
  for (uint8_t i = 0; i < spo2HistCount; i++) {
    sum += spo2History[i];
  }
  return sum / spo2HistCount;
}

// ======================== FINGER DETECTION ========================

// Check average IR value from collected samples.
// A finger on the sensor reflects IR light -> high values (>50K typically).
// No finger -> ambient IR is very low (<50K).
static bool checkFingerPresent() {
  uint32_t avgIR = 0;
  for (uint8_t i = 0; i < HR_BUFFER_SIZE; i++) {
    avgIR += irBuffer[i];
  }
  avgIR /= HR_BUFFER_SIZE;
  return (avgIR > IR_FINGER_THRESHOLD);
}

// ======================== SAMPLE COLLECTION ========================

// Collect 100 samples from MAX30102 (original logic preserved)
static void collectHeartSamples() {
  for (uint8_t i = 0; i < HR_BUFFER_SIZE; i++) {
    while (!particleSensor.available()) {
      particleSensor.check();
      delay(1);
    }
    redBuffer[i] = particleSensor.getRed();
    irBuffer[i]  = particleSensor.getIR();
    particleSensor.nextSample();
  }
}

// ======================== PUBLIC API ========================

void sensorsInit() {
  // I2C bus
  Wire.begin(I2C_SDA, I2C_SCL);
  Wire.setClock(400000);

  // MPU6050
  mpu.begin();
  Serial.println("[Sensors] MPU6050 initialized");

  // MAX30102
  if (!particleSensor.begin(Wire, I2C_SPEED_FAST)) {
    Serial.println("[Sensors] MAX30102 NOT FOUND - HALTING");
    while (1); // Original behavior: halt if sensor missing
  }
  particleSensor.setup(60, 4, 2, 100, 411, 4096);
  Serial.println("[Sensors] MAX30102 initialized");

  // BME680 / BSEC
  iaqSensor.begin(BME68X_I2C_ADDR_HIGH, Wire);
  bsec_virtual_sensor_t sensorList[] = {
    BSEC_OUTPUT_IAQ,
    BSEC_OUTPUT_CO2_EQUIVALENT,
    BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_TEMPERATURE,
    BSEC_OUTPUT_SENSOR_HEAT_COMPENSATED_HUMIDITY
  };
  iaqSensor.updateSubscription(sensorList, 4, BSEC_SAMPLE_RATE_LP);
  Serial.println("[Sensors] BME680/BSEC initialized");

  // Zero-initialize filter buffers
  memset(bpmHistory, 0, sizeof(bpmHistory));
  memset(spo2History, 0, sizeof(spo2History));
}

void sensorsBsecRun() {
  iaqSensor.run();
}

void sensorsRead(SensorData &data) {
  // Collect heart rate samples and calculate BPM/SpO2
  collectHeartSamples();

  // Check finger detection BEFORE running algorithm
  data.fingerDetected = checkFingerPresent();

  if (!data.fingerDetected) {
    // No finger -> report zeros, don't pollute the filter
    data.bpm = 0;
    data.spo2 = 0;
    data.healthValid = false;
    Serial.println("[Sensors] No finger detected on MAX30102");
  } else {
    // Run the SparkFun algorithm
    maxim_heart_rate_and_oxygen_saturation(
      irBuffer, HR_BUFFER_SIZE,
      redBuffer,
      &spo2Val, &validSpO2,
      &heartRateVal, &validHeartRate
    );

    // Validate BPM and spo2 with tighter range
    bool bpmOk = (validHeartRate && heartRateVal >= BPM_MIN_VALID && heartRateVal <= BPM_MAX_VALID);
    bool spo2Ok = (validSpO2 && spo2Val >= SPO2_MIN_VALID && spo2Val <= 100);

    if (bpmOk) {
      bpmFilterPush(heartRateVal);
    }
    if (spo2Ok) {
      spo2FilterPush(spo2Val);
    }

    // Output filtered values (smoothed across recent valid reads)
    data.bpm = bpmFilterGet();
    data.spo2 = spo2FilterGet();
    data.healthValid = (data.bpm > 0 && data.spo2 > 0);

    if (!bpmOk) {
      Serial.printf("[Sensors] Raw BPM rejected: %ld (valid=%d)\n", heartRateVal, validHeartRate);
    }
    if (!spo2Ok) {
      Serial.printf("[Sensors] Raw SpO2 rejected: %ld (valid=%d)\n", spo2Val, validSpO2);
    }
  }

  // Environment (latest BSEC values) - unchanged
  data.iaq         = iaqSensor.iaq;
  data.temperature = iaqSensor.temperature;
  data.humidity    = iaqSensor.humidity;
  data.co2         = iaqSensor.co2Equivalent;

  // Accelerometer 
  mpu.read();
  data.x = mpu.getAccelX();
  data.y = mpu.getAccelY();
  data.z = mpu.getAccelZ();

}