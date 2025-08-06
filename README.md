# Fedorable v2.0

</h1>
<p align="center">
  <img width="300" height="300" src="./images/logo.png">
</p>

Fedorable is a **post-install setup utility** for Fedora GNOME, designed to streamline common configuration tasks after installing Fedora.  
It provides an interactive `dialog`-based menu for installing software, enabling repositories, configuring the desktop, and applying useful tweaks.

---

## Features

Fedorable can:
- Enable additional repositories (e.g. RPM Fusion, Flathub)
- Install essential software and fonts
- Configure GNOME appearance and behaviour
- Install hardware drivers
- Apply common performance tweaks

---

## Requirements

- Fedora (tested on GNOME edition)
- Root privileges (`sudo` or root login)
- Internet connection

Fedorable will install `dialog` automatically if it is missing.

---

## Installation

Clone this repository and run the script:

```bash
git clone https://github.com/smittix/fedorable.git
cd fedorable
chmod +x fedorable.sh
sudo ./fedorable.sh
```


## Menu Structure (v2.0)

Fedorable’s interface is divided into **five main sections**:

### **Main Menu**

```
1  System Setup
2  Software Installation
3  Hardware Drivers
4  Customisation
5  Quit
```

### **System Setup**

* **Enable RPM Fusion** – Enables free & non-free RPM Fusion repositories.
* **Update Firmware** – Checks and installs firmware updates.
* **Optimise DNF Speed** – Enables parallel downloads for faster package installs.
* **Enable Flathub** – Adds the Flathub repository and installs Flatpak apps listed in `assets/flatpak-packages.txt`.

### **Software Installation**

* **Install Software Packages** – Installs packages listed in `assets/dnf-packages.txt`.
* **Install Oh-My-ZSH** – Installs ZSH, Oh-My-ZSH, plugins, and Starship prompt.
* **Install Extras (Fonts & Codecs)** – Installs extra fonts, media codecs, and icon themes (without switching themes).

### **Hardware Drivers**

* **Install Intel Media Driver** – VA-API driver for Intel GPUs.
* **Install AMD Hardware Codecs** – VA-API and VDPAU drivers for AMD GPUs.
* **Install NVIDIA Drivers** – Installs NVIDIA proprietary drivers via RPM Fusion.

### **Customisation**

* **Set Hostname** – Changes the system hostname.
* **Setup Custom Fonts** – Configures GNOME interface and monospace fonts.
* **Customise Clock** – Adjusts time format and date display in GNOME top bar.
* **Enable Window Buttons** – Adds minimise and maximise buttons.
* **Center New Windows** – Centers windows on open.
* **Disable Auto-Maximise** – Prevents automatic window maximisation.
* **Apply All Customisations** – Applies all above tweaks at once.

---

## Screenshots

*(Screenshots to be added)*

---

## Contributing

Pull requests are welcome! Please test changes before submitting.

---

## License

This project is licensed under the MIT License
