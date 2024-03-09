# AnyChat AppImage

AnyChat is provided as AppImage too. To Download, visit anychat.im.

## Building

- Ensure you install `appimagetool`

```shell
flutter build linux

# copy binaries to appimage dir
cp -r build/linux/{x64,arm64}/release/bundle appimage/AnyChat.AppDir
cd appimage

# prepare AppImage files
cp AnyChat.desktop AnyChat.AppDir/
mkdir -p AnyChat.AppDir/usr/share/icons
cp ../assets/logo.svg AnyChat.AppDir/anychat.svg
cp AppRun AnyChat.AppDir

# build the AppImage
appimagetool AnyChat.AppDir
```
