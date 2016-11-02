include:
  - cuckoo.deps

stop_cuckoo:
  cmd.run:
    - name: "supervisorctl stop cuckoo:"
    - user: {{ salt['pillar.get']('cuckoo:user', 'cuckoo') }}
    - cwd: {{ salt['pillar.get']('cuckoo:cwd') }}

stop_vbox:
  cmd.run:
    - name: vmcloak-killvbox || true
    - user: {{ salt['pillar.get']('cuckoo:user', 'cuckoo') }}

remove_vms:
  cmd.run:
    - name: echo y|vmcloak-removevms
    - user: {{ salt['pillar.get']('cuckoo:user', 'cuckoo') }}

remove_vmcloak:
  file.absent:
    - name: /home/{{ salt['pillar.get']('cuckoo:user', 'cuckoo') }}/.vmcloak

cuckoo_clean:
  cmd.run:
    - name: cuckoo clean
    - user: {{ salt['pillar.get']('cuckoo:user', 'cuckoo') }}
    - cwd: {{ salt['pillar.get']('cuckoo:cwd') }}
    - require:
      - cmd: stop_cuckoo
