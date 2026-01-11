from flask import Flask, request, jsonify
from prophet import Prophet
import pandas as pd
import numpy as np
import tensorflow as tf
import joblib
from datetime import datetime, timedelta
import logging

# Suppress Prophet's verbose logging
logging.getLogger('prophet').setLevel(logging.WARNING)
logging.getLogger('cmdstanpy').setLevel(logging.WARNING)

app = Flask(__name__)

# Load the pedestrian model and scaler at startup
try:
    pedestrian_model = tf.keras.models.load_model('pedestrian_model.keras')
    scaler = joblib.load('scaler.pkl')
    print("Pedestrian model and scaler loaded successfully.")
except Exception as e:
    print(f"Warning: Could not load pedestrian model: {e}")
    pedestrian_model = None
    scaler = None

# Weekday mapping
weekday_map = {
    'Monday': 0, 'Tuesday': 1, 'Wednesday': 2, 'Thursday': 3,
    'Friday': 4, 'Saturday': 5, 'Sunday': 6
}

def generate_holidays():
    """Generate a reasonable set of US holidays for multiple years"""
    years = range(2024, 2028)  # Cover past and future years
    holidays_list = []
    
    for year in years:
        # Major US holidays that affect retail traffic
        holidays_list.extend([
            {'holiday': 'New Year\'s Day', 'ds': f'{year}-01-01'},
            {'holiday': 'Martin Luther King Jr. Day', 'ds': f'{year}-01-15'},
            {'holiday': 'Valentine\'s Day', 'ds': f'{year}-02-14'},
            {'holiday': 'Presidents Day', 'ds': f'{year}-02-17'},
            {'holiday': 'Easter', 'ds': f'{year}-04-20'},
            {'holiday': 'Memorial Day', 'ds': f'{year}-05-27'},
            {'holiday': 'Independence Day', 'ds': f'{year}-07-04'},
            {'holiday': 'Labor Day', 'ds': f'{year}-09-02'},
            {'holiday': 'Halloween', 'ds': f'{year}-10-31'},
            {'holiday': 'Thanksgiving', 'ds': f'{year}-11-28'},
            {'holiday': 'Black Friday', 'ds': f'{year}-11-29'},
            {'holiday': 'Cyber Monday', 'ds': f'{year}-12-02'},
            {'holiday': 'Christmas Eve', 'ds': f'{year}-12-24'},
            {'holiday': 'Christmas', 'ds': f'{year}-12-25'},
            {'holiday': 'New Year\'s Eve', 'ds': f'{year}-12-31'},
        ])
    
    holidays_df = pd.DataFrame(holidays_list)
    holidays_df['ds'] = pd.to_datetime(holidays_df['ds'])
    
    # Add windows for multi-day effects
    holidays_df['lower_window'] = 0
    holidays_df['upper_window'] = 1
    
    # Extend Black Friday and Christmas windows
    holidays_df.loc[holidays_df['holiday'] == 'Black Friday', 'lower_window'] = -1
    holidays_df.loc[holidays_df['holiday'] == 'Black Friday', 'upper_window'] = 3
    holidays_df.loc[holidays_df['holiday'] == 'Christmas', 'lower_window'] = -7
    holidays_df.loc[holidays_df['holiday'] == 'Christmas', 'upper_window'] = 1
    
    return holidays_df

@app.route('/predict', methods=['POST'])
def predict():
    try:
        # Get data from request
        data = request.get_json()
        
        if not data or 'data' not in data:
            return jsonify({'error': 'No data provided. Expected format: {"data": [{"ds": "2026-01-10 14:00:00", "y": 5}, ...]}'}), 400
        
        # Convert to DataFrame
        df = pd.DataFrame(data['data'])
        
        # Validate required columns
        if 'ds' not in df.columns or 'y' not in df.columns:
            return jsonify({'error': 'Data must contain "ds" and "y" columns'}), 400
        
        # Check minimum data points
        if len(df) < 14:
            return jsonify({
                'error': 'Insufficient data',
                'message': f'Prophet requires at least 14 data points. You provided {len(df)}.',
                'days_needed': 14 - len(df)
            }), 400
        
        # Convert ds to datetime
        df['ds'] = pd.to_datetime(df['ds'])
        df['y'] = pd.to_numeric(df['y'])
        
        # Sort by date
        df = df.sort_values('ds').reset_index(drop=True)
        
        # Generate holidays
        holidays = generate_holidays()
        
        # Initialize and fit Prophet model
        model = Prophet(
            holidays=holidays,
            daily_seasonality=True,
            weekly_seasonality=True,
            yearly_seasonality=True,
            seasonality_mode='additive',
            interval_width=0.8
        )
        
        model.fit(df)
        
        # Get forecast periods from request or default to 7 days
        periods = data.get('periods', 7)
        
        # Create future dataframe
        future = model.make_future_dataframe(periods=periods, freq='D')
        
        # Make predictions
        forecast = model.predict(future)
        
        # Get only future predictions (not historical)
        future_forecast = forecast[forecast['ds'] > df['ds'].max()].copy()
        
        # Prepare response
        predictions = []
        for _, row in future_forecast.iterrows():
            predictions.append({
                'ds': row['ds'].strftime('%Y-%m-%d %H:%M:%S'),
                'yhat': round(row['yhat'], 2),
                'yhat_lower': round(row['yhat_lower'], 2),
                'yhat_upper': round(row['yhat_upper'], 2),
                'trend': round(row['trend'], 2)
            })
        
        return jsonify({
            'success': True,
            'predictions': predictions,
            'model_info': {
                'training_data_points': len(df),
                'forecast_periods': periods,
                'date_range': {
                    'start': df['ds'].min().strftime('%Y-%m-%d'),
                    'end': df['ds'].max().strftime('%Y-%m-%d')
                }
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'error': 'Prediction failed',
            'message': str(e)
        }), 500

@app.route('/staffing', methods=['POST'])
def staffing():
    try:
        # Check if model is loaded
        if pedestrian_model is None or scaler is None:
            return jsonify({
                'error': 'Model not loaded',
                'message': 'pedestrian_model.keras or scaler.pkl not found. Please ensure both files are in the same directory as the Flask app.'
            }), 500
        
        # Get data from request
        data = request.get_json()
        
        if not data or 'max_staff' not in data:
            return jsonify({'error': 'No data provided. Expected format: {"max_staff": 10, "day": "Monday"}'}), 400
        
        max_staff = data['max_staff']
        
        # Get day from request or use current day
        day_name = data.get('day', datetime.now().strftime('%A'))
        
        # Validate day
        if day_name not in weekday_map:
            return jsonify({'error': f'Invalid day: {day_name}. Must be one of {list(weekday_map.keys())}'}), 400
        
        # Validate max_staff
        if not isinstance(max_staff, (int, float)) or max_staff <= 0:
            return jsonify({'error': 'max_staff must be a positive number'}), 400
        
        # Get day number
        day_num = weekday_map[day_name]
        
        # Predict pedestrian traffic for each hour (0-23)
        hourly_predictions = []
        for hour in range(24):
            # Prepare input
            input_data = np.array([[hour, day_num]])
            input_scaled = scaler.transform(input_data)
            
            # Predict
            prediction = pedestrian_model.predict(input_scaled, verbose=0)
            predicted_pedestrians = max(0, int(prediction[0][0]))  # Ensure non-negative
            hourly_predictions.append(predicted_pedestrians)
        
        # Find the maximum predicted pedestrian count
        max_pedestrians = max(hourly_predictions)
        
        # Normalize: scale all values so that max becomes max_staff
        if max_pedestrians == 0:
            # Avoid division by zero
            normalized_staffing = [0] * 24
        else:
            normalized_staffing = [
                round((pred / max_pedestrians) * max_staff, 1)
                for pred in hourly_predictions
            ]
        
        # Prepare response
        staffing_schedule = []
        for hour in range(24):
            staffing_schedule.append({
                'hour': hour,
                'time': f'{hour:02d}:00',
                'predicted_pedestrians': hourly_predictions[hour],
                'recommended_staff': normalized_staffing[hour]
            })
        
        return jsonify({
            'success': True,
            'day': day_name,
            'max_staff': max_staff,
            'staffing_schedule': staffing_schedule,
            'summary': {
                'peak_hour': hourly_predictions.index(max_pedestrians),
                'peak_pedestrians': max_pedestrians,
                'total_predicted_pedestrians': sum(hourly_predictions)
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'error': 'Staffing prediction failed',
            'message': str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health():
    model_status = 'loaded' if pedestrian_model is not None else 'not loaded'
    scaler_status = 'loaded' if scaler is not None else 'not loaded'
    
    return jsonify({
        'status': 'healthy',
        'service': 'Prophet Foot Traffic & Staffing Prediction',
        'pedestrian_model': model_status,
        'scaler': scaler_status
    }), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5002, debug=True)