# SoundLobby

SoundLobby allows users to create or join music lobbies where DJs can stream synchronized music playback for all participants in real time. Users can chat, request songs, and enjoy shared listening sessions together.

## Features

- Firebase Authentication
- Firebase Cloud Firestore
- Real-time synced playback
- Role-based lobby management
- Music search API
- Chatting system
- Songs Queue Management

> [!NOTE]
> The Music API uses [yt-dlp](https://github.com/yt-dlp/yt-dlp) tool to fetch audio streams from YouTube.<br>
>
> [![GitHub Repo](https://img.shields.io/badge/Repository-yt--audio--api-181717?style=for-the-badge&logo=github)](https://github.com/Aleem-27/yt-audio-api)
> [![GitHub Profile](https://img.shields.io/badge/GitHub-Aleem--27-181717?style=for-the-badge&logo=github)](https://github.com/Aleem-27)

## Music Playback

Music metadata is fetched from:

```bash
https://bardi.fsc-clan.eu/search?query=<song-name>
```

Audio URL is fetched from:
```bash
https://bardi.fsc-clan.eu/stream/<id_retreived_from_metadata>
```

Playback events are synchronized in real time across all connected users.

### Synced events include
- Play
- Pause
- Resume
- Prev/Next song
- Seek
- Track changes

## Screenshots
[![Whats-App-Image-2026-07-09-at-11-52-43-AM.jpg](https://i.postimg.cc/JzWZhTkK/Whats-App-Image-2026-07-09-at-11-52-43-AM.jpg)](https://postimg.cc/zV0VtFpR)
[![Whats-App-Image-2026-07-09-at-11-52-44-AM.jpg](https://i.postimg.cc/YCwYSXWR/Whats-App-Image-2026-07-09-at-11-52-44-AM.jpg)](https://postimg.cc/PP2P3QKv)
[![Whats-App-Image-2026-07-09-at-11-52-45-AM.jpg](https://i.postimg.cc/qvdy7m3s/Whats-App-Image-2026-07-09-at-11-52-45-AM.jpg)](https://postimg.cc/LnNnC3v5)
[![Whats-App-Image-2026-07-09-at-11-52-45-AM-(1).jpg](https://i.postimg.cc/L8MLsy1k/Whats-App-Image-2026-07-09-at-11-52-45-AM-(1).jpg)](https://postimg.cc/crXr9BT6)
[![Whats-App-Image-2026-07-09-at-11-52-45-AM-(2).jpg](https://i.postimg.cc/NfXRBh5P/Whats-App-Image-2026-07-09-at-11-52-45-AM-(2).jpg)](https://postimg.cc/ykVDybhF)
[![Whats-App-Image-2026-07-09-at-11-52-46-AM.jpg](https://i.postimg.cc/L6Pj2dnk/Whats-App-Image-2026-07-09-at-11-52-46-AM.jpg)](https://postimg.cc/2Vz17Kd3)

# Demo Video
Watch the full demo here:

[![Watch Demo](https://img.shields.io/badge/▶%20Watch%20Demo-4285F4?style=for-the-badge&logo=google-drive&logoColor=white)]([YOUR_GOOGLE_DRIVE_LINK](https://drive.google.com/file/d/1BCwiY0sjqs2tFD4bwRYCyJ5Y9rMOXGqw/view?usp=sharing))
