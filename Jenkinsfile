pipeline {
    agent any

    environment {
        // Define environment variables
        DOTNET_CLI_TELEMETRY_OPDOUT = '1'
        PYTHONUNBUFFERED = '1'
    }

    stages {
        stage('Initialize') {
            steps {
                echo 'Starting Pipeline for TrafficTrend...'
                // Print environment info
                script {
                    if (isUnix()) {
                        sh 'dotnet --version'
                        sh 'python3 --version'
                        sh 'node --version'
                    } else {
                        bat 'dotnet --version'
                        bat 'python --version'
                        bat 'node --version'
                    }
                }
            }
        }

        stage('Build Auth Backend (.NET)') {
            steps {
                dir('AuthBackend') {
                    script {
                        if (isUnix()) {
                            sh 'dotnet restore'
                            sh 'dotnet build --configuration Release'
                        } else {
                            bat 'dotnet restore'
                            bat 'dotnet build --configuration Release'
                        }
                    }
                }
            }
        }

        stage('Build & Lint Frontend (React Native)') {
            steps {
                dir('MyProject') {
                    script {
                        if (isUnix()) {
                            sh 'npm install'
                            // Linting ensures code quality (TypeScript checks)
                            sh 'npm run lint'
                        } else {
                            bat 'npm install'
                            bat 'npm run lint'
                        }
                    }
                }
            }
        }
        
        stage('Setup AI Service (Python)') {
            steps {
                dir('PythonBackend') {
                   script {
                       if (isUnix()) {
                           // Setup virtual environment and dependencies
                           sh 'python3 -m venv venv'
                           sh '. venv/bin/activate && pip install -r requirements.txt' 
                           // Optional: Run a smoke test or check syntax
                           sh '. venv/bin/activate && python -c "import flask; print(\'Flask installed\')"'
                       } else {
                           // Windows setup
                           bat 'python -m venv venv'
                           bat 'call venv\\Scripts\\activate.bat && pip install -r requirements.txt'
                           bat 'call venv\\Scripts\\activate.bat && python -c "import flask; print(\'Flask installed\')"'
                       }
                   }
                }
            }
        }

        stage('Test') {
            steps {
                echo 'Running Unit Tests...'
                // Placeholder for actual test commands
                // dir('AuthBackend') { bat 'dotnet test' }
            }
        }
    }

    post {
        success {
            echo 'TrafficTrend Build Passed!'
        }
        failure {
            echo 'Build Failed. Please check logs.'
        }
    }
}
