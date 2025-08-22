import os
import numpy as np
import pandas as pd
from scipy.stats import iqr
from scipy.fft import fft
from sklearn.preprocessing import StandardScaler

def load_data(data_dir):
    """Loads all mhealth_subject*.log files into a single DataFrame."""
    all_files = [os.path.join(data_dir, f) for f in os.listdir(data_dir) if f.startswith('mHealth_subject')]
    
    column_names = [
        'acc_chest_x', 'acc_chest_y', 'acc_chest_z',
        'ecg_lead_1', 'ecg_lead_2',
        'acc_left_ankle_x', 'acc_left_ankle_y', 'acc_left_ankle_z',
        'gyro_left_ankle_x', 'gyro_left_ankle_y', 'gyro_left_ankle_z',
        'mag_left_ankle_x', 'mag_left_ankle_y', 'mag_left_ankle_z',
        'acc_right_arm_x', 'acc_right_arm_y', 'acc_right_arm_z',
        'gyro_right_arm_x', 'gyro_right_arm_y', 'gyro_right_arm_z',
        'mag_right_arm_x', 'mag_right_arm_y', 'mag_right_arm_z',
        'label'
    ]
    
    df_list = []
    for i, file_path in enumerate(all_files):
        subject_id = i + 1
        df = pd.read_csv(file_path, header=None, sep='\s+', names=column_names)
        df['subject'] = subject_id
        df_list.append(df)
        
    full_df = pd.concat(df_list, ignore_index=True)
    
    # Filter out non-activity labels (label 0)
    full_df = full_df[full_df['label'] != 0]
    
    return full_df

def get_time_domain_features(window):
    """Calculates time-domain features for a given window."""
    features = {}
    for col in window.columns:
        features[f'{col}_mean'] = window[col].mean()
        features[f'{col}_std'] = window[col].std()
        features[f'{col}_min'] = window[col].min()
        features[f'{col}_max'] = window[col].max()
        features[f'{col}_median'] = window[col].median()
        features[f'{col}_iqr'] = iqr(window[col])
        features[f'{col}_rms'] = np.sqrt(np.mean(window[col]**2))
    return features

def get_frequency_domain_features(window):
    """Calculates frequency-domain features for a given window."""
    features = {}
    N = len(window)
    T = 1.0 / 50.0  # Sampling frequency is 50 Hz
    
    for col in window.columns:
        y = window[col].values
        yf = fft(y)
        
        # Power spectral density
        psd = (1/(N*50)) * np.abs(yf[1:N//2])**2
        
        features[f'{col}_fft_mean'] = np.mean(np.abs(yf))
        features[f'{col}_fft_std'] = np.std(np.abs(yf))
        features[f'{col}_psd_mean'] = np.mean(psd)
        features[f'{col}_psd_max'] = np.max(psd)
        
    return features

def process_data():
    """
    Main function to load, process, and engineer features from the MHEALTH dataset.
    """
    data_dir = "human_activity_recognition/data"
    output_path = os.path.join(data_dir, "mhealth_features.parquet")
    
    print("Loading raw data...")
    df = load_data(data_dir)
    
    # Define sensor columns for feature extraction
    sensor_cols = [col for col in df.columns if col not in ['label', 'subject']]
    
    # Sliding window parameters
    # Window size 2.56s, 50Hz -> 128 samples
    # Overlap 50% -> 64 samples step
    window_size = 128
    step_size = 64
    
    print("Applying sliding window and extracting features...")
    feature_list = []
    
    for subject_id in df['subject'].unique():
        print(f"Processing subject {subject_id}...")
        df_subject = df[df['subject'] == subject_id].copy()
        
        for activity_label in df_subject['label'].unique():
            df_activity = df_subject[df_subject['label'] == activity_label]
            
            for i in range(0, len(df_activity) - window_size, step_size):
                window = df_activity[sensor_cols].iloc[i : i + window_size]
                
                if len(window) < window_size:
                    continue

                # Get the label for the window (most frequent label)
                label = df_activity['label'].iloc[i : i + window_size].mode()[0]
                
                # Extract features
                time_features = get_time_domain_features(window)
                freq_features = get_frequency_domain_features(window)
                
                # Combine all features
                all_features = {**time_features, **freq_features}
                all_features['label'] = label
                all_features['subject'] = subject_id
                
                feature_list.append(all_features)

    print("Creating feature DataFrame...")
    feature_df = pd.DataFrame(feature_list)
    
    # Scale features
    print("Scaling features...")
    feature_cols = [col for col in feature_df.columns if col not in ['label', 'subject']]
    scaler = StandardScaler()
    feature_df[feature_cols] = scaler.fit_transform(feature_df[feature_cols])
    
    print(f"Saving feature data to {output_path}...")
    feature_df.to_parquet(output_path, index=False)
    
    print("\nProcessing complete. Feature data info:")
    feature_df.info()

if __name__ == "__main__":
    process_data()
