cuckoo_dependencies:
  pkg.installed:
    - refresh: True
    - pkgs:
      - git
      - python-setuptools
      - libffi-dev
      - libssl-dev
      - python-dev
      - unzip
      - libxml2-dev
      - libxslt1-dev
      - libjpeg-dev
      - libpq-dev
      - automake
      - libtool
      - libjansson-dev
      - libmagic-dev
      - mongodb
      - postgresql
      - tcpdump
      - supervisor
      - uwsgi
      - uwsgi-plugin-python
      - nginx

virtualbox:
  pkgrepo.managed:
    - name: deb http://download.virtualbox.org/virtualbox/debian {{ grains['lsb_distrib_codename'] }} contrib non-free
    - comps: contrib
    - dist: {{ grains['lsb_distrib_codename'] }}
    - file: /etc/apt/sources.list.d/oracle-virtualbox.list
    - key_url: https://www.virtualbox.org/download/oracle_vbox_2016.asc
    - require_in:
      - pkg: virtualbox
  pkg.installed:
    - name: virtualbox-{{ salt['pillar.get']('virtualbox:version') }}

pip_uninstalled:
  pkg.removed:
    - name: python-pip
    - require:
      - pkg: cuckoo_dependencies

pip:
  cmd.run:
    - name: easy_install pip
    - require:
      - pkg: pip_uninstalled

cuckoo_pip:
  cmd.run:
    - name: pip install -U psycopg2 yara-python distorm3 setuptools
    - require:
      - cmd: pip

# Cuckoo-specific setup instructions, refer to the documentation.

# Patches for Ubuntu 16.04
{% if salt['grains.get']('oscodename') == 'xenial' %}
apparmor-utils:
  pkg.installed:
    - require:
      - pkg: cuckoo_dependencies

disable_aa_tcpdump:
  cmd.run:
    - name: aa-disable /usr/sbin/tcpdump
    - runas: root
    - onlyif: '/usr/sbin/aa-status | /bin/grep "/usr/sbin/tcpdump"'
    - require:
      - pkg: apparmor-utils

tcpdump_perms:
  file.managed:
    - name: /usr/sbin/tcpdump
    - user: root
    - group: cuckoo
    - mode: 750
    - create: False
    - replace: False
    - require:
      - pkg: cuckoo_dependencies

tcpdump_path:
  cmd.run:
    - name: >
        export PATH=$PATH:/usr/sbin
    - runas: {{ salt['pillar.get']('cuckoo:user', 'cuckoo') }}
    - require:
      - user: cuckoo_user
{#
tcpdump_path:
  file.replace:
    - name: /home/cuckoo/.profile
    - pattern: "/.local/bin:"
    - repl: "/.local/bin:/usr/sbin:"
    - require:
      - user: cuckoo_user
#}
supervisor_systemd:
  file.replace:
    - name: /lib/systemd/system/supervisor.service
    - pattern: /usr/bin/
    - repl: /usr/local/bin/
    - require:
      - pkg: cuckoo_dependencies

supervisor:
  service.running:
    - enable: True
    - require:
      - pkg: cuckoo_dependencies
      - file: supervisor_systemd
{% endif %}

cuckoo_setcap:
  cmd.run:
    - name: setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump
    - require:
      - pkg: cuckoo_dependencies

mongodb:
  service.running:
    - enable: True

postgresql:
  service.running:
    - enable: True

db:
  postgres_database.present:
    - name: {{ salt['pillar.get']('db:name', 'cuckoo') }}
    - require:
      - service: postgresql

db_user:
  postgres_user.present:
    - name: {{ salt['pillar.get']('db:user', 'cuckoo') }}
    - password: {{ salt['pillar.get']('db:password', 'cuckoo') }}
    - require:
      - service: postgresql

db_priv:
  postgres_privileges.present:
    - name: {{ salt['pillar.get']('db:name', 'cuckoo') }}
    - object_name: {{ salt['pillar.get']('db:user', 'cuckoo') }}
    - object_type: database
    - privileges:
      - ALL
    - require:
      - postgres_database: db
      - postgres_user: db_user

cuckoo_user:
  group.present:
    - name: {{ salt['pillar.get']('cuckoo:user', 'cuckoo') }}
  user.present:
    - name: {{ salt['pillar.get']('cuckoo:user', 'cuckoo') }}
    - fullname: {{ salt['pillar.get']('cuckoo:user', 'cuckoo') }}
    - gid_from_name: True
    - groups:
      - vboxusers
