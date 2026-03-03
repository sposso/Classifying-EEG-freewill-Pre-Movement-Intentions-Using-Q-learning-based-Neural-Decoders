# Classifying EEG freewill Pre-Movement Intentions Using Q-learning-based Neural Decoders

## Repository Python files

- `main_all.py`: Main experiment/training entry point. Loads the EEG dataset, applies band-pass settings, then runs Monte Carlo DQN training/evaluation loops and saves per-subject/section success-rate curves.
- `data_function.py`: Core EEG data utilities and preprocessing helpers (e.g., raw feature extraction and anti-aliased downsampling via Butterworth low-pass filtering + cubic-spline resampling), plus dataset-related helpers used by the training script.
- `load_data.py`: Convenience loader for the Freewill Reaching & Grasping `.mat` files. Walks the dataset directory, parses subject/session filenames, and returns a nested dict of loaded MATLAB structures.
- `download.py`: Command-line utility to download the public dataset zip from Figshare by file id and unzip it locally.