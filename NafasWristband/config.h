/*
 * config.h - Central configuration for Nafas Wristband
 *
 * All tunable parameters in one place. Hardware pins, timing,
 * Firebase credentials, and BLE config.
 */

#ifndef CONFIG_H
#define CONFIG_H

// ======================== HARDWARE PINS ========================
#define I2C_SDA           21
#define I2C_SCL           22
#define VIBRATION_PIN     12
#define LED_BUILTIN_BLUE  2

// ======================== TIMING ========================
#define UPLOAD_INTERVAL_MS    15000   // Sensor upload interval
#define WIFI_CONNECT_TIMEOUT  15000   // Max ms to wait for WiFi connect per network
#define WIFI_RETRY_MAX        2       // Retries per network before trying next

// ======================== SENSOR CONFIG ========================
#define HR_BUFFER_SIZE        100     // MAX30102 sample buffer size
#define BPM_MIN_VALID         50      // Minimum plausible BPM
#define BPM_MAX_VALID         150     // Maximum plausible BPM
#define SPO2_MIN_VALID        70      // Minimum plausible SpO2%
#define IR_FINGER_THRESHOLD   50000   // IR value below this = no finger on sensor
#define HR_FILTER_SIZE        5       // Moving average window for BPM
#define SPO2_FILTER_SIZE      5       // Moving average window for SpO2

// ======================== BATTERY (simulated) ========================
#define BATTERY_CAPACITY_MAH  500     // Li-Po capacity in mAh
#define BATTERY_DRAW_MA       200     // Estimated average current draw (mA)

// ======================== BLE ========================
#define BLE_DEVICE_NAME   "NAFAS WRISTBAND"

// BLE Service and Characteristic UUIDs (custom)
#define BLE_SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define BLE_CHAR_SSID_UUID      "beb5483e-36e1-4688-b7f5-ea07361b26a8"
#define BLE_CHAR_PASSWORD_UUID  "1c95d5e3-d8f7-413a-bf3d-7a2e5d7be87e"
#define BLE_CHAR_STATUS_UUID    "d1a7e84c-5ef2-4d9a-b9c3-f8a6b3c21e07"

// ======================== NVS ========================
#define NVS_NAMESPACE      "wifi_creds"
#define NVS_MAX_NETWORKS   3          // Store up to 3 WiFi networks

// --- AWS MQTT CONFIGURATION ---
#define MQTT_BROKER    "a29m1l790wtzg-ats.iot.eu-central-1.amazonaws.com" 
#define MQTT_PORT      8883
#define MQTT_TOPIC     "nafas/wristband_1/vitals"

// 1. Amazon Root CA 1
static const char* root_ca = R"EOF(
-----BEGIN CERTIFICATE-----
MIIDQTCCAimgAwIBAgITBmyfz5m/jAo54vB4ikPmljZbyjANBgkqhkiG9w0BAQsF
ADA5MQswCQYDVQQGEwJVUzEPMA0GA1UEChMGQW1hem9uMRkwFwYDVQQDExBBbWF6
b24gUm9vdCBDQSAxMB4XDTE1MDUyNjAwMDAwMFoXDTM4MDExNzAwMDAwMFowOTEL
MAkGA1UEBhMCVVMxDzANBgNVBAoTBkFtYXpvbjEZMBcGA1UEAxMQQW1hem9uIFJv
b3QgQ0EgMTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALJ4gHHKeNXj
ca9HgFB0fW7Y14h29Jlo91ghYPl0hAEvrAIthtOgQ3pOsqTQNroBvo3bSMgHFzZM
9O6II8c+6zf1tRn4SWiw3te5djgdYZ6k/oI2peVKVuRF4fn9tBb6dNqcmzU5L/qw
IFAGbHrQgLKm+a/sRxmPUDgH3KKHOVj4utWp+UhnMJbulHheb4mjUcAwhmahRWa6
VOujw5H5SNz/0egwLX0tdHA114gk957EWW67c4cX8jJGKLhD+rcdqsq08p8kDi1L
93FcXmn/6pUCyziKrlA4b9v7LWIbxcceVOF34GfID5yHI9Y/QCB/IIDEgEw+OyQm
jgSubJrIqg0CAwEAAaNCMEAwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMC
AYYwHQYDVR0OBBYEFIQYzIU07LwMlJQuCFmcx7IQTgoIMA0GCSqGSIb3DQEBCwUA
A4IBAQCY8jdaQZChGsV2USggNiMOruYou6r4lK5IpDB/G/wkjUu0yKGX9rbxenDI
U5PMCCjjmCXPI6T53iHTfIUJrU6adTrCC2qJeHZERxhlbI1Bjjt/msv0tadQ1wUs
N+gDS63pYaACbvXy8MWy7Vu33PqUXHeeE6V/Uq2V8viTO96LXFvKWlJbYK8U90vv
o/ufQJVtMVT8QtPHRh8jrdkPSHCa2XV4cdFyQzR1bldZwgJcJmApzyMZFo6IQ6XU
5MsI+yMRQ+hDKXJioaldXgjUkK642M4UwtBV8ob2xJNDd2ZhwLnoQdeXeGADbkpy
rqXRfboQnoZsG4q5WTP468SQvvG5
-----END CERTIFICATE-----
)EOF";

// 2. Device Certificate (xxx-certificate.pem.crt)
static const char* device_cert = R"EOF(
-----BEGIN CERTIFICATE-----
MIIDWTCCAkGgAwIBAgIUXjqdqYl2LHbS00c6LjUb6Y/+QtIwDQYJKoZIhvcNAQEL
BQAwTTFLMEkGA1UECwxCQW1hem9uIFdlYiBTZXJ2aWNlcyBPPUFtYXpvbi5jb20g
SW5jLiBMPVNlYXR0bGUgU1Q9V2FzaGluZ3RvbiBDPVVTMB4XDTI2MDQxNzIwNDIx
MVoXDTQ5MTIzMTIzNTk1OVowHjEcMBoGA1UEAwwTQVdTIElvVCBDZXJ0aWZpY2F0
ZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOLgEYqoO7aMa7+J5M3o
GF6zMKDd5rBFS//4dxXPNBROEQwNxK4ZtfeIp5IsWgdvemsV9J3OymYnJX2vELDl
xB2Op7Fb1PGbO8DWKwMhGVkLQBM+CxOKFv9VD4Pxcv1GfjzvjyOmavBgn4/PFhan
VyKjomPHOnNDSRAUiYginolzNK6vwn+PvKQoV1widOo2jg8G74n+SIZ1YT1RCmvq
QcuyuxgWLIcFb/iseLiGsIXsr45hOUy5y+hKNnEckvJgwtUhm6YICqlTvqD68VFv
Mzzna9bgX/xJgJWOVxAp2gDN5n5tclPehkICAT/+FXlR1ogXRFUr44A5Ek+EHqK8
nNsCAwEAAaNgMF4wHwYDVR0jBBgwFoAUYFloGAvkXZDZu3jGGJp2U4VGVxowHQYD
VR0OBBYEFOOfaGOrTLfpBDNLZK56LusfZymMMAwGA1UdEwEB/wQCMAAwDgYDVR0P
AQH/BAQDAgeAMA0GCSqGSIb3DQEBCwUAA4IBAQArNcT/2qu2iEfwzSEVJH9mwwNw
ur85D60k5ABSk6j+0rj67NXbOsIwqHuY2Ir4O7Gctvol1qXC4jLlMM7VHqIyfgeN
2lP50wtiPOwJfDRE4IuGL3PBPwv9TsseL3xVOjhb+vntHGLAsW4bOA0MAiG318Co
Lwo2Kyfr4GJ9tHyyczXWJxJMMCji/6xHAYr2G/iqScfVM6yh9yrtKVZwrdl8IkZO
DPcuMFXPSzC2jRYQ9dEc7WLV2p7K2vYRAC4YGXJ+M/4LZelMRJ59/X/xSk6FX3rT
G0MEpO3y6CFWwK/z+kydW1erOP840jO0Mz5LjYSSSWYX6vBxn4xEbH6Ft1kO
-----END CERTIFICATE-----

)EOF";

// 3. Private Key (xxx-private.pem.key)
static const char* device_private_key = R"EOF(
-----BEGIN RSA PRIVATE KEY-----
MIIEogIBAAKCAQEA4uARiqg7toxrv4nkzegYXrMwoN3msEVL//h3Fc80FE4RDA3E
rhm194inkixaB296axX0nc7KZiclfa8QsOXEHY6nsVvU8Zs7wNYrAyEZWQtAEz4L
E4oW/1UPg/Fy/UZ+PO+PI6Zq8GCfj88WFqdXIqOiY8c6c0NJEBSJiCKeiXM0rq/C
f4+8pChXXCJ06jaODwbvif5IhnVhPVEKa+pBy7K7GBYshwVv+Kx4uIawheyvjmE5
TLnL6Eo2cRyS8mDC1SGbpggKqVO+oPrxUW8zPOdr1uBf/EmAlY5XECnaAM3mfm1y
U96GQgIBP/4VeVHWiBdEVSvjgDkST4Qeoryc2wIDAQABAoIBAEhrri3MtgL3oA1s
PxVbWSwhlwxCyTjLZg83iQv1MHKq2NY4LuhEXMm/XX5Tmgl1lGZKg+M792/UXytX
jsRpE8k7mFwNLFRTcSeFNgWxsx2xcaqyy2ZZVi37QRClKkefEPzym4aNwOUqcsS9
HhftIutzwIqJNidE+zWe2KgUJPdKrRXdTYdA43E1Ev+AwUM7AFZFaEu/NmuI3sGq
35WGw9csavsRsuwxv5ePkUqfzMiMt1BrelnjIxosg4mf8i6JfCSR6QDy3+Rd1W6f
XezzCI1B5q8VSzQDJB33ttn3mLpL7ZI8MjXEFeD4W5O0vac86P5JEwEQbMb4A6Fr
fMurCoECgYEA/rpY8/hxOEkTKR5w3wGJ47SOv5f2nDyAL0DvGzglnm/+FmBdY7uC
SppMk0BDp3vrPZpt58XsLFCVihR8Ti+MRNTxXxScOcX6xMo8QF1xvXNgefq1kfdr
g3ErX4xNLLssocZM0ATF9K83XHTwbOKOkAocLQO0+a/7mY7yJ4v7ANkCgYEA5AId
AZL77S1030e7K4tTojZfiOthBrY9g06Yi6LmsIBp6/4mdArLWPG4MFV+wnOFHjA4
f1/e/OvNw0rdNjFok8HzLcArGI7K596ElTILfWtrGAcYX0gkeRDbtmSm5gdolnxK
erwTbvQ4baCpAQn0tdwIx+XVggzgoj4uuD/f+tMCgYBr0L3zzZVGaI+mmM7XZRRS
/8pnx89Gw8jRt189Gx+5Ftfp6rG8k9IK95IvxUSdcDLaaTHZpwlWnGke/5q5kSCC
xcrAHr4dKfIBN0QXTjXlJR+RoY8WkC2+fbkJAR5tL3AtrPw4E70h2sPI62oT/DSx
PMY+O1JvWJBap4lROctsyQKBgF1biCjm2AQrApmRs0+HAr1+aeuUBOxMni8vdUJn
dvF6AuS/8Vq+OLi4cGRJ/Vb9GdpcgCWXSaRhoKR/+MeBv4IQfdOTxZGOlgIOmFbG
YPH/k6AI96+7yENR5cRuve+dxPMo/Q34CDT8BkbM66YjP3FfILFIp/1R7IBB2btT
XBBFAoGAbVDbu+TfGDQ3wlqA96wMYFY6T9W3Pk7P/xQWvFC46p0Kb0W2ITyUFWQA
qGTu6vysIymbY/J2igY+Ylo7XhMSOxYbsW1j10uGsSfs+ZOOIkDRUALnaIkXIMPL
IywrCVOvEXn28H/ZLoCL+kfmYvcNARALbJYu53IoVy9ckDgLdFs=
-----END RSA PRIVATE KEY-----
)EOF";

#endif // CONFIG_H