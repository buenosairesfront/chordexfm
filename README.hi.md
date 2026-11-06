[English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · [中文](README.zh.md) · **हिन्दी**

# Chordex FM

[monome norns](https://monome.org/docs/norns/) के लिए 4-ऑपरेटर FM इंजन (DX / TX81Z शैली) वाला कॉर्ड वाद्य। एक बटन चार नोट का कॉर्ड और साथ में बेस बजाता है; दबाया गया सबसे नीचा बटन मूल स्वर (root) तय करता है।

![Chordex FM के छह मॉडल](docs/sheet.png)

**स्क्रीन ही FM है**, जिसे उसी सूत्र से बनाया गया है जिससे ध्वनि बनती है:

- **बाएँ, एल्गोरिदम:** 4 ऑपरेटर गोलों के रूप में। उनकी चमक उनका एनवेलप है, अंदर घूमता बिंदु उसके रेशियो की गति से घूमता है, रेखाएँ मॉड्यूलेशन हैं (चलते कण = कितना इंडेक्स), और ऑपरेटर 4 पर बना छल्ला उसका फ़ीडबैक है। नीचे 9 फ़ेडर।
- **बीच में, फूल:** नोट का असली वेवफ़ॉर्म, ध्रुवीय (polar) रूप में। कम इंडेक्स पर यह एक चिकना गोला है; ज़्यादा इंडेक्स पर यह पंखुड़ियों और काँटों से भर जाता है। धुंधली रूपरेखा fatness है, चिंगारियाँ shimmer और चटकन हैं, और अंदर 12 नोट के चक्र पर कॉर्ड है। आर्पेजियो का हर नोट धूमकेतु की तरह निकलता है।
- **दाएँ:** ऑसिलोस्कोप (एक चक्र) और स्पेक्ट्रम (FM से बनने वाले हार्मोनिक्स और साइडबैंड); नीचे आर्पेजियो पैटर्न।

## विशेषताएँ

- **4-ऑपरेटर FM**: 8 एल्गोरिदम, रेशियो, ऑपरेटर 4 फ़ीडबैक, हर ऑपरेटर का अपना एनवेलप और मॉड्यूलेटरों का "स्वीप"
- **10 मॉडल**: EPIANO (इलेक्ट्रिक पियानो), CAMPANA (घंटी), METAL (धातु), CORO (कोरस), BAJO (बेस), ORGANO (ऑर्गन), MARIMBA (मारिम्बा), CUERDAS (स्ट्रिंग्स), FLAUTA (बाँसुरी), VIDRIO (काँच)
- **10 कॉर्ड**: maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **आर्पेजिएटर**: up, down, up-down, up x2, down x2, random और *arpa* (हार्प); गेट अधिकतम पर असली लेगाटो
- **कॉर्ड मोड** चालू/बंद (बंद = एक नोट) और **होल्ड**
- आर्पेजियो की गति आने वाली MIDI क्लॉक का पालन करती है
- सभी सेटिंग्स अपने आप सेव होती हैं

Chordex परिवार का हिस्सा: कंट्रोल Chordex80 जैसे ही हैं।

<!-- u-ma:family -->
## Chordex परिवार

कंट्रोल वही, इंजन अलग। बाकी भी आज़माएँ:

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.hi.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.hi.md)**<br>outrun सूर्यास्त वाला 80 के दशक का पॉलीसिंथ<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.hi.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.hi.md)**<br>गज़ से बजे तार की असली गति वाले ऑर्केस्ट्रा स्ट्रिंग्स<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexwt/blob/main/README.hi.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexwt/main/docs/2_vocal.png" width="200" alt="Chordex WT"></a> | **[Chordex WT](https://github.com/buenosairesfront/chordexwt/blob/main/README.hi.md)**<br>वेवटेबल: 8 वेव वाले 8 बैंक, 3D टेबल के रूप में<br>`;install https://github.com/buenosairesfront/chordexwt` |
| <a href="https://github.com/buenosairesfront/chordexchip/blob/main/README.hi.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexchip/main/docs/1_nes.png" width="200" alt="Chordex CHIP"></a> | **[Chordex CHIP](https://github.com/buenosairesfront/chordexchip/blob/main/README.hi.md)**<br>चिपट्यून: 8 कंसोल चिप × 8 प्रीसेट, ट्रैकर के रूप में<br>`;install https://github.com/buenosairesfront/chordexchip` |

**U-MA से और:** सभी वाद्य और टूल एक जगह → [U-MA शोकेस](https://github.com/buenosairesfront/U-ma/blob/main/README.hi.md)
<!-- /u-ma:family -->

## ज़रूरतें

- norns (shield, standard या fates)
- MIDI कीबोर्ड या कंट्रोलर

## इंस्टॉल

maiden में:

```
;install https://github.com/buenosairesfront/chordexfm
```

फिर नया इंजन `ChordexFM` कंपाइल होने के लिए **norns को रीस्टार्ट करें** (SYSTEM > RESTART), और SELECT से **chordexfm** लोड करें।

## कंट्रोल

| कंट्रोल | काम |
|---|---|
| E1 | FM इंडेक्स (चमक) |
| E2 | फ़ेडर चुनें |
| E3 | फ़ेडर समायोजित करें |
| K3 + E1 | मॉडल |
| K3 + E2 | ऑपरेटर 4 फ़ीडबैक |
| K3 + E3 | कॉर्ड का प्रकार |
| K3 दबाए रखें (बिना घुमाए) | कॉर्ड मोड चालू/बंद |
| K2 (टैप) | आर्पेजिएटर चालू/बंद |
| K2 + E1 | आर्पेजियो गेट (अधिकतम = लेगाटो) |
| K2 + E2 | आर्पेजियो पैटर्न |
| K2 + E3 | आर्पेजियो गति |
| K1 दबाए रखें | होल्ड चालू/बंद (ऊपर दाएँ छोटा बिंदु) |

**फ़ेडर:** अटैक, डिके, ऑपरेटर 2 रेशियो, एल्गोरिदम, स्वीप (मॉड्यूलेटरों का डिके), डिस्टॉर्शन, वॉबल, fatness, shimmer।

**PARAMETERS मेनू:** MIDI चैनल (0 = सभी, डिफ़ॉल्ट), MIDI क्लॉक डिवाइडर, हॉल, वॉल्यूम, और ऊपर का सब कुछ।

## गैलरी

| | |
|---|---|
| ![EPIANO](docs/1_epiano.png) EPIANO · maj7 | ![CAMPANA](docs/2_campana.png) CAMPANA (घंटी) |
| ![METAL](docs/3_metal.png) METAL · ऊँचा इंडेक्स | ![ORGANO](docs/4_organo.png) ORGANO (ऑर्गन) |
| ![CUERDAS](docs/5_cuerdas_arp.png) CUERDAS (स्ट्रिंग्स) · आर्पेजियो | ![VIDRIO](docs/6_vidrio.png) VIDRIO (काँच) |

## श्रेय

[Buenos Aires Front](https://github.com/buenosairesfront) / U-MA द्वारा बनाया गया।
MIT लाइसेंस।
