output "corda_api_url" {
  value = "http://${kubernetes_service.corda.status.0.load_balancer.0.ingress.0.ip}:8888"
}

output "flow_management_tool_url" {
  value = "http://${kubernetes_service.flow_management_tool.status.0.load_balancer.0.ingress.0.ip}:5000"
}
