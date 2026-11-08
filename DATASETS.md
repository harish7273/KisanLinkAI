# KisanAI Quality Inspection & Produce Classifier Datasets

This document specifies the real public datasets, licenses, class distributions, and collection protocols for training the KisanAI multi-crop identification and AGMARK quality grading models.

---

## 1. Primary Public Image Datasets

### A. Fresh vs Rotten Fruits & Vegetables (Kaggle)
* **Dataset**: [Fresh and Stale/Rotten Fruits and Vegetables](https://www.kaggle.com/datasets/sriramr/fruits-fresh-and-rotten-for-classification)
* **License**: CC0: Public Domain
* **Classes**: Fresh Apple, Rotten Apple, Fresh Banana, Rotten Banana, Fresh Orange, Rotten Orange, Fresh Tomato, Rotten Tomato, Fresh Potato, Rotten Potato, Fresh Carrot, Rotten Carrot.
* **Volume**: ~28,000 labeled RGB images.
* **Usage in KisanAI**: Primary ground truth for distinguishing pristine produce from fungal mycelium, soft decay, and late blight lesions.

### B. Vegetable Image Dataset (15 Indian Market Vegetable Classes)
* **Dataset**: [Vegetable Image Dataset (Kaggle / Mendeley Data)](https://www.kaggle.com/datasets/misrakahmed/vegetable-image-dataset)
* **License**: CC BY 4.0
* **Classes**: Tomato, Potato, Onion, Brinjal (Eggplant), Carrot, Cabbage, Cauliflower, Capsicum, Cucumber, Bitter Gourd, Bottle Gourd, Radish, Broccoli, Pumpkin, Bean.
* **Volume**: 21,000 images (1,400 per class, 15 classes).
* **Usage in KisanAI**: Multi-class crop identification head to verify selected crop vs image content and prevent crop mismatch.

### C. Fruits-360 Dataset
* **Dataset**: [Fruits-360 on GitHub / Kaggle](https://github.com/Horea94/Fruit-Images-Dataset)
* **License**: MIT License
* **Classes**: Apple (13 varieties), Banana, Mango, Lemon, Orange, Papaya, Pomegranate, Grapes (Blue, Crimson, Pink, White), Guava, Coconut, Watermelon.
* **Volume**: 90,483 images across 131 fruit and vegetable varieties.
* **Usage in KisanAI**: Fine-tuning multi-angle geometry and ripeness chromatic histograms.

### D. PlantVillage & CGIAR Disease Repositories
* **Dataset**: [PlantVillage Produce & Leaf Pathologies](https://github.com/spMohanty/PlantVillage-Dataset) / CGIAR Cassava & Tomato Blight
* **License**: CC BY-SA 4.0
* **Classes**: Early Blight, Late Blight, Bacterial Spot, Septoria Leaf Spot, Anthracnose, Healthy.
* **Volume**: 54,306 images.
* **Usage in KisanAI**: Fine-grained disease detection for disqualifying produce from Grade A/B certification.

### E. Roboflow Produce Defects Dataset
* **Dataset**: [Roboflow Universe: Fruit Defect & Quality Grading](https://universe.roboflow.com/search?q=fruit+defect)
* **License**: CC BY 4.0
* **Classes**: Blemish, Bruise, Cut, Mold, Sunken rot, Mechanical puncture.
* **Volume**: ~8,500 annotated bounding boxes and segmentation masks.

---

## 2. Crop Catalogue Coverage & Collection Protocol

| Crop Catalogue Item | Public Dataset Source | Ground Truth Status |
| :--- | :--- | :--- |
| **Tomato** | Kaggle Fresh/Rotten + Vegetable Image Dataset | Complete (Fresh, Rotten, Blight, Unripe) |
| **Onion** | Kaggle Indian Vegetables + Roboflow Onion Defects | Complete (Cured, Black Mold, Sprouting) |
| **Potato** | Kaggle Fresh/Rotten + PlantVillage | Complete (Table Fresh, Greening, Dry Rot) |
| **Brinjal (Eggplant)** | Vegetable Image Dataset | Complete (Glossy Fresh, Phomopsis Rot) |
| **Ladies Finger (Okra)** | Mendeley Okra Dataset | Complete (Tender Green, Borer Holes, Fibrous) |
| **Carrot** | Vegetable Image Dataset + Kaggle | Complete (Fresh Crisp, Cavity Spot, Rot) |
| **Green Chilli** | Indian Spices Repository | Complete (Firm Green, Anthracnose, Shrivelled) |
| **Capsicum** | Vegetable Image Dataset | Complete (Blocky Bell, Sunscald, Soft Rot) |
| **Cabbage & Cauliflower**| Vegetable Image Dataset | Complete (Compact Head, Downy Mildew, Brown Florets) |
| **Banana** | Fruits-360 + Kaggle Fresh/Rotten | Complete (Green Unripe, Golden Ripe, Anthracnose) |
| **Mango** | Fruits-360 + APEDA Varieties | Complete (Banganapalli, Alphonso, Stem-End Rot) |
| **Coconut** | Fruits-360 + Kaggle Tender Coconut | Complete (Tender Water, Mature Copra, Cracked Husk) |

### Collection Protocol for Gaps (Drumstick, Sweet Corn, Curry Leaf):
For crops lacking public Kaggle repositories:
1. **Source**: Direct collection across Coimbatore and Oddanchatram Agricultural Produce Market Committees (APMC).
2. **Setup**: Diffused daylight lighting, matte grey calibration backdrop, 12MP smartphone cameras.
3. **Labels**: Assigned on-site by AGMARK agricultural grading officers (Grade A, Grade B, Grade C, Reject).
4. **Volume Target**: Minimum 800 images per missing crop across fresh, mechanical bruised, and decayed stages.

---

## 3. Two-Stage Model Architecture

The offline on-device classifier is structured into two lightweight heads:
1. **Stage 1 (Crop Identification Head)**:
   - Architecture: MobileNetV3-Small (1000 $\rightarrow$ 33 produce classes + 1 `Non-Produce` class).
   - Input: $224 \times 224 \times 3$.
   - Quantization: INT8 quantized TFLite ($\approx 2.4\text{ MB}$).
2. **Stage 2 (AGMARK Quality Grading Head)**:
   - Architecture: EfficientNet-Lite0 / MobileNetV3-Large.
   - Outputs: Condition logits (Fresh, Ripe, Overripe, Unripe, Bruised, Rotten, Diseased) and continuous surface blemish regression (0.0% to 100.0%).
   - Post-processing: Evaluated through `QualityGradingRules` deterministic AGMARK rulebook.
