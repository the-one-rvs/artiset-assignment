mkdir -p test-output

# /health probe
curl -v http://localhost:5000/health >> test-output/health.txt
grep '"status":"ok"' test-output/health.txt

# /live probe
curl -v http://localhost:5000/live >> test-output/live.txt
grep '"status":"alive"' test-output/live.txt

# /ready probe
curl -v http://localhost:5000/ready >> test-output/ready.txt
grep '"status":"ready"' test-output/ready.txt

docker stop test_container
docker rm test_container
