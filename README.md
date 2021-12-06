# OBS Blade

![alt text](https://assets.kounex.com/images/obs-blade/store_banner_3.png 'OBS Blade Store Banner')

DISCLAIMER: This app is not in any way affiliated with [OBS](https://github.com/obsproject/obs-studio) (Open Broadcaster Software).

Control and manage your stream while using OBS by making use of the WebSocket Plugin for OBS. This project is build with the Flutter framework and could therefore be compiled and deployed for various platforms. This release is optimized for iOS and Android (Phone as well as Tablet).

Feel free to either create issues if something does not work or pull this repo and make changes and build it on your own!

## Preparation

In order to be able to connect to OBS with OBS Blade, you need to install the OBS WebSocket plugin:

https://github.com/Palakis/obs-websocket

Go to the [Release](https://github.com/obsproject/obs-websocket/releases) section of this GitHub page and download version 4.9.1 (important to use this one currently!) for your operating system (found under 'Assets').

Once this plugin is installed and active (usually restarting OBS right after) the device running OBS Blade needs to be in the same network as the device running OBS itself and the autodiscover feature should find open OBS sessions on its own! You can also enter the local (internal) IP address of the device running OBS ([How to find my local IP address](https://www.whatismybrowser.com/detect/what-is-my-local-ip-address))

## Features

<div align="center">
  <div style="display: flex; align-items: flex-start;">
    <img src="https://assets.kounex.com/images/obs-blade/iphone_1.png" width="110">
    <img src="https://assets.kounex.com/images/obs-blade/iphone_2.png" width="110">
    <img src="https://assets.kounex.com/images/obs-blade/iphone_3.png" width="110">
    <img src="https://assets.kounex.com/images/obs-blade/iphone_4.png" width="110">
    <img src="https://assets.kounex.com/images/obs-blade/iphone_5.png" width="110">
    <img src="https://assets.kounex.com/images/obs-blade/iphone_6.png" width="110">
  </div>
</div>

OBS Blade is designed to be your stream companion and help you to manage your live stream. While using OBS (Open Broadcaster Software) you can connect to the running instance and gain control over important parts of the software. This should help you to manage what your audience can see / hear without the need to switch to OBS on your machine and make such changes. You can keep doing what you do and easily use this app to control OBS!

Currently OBS Blade supports:

-   Start / stop the stream
-   Changing the active scene
-   Toggle visibility of scene items (like desktop capture etc.)
-   Change the volume of your current audio sources (or mute them)
-   View any Twitch chat and write messages
-   See live statistics of your stream performance (FPS, CPU usage, kbit/s etc.)

OBS Blade also saves statistics of your previous streams so you can track the overall performance and some nice to know facts!

This app is still in its early stages and will get updated with new features over time - for now the main features which I want to add are:

-   More engagement with OBS (renaming, sorting, scripted switching etc.)
-   Export / merge statistics
-   Enable Youtube chat
-   Soundboard
-   Incoming feature requests
-   (Maybe) Streamlabs client connection

I hope you have a good time using this app. If you encounter any bugs, have feature requests or anything similar, feel free to get in touch with me!

contact@kounex.com

## App Store

This App is available in the iOS App Store and the Google Play Store:

-   [iOS App Store](https://apps.apple.com/de/app/obs-blade/id1523915884?l=en)
-   [Google Play Store](https://play.google.com/store/apps/details?id=com.kounex.obsBlade)

## Support me!

I love developing free, high quality applications accessible for everyone, no need for In-App purchases or Ads. No one wants that. It takes a lot of time creating and maintaining my work - if you like using them and want me to continue working on them please consider supporting me!

<a href="https://www.buymeacoffee.com/Kounex" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>
<a href="https://paypal.me/Kounex" target="_blank"><img src="https://assets.kounex.com/images/general/paypal-me-logo.png" alt="PayPal.Me" height="41"  width="174"></a>
