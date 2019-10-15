INGESTERS=$(kubectl -ncortex get po -lname=ingester -ojson | jq -r .items[].metadata.name)

for i in $INGESTERS; do
  echo "Flushing $i"

  kubectl -ncortex port-forward pod/$i 50080:80 &
  PORT_FORWARD=$!

  # Wait a little so the port-forward starts
  sleep 2

  curl -XPOST localhost:50080/flush

  kill $PORT_FORWARD
done
