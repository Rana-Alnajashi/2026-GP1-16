<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nafas – Smart Asthma Monitoring System</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #24292e;
            max-width: 900px;
            margin: 0 auto;
            padding: 30px;
        }
        h1, h2, h3 {
            margin-top: 24px;
            margin-bottom: 16px;
            font-weight: 600;
            line-height: 1.25;
        }
        h1 {
            font-size: 2em;
            border-bottom: 1px solid #eaecef;
            padding-bottom: 0.3em;
        }
        h2 {
            font-size: 1.5em;
            border-bottom: 1px solid #eaecef;
            padding-bottom: 0.3em;
        }
        h3 {
            font-size: 1.25em;
        }
        p {
            margin-top: 0;
            margin-bottom: 16px;
        }
        ul, ol {
            padding-left: 2em;
            margin-top: 0;
            margin-bottom: 16px;
        }
        .badges {
            margin-bottom: 20px;
        }
        .badges img {
            margin-right: 5px;
            vertical-align: middle;
        }
        pre {
            background-color: #f6f8fa;
            border-radius: 6px;
            padding: 16px;
            overflow: auto;
            line-height: 1.45;
        }
        code {
            font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, Consolas, "Liberation Mono", monospace;
            font-size: 85%;
        }
        hr {
            height: 1px;
            padding: 0;
            margin: 24px 0;
            background-color: #eaecef;
            border: 0;
        }
        .note {
            font-style: italic;
            color: #586069;
        }
    </style>
</head>
<body>

    <h1>🫁 Nafas – Smart Asthma Monitoring System</h1>

    <div class="badges">
        <img src="https://img.shields.io/badge/iOS-Swift-orange" alt="iOS Swift">
        <img src="https://img.shields.io/badge/Backend-Firebase-yellow" alt="Firebase Backend">
        <img src="https://img.shields.io/badge/Hardware-IoT-blue" alt="Hardware IoT">
        <img src="https://img.shields.io/badge/Status-Active-brightgreen" alt="Active Status">
    </div>

    <h2>📖 Overview</h2>
    <p><strong>Nafas</strong> is a comprehensive, IoT-based smart asthma monitoring system designed to support continuous respiratory health awareness in children.</p>
    <p>The system seamlessly integrates wearable physiological and environmental sensors with cloud-based data processing. By continuously collecting health indicators through a custom wristband device, Nafas delivers real-time risk alerts and weather-based environmental recommendations to caregivers via a secure iOS application.</p>

    <hr>

    <h2>🎯 Project Goals</h2>
    <ul>
        <li>✅ <strong>Continuous Health Monitoring:</strong> Track vital signs in real-time using wearable sensors.</li>
        <li>✅ <strong>Environmental Context:</strong> Provide proactive recommendations based on localized weather and air quality data.</li>
        <li>✅ <strong>Early Intervention:</strong> Support early awareness of abnormal physiological changes that may precede an asthma event.</li>
        <li>✅ <strong>Cloud Integration:</strong> Ensure secure, low-latency data processing and storage.</li>
        <li>✅ <strong>Caregiver Support:</strong> Assist parents in proactive, data-driven asthma management.</li>
        <li>✅ <strong>Vision 2030 Alignment:</strong> Contribute to Saudi Arabia's Vision 2030 digital health transformation initiatives.</li>
    </ul>

    <hr>

    <h2>🗂️ Repository Structure</h2>
<pre><code>📦 Nafas-Project
 ┣ 📂 NafasWristband       # C++/Arduino firmware for the microcontroller and sensors
 ┣ 📂 NafasApp             # Swift source code for the iOS mobile application
 ┣ 📜 README.md            # Project documentation
 ┗ 📜 LICENSE              # Licensing information</code></pre>
    <p class="note">(Note: Navigate to the <code>NafasWristband</code> directory for specific hardware setup and firmware flashing instructions).</p>

    <hr>

    <h2>🏗️ System Architecture</h2>
    <p>Nafas is built on a robust, four-layer IoT architecture:</p>
    <ol>
        <li><strong>Perception Layer:</strong> Wearable physiological and environmental sensors collect raw health telemetry.</li>
        <li><strong>Network Layer:</strong> Secure communication via Bluetooth Low Energy (BLE) for provisioning and Wi-Fi for continuous cloud telemetry (MQTT).</li>
        <li><strong>Data Processing Layer:</strong> Firebase Realtime Database handles state synchronization, while Google Cloud executes the predictive models.</li>
        <li><strong>Application Layer:</strong> A native iOS application provides the user interface, alerting system, and weather integration.</li>
    </ol>

    <hr>

    <h2>🚀 Key Features</h2>
    <ul>
        <li><strong>Real-Time Physiological Monitoring:</strong> Continuous tracking of Heart Rate and SpO₂.</li>
        <li><strong>Environmental Awareness:</strong> Indoor Air Quality (IAQ) and Volatile Organic Compound (VOC) sensing.</li>
        <li><strong>Cloud-Based AI Deployment:</strong> Remote execution of health models for risk prediction.</li>
        <li><strong>Contextual Recommendations:</strong> Weather-driven advice powered by external APIs.</li>
        <li><strong>Closed-Loop Alerts:</strong> Haptic feedback on the wristband and push notifications on the mobile app.</li>
    </ul>

    <hr>

    <h2>💻 Technologies Used</h2>

    <h3>Hardware (Perception Layer)</h3>
    <ul>
        <li><strong>MAX30102:</strong> Pulse Oximetry & Heart Rate (PPG)</li>
        <li><strong>MPU6050:</strong> Accelerometer & Gyroscope (Motion/Activity Monitoring)</li>
        <li><strong>BME688:</strong> Environmental Sensor (IAQ & VOC)</li>
    </ul>

    <h3>Software & Cloud</h3>
    <ul>
        <li><strong>Mobile App:</strong> Swift (Native iOS Development)</li>
        <li><strong>Backend:</strong> Firebase Realtime Database</li>
        <li><strong>Cloud Computing:</strong> Google Cloud (Model Deployment)</li>
        <li><strong>External API:</strong> Tomorrow.io Weather API</li>
    </ul>

    <h3>Project Management & Design</h3>
    <ul>
        <li><strong>Version Control:</strong> GitHub</li>
        <li><strong>UI/UX Design:</strong> Figma</li>
        <li><strong>Agile Management:</strong> Jira</li>
    </ul>

    <hr>

    <h2>⚙️ Getting Started</h2>

    <h3>Hardware Setup</h3>
    <ol>
        <li>Navigate to the <code>NafasWristband</code> folder.</li>
        <li>Ensure you have the required libraries installed for the MAX30102, MPU6050, and BME688 sensors.</li>
        <li>Flash the firmware to your microcontroller following the instructions in the hardware sub-directory.</li>
    </ol>

    <h3>iOS App Setup</h3>
    <ol>
        <li>Clone the repository to your local machine.</li>
        <li>Open the <code>.xcodeproj</code> or <code>.xcworkspace</code> file in Xcode.</li>
        <li>Ensure your Firebase <code>GoogleService-Info.plist</code> is correctly configured in the project root.</li>
        <li>Build and run on your target iOS device.</li>
    </ol>

    <hr>

    <p class="note" style="text-align: center;">This project was developed to advance digital healthcare solutions and empower caregivers with actionable, real-time pediatric asthma monitoring.</p>

</body>
</html>
