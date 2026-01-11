import pandas as pd
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
import joblib # <--- NEW: This library is used to save the scaler
import os    # <--- NEW: Used to create folders if they don't exist

# 1. Load the Data
# ---------------------------------------------------------
file_path = 'wuerzburg_pedestrians.csv' # Make sure this matches your filename

try:
    df = pd.read_csv(file_path)
    print("Data loaded successfully.")
except FileNotFoundError:
    print(f"Error: File not found at {file_path}.")
    exit()

# 2. Select Columns
# ---------------------------------------------------------
required_columns = ['hour', 'weekday', 'n_pedestrians_towards']
df = df[required_columns].copy() 

# 2.5 Convert 'weekday' strings to numbers
# ---------------------------------------------------------
weekday_map = {
    'Monday': 0, 'Tuesday': 1, 'Wednesday': 2, 'Thursday': 3,
    'Friday': 4, 'Saturday': 5, 'Sunday': 6
}

df['weekday_num'] = df['weekday'].map(weekday_map)
df = df.dropna(subset=['weekday_num']) 

# 3. Prepare Inputs (X) and Target (y)
# ---------------------------------------------------------
X = df[['hour', 'weekday_num']].values
y = df['n_pedestrians_towards'].values

# 4. Preprocessing
# ---------------------------------------------------------
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# 5. Build the TensorFlow Model
# ---------------------------------------------------------
model = tf.keras.Sequential([
    tf.keras.layers.Input(shape=(2,)),
    tf.keras.layers.Dense(64, activation='relu'),
    tf.keras.layers.Dense(32, activation='relu'),
    tf.keras.layers.Dense(1, activation='linear') 
])

model.compile(optimizer='adam', loss='mse', metrics=['mae'])

# 6. Train the Model
# ---------------------------------------------------------
print("\nStarting Training...")
history = model.fit(
    X_train_scaled, 
    y_train, 
    epochs=50,
    batch_size=32,
    validation_split=0.2,
    verbose=1
)

# 7. Evaluate
# ---------------------------------------------------------
loss, mae = model.evaluate(X_test_scaled, y_test, verbose=0)
print(f"\nTest Mean Absolute Error: {mae:.2f}")

# 8. SAVE THE MODEL AND SCALER
# ---------------------------------------------------------
# Define the filenames
model_filename = 'pedestrian_model.keras'
scaler_filename = 'scaler.pkl'

print(f"\nSaving model to {model_filename}...")
model.save(model_filename) 

print(f"Saving scaler to {scaler_filename}...")
joblib.dump(scaler, scaler_filename)

print("Done! Your model and scaler are saved in the current folder.")

# 9. Prediction Function (Demonstration)
# ---------------------------------------------------------
def predict_pedestrians(hour, day_name):
    """
    Inputs:
    hour: int (0-23)
    day_name: string (e.g., "Friday")
    """
    if day_name not in weekday_map:
        return f"Error: {day_name} is not a valid day."
        
    day_num = weekday_map[day_name]
    
    # Scale inputs using the scaler currently in memory
    input_data = np.array([[hour, day_num]])
    input_scaled = scaler.transform(input_data)
    
    # Predict
    prediction = model.predict(input_scaled, verbose=0)
    return int(prediction[0][0])

# --- Test the prediction ---
test_hour = 19
test_day = "Tuesday"

pred = predict_pedestrians(test_hour, test_day)
print(f"\nPrediction for {test_day} at {test_hour}:00 -> {pred} pedestrians towards.")