# Human Activity Recognition using MHEALTH Dataset

This project implements a machine learning pipeline to perform Human Activity Recognition (HAR) on the MHEALTH dataset. The goal is to classify 12 different physical activities based on sensor data from the chest, left ankle, and right arm.

This implementation is based on the plan outlined in Issue #46, which aims to reproduce the analysis from the paper "A comparative analysis of classical and deep learning techniques for human activity recognition" by O’Halloran & Curry (2019).

## Pipeline Overview

The pipeline consists of three main Python scripts located in the `scripts/` directory:

1.  **`01_download_data.py`**: Downloads and extracts the MHEALTH dataset from the UCI Machine Learning Repository.
2.  **`02_process_data.py`**: Loads the raw sensor data, applies a sliding window (2.56s with 50% overlap), extracts time-domain and frequency-domain features, scales the features, and saves the final feature matrix to `data/mhealth_features.parquet`.
3.  **`03_train_and_evaluate.py`**: Loads the engineered features, performs a subject-wise train-test split, trains two models (XGBoost and a Multi-layer Perceptron), and evaluates their performance. It also generates and saves a confusion matrix and a feature importance plot in the `reports/` directory.

## How to Run

1.  **Install Dependencies**:
    Install the required Python libraries using the provided `requirements.txt` file.
    ```bash
    pip install -r human_activity_recognition/requirements.txt
    ```

2.  **Run the Full Pipeline**:
    Execute the scripts in order.

    ```bash
    # Step 1: Download the data
    python3 human_activity_recognition/scripts/01_download_data.py

    # Step 2: Process data and create features
    python3 human_activity_recognition/scripts/02_process_data.py

    # Step 3: Train and evaluate models
    python3 human_activity_recognition/scripts/03_train_and_evaluate.py
    ```

## Results

The models were evaluated on a test set containing data from subjects not seen during training.

-   **XGBoost Model**:
    -   Accuracy: ~92.7%
    -   F1-score (Weighted): ~92.6%
-   **MLP Model**:
    -   Accuracy: ~96.8%
    -   F1-score (Weighted): ~96.8%

Both models successfully surpassed the performance reported in the reference paper (Accuracy ≈ 90.5%). The analysis plots, including the confusion matrix and feature importance for the XGBoost model, are saved in the `human_activity_recognition/reports/` directory.
