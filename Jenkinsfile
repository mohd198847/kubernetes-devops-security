@Library('slack') _

pipeline {
  agent any
  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "saeed1988/numeric-app:${GIT_COMMIT}"
    applicationURL="http://devsecops-kube.eastus.cloudapp.azure.com"
    applicationURI="/increment/99"
  }
	
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
	     post { 
         always { 

	   pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'

        }   
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
        timeout(time: 1, unit: 'MINUTES') {
                waitForQualityGate abortPipeline: true
              }
            }
	}

    	 stage('Vulnerability Scan - Docker') {
     		 steps {
             parallel(
        	"Dependency Scan": {
       		sh "mvn dependency-check:check"
			},
		"Trivy Scan":{
		sh "bash trivy-docker-image-scan.sh"
		},
		"OPA Conftest":{
		sh 'sudo docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy docker.rego Dockerfile'
		}   	
     			)
	 }
	 }
    
    stage('Docker Build') {
            steps {
               withDockerRegistry([credentialsId: "dockerlogin", url: ""]) {
              sh 'printenv'
              sh 'sudo docker build -t saeed1988/numeric-app:""$GIT_COMMIT"" .'
              
              sh 'sudo docker push  saeed1988/numeric-app:""$GIT_COMMIT""'
            }
        }  
 	 }
	   stage('Vulnerability Scan - Kubernetes') {
     steps {
        parallel(
          "OPA Scan": {
          sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy k8s-security.rego k8s_deployment_service.yaml'
          },
         "Kubesec Scan": {
           sh "bash kubesec-scan.sh"
          }
    //   "Trivy K8S Scan": {
   //     sh "bash trivy-k8s-scan.sh"
  //     }
           )
         
		}
       }
     
 //  stage('K8s Deployment') {
 //          steps {
 //             withKubeConfig([credentialsId: "kubeconfig"]) {
 //            sh "sed -i 's#replace#saeed1988/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
 //            sh 'kubectl apply -f k8s_deployment_service.yaml'
 //          
 //          }
 //      }  
 //	}
// } 
 
 stage('K8S Deployment - DEV') {
   steps {
     parallel(
       "Deployment": {
         withKubeConfig([credentialsId: 'kubeconfig']) {
           sh "bash k8s-deployment.sh"
         }
       },
       "Rollout Status": {
         withKubeConfig([credentialsId: 'kubeconfig']) {
           sh "bash k8s-deployment-rollout-status.sh"
         }
       }
     )
   }
 }
  
 stage ('Integration Tests - DEV') {
   steps {
     script {
       try {
         withKubeConfig([credentialsId: 'kubeconfig']) {
           sh "bash integration-test.sh"
         }
       } catch (e) {
         withKubeConfig([credentialsId: 'kubeconfig']) {
           sh "kubectl -n default rollout undo deploy ${deploymentName}"
         }
         throw e
       }
     }
   }
 }
//   stage('OWASP ZAP - DAST') {
//   steps {
//         withKubeConfig([credentialsId: 'kubeconfig']) {
  //        sh 'bash zap.sh'
  //       }
 //      }
 //    }

//     stage('Testing Slack - Error Stage') {
//      steps {
//          sh 'exit 0'
//      }
//    }
	  stage('Prompte to PROD?') {
       steps {
         timeout(time: 2, unit: 'DAYS') {
           input 'Do you want to Approve the Deployment to Production Environment/Namespace?'
     }
       }
	  }
      stage('K8S Deployment - PROD') {
      steps {
        parallel(
		"Deployment": {
             withKubeConfig([credentialsId: 'kubeconfig']) {
               sh "sed -i 's#replace#${imageName}#g' k8s_PROD-deployment_service.yaml"
               sh "kubectl -n prod apply -f k8s_PROD-deployment_service.yaml"
             }
           },
           "Rollout Status": {
             withKubeConfig([credentialsId: 'kubeconfig']) {
               sh "bash k8s-PROD-deployment-rollout-status.sh"
             }
           }
         )
     }
     }
  }
	post { 
         always { 
           junit 'target/surefire-reports/*.xml'
           jacoco execPattern: 'target/jacoco.exec'
	 //  pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml' //
	   dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
		 sendNotification currentBuild.result
	 //  publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'owasp-zap-report', reportFiles: 'zap_report.html', reportName: 'OWASP ZAP HTML REPORT', reportTitles: 'OWASP ZAP HTML REPORT', useWrapperFileDirectly: true])
        }   
  }
  
}
