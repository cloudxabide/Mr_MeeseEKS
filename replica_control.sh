#!/bin/bash
#

usage() { echo "$0 {up|down}"; exit 9; }
if  [ $# -ne 1 ]; then usage; fi 
ACTION=$1
DEPLOYMENTS="ecsdemo-frontend ecsdemo-crystal ecsdemo-nodejs"
SLEEPYTIME=8

for DEPLOYMENT in $DEPLOYMENTS
do
        echo "Deployment to scale: $DEPLOYMENT"
        case $ACTION in
                "down")
                        CURRENT_REPLICAS=$(kubectl get deployment $DEPLOYMENT -o=jsonpath='{.status.replicas}')
                        if [ $CURRENT_REPLICAS == 1 ]; then echo "Already scaled to 1"; break; fi
                        for REPLICAS in 3 2 1
                        do
                                kubectl scale deployment $DEPLOYMENT --replicas=$REPLICAS
                                echo "Deployment: $DEPLOYMENT scaled to - $REPLICAS"
                                sleep $SLEEPYTIME
                        done
                        kubectl get pods | grep $DEPLOYMENT
                        ;;
                "up")
                        CURRENT_REPLICAS=$(kubectl get deployment $DEPLOYMENT -o=jsonpath='{.status.replicas}')
                        if [ $CURRENT_REPLICAS == 3 ]; then echo "Already scaled to 3"; break; fi
                        for REPLICAS in 1 2 3
                        do
                                kubectl scale deployment $DEPLOYMENT --replicas=$REPLICAS
                                echo "Deployment: $DEPLOYMENT scaled to - $REPLICAS"
                                sleep $SLEEPYTIME
                        done
                        kubectl get pods | grep $DEPLOYMENT
                        ;;
                "current")
                        CURRENT_REPLICAS=$(kubectl get deployment $DEPLOYMENT -o=jsonpath='{.status.replicas}')
                        echo "Deployment: $DEPLOYMENT scaled to - $CURRENT_REPLICAS"
                ;;
                *)
                        usage
                        ;;
        esac
        echo ""
done
