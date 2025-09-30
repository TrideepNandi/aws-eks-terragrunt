output "policies" {
  description = "Map of created IAM policies"
  value = {
    for k, v in aws_iam_policy.this : k => {
      arn  = v.arn
      name = v.name
      id   = v.id
    }
  }
}

output "roles" {
  description = "Map of created IAM roles"
  value = {
    for k, v in aws_iam_role.this : k => {
      arn  = v.arn
      name = v.name
      id   = v.id
    }
  }
}

output "oidc_providers" {
  description = "Map of created OIDC providers"
  value = {
    for k, v in aws_iam_openid_connect_provider.this : k => {
      arn = v.arn
      url = v.url
    }
  }
}

output "users" {
  description = "Map of created IAM users"
  value = {
    for k, v in aws_iam_user.this : k => {
      arn  = v.arn
      name = v.name
      id   = v.id
    }
  }
}

output "access_keys" {
  description = "Map of created access keys (sensitive)"
  value = {
    for k, v in aws_iam_access_key.this : k => {
      id     = v.id
      secret = v.secret
    }
  }
  sensitive = true
}