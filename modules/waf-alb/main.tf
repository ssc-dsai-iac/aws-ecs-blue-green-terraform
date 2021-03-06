# ---------------------------------------------------------------------------------------------------------------------
# AWS WAF V2 for ALB
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "this" {
  name        = var.name
  description = "The Application Load Balancer Firewall"
  scope       = "REGIONAL"

  tags        = var.tags

  default_action {
    block {}
  }

	rule {
    name     = "CDXP-Whitelist"
    priority = 0

    action {
      allow {}
    }

    statement {
			ip_set_reference_statement {
				arn = aws_wafv2_ip_set.this.arn
			}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "cdxp-whitelist"
      sampled_requests_enabled   = true
    }
  }

	visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = var.name
      sampled_requests_enabled   = true
    }

}

# ---------------------------------------------------------------------------------------------------------------------
# WAF V2 CDXP IP Set
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_wafv2_ip_set" "this" {
  name               = "CDXP-IP-Set"
  description        = "The CDXP IP set"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.cdxp_ip_set

  tags = var.tags
}

# ---------------------------------------------------------------------------------------------------------------------
# WAF V2 to ALB Association
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = "${var.alb_arn}"
  web_acl_arn = "${aws_wafv2_web_acl.this.arn}"
}