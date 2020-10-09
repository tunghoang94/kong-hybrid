# tf-connectivity-platform-gcp
This module will help you deploy a connectivity platform

<h2>1. Build image kong cp hybrid</h2>
# kong cp multi region
```
packer build -var 'region=taiwan' -var 'conf_dir=packer/conf/kong-cp-taiwan' -var 'playbook=packer/ansible/inventory/kong_hybrid.yml' -var 'cluster_crt=packer/conf/cluster.crt' -var 'cluster_key=packer/conf/cluster.key' packer/kong_cp.json
packer build -var 'region=singapore' -var 'conf_dir=packer/conf/kong-cp-singapore' -var 'playbook=packer/ansible/inventory/kong_hybrid.yml' -var 'cluster_crt=packer/conf/cluster.crt' -var 'cluster_key=packer/conf/cluster.key' packer/kong_cp.json
```

# kong dp multi region
```
packer build -var 'region=taiwan' -var 'conf_dir=packer/conf/kong-dp-taiwan' -var 'playbook=packer/ansible/inventory/kong_hybrid.yml' -var 'cluster_crt=packer/conf/cluster.crt' -var 'cluster_key=packer/conf/cluster.key' packer/kong_dp.json
packer build -var 'region=singapore' -var 'conf_dir=packer/conf/kong-dp-singapore' -var 'playbook=packer/ansible/inventory/kong_hybrid.yml' -var 'cluster_crt=packer/conf/cluster.crt' -var 'cluster_key=packer/conf/cluster.key' packer/kong_dp.json
```

# kong admin
```
packer build -var 'env_dir=packer/conf/kong-admin/.env' -var 'playbook=packer/ansible/inventory/kong_admin.yml' packer/kong_admin.json
```