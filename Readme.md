# Assignment: CI/CD + Dockerized Flask app

This repository contains a small Flask web app packaged as a Docker image and an automated GitHub Actions pipeline that builds, tests, pushes the image to Docker Hub, and deploys it to a Google Cloud VM.

Quick links
- App source: [app.py](app.py) — WSGI app object [`app`](app.py) with routes [`app.home`](app.py) and [`app.name`](app.py)  
- Docker build: [Dockerfile](Dockerfile)  
- Dependencies: [requirements.txt](requirements.txt)  
- CI/CD workflow: [.github/workflows/cicd.yaml](.github/workflows/cicd.yaml) (job: [`build-test-push`](.github/workflows/cicd.yaml))  
- Ignore: [.dockerignore](.dockerignore), [.gitignore](.gitignore)

1. Project overview
- What it is: a minimal Flask app that returns simple greetings, packaged in a Docker image and deployed by a GitHub Actions pipeline.
- Exposed endpoints (see [app.py](app.py)):
  - GET / → handled by [`app.home`](app.py), returns: `Hello World from Flask!`
  - GET /name/hello/<name> → handled by [`app.name`](app.py), returns: `Hello <name>`
- Runtime: container listens on port 5000 (see [Dockerfile](Dockerfile)).

2. Files and responsibilities
- [app.py](app.py) — Flask application and routes (`app`, `app.home`, `app.name`).
- [Dockerfile](Dockerfile) — two-stage build: installs Python dependencies in a builder stage and copies them into the final image based on `python:3.11-slim`.
- [requirements.txt](requirements.txt) — application dependencies (`flask`).
- [.github/workflows/cicd.yaml](.github/workflows/cicd.yaml) — CI and CD workflow which builds, tests, pushes, and deploys.
- [.dockerignore](.dockerignore), [.gitignore](.gitignore) — ignore local venv.

3. How the GitHub Actions pipeline works (see [.github/workflows/cicd.yaml](.github/workflows/cicd.yaml), job: [`build-test-push`](.github/workflows/cicd.yaml))
High-level steps executed on push to branch `master`:
  1. Checkout code.
  2. Compute an image tag and export it as `IMAGE_TAG`.
  3. Login to Docker Hub using repository secrets.
  4. Build the Docker image and tag as `${{ secrets.DOCKERHUB_USERNAME }}/artiset-assignment:${{ env.IMAGE_TAG }}`.
  5. Run a basic smoke test by starting a container, curling `http://localhost:5000`, and asserting the response.
  6. Upload the test output as an artifact.
  7. Push the image to Docker Hub.
  8. Authenticate to GCP and SSH into the target VM to pull and run the new image.

Image tag generation (workflow logic)
- The workflow computes a 3-part tag $Z.Y.X$ where $Z$ is fixed to 1 and $X,Y$ are derived from `GITHUB_RUN_NUMBER`. The logic in the workflow is:

$$
X = \mathrm{GITHUB\_RUN\_NUMBER} \bmod 10, \quad
Y = \left\lfloor\frac{\mathrm{GITHUB\_RUN\_NUMBER}}{10}\right\rfloor \bmod 10, \quad
\mathrm{IMAGE\_TAG} = 1.Y.X
$$

(See the `Set image version` step in [.github/workflows/cicd.yaml](.github/workflows/cicd.yaml).)

4. Docker & local run
- Build locally:
```sh
docker build -t <dockerhub_user>/artiset-assignment:local .
```
- Run locally:
```sh
docker run -p 5000:5000 <dockerhub_user>/artiset-assignment:local
curl http://localhost:5000
```
- Or run without Docker:
```sh
python app.py
```
Docker image pattern used by CI: `${{ secrets.DOCKERHUB_USERNAME }}/artiset-assignment:${{ env.IMAGE_TAG }}` (see [Dockerfile](Dockerfile) and [.github/workflows/cicd.yaml](.github/workflows/cicd.yaml)).

5. CI smoke test details
- The workflow starts the built image in a container named `test_container`, waits ~5s, then runs:
  - `curl http://localhost:5000` and verifies the response contains `Hello World from Flask!`.
- The raw output is saved to `test-output/result.txt` and uploaded via the `actions/upload-artifact` step (see [.github/workflows/cicd.yaml](.github/workflows/cicd.yaml)).

6. Deployment (CD) details
- After pushing the image, the workflow authenticates to GCP using the `GCP_SA_KEY` secret and uses `gcloud compute ssh` to run remote commands on host `instance-20260114-104743` in zone `us-central1-c`.
- Remote commands:
  - `docker pull <image>`
  - stop/remove any existing container named `app`
  - run the container mapping host port 80 → container port 5000:
    - `docker run -d --name app -p 80:5000 <image>`
- Confirm the VM's firewall and SSH access for the service account used.

7. Required GitHub secrets
- `DOCKERHUB_USERNAME` — Docker Hub username (used for image name and login)  
- `DOCKERHUB_TOKEN` — Docker Hub access token or password  
- `GCP_SA_KEY` — JSON service account key with permissions to SSH and manage compute instances (used by `google-github-actions/auth@v2`)

8. Common troubleshooting
- "curl fails" in CI: runner port 5000 may be occupied; increase sleep before curl or change ports.
- "docker push" fails: verify `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` are correct and have push rights.
- GCP deploy errors: ensure `GCP_SA_KEY` has compute instance access and the VM name/zone match [.github/workflows/cicd.yaml](.github/workflows/cicd.yaml).
- Inspect the uploaded artifact `basic-test-output` in workflow run for raw response.

9. Useful commands (local testing & debugging)
- Build: `docker build -t myuser/artiset-assignment:debug .`
- Run: `docker run -it --rm -p 5000:5000 myuser/artiset-assignment:debug`
- Test locally: `curl -v http://localhost:5000`
- Reproduce CI tag logic locally:
```sh
GITHUB_RUN_NUMBER=123
Z=1
X=$((GITHUB_RUN_NUMBER % 10))
Y=$(((GITHUB_RUN_NUMBER / 10) % 10))
echo "$Z.$Y.$X"
```

10. Notes & next steps
- To change tag logic, deployment host, or ports, update [.github/workflows/cicd.yaml](.github/workflows/cicd.yaml).
- Secure secrets in repository settings; do not commit credentials.
- For production: add real testing (unit/integration), health checks, and rolling deployment strategy.

## File map (quick)
- [app.py](app.py) — Flask app (`app`, `app.home`, `app.name`)  
- [Dockerfile](Dockerfile) — build instructions  
- [requirements.txt](requirements.txt) — dependencies  
- [.github/workflows/cicd.yaml](.github/workflows/cicd.yaml) — pipeline (job: [`build-test-push`](.github/workflows/cicd.yaml))  
- [.dockerignore](.dockerignore), [.gitignore](.gitignore)