output "ansible_inventory" {
  value = {
    all = {
      hosts = {
        (var.vm_name) = {
          ansible_host       = "127.0.0.1"
          ansible_connection = "local"
        }
      }
    }
  }
}
