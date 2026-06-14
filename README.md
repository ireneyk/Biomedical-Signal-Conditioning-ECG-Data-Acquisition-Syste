# Biomedical Signal Conditioning: ECG Data Acquisition System

## 📌 Project Overview
This repository contains the technical documentation, MATLAB simulation code, and schematic designs for a comprehensive Electrocardiogram (ECG) Data Acquisition System (DAS). The primary objective of this project is to construct a highly sensitive analog front-end capable of capturing, safely isolating, and conditioning microvolt-level ECG signals from severe environmental electromagnetic noise.

## 🏗️ System Architecture
The system is engineered using a robust 4-stage Data Acquisition System block design, tailored specifically for the rigorous demands of biomedical engineering:

### 1. Bio Sensing
* **Electrodes:** Disposable Silver-Chloride (AgCl) electrodes.
* **Configuration:** Einthoven's Triangle (Right Arm, Left Arm, Left Leg) to capture differential bio-potentials and minimize electrochemical noise.

### 2. Analog Front-End (AFE) Signal Conditioning
* **Patient Isolation:** Galvanic isolation amplifier integrated to comply with IEC 60601-1 safety mandates, eliminating leakage current risks.
* **Common-Mode Rejection:** An Instrumentation Amplifier paired with an active Right-Leg Drive (RLD) circuit achieves a Common-Mode Rejection Ratio (CMRR) of over 100 dB to actively suppress 50/60 Hz power-line interference.
* **Multi-Stage Filtering:**
  * **High-Pass Filter (fc ≈ 0.05 Hz):** Eliminates baseline wander induced by respiration.
  * **Notch Filter (50/60 Hz):** Razor-sharp attenuation of residual mains power interference.
  * **Low-Pass Filter (fc ≈ 150 Hz):** Suppresses high-frequency EMG cross-talk and electrode motion artifacts.

### 3. Digitization (ADC)
* **Hardware:** Sigma-Delta ADC (e.g., Texas Instruments ADS1298).
* **Specifications:** Samples at 1,000 sps with a 16-bit resolution (65,536 discrete levels), easily satisfying the Nyquist criterion for the 150 Hz diagnostic bandwidth while capturing subtle sub-millivolt clinical features (like the QRS complex and ST-segment).

### 4. Processing & Telemetry
* **Microcontroller:** ARM Cortex-M4 or ESP32 SoC.
* **Algorithm:** Real-time Pan-Tompkins algorithm for robust R-peak detection and Heart Rate (BPM) derivation.
* **Storage/Output:** Data logging to a local SD card with wireless telemetry support via Bluetooth Low Energy (BLE) or Wi-Fi.

## 📊 Critical Engineering Metrics

| Parameter | Target Specification | Engineering Rationale |
| :--- | :--- | :--- |
| **Total System Gain** | 1,000x - 5,000x | Boosts the µV-mV ECG to utilize the full ADC dynamic range. |
| **CMRR** | ≥ 100 dB | Essential for suppressing dominant common-mode interference. |
| **Diagnostic Bandwidth** | 0.05 Hz - 150 Hz | Preserves valid cardiac morphology while rejecting out-of-band noise. |
| **ADC Resolution** | 16-bit | Guarantees amplitude precision for subtle ST-segment analysis. |
| **Sampling Rate** | 1,000 sps | Provides a 3.3x oversampling margin above the Nyquist requirement. |

## 📈 MATLAB Simulation Results
The signal conditioning chain is fully modeled and validated using a custom MATLAB dashboard. 

* **Simulation Process:** A synthetic ECG signal is heavily corrupted with power-line noise, baseline wander, and high-frequency artifacts. It is then processed through the digital equivalent of the AFE pipeline.
* **Validation:** The simulation proves the efficacy of the filter chain, demonstrating complete 50 Hz harmonic attenuation, clear extraction of the R-peaks, and accurate real-time calculation of heart rate (BPM) with a significant Signal-to-Noise Ratio (SNR) improvement.

## 🚀 How to Use This Repository

1. **Clone the repository:**
   ```bash
   git clone [https://github.com/YourUsername/ecg-signal-conditioning.git](https://github.com/YourUsername/ecg-signal-conditioning.git)
   cd ecg-signal-conditioning
