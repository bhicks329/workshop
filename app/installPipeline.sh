fly -t local set-pipeline -p hello_hapi -c ci/pipeline.yml -l ~/CONTINO/credentials.yml
sleep 2
fly -t local unpause-pipeline -p hello_hapi
sleep 2
# fly -t local trigger-job -j hello_hapi/"Install dependencies" -w
