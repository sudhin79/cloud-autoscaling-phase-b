#!/bin/bash

ALB_URL="http://alb-986d3c54-1947682390.ap-south-1.elb.amazonaws.com"

echo "Starting LIGHT load test on $ALB_URL..."

for i in {1..300}
do
  curl -s "$ALB_URL/hello" >/dev/null &
  
  if (( $i % 50 == 0 )); then
    wait
    echo "$i requests sent..."
  fi
done

wait
echo "Light load test completed!"
