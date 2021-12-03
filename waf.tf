# ---------------------------------------------------------------------------------------------------------------------
# AWS WAF V2
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_wafv2_web_acl" "this" {
  name        = "${var.prefix}-${var.user_defined}-alb-waf"
  description = "The Application Load Balancer Firewall"
  scope       = "REGIONAL"

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
      metric_name                = "${var.prefix}-${var.user_defined}-alb-waf"
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

  tags = {
    Env = var.env
    CostCenter = var.costcenter
    SSN = var.ssn
    SubOwner = var.subowner
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# WAF V2 to ALB Association
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_wafv2_web_acl_association" "this" {
  resource_arn = "${module.alb.lb_arn}"
  web_acl_arn = "${aws_wafv2_web_acl.this.arn}"
}