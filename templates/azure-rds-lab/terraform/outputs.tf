locals {
  dc_host = {
    (azurerm_windows_virtual_machine.dc.name) = {
      ansible_host                         = azurerm_public_ip.dc.ip_address
      ansible_user                         = var.admin_username
      ansible_password                     = var.admin_password
      ansible_connection                   = "winrm"
      ansible_winrm_transport              = "basic"
      ansible_port                         = 5985
      ansible_winrm_server_cert_validation = "ignore"
      fqdn                                 = "${azurerm_windows_virtual_machine.dc.computer_name}.${var.domain_name}"
    }
  }

  broker_host = {
    (azurerm_windows_virtual_machine.broker.name) = {
      ansible_host                         = azurerm_public_ip.broker.ip_address
      ansible_user                         = var.admin_username
      ansible_password                     = var.admin_password
      ansible_connection                   = "winrm"
      ansible_winrm_transport              = "basic"
      ansible_port                         = 5985
      ansible_winrm_server_cert_validation = "ignore"
      fqdn                                 = "${azurerm_windows_virtual_machine.broker.computer_name}.${var.domain_name}"
    }
  }

  session_host_hosts = {
    for idx in range(var.session_host_count) :
    azurerm_windows_virtual_machine.session_host[idx].name => {
      ansible_host                         = azurerm_public_ip.session_host[idx].ip_address
      ansible_user                         = var.admin_username
      ansible_password                     = var.admin_password
      ansible_connection                   = "winrm"
      ansible_winrm_transport              = "basic"
      ansible_port                         = 5985
      ansible_winrm_server_cert_validation = "ignore"
      fqdn                                 = "${azurerm_windows_virtual_machine.session_host[idx].computer_name}.${var.domain_name}"
    }
  }
}

output "ansible_inventory" {
  description = "Ansible JSON inventory consumed by Lab Manager after terraform apply"
  sensitive   = true
  value = {
    all = {
      children = {
        domain_controllers = {
          hosts = local.dc_host
        }
        brokers = {
          hosts = local.broker_host
        }
        session_hosts = {
          hosts = local.session_host_hosts
        }
      }
      vars = {
        domain_name = var.domain_name
      }
    }
  }
}

output "resource_group_name" {
  description = "Resource group holding every resource in this lab instance"
  value       = azurerm_resource_group.lab.name
}

output "rd_web_access_url" {
  description = "RD Web Access URL for connecting to the published session collection"
  value       = "https://${azurerm_public_ip.broker.ip_address}/RDWeb"
}
