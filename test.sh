mkdir -p test-output

docker run -d -p 5000:5000 --name test_container \
  ${{ secrets.DOCKERHUB_USERNAME }}/artiset-assignment:${{ env.IMAGE_TAG }}

sleep 5

# Health probe
curl -s -o test-output/health.txt -w "%{http_code}" \
  http://localhost:5000/health | grep 200
grep '"status":"ok"' test-output/health.txt

# Liveness probe
curl -s -o test-output/live.txt -w "%{http_code}" \
  http://localhost:5000/live | grep 200
grep '"status":"alive"' test-output/live.txt

# Readiness probe
curl -s -o test-output/ready.txt -w "%{http_code}" \
  http://localhost:5000/ready | grep 200
grep '"status":"ready"' test-output/ready.txt

# Root endpoint
curl -s http://localhost:5000 | tee test-output/root.txt
grep "Hello World from Flask!" test-output/root.txt

# Name endpoint
curl -s http://localhost:5000/name/hello/DevOps | tee test-output/name.txt
grep "Hello DevOps" test-output/name.txt


docker stop test_container
docker rm test_container
