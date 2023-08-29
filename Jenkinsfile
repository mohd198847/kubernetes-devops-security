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
               withDockerRegistry([ credentialsId: "dockerhub", url: "" ]) {
              sh 'printenv'
              sh 'docker build -t saeed1988/numeric-app:""$GIT_COMMIT"" .'
              
              sh 'docker push  saeed1988/numeric-app:""$GIT_COMMIT""'
            }
        }  
  }
    stage('K8s Deployment') {
            steps {
               withKubeConfig([ credentialsId: "kubeconfig" ]) {
              sh "sed -i 's#replace#saeed1988/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
              sh 'kubectl apply -f k8s_deployment_service.yaml'
            
            }
        }  
  }
     stage('Mutation Tests - PIT') {
       steps {
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
       }
        post { 
          always{ 
            pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
        }
    }
   }
  }
}
