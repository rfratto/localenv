# Debugging Go Applications

Build your container where the binary to debug is built without stripping
symobls and has the following go flags: `-gcflags "-N -l"`.

Then, inject delve into your image and push it to `k3d`:

```
./scripts/inject_delve.bash <image>:<tag> && k3d -n localenv import-images <image>
```

Run or restart your services so they use the new image. Once your
service is running `kubectl port-forward` a port of your choosing for the dlv
API:

```
kubectl port-forward <pod> 50080:50080
```

Now, launch the delve API server using `kubectl exec`:

```
kubectl exec -it <pod> -- dlv attach 1 --headless --accept-multiclient -l 0.0.0.0:50080
```

Finally, connect to your delve client locally:

```
dlv connect 127.0.0.1:50080
```

You can now debug your application. See the section below for other things you
may have to do before you can start debugging:

## Delve Path Substitution

When running `ls` in delve, you may get an error that there is no such file for
some Go source path in `/go/src`. If you have the source locally, you can
configure delve to substitute the path with the directory where the code is
on your local machine. For example:

```
config substitute-path /go/src/github.com/cortexproject/cortex /home/robert/dev/grafana/cortex
```

