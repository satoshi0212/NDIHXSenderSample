# NDIHXSenderSample

## Overview

Sample implementation of NDI HX transmission that works on the iPhone using Swift.

![output](https://user-images.githubusercontent.com/5768361/166105150-ba6c89f8-bd35-412a-99e2-4151c9bc97c9.gif)

This demo is running at 1080p 30 fps.
Normal NDI has rattles when not wired, but this implementation works fast even with wireless lan!

## How to use

1. Get "libndi_embedded_ios.a"
Get the NDI Advanced SDK for Apple from the [NDI SDK](https://www.ndi.tv/sdk/) site and install it. (NDI 2022-02-10 r129281 v5.1.1)
or use this: https://drive.google.com/drive/folders/1h5aAZxxSJwDmKHa8nOb_HmEgihnHzPVQ?usp=sharing

2. Copy `lib/iOS/libndi_advanced_ios.a` to `/NDIHXSenderSample/NDIWrapper/NDIWrapper/wrapper/libndi_advanced_ios.a`

3. Open `NDIHXSenderSample.xcworkspace` in Xcode, select the `NDIHXSenderSample` schema, and run it.

4. Tap the Send button on the screen to start sending with NDI.


## 概要

NDI HX送信をiPhoneから行う実装です。
デモでは1080p、30fpsで動作しています。
通常のNDIはデータサイズが大きいため、有線LANで安定した速度を確保しないと映像ガタつきが発生しますが、この実装では無線LANでも安定した映像が実現できます。

## 本リポジトリの使い方

1. libndi_embedded_ios.a 入手
[NDI SDK](https://www.ndi.tv/sdk/)サイトよりNDI Advanced Developer Kitを入手しインストール (NDI 2022-02-10 r129281 v5.1.1)
もしくはこちらからダウンロード https://drive.google.com/drive/folders/1h5aAZxxSJwDmKHa8nOb_HmEgihnHzPVQ?usp=sharing

2. `lib/iOS/libndi_advanced_ios.a` をコピーし `/NDIHXSenderSample/NDIWrapper/NDIWrapper/wrapper/libndi_advanced_ios.a` に配置

3. Xcodeで `NDIHXSenderSample.xcworkspace` を開き `NDIHXSenderSample` スキーマを選択し実行

4. 画面内のSendボタンをタップするとNDIで送信開始します。
