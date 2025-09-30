# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  common_tags = merge(var.tags, {
    ManagedBy = "Terraform"
    Module    = "iam-roles"
  })
}

# OIDC Providers
resource "aws_iam_openid_connect_provider" "this" {
  for_each = var.oidc_providers

  url             = each.value.url
  client_id_list  = each.value.client_id_list
  thumbprint_list = each.value.thumbprint_list

  tags = merge(local.common_tags, each.value.tags, {
    Name = "${var.name_prefix}${each.key}"
  })
}

# IAM Policies (Custom Managed Policies)
resource "aws_iam_policy" "this" {
  for_each = var.policies

  name        = "${var.name_prefix}${each.value.name_suffix}"
  description = each.value.description
  policy      = each.value.policy
  path        = each.value.path

  tags = merge(local.common_tags, each.value.tags, {
    Name = "${var.name_prefix}${each.value.name_suffix}"
  })
}

# IAM Roles
resource "aws_iam_role" "this" {
  for_each = var.roles

  name                 = "${var.name_prefix}${each.value.name_suffix}"
  description          = each.value.description
  max_session_duration = each.value.max_session_duration
  assume_role_policy   = each.value.assume_role_policy
  path                 = each.value.path

  tags = merge(local.common_tags, each.value.tags, {
    Name = "${var.name_prefix}${each.value.name_suffix}"
  })
}

# AWS Managed Policy Attachments
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = {
    for combo in flatten([
      for role_key, role in var.roles : [
        for policy_arn in role.managed_policy_arns : {
          role_key   = role_key
          policy_arn = policy_arn
          key        = "${role_key}-${replace(policy_arn, "/[^a-zA-Z0-9]/", "-")}"
        }
      ]
    ]) : combo.key => combo
  }

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}

# Custom Policy Attachments (policies created by this module)
resource "aws_iam_role_policy_attachment" "custom" {
  for_each = {
    for combo in flatten([
      for role_key, role in var.roles : [
        for policy_key in role.custom_policy_attachments : {
          role_key   = role_key
          policy_key = policy_key
          key        = "${role_key}-${policy_key}"
        }
      ]
    ]) : combo.key => combo
  }

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = aws_iam_policy.this[each.value.policy_key].arn
}

# Inline Policies
resource "aws_iam_role_policy" "inline" {
  for_each = {
    for combo in flatten([
      for role_key, role in var.roles : [
        for policy_name, policy_document in role.inline_policies : {
          role_key        = role_key
          policy_name     = policy_name
          policy_document = policy_document
          key             = "${role_key}-${policy_name}"
        }
      ]
    ]) : combo.key => combo
  }

  name   = each.value.policy_name
  role   = aws_iam_role.this[each.value.role_key].id
  policy = each.value.policy_document
}

# IAM Users
resource "aws_iam_user" "this" {
  for_each = var.users

  name = "${var.name_prefix}${each.value.name_suffix}"
  path = each.value.path

  tags = merge(local.common_tags, each.value.tags, {
    Name = "${var.name_prefix}${each.value.name_suffix}"
  })
}

# IAM User Policies (AWS Managed)
resource "aws_iam_user_policy_attachment" "managed" {
  for_each = {
    for combo in flatten([
      for user_key, user in var.users : [
        for policy_arn in user.managed_policy_arns : {
          user_key   = user_key
          policy_arn = policy_arn
          key        = "${user_key}-${replace(policy_arn, "/[^a-zA-Z0-9]/", "-")}"
        }
      ]
    ]) : combo.key => combo
  }

  user       = aws_iam_user.this[each.value.user_key].name
  policy_arn = each.value.policy_arn
}

# IAM User Custom Policy Attachments
resource "aws_iam_user_policy_attachment" "custom" {
  for_each = {
    for combo in flatten([
      for user_key, user in var.users : [
        for policy_key in user.custom_policy_attachments : {
          user_key   = user_key
          policy_key = policy_key
          key        = "${user_key}-${policy_key}"
        }
      ]
    ]) : combo.key => combo
  }

  user       = aws_iam_user.this[each.value.user_key].name
  policy_arn = aws_iam_policy.this[each.value.policy_key].arn
}

# IAM User Inline Policies
resource "aws_iam_user_policy" "inline" {
  for_each = {
    for combo in flatten([
      for user_key, user in var.users : [
        for policy_name, policy_document in user.inline_policies : {
          user_key        = user_key
          policy_name     = policy_name
          policy_document = policy_document
          key             = "${user_key}-${policy_name}"
        }
      ]
    ]) : combo.key => combo
  }

  name   = each.value.policy_name
  user   = aws_iam_user.this[each.value.user_key].name
  policy = each.value.policy_document
}

# IAM Access Keys (optional)
resource "aws_iam_access_key" "this" {
  for_each = {
    for user_key, user in var.users : user_key => user
    if user.create_access_key
  }

  user = aws_iam_user.this[each.key].name
}