import requests
import zipfile
import io
import os

def download_and_unzip_mhealth_data():
    """
    Downloads the MHEALTH dataset, unzips it, and places the contents
    in the 'human_activity_recognition/data' directory.
    """
    url = "https://archive.ics.uci.edu/ml/machine-learning-databases/00319/MHEALTHDATASET.zip"
    data_dir = "human_activity_recognition/data"
    
    # Create the target directory if it doesn't exist
    if not os.path.exists(data_dir):
        os.makedirs(data_dir)
        
    print(f"Downloading dataset from {url}...")
    try:
        response = requests.get(url, timeout=60)
        response.raise_for_status()  # Raise an exception for bad status codes
        
        print("Download complete. Extracting files...")
        with zipfile.ZipFile(io.BytesIO(response.content)) as z:
            z.extractall(data_dir)
        
        # The files are extracted into a subdirectory, let's move them up
        extracted_folder = os.path.join(data_dir, "MHEALTHDATASET")
        if os.path.exists(extracted_folder):
            for filename in os.listdir(extracted_folder):
                os.rename(os.path.join(extracted_folder, filename), os.path.join(data_dir, filename))
            os.rmdir(extracted_folder)

        print(f"Dataset successfully extracted to {os.path.abspath(data_dir)}")

    except requests.exceptions.RequestException as e:
        print(f"Error downloading the file: {e}")
    except zipfile.BadZipFile:
        print("Error: Downloaded file is not a valid zip file.")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")

if __name__ == "__main__":
    download_and_unzip_mhealth_data()
