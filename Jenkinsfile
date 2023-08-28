pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archive 'target/*.jar'
            }
        }   
    stage('Unit Test') {
            steps {
              sh "mvn test"
            }
       post { 
       always { 
       junit 'target/surefire-reports/*.xml'
        jacoco execPattern: 'target/jacoco.exec'
        }   
  }
}
      stage('Docker Build') {
            steps {
              sh 'printevn'
              sh 'docker build -t saeed1988/numeric-app:""$GIT_COMMIT""'
              sh 'docker push  saeed1988/numeric-app:""$GIT_COMMIT""'
            }
        }  
  }
}
