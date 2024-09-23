## Directory Structure
```markdown
hackathon-starter/
│
├── setup/
│   ├── deployment/
│   │   ├── backend/
│   │   │   ├── deployment.yaml // Kubernetes deployment configuration for backend
│   │   │   └── ingress.yaml // Kubernetes ingress configuration for backend
│   │   ├── frontend/
│   │   │   ├── deployment.yaml // Kubernetes deployment configuration for frontend
│   │   │   └── ingress.yaml // Kubernetes ingress configuration for frontend
│   │   └── hpa.yaml // Horizontal Pod Autoscaler configuration
│   ├── setup.sh // Script for setting up the environment
│   ├── config.yaml // Configuration file for the project
│   └── Jenkinsfile.groovy // Jenkins pipeline configuration
│
├── Dockerfile.backend // Dockerfile for building the backend image
│
├── Dockerfile.frontend // Dockerfile for building the frontend image
│
└── build.sh // Script for building and pushing Docker images
```
### Horizontal Pod Autoscaler (HPA)

The application is configured with Horizontal Pod Autoscalers for both frontend and backend deployments. This allows the number of pods to automatically scale based on CPU utilization. The HPA is configured to:

- Maintain a minimum of 1 replica
- Scale up to a maximum of 10 replicas
- Target 50% average CPU utilization

To view the current status of the HPAs:

```bash
kubectl get hpa
```

To modify the HPA settings, edit the `setup/deployment/hpa.yaml` file and reapply it using kubectl.

### Jenkins Pipeline

The Jenkins pipeline is defined in `setup/deployment/Jenkinsfile.groovy`. It performs the following steps:

1. **Checkout Code**: Retrieves the source code from the repository.
2. **Run Tests**: Runs the frontend and backend tests.
3. **SonarQube Analysis**: Performs a SonarQube analysis of the code.
4. **Build Docker Images**: Builds the frontend and backend Docker images.
5. **Push Docker Images**: Pushes the Docker images to the Docker Hub.
6. **Deploy to Kubernetes**: Uses Helm to install and deploy the application on Kubernetes.
5. **Create ConfigMap**: Creates a ConfigMap from the `.env.example` file.
6. **Apply Kubernetes Resources**: Applies the Kubernetes resources (deployments, services, ingress, and HPAs) using kubectl.

To trigger a build, you can use the Jenkins pipeline in the Jenkins web interface.

