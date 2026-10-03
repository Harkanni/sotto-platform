# Secrets for the demo live in SSM Parameter Store as encrypted SecureStrings. deploy.sh turns
# everything under /sotto/demo/ into the server's .env. Terraform generates the passwords, so no
# human ever sees or types them. (They're also in the state file — another reason state is a
# private, encrypted bucket.)
resource "random_password" "postgres" {
  length  = 32
  special = false # used inside a connection URL
}

resource "random_password" "rabbitmq" {
  length  = 32
  special = false
}

resource "aws_ssm_parameter" "postgres_password" {
  name  = "/sotto/demo/POSTGRES_PASSWORD"
  type  = "SecureString"
  value = random_password.postgres.result
}

resource "aws_ssm_parameter" "rabbitmq_password" {
  name  = "/sotto/demo/RABBITMQ_PASSWORD"
  type  = "SecureString"
  value = random_password.rabbitmq.result
}

# Phase 3: signs sessions and CSRF tokens (sotto-api requires 32+ characters in production).
resource "random_password" "auth_secret" {
  length  = 48
  special = false
}

resource "aws_ssm_parameter" "auth_secret" {
  name  = "/sotto/demo/AUTH_SECRET"
  type  = "SecureString"
  value = random_password.auth_secret.result
}

# Phase 3: until sotto.ai exists (and SES with it), the demo's sign-in links and invites land in
# Mailpit on the server, behind this password (ADR 0015). `terraform output -raw
# demo_mail_password` shows it.
resource "random_password" "mailpit" {
  length  = 24
  special = false # used inside MP_UI_AUTH ("user:password")
}

resource "aws_ssm_parameter" "mailpit_password" {
  name  = "/sotto/demo/MAILPIT_PASSWORD"
  type  = "SecureString"
  value = random_password.mailpit.result
}

resource "aws_ssm_parameter" "site_address" {
  name  = "/sotto/demo/SITE_ADDRESS"
  type  = "String"
  value = local.site_address
}

# The only command CI may run on the server. Parameters are pattern-checked, so a workflow can't
# smuggle arbitrary shell through them.
resource "aws_ssm_document" "deploy" {
  name            = "sotto-deploy"
  document_type   = "Command"
  document_format = "JSON"
  content = jsonencode({
    schemaVersion = "2.2"
    description   = "Deploy Sotto service images on the demo server"
    parameters = {
      tag = {
        type           = "String"
        description    = "Image tag, e.g. sha-1a2b3c4"
        allowedPattern = "^(sha-[0-9a-f]{7,40}|main|bootstrap)$"
      }
      services = {
        type           = "String"
        description    = "Space-separated services: web api worker transcriber"
        allowedPattern = "^((web|api|worker|transcriber)( (web|api|worker|transcriber))*)?$"
        default        = ""
      }
    }
    mainSteps = [{
      action = "aws:runShellScript"
      name   = "deploy"
      inputs = {
        timeoutSeconds = "900"
        runCommand     = ["/opt/sotto/deploy.sh {{ tag }} {{ services }}"]
      }
    }]
  })
}
