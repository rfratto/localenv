#!/usr/bin/env bash
#
# merge_k3d_config.bash
#
# Depends on https://github.com/kislyuk/yq:
#   pip install yq

NEW_KUBECONFIG=$(k3d get-kubeconfig --name='localenv')

yq -s -y \ "(\
  .[0].clusters[0].name = \"localenv\" | \
  .[0].users[0].name = \"localenv\" | \
  .[0].contexts[0].context.cluster = \"localenv\" | \
  .[0].contexts[0].context.user = \"localenv\" | \
  .[0].contexts[0].name = \"localenv\" | \
  .[0][\"current-context\"] = \"localenv\" \
  ) | .[0]" $NEW_KUBECONFIG > $NEW_KUBECONFIG.bk

mv $NEW_KUBECONFIG.bk $NEW_KUBECONFIG

KUBECONFIG=${KUBECONFIG:=$HOME/.kube/config}
cp $KUBECONFIG ${KUBECONFIG}.bk
KUBECONFIG=$NEW_KUBECONFIG:${KUBECONFIG}.bk kubectl config view --raw > $KUBECONFIG
rm ${KUBECONFIG}.bk

