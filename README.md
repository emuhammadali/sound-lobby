# 🎵 SoundLobby

**SoundLobby** is a real-time social music streaming application that lets users create or join virtual music lobbies. A designated DJ can stream synchronized music playback for all participants, creating a shared listening experience. Users can chat, request songs, and enjoy a collaborative music session together.

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

---

## 📖 Overview

SoundLobby is built to bring people together through music. Whether you're hosting a listening party with friends or running a live DJ session, SoundLobby ensures that every user hears the exact same audio at the exact same moment. Powered by Firebase and a custom YouTube audio extraction API, it delivers a seamless and synchronized experience.

---

## ✨ Key Features

| Feature | Description |
| :--- | :--- |
| 🔐 **Firebase Authentication** | Secure user login and registration. |
| ☁️ **Cloud Firestore** | Real-time database for lobby management and sync. |
| 🎧 **Real-time Synced Playback** | Every user hears the same track at the same time. |
| 👑 **Role-Based Lobby Management** | Assign DJs and listeners with specific permissions. |
| 🔍 **Music Search API** | Search and fetch songs from YouTube. |
| 💬 **Live Chat System** | Chat with everyone in the lobby while music plays. |
| 📋 **Queue Management** | Request songs and manage the playlist in real-time. |

---

## 🎵 Music Playback & Synchronization

The application fetches music metadata and audio streams using a custom-built API.

- **Metadata Endpoint:**  
  `https://bardi.fsc-clan.eu/search?query=<song-name>`
- **Audio Stream Endpoint:**  
  `https://bardi.fsc-clan.eu/stream/<id_retrieved_from_metadata>`

> **Note:** The Music API uses [yt-dlp](https://github.com/yt-dlp/yt-dlp) to fetch audio streams from YouTube.  
> [![GitHub Repo](https://img.shields.io/badge/Repository-yt--audio--api-181717?style=for-the-badge&logo=github)](https://github.com/Aleem-27/yt-audio-api)  
> [![GitHub Profile](https://img.shields.io/badge/GitHub-Aleem--27-181717?style=for-the-badge&logo=github)](https://github.com/Aleem-27)

### 🔄 Synced Events
Playback events are broadcasted in real-time to all connected users, ensuring perfect synchronization for:
- ▶️ Play
- ⏸️ Pause
- ⏯️ Resume
- ⏮️ Previous / ⏭️ Next Song
- ⏩ Seek
- 🔄 Track Changes

---

## 📸 Screenshots

| | | |
| :---: | :---: | :---: |
| [![Screenshot 1](https://i.postimg.cc/JzWZhTkK/Whats-App-Image-2026-07-09-at-11-52-43-AM.jpg)](https://postimg.cc/zV0VtFpR) | [![Screenshot 2](https://i.postimg.cc/YCwYSXWR/Whats-App-Image-2026-07-09-at-11-52-44-AM.jpg)](https://postimg.cc/PP2P3QKv) | [![Screenshot 3](https://i.postimg.cc/qvdy7m3s/Whats-App-Image-2026-07-09-at-11-52-45-AM.jpg)](https://postimg.cc/LnNnC3v5) |
| [![Screenshot 4](https://i.postimg.cc/L8MLsy1k/Whats-App-Image-2026-07-09-at-11-52-45-AM-(1).jpg)](https://postimg.cc/crXr9BT6) | [![Screenshot 5](https://i.postimg.cc/NfXRBh5P/Whats-App-Image-2026-07-09-at-11-52-45-AM-(2).jpg)](https://postimg.cc/ykVDybhF) | [![Screenshot 6](https://i.postimg.cc/L6Pj2dnk/Whats-App-Image-2026-07-09-at-11-52-46-AM.jpg)](https://postimg.cc/2Vz17Kd3) |

---

## 🎥 Demo Video

Watch the full demo of SoundLobby in action:

[![Watch Demo](https://img.shields.io/badge/▶%20Watch%20Demo-4285F4?style=for-the-badge&logo=google-drive&logoColor=white)](https://drive.google.com/file/d/1BCwiY0sjqs2tFD4bwRYCyJ5Y9rMOXGqw/view?usp=sharing)

---

## 🛠️ Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Firebase (Authentication, Cloud Firestore)
- **API:** Custom YouTube Audio API (yt-dlp)
- **Platforms:** Android, iOS, Web, Windows, macOS, Linux

---

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites
- Flutter SDK installed on your machine.
- A Firebase project set up.

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/Aleem-27/sound-lobby.git