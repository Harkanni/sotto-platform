// sotto-platform on Jenkins (ADR 0030): what GitHub Actions' ci.yml and deploy-config.yml did.
// Terraform, shellcheck and Caddy run in containers, so the host needs only Docker (with the
// compose plugin), the AWS CLI and the Lockable Resources plugin.
//
// Terraform formatting is checked, not fixed: run `terraform fmt -recursive terraform` before
// pushing (or read the diff this prints and apply it).

pipeline {
  agent any

  options {
    timeout(time: 20, unit: 'MINUTES')
    disableConcurrentBuilds()
    buildDiscarder(logRotator(numToKeepStr: '30'))
  }

  environment {
    AWS_REGION = 'eu-west-2'
    TF_IMAGE = 'hashicorp/terraform:1.16.4'
  }

  stages {
    stage('Secrets scan') {
      steps {
        sh 'docker run --rm -v "$PWD:/repo" ghcr.io/gitleaks/gitleaks:latest dir /repo --redact --verbose'
      }
    }

    // fmt, then init without the remote state or AWS credentials, then validate: syntax and
    // references, for both stacks.
    stage('Terraform') {
      steps {
        sh '''
          for stack in bootstrap dev; do
            echo "== terraform/$stack"
            docker run --rm -v "$PWD/terraform/$stack:/tf" -w /tf --entrypoint sh "$TF_IMAGE" -c '
              set -e
              terraform fmt -check -diff
              terraform init -backend=false -input=false >/dev/null
              terraform validate -no-color
              rm -rf .terraform .terraform.lock.hcl.tmp' || exit 1
          done
        '''
      }
    }

    stage('Scripts') {
      steps {
        sh 'docker run --rm -v "$PWD:/mnt" koalaman/shellcheck:v0.11.0 deploy/demo/deploy.sh deploy/demo/backup.sh terraform/dev/user_data/workbench.sh'
      }
    }

    stage('Compose and Caddy files parse') {
      steps {
        sh '''
          # local/compose.yaml builds from the sibling repos: empty stand-ins are enough to parse.
          mkdir -p ../sotto-web ../sotto-api/services/transcriber
          docker compose -f local/compose.yaml config --quiet
          printf 'ECR_REGISTRY=x\\nPOSTGRES_PASSWORD=x\\nRABBITMQ_PASSWORD=x\\nSITE_ADDRESS=localhost\\nAUTH_SECRET=x\\nMAILPIT_PASSWORD=x\\nFILES_BUCKET=x\\nAWS_REGION=eu-west-2\\n' > demo-ci.env
          docker compose -f deploy/demo/compose.yaml --env-file demo-ci.env config --quiet
          rm -f demo-ci.env
          docker run --rm -v "$PWD/local/Caddyfile:/etc/caddy/Caddyfile:ro" caddy:2-alpine \
            caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
          docker run --rm -e SITE_ADDRESS=localhost -v "$PWD/deploy/demo/Caddyfile:/etc/caddy/Caddyfile:ro" \
            caddy:2-alpine caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile
        '''
      }
    }

    // What deploy-config.yml did: when deploy/demo changes on main, upload the files to the
    // config bucket and tell the demo server to re-sync and restart what changed. CONFIG_BUCKET
    // is a Jenkins global environment variable (`terraform output` prints the bucket).
    stage('Deploy demo config') {
      when {
        branch 'main'
        changeset 'deploy/demo/**'
      }
      steps {
        sh '''
          for f in deploy/demo/*; do
            aws s3 cp "$f" "s3://$CONFIG_BUCKET/demo/$(basename "$f")" --no-progress
          done
          ID=$(aws ssm send-command --document-name sotto-deploy \
            --targets "Key=tag:sotto-role,Values=demo" \
            --parameters "tag=bootstrap,services=" \
            --comment "sotto-platform config $(echo $GIT_COMMIT | cut -c1-7)" \
            --query Command.CommandId --output text)
          for i in $(seq 1 60); do
            STATUS=$(aws ssm list-commands --command-id "$ID" --query 'Commands[0].Status' --output text)
            echo "status: $STATUS"
            case "$STATUS" in Success) exit 0 ;; Failed|Cancelled|TimedOut) exit 1 ;; esac
            sleep 10
          done
          exit 1
        '''
      }
    }
  }

  post {
    always { cleanWs() }
  }
}
