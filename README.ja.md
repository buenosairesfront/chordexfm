[English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · **日本語** · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex FM

[monome norns](https://monome.org/docs/norns/) 用の、4 オペレーター FM エンジン（DX / TX81Z スタイル）を搭載したコード楽器。
1 つのキーで 4 音のコード＋ベースを鳴らします。押さえている一番低いキーがルートになります。

![Chordex FM の 6 つのモデル](docs/sheet.png)

**画面そのものが FM です。** 音を作っているのと同じ式で描かれています：

- **左、アルゴリズム：** 4 つのオペレーターを円で表示。明るさはエンベロープ、内側で回る点はレシオの速さで回転し、線はモジュレーション（流れる粒子 = インデックスの量）、オペレーター 4 のループはフィードバックです。下には 9 本のフェーダー。
- **中央、花：** ノートの実際の波形を極座標で描いたもの。インデックスが低いとなめらかな円、高いと花びらやトゲでいっぱいになります。ゴーストの輪郭はファットネス、火花はシマーとクラックル、内側には 12 音の輪の上のコード。アルペジオの各音は彗星のように飛び出します。
- **右：** オシロスコープ（1 周期）とスペクトラム（FM が生む倍音とサイドバンド）。下にアルペジオのパターン。

## 機能

- **4 オペレーター FM**：8 アルゴリズム、レシオ、オペレーター 4 のフィードバック、オペレーターごとのエンベロープ、モジュレーターの「スイープ」
- **10 モデル**：EPIANO、CAMPANA（ベル）、METAL、CORO（コーラス）、BAJO（ベース）、ORGANO（オルガン）、MARIMBA、CUERDAS（ストリングス）、FLAUTA（フルート）、VIDRIO（ガラス）
- **10 種類のコード**：maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **アルペジエーター**：up, down, up-down, up x2, down x2, random, *arpa*（ハープ）。ゲート最大で本物のレガート
- **コードモード** オン/オフ（オフ = 単音）と**ホールド**
- 3 つ以上のキーを押すと古いレコードのクラックルノイズ
- アルペジオのテンポは受信した MIDI クロックに追従
- すべての設定は自動保存

Chordex ファミリーの一員：操作は Chordex80 と同じです。

## 必要なもの

- norns（shield、標準モデル、fates）
- MIDI キーボードまたはコントローラー

## インストール

maiden から：

```
;install https://github.com/buenosairesfront/chordexfm
```

その後、新しいエンジン `ChordexFM` をコンパイルするために **norns を再起動**（SYSTEM > RESTART）し、SELECT から **chordexfm** を読み込みます。

## 操作

| 操作 | 機能 |
|---|---|
| E1 | FM インデックス（明るさ） |
| E2 | フェーダー選択 |
| E3 | フェーダー調整 |
| K3 + E1 | モデル |
| K3 + E2 | オペレーター 4 のフィードバック |
| K3 + E3 | コードの種類 |
| K3 長押し（回さずに） | コードモード オン/オフ |
| K2（タップ） | アルペジエーター オン/オフ |
| K2 + E1 | アルペジオのゲート（最大 = レガート） |
| K2 + E2 | アルペジオのパターン |
| K2 + E3 | アルペジオの速度 |
| K1 長押し | ホールド オン/オフ（右上の小さな点） |

**フェーダー：** アタック、ディケイ、オペレーター 2 のレシオ、アルゴリズム、スイープ（モジュレーターのディケイ）、ディストーション、ウォブル、ファットネス、シマー。

**PARAMETERS メニュー：** MIDI チャンネル（0 = 全チャンネル、初期値）、MIDI クロック分周、ホール、音量、および上記すべて。

## ギャラリー

| | |
|---|---|
| ![EPIANO](docs/1_epiano.png) EPIANO · maj7 | ![CAMPANA](docs/2_campana.png) CAMPANA（ベル） |
| ![METAL](docs/3_metal.png) METAL · 高インデックス | ![ORGANO](docs/4_organo.png) ORGANO（オルガン） |
| ![CUERDAS](docs/5_cuerdas_arp.png) CUERDAS（ストリングス）· アルペジオ | ![VIDRIO](docs/6_vidrio.png) VIDRIO（ガラス） |

## クレジット

制作：[Buenos Aires Front](https://github.com/buenosairesfront) / U-MA。
MIT ライセンス。
