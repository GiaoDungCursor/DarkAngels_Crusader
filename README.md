# DarkAngels: Crusader 🛡️⚔️

A turn-based tactical strategy game built with **Flutter** and the **Flame Engine**. 

Command an elite squad of Space Marines through intense grid-based combat. Manage your Command Points (CP), utilize directional cover, secure strategic objectives, and call in reinforcements via thrilling Orbital Drops!

![Project Setup](https://img.shields.io/badge/Made_with-Flutter_%26_Flame-02569B?style=for-the-badge&logo=flutter&logoColor=white)

## ✨ Key Features

* **Tactical Grid Combat:** Engage in deep, turn-based warfare where positioning is everything.
* **Smart Environment:** Utilize directional cover mechanics (indicated by shield icons) to protect your Marines.
* **Threat Preview & Intent:** The movement system automatically calculates threat levels (Safe, Warning, Danger) based on enemy reach. Enemies also telegraph their intended targets before activating!
* **Orbital Drop Reinforcements:** Establish Tactical Beacons mid-battle to call down reserve Marines directly onto the front lines, complete with cinematic camera cutscenes.
* **Dynamic Objectives:** Complete varying mission types including Survival, Base Destruction, Elimination, and Extraction across uniquely designed maps (e.g., 3-lane choke-point setups).

## 🚀 Getting Started & Installation

### Prerequisites
Before you begin, ensure you have the following installed on your machine:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (Version 3.19.0 or higher recommended)
* An IDE with Flutter support (like VS Code, Android Studio, or IntelliJ IDEA)

### How to Run Locally

1. **Clone the repository:**
   ```bash
   git clone https://github.com/GiaoDungCursor/DarkAngels_Crusader.git
   ```

2. **Navigate to the project directory:**
   ```bash
   cd DarkAngels_Crusader
   ```

3. **Fetch dependencies:**
   ```bash
   flutter pub get
   ```

4. **Run the game:**
   * **For Windows (Recommended for Desktop experience):**
     ```bash
     flutter run -d windows
     ```
   * **For Web:**
     ```bash
     flutter run -d chrome
     ```
   * **For Mobile (Android/iOS):**
     Ensure your emulator is running or device is connected, then run:
     ```bash
     flutter run
     ```

## 🎮 How to Play
* **Marine Phase:** Select a Marine, choose an Action (Move, Shoot, Melee, Overwatch, Deploy Beacon), and click on the grid to execute. Pay attention to your Command Points (CP) when using special abilities!
* **Enemy Phase:** Watch out for the red dashed lines! Enemies will telegraph their intent before moving and attacking.
* **Win Conditions:** Keep an eye on the Objective Bar at the top of the screen to know exactly what needs to be done to achieve Victory.

---
*For the Emperor!*
