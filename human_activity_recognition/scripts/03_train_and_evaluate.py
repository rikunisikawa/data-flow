import os
import pandas as pd
import numpy as np
import xgboost as xgb
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.neural_network import MLPClassifier
from sklearn.model_selection import train_test_split, GroupShuffleSplit
from sklearn.metrics import accuracy_score, f1_score, classification_report, confusion_matrix

def train_and_evaluate():
    """
    Loads the feature data, trains XGBoost and MLP models, and evaluates their performance.
    """
    data_path = "human_activity_recognition/data/mhealth_features.parquet"
    reports_dir = "human_activity_recognition/reports"
    
    if not os.path.exists(reports_dir):
        os.makedirs(reports_dir)
        
    print(f"Loading feature data from {data_path}...")
    df = pd.read_parquet(data_path)
    
    # Drop rows with missing values that may have been introduced during feature calculation
    df.dropna(inplace=True)
    
    X = df.drop(['label', 'subject'], axis=1)
    y = df['label']
    groups = df['subject']
    
    # --- Subject-wise Train-Test Split ---
    # This ensures that data from a single subject does not appear in both train and test sets.
    print("Performing subject-wise train-test split...")
    splitter = GroupShuffleSplit(n_splits=1, test_size=0.3, random_state=42)
    train_idx, test_idx = next(splitter.split(X, y, groups))
    
    X_train, X_test = X.iloc[train_idx], X.iloc[test_idx]
    y_train, y_test = y.iloc[train_idx], y.iloc[test_idx]
    
    train_subjects = groups.iloc[train_idx].unique()
    test_subjects = groups.iloc[test_idx].unique()
    
    print(f"Training subjects: {train_subjects}")
    print(f"Testing subjects: {test_subjects}")
    print(f"Train set size: {len(X_train)}, Test set size: {len(X_test)}")

    # --- XGBoost Model ---
    print("\n--- Training XGBoost Model ---")
    # Labels need to be 0-indexed for XGBoost
    y_train_xgb = y_train - 1
    y_test_xgb = y_test - 1
    
    xgb_model = xgb.XGBClassifier(objective='multi:softmax', num_class=12, use_label_encoder=False, eval_metric='mlogloss', random_state=42)
    xgb_model.fit(X_train, y_train_xgb)
    
    print("Evaluating XGBoost Model...")
    y_pred_xgb = xgb_model.predict(X_test)
    
    accuracy_xgb = accuracy_score(y_test_xgb, y_pred_xgb)
    f1_xgb = f1_score(y_test_xgb, y_pred_xgb, average='weighted')
    
    print(f"XGBoost Accuracy: {accuracy_xgb:.4f}")
    print(f"XGBoost F1-score (Weighted): {f1_xgb:.4f}")
    print("\nXGBoost Classification Report:")
    print(classification_report(y_test_xgb, y_pred_xgb))
    
    # --- MLP Model ---
    print("\n--- Training MLP Model ---")
    mlp_model = MLPClassifier(hidden_layer_sizes=(100, 50), max_iter=500, random_state=42)
    mlp_model.fit(X_train, y_train)
    
    print("Evaluating MLP Model...")
    y_pred_mlp = mlp_model.predict(X_test)
    
    accuracy_mlp = accuracy_score(y_test, y_pred_mlp)
    f1_mlp = f1_score(y_test, y_pred_mlp, average='weighted')
    
    print(f"MLP Accuracy: {accuracy_mlp:.4f}")
    print(f"MLP F1-score (Weighted): {f1_mlp:.4f}")
    print("\nMLP Classification Report:")
    print(classification_report(y_test, y_pred_mlp))
    
    # --- Result Analysis and Visualization ---
    print("\nGenerating result visualizations...")
    
    # Confusion Matrix (for the better model, XGBoost)
    cm = confusion_matrix(y_test_xgb, y_pred_xgb)
    plt.figure(figsize=(10, 8))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=range(1, 13), yticklabels=range(1, 13))
    plt.title('XGBoost Confusion Matrix')
    plt.xlabel('Predicted Label')
    plt.ylabel('True Label')
    cm_path = os.path.join(reports_dir, 'xgboost_confusion_matrix.png')
    plt.savefig(cm_path)
    print(f"Confusion matrix saved to {cm_path}")
    
    # Feature Importance (for XGBoost)
    feature_importances = pd.Series(xgb_model.feature_importances_, index=X.columns)
    top_20_features = feature_importances.nlargest(20)
    
    plt.figure(figsize=(12, 8))
    top_20_features.sort_values().plot(kind='barh')
    plt.title('Top 20 Feature Importances for XGBoost')
    plt.xlabel('Importance')
    fi_path = os.path.join(reports_dir, 'xgboost_feature_importance.png')
    plt.savefig(fi_path, bbox_inches='tight')
    print(f"Feature importance plot saved to {fi_path}")

if __name__ == "__main__":
    train_and_evaluate()
