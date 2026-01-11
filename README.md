# TrafficTrend - AI-Powered Retail Analytics Dashboard

TrafficTrend is a comprehensive mobile dashboard application designed to help retail managers track daily foot traffic, detect anomalies, optimize staffing levels, and forecast future customer trends using AI.

## 🏗 Architecture

The project is built as a monorepo with three distinct services:

1.  **Frontend (`MyProject`)**: A React Native (Expo) mobile application serving as the user interface.
2.  **Auth Backend (`AuthBackend`)**: An ASP.NET Core Web API handling user authentication (JWT), data persistence (SQL Server), and business logic.
3.  **AI Service (`PythonBackend`)**: A Python Flask microservice utilizing TensorFlow and Prophet for time-series forecasting and staffing optimization.

## 🚀 Tech Stack

-   **Frontend**: React Native, Expo, TypeScript, React Native Reanimated, React Native Chart Kit.
-   **Backend**: C# .NET 8.0, ASP.NET Core Entity Framework Core, SQL Server.
-   **AI/ML**: Python 3.x, Flask, TensorFlow, Prophet, Pandas, Scikit-learn.

## 🛠 Prerequisites

-   Node.js & npm
-   .NET 10.0 SDK
-   Python 3.10+
-   SQL Server (LocalDB or full instance)
-   Expo Go app (for testing on mobile)

## 📦 Setup & Running

### 1. Database Setup
Ensure you have a SQL Server instance running. The `AuthBackend` is configured to use `(localdb)\\mssqllocaldb` by default. Update `appsettings.json` if needed.

### 2. Auth Backend (C#)
Navigate to the `AuthBackend` directory and start the server:
```bash
cd AuthBackend
dotnet restore
dotnet run
```
*Runs on: `http://localhost:5000`*

### 3. AI Service (Python)
Navigate to the `PythonBackend` directory, install dependencies, and start the Flask server:
```bash
cd PythonBackend
pip install -r requirements.txt
python main.py
```
*Runs on: `http://localhost:5002`*

> **Note**: You may need to train the model first if `pedestrian_model.keras` is missing. Run `python train-tf-model.py` to generate it.

### 4. Frontend (React Native)
Navigate to the `MyProject` directory and start the Expo development server:
```bash
cd MyProject
npm install
npx expo start
```
*Scan the QR code with the Expo Go app on your phone.*

## ✨ Key Features

-   **Daily Input**: Log daily customer foot traffic counts.
-   **Secure Auth**: Full sign-up and login flow using JWT.
-   **Traffic History**: Interactive charts visualizing historical data.
-   **Staffing Optimization**: Get AI-recommended staffing levels for every hour of the day based on predicted traffic.
-   **AI Forecasting**: Predict tomorrow's foot traffic using advanced machine learning models.

## 📄 License
[Proprietary/MIT] - See LICENSE file for details.
