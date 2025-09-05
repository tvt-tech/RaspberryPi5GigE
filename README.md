# **Gige Camera Video Monitoring and Recording System on Raspberry Pi**

This project provides a reliable, automated system for capturing, displaying, and recording a video stream from a Gige camera on a Raspberry Pi device. The system is designed to be resilient, automatically recovering from a lost camera connection or other issues.

## **Table of Contents**

- [**Gige Camera Video Monitoring and Recording System on Raspberry Pi**](#gige-camera-video-monitoring-and-recording-system-on-raspberry-pi)
  - [**Table of Contents**](#table-of-contents)
  - [**Features**](#features)
  - [**Requirements**](#requirements)
  - [**Project Structure**](#project-structure)
  - [**Installation**](#installation)
  - [**Usage**](#usage)
  - [**Configuration**](#configuration)

## **Features**

* **Automatic Startup:** The system starts automatically after the Raspberry Pi boots, thanks to a systemd service.  
* **Resilience:** In case of a lost camera signal or stream failure, the system displays a "NO SIGNAL" screensaver on the screen and automatically attempts to restart the stream.  
* **Parallel Processing:** The video stream is simultaneously displayed on the screen (scaled to the display resolution) and recorded to an MP4 file in its original quality.  
* **Dynamic Configuration:** All key parameters (IP addresses, resolution, etc.) are located in a single configuration file for easy management.  
* **Logging:** All service logs are written to the systemd journal for convenient monitoring and debugging.

## **Requirements**

* A Raspberry Pi device running Raspberry Pi OS.  
* A connected Gige camera.  
* A power cable and a display connected to the Raspberry Pi.

## **Project Structure**

* `setup.sh`: The initial setup script. It installs necessary software, configures the network, and creates the systemd service.  
* `start.sh`: The watchdog script. It monitors the stream's status and restarts it in case of failure.  
* `gige.sh`: The main script that launches the GStreamer pipeline for video capture, display, and recording.  
* `config.sh`: The configuration file containing all the project settings.  
* `gige-stream.service`: The systemd service file. It is created automatically by the setup.sh script.

## **Installation**

1. Copy all the files (setup.sh, start.sh, gige.sh, config.sh) to a single directory on your Raspberry Pi.  

2. Grant execute permissions to the scripts:  
  ```bash
  chmod +x *.sh
  ```

3. Run the setup script. It will automatically install all dependencies, configure the network, and enable the service. **This command only needs to be run once.**  
  ```bash
  sudo ./setup.sh
  ```

## **Usage**

After running setup.sh, the system will start working automatically.

* **Monitoring:** To check the service status, use the command: 
  ```bash
  sudo systemctl status gige-stream.service
  ```

* **Restarting:** To manually restart the service:  
  ```bash
  sudo systemctl restart gige-stream.service
  ```

* **Stopping:** To stop the service:  
  ```bash
  sudo systemctl stop gige-stream.service
  ```

## **Configuration**

All settings are stored in the config.sh file. Edit this file to change parameters:

* **Camera IP Address:**  
  ```
  IP_ADDRESS="10.0.5.100/8"  
  PING_TARGET="10.0.5.244"
  ```

* **Resolution:**  
  ```
  SOURCE_WIDTH=640  
  SOURCE_HEIGHT=512
  ```

* **Restart Timeout:**  
  ```
  RETRY_TIMEOUT=5
  ```

After changing `config.sh`, to apply the changes restart the service with the command 
```bash
sudo systemctl restart gige-stream.service
```
