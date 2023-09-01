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

}

     stage('Mutation Tests - PIT') {
       steps {
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
       }

  
 
   }
stage('SonarQube - SAST') {
      steps {
        withSonarQubeEnv('SonarQube') {
          sh "mvn clean verify sonar:sonar  -Dsonar.projectKey=numeric-application -Dsonar.projectName='numeric-application' -Dsonar.host.url=http://devsecops-kube.eastus.cloudapp.azure.com:9000"
         }
  }
}
              stage("Quality Gate") {
            steps {
              sleep(60)
              timeout(time: 1, unit: 'HOURS') {
                waitForQualityGate abortPipeline: true
              }
            }
              }

    	 stage('Vulnerability Scan - Docker') {
      steps {
         		sh "mvn dependency-check:check"
			}

     
  
       }


    
	// 		"Trivy Scan":{
	// 			sh "bash trivy-docker-image-scan.sh"
	// 		},
	// 		"OPA Conftest":{
	// 			sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
	// 		}   	
 //      	)
 //      }
 //    }
    
    
    
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
  }  
  }
       post { 
       always { 
       junit 'target/surefire-reports/*.xml'
        jacoco execPattern: 'target/jacoco.exec'
                  pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
	          dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
        }   
  }
	
