# tf-connectivity-platform-gcp
This module will help you deploy a connectivity platform

<h2>1. Build image kong cp hybrid</h2>
```
# kong cp multi region

packer build -var 'region=taiwan' -var 'conf_dir=packer/conf/kong-cp-taiwan' -var 'playbook=packer/ansible/inventory/kong_hybrid.yml' packer/kong_cp.json
packer build -var 'region=singapore' -var 'conf_dir=packer/conf/kong-cp-singapore' -var 'playbook=packer/ansible/inventory/kong_hybrid.yml' packer/kong_cp.json
```

```
# kong dp multi region

packer build -var 'region=taiwan' -var 'conf_dir=packer/conf/kong-dp-singapore' -var 'playbook=packer/ansible/inventory/kong_hybrid.yml' packer/kong_dp.json
packer build -var 'region=singapore' -var 'conf_dir=packer/conf/kong-dp-singapore' -var 'playbook=packer/ansible/inventory/kong_hybrid.yml' packer/kong_dp.json
```