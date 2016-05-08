#!/bin/bash

set -e

job_namespace="mysql"
job_name="mysqldumper"

kubectl replace --force -f - > /dev/null <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: $job_name
  namespace: $job_namespace
spec:
  activeDeadlineSeconds: 7200
  template:
    metadata:
      name: mysql-backup
    spec:
      containers:
      - name: mysql-backup
        image: simonswine/mysqldumper
        imagePullPolicy: Always
        env:
        - name: MYSQL_HOST
          value: mysql
        - name: MYSQL_USER
          value: root
        - name: BACKUP_DIR
          value: /_backup
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql
              key: root.password
        volumeMounts:
        - mountPath: /_backup
          name: mysql-backup
      volumes:
      - name: mysql-backup
        <add your backup volume here>
      restartPolicy: Never
EOF

# wait for job to succeed
tries=0
while true; do
    succeeded=$(kubectl get job --namespace=${job_namespace} ${job_name} --output=jsonpath={.status.succeeded})
    if [[ $succeeded -eq 1 ]]; then
        break
    fi
    if [[ $tries -gt 3600 ]]; then
        echo "job timed out"
        kubectl describe job --namespace=${job_namespace} ${job_name}
        exit 1
    fi
    tries=$((tries + 1))
    sleep 1
done

exit 0
